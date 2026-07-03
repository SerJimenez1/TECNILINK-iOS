import Foundation
import FirebaseAuth
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var isAuthenticated = false
    @Published var currentUser: Usuario?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var navigateToTecnicoRegistro = false
    @Published var tecnicoStatus: String = ""
    @Published var tecnicoDocumentId: String = ""

    private let firebaseService: FirebaseService
    private let firestoreService = FirestoreService.shared

    // Mientras es true, el listener de Auth (observeAuthState) no toca
    // currentUser ni isAuthenticated. Evita que el listener lea Firestore
    // ANTES de que signUp() termine de guardar el documento (race condition
    // que causaba el flash de MainTabView antes de corregirse a TecnicoRegistroView).
    private var isRegistering = false

    init(firebaseService: FirebaseService = FirebaseService()) {
        self.firebaseService = firebaseService
        observeAuthState()
    }

    // MARK: - Public actions

    func login(email: String, password: String) async {
        guard validateEmail(email) else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await firebaseService.signIn(email: email, password: password)
        } catch {
            errorMessage = mapError(error)
        }
        isLoading = false
    }

    func register(name: String, email: String, password: String, role: String = "user") async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "El nombre no puede estar vacío."
            return
        }
        guard validate(email: email, password: password) else { return }
        isLoading = true
        errorMessage = nil
        isRegistering = true   // el listener no debe reaccionar mientras hacemos esto nosotros mismos
        do {
            try await firebaseService.signUp(name: name, email: email, password: password, role: role)

            // signUp ya terminó -> Firestore ya tiene el doc con el role correcto.
            // Leemos nosotros mismos (el listener está silenciado por isRegistering).
            if let firebaseUser = Auth.auth().currentUser {
                await loadUserFromFirestore(firebaseUser: firebaseUser)
                // loadUserFromFirestore ya llama a loadTecnicoStatus() internamente
                // cuando role == "tecnico", así que currentUser y tecnicoStatus
                // quedan listos ANTES de marcar isAuthenticated = true.
            }

            // Recién ahora activamos isAuthenticated, con currentUser.role y
            // tecnicoStatus ya correctos. Así ContentView nunca llega a pintar
            // MainTabView de por medio.
            isAuthenticated = true
        } catch {
            errorMessage = mapError(error)
        }
        isRegistering = false
        isLoading = false
    }

    func loginWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            try await firebaseService.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        do { try firebaseService.signOut() } catch { errorMessage = error.localizedDescription }
        currentUser = nil
        isAuthenticated = false
        navigateToTecnicoRegistro = false
        tecnicoStatus = ""
        tecnicoDocumentId = ""
    }

    // MARK: - Tecnico Status

    func loadTecnicoStatus() async {
        // currentUser puede no estar listo aún (se llena de forma async vía el
        // listener de Auth), así que caemos a Auth.auth().currentUser?.uid,
        // que sí está disponible inmediatamente después de signUp/signIn.
        guard let userId = currentUser?.id ?? Auth.auth().currentUser?.uid else { return }
        do {
            let data = try await firestoreService.fetchTecnicoByUserId(userId)
            tecnicoStatus = data?["verificationStatus"] as? String ?? "pending_documents"
            tecnicoDocumentId = data?["id"] as? String ?? ""
        } catch {
            tecnicoStatus = "pending_documents"
            tecnicoDocumentId = ""
        }
    }

    // MARK: - Private helpers

    private func observeAuthState() {
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor [weak self] in
                guard let self else { return }
                // register() ya se está encargando de leer Firestore y setear
                // currentUser/isAuthenticated con los datos correctos. Si el
                // listener también lo hiciera aquí, podría leer Firestore antes
                // de que el documento exista (role="user" por fallback) y
                // causar el flash de MainTabView antes de corregirse.
                if self.isRegistering { return }
                if let user = firebaseUser {
                    await self.loadUserFromFirestore(firebaseUser: user)
                    self.isAuthenticated = true
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
                    self.tecnicoStatus = ""
                    self.tecnicoDocumentId = ""
                }
            }
        }
    }

    // Antes era `private`. Se quitó el modificador para poder llamarla
    // explícitamente desde register() y forzar una relectura de Firestore
    // una vez que signUp() ya terminó de escribir el documento.
    func loadUserFromFirestore(firebaseUser: FirebaseAuth.User) async {
        do {
            let data = try await firestoreService.fetchUsuario(id: firebaseUser.uid)
            if let data = data {
                let role = data["role"] as? String ?? "user"
                currentUser = Usuario(
                    id: firebaseUser.uid,
                    name: data["name"] as? String ?? firebaseUser.displayName ?? "Usuario",
                    email: data["email"] as? String ?? firebaseUser.email ?? "",
                    phone: data["phone"] as? String,
                    profilePhotoURL: data["profilePhotoURL"] as? String ?? firebaseUser.photoURL?.absoluteString,
                    serviceHistory: data["serviceHistory"] as? [String] ?? [],
                    registeredAt: (data["registeredAt"] as? Date) ?? Date(),
                    role: role
                )
                if role == "tecnico" {
                    await loadTecnicoStatus()
                }
            } else {
                currentUser = Usuario(
                    id: firebaseUser.uid,
                    name: firebaseUser.displayName ?? "Usuario",
                    email: firebaseUser.email ?? "",
                    phone: nil,
                    profilePhotoURL: firebaseUser.photoURL?.absoluteString,
                    serviceHistory: [],
                    registeredAt: Date(),
                    role: "user"
                )
            }
        } catch {
            currentUser = Usuario(
                id: firebaseUser.uid,
                name: firebaseUser.displayName ?? "Usuario",
                email: firebaseUser.email ?? "",
                phone: nil,
                profilePhotoURL: firebaseUser.photoURL?.absoluteString,
                serviceHistory: [],
                registeredAt: Date(),
                role: "user"
            )
        }
    }

    private func validateEmail(_ email: String) -> Bool {
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Ingresa tu correo electrónico."
            return false
        }
        let emailRegex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        guard email.range(of: emailRegex, options: .regularExpression) != nil else {
            errorMessage = "Ingresa un correo electrónico válido."
            return false
        }
        return true
    }

    private func validate(email: String, password: String) -> Bool {
        guard validateEmail(email) else { return false }
        if password.count < 8 {
            errorMessage = "La contraseña debe tener al menos 8 caracteres."
            return false
        }
        if !password.contains(where: { $0.isUppercase }) {
            errorMessage = "La contraseña debe tener al menos una mayúscula."
            return false    
        }
        if !password.contains(where: { $0.isNumber }) {
            errorMessage = "La contraseña debe tener al menos un número."
            return false
        }
        return true
    }

    private func mapError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case 17004: return "Correo o contraseña incorrectos."
        case 17007: return "Este correo ya está registrado."
        case 17008: return "Formato de correo inválido."
        case 17026: return "La contraseña debe tener al menos 8 caracteres."
        case 17020: return "Sin conexión a int  ernet. Verifica tu red."
        default:    return "Error inesperado. Intenta de nuevo."
        }
    }
}
