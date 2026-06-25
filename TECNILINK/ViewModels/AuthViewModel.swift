import Foundation
import FirebaseAuth
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var isAuthenticated = false
    @Published var currentUser: Usuario?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firebaseService: FirebaseService

    init(firebaseService: FirebaseService = FirebaseService()) {
        self.firebaseService = firebaseService
        observeAuthState()
    }

    // MARK: - Public actions

    func login(email: String, password: String) async {
        guard validate(email: email, password: password) else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await firebaseService.signIn(email: email, password: password)
        } catch {
            errorMessage = mapError(error)
        }
        isLoading = false
    }

    func register(name: String, email: String, password: String) async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "El nombre no puede estar vacío."
            return
        }
        guard validate(email: email, password: password) else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await firebaseService.signUp(name: name, email: email, password: password)
        } catch {
            errorMessage = mapError(error)
        }
        isLoading = false
    }

    func logout() {
        do { try firebaseService.signOut() } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Private helpers

    private func observeAuthState() {
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor [weak self] in
                if let user = firebaseUser {
                    self?.currentUser = Usuario(
                        id: user.uid,
                        name: user.displayName ?? "Usuario",
                        email: user.email ?? "",
                        phone: nil,
                        profilePhotoURL: user.photoURL?.absoluteString,
                        serviceHistory: [],
                        registeredAt: Date()
                    )
                    self?.isAuthenticated = true
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }

    private func validate(email: String, password: String) -> Bool {
        if email.isEmpty || !email.contains("@") {
            errorMessage = "Ingresa un correo electrónico válido."
            return false
        }
        if password.count < 6 {
            errorMessage = "La contraseña debe tener al menos 6 caracteres."
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
        case 17026: return "La contraseña debe tener al menos 6 caracteres."
        case 17020: return "Sin conexión a internet. Verifica tu red."
        default:    return "Error inesperado. Intenta de nuevo."
        }
    }
}
