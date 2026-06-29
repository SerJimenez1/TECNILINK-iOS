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

    private let firebaseService: FirebaseService
    private let firestoreService = FirestoreService.shared

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
        do {
            try await firebaseService.signUp(name: name, email: email, password: password, role: role)
            if role == "tecnico" {
                navigateToTecnicoRegistro = true
            }
        } catch {
            errorMessage = mapError(error)
        }
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
    }

    // MARK: - Tecnico Status

    func loadTecnicoStatus() async {
        guard let userId = currentUser?.id else { return }
        do {
            let data = try await firestoreService.fetchTecnicoByUserId(userId)
            tecnicoStatus = data?["verificationStatus"] as? String ?? "pending_documents"
        } catch {
            tecnicoStatus = "pending_documents"
        }
    }

    // MARK: - Private helpers

    private func observeAuthState() {
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let user = firebaseUser {
                    await self.loadUserFromFirestore(firebaseUser: user)
                    self.isAuthenticated = true
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
                    self.tecnicoStatus = ""
                }
            }
        }
    }

    private func loadUserFromFirestore(firebaseUser: FirebaseAuth.User) async {
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
                // Si es técnico cargar su estado de verificación
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

    // Validación solo email — para login
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

    // Validación completa email + contraseña — para registro
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
        case 17020: return "Sin conexión a internet. Verifica tu red."
        default:    return "Error inesperado. Intenta de nuevo."
        }
    }
}
