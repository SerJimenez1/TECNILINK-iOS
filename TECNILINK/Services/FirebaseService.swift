import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

final class FirebaseService {

    private let firestoreService = FirestoreService.shared

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(name: String, email: String, password: String, role: String = "user") async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let request = result.user.createProfileChangeRequest()
        request.displayName = name
        try await request.commitChanges()

        // Guardar usuario en Firestore con el rol correcto
        try await firestoreService.saveUsuario(
            id: result.user.uid,
            name: name,
            email: email,
            role: role
        )
    }

    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = await windowScene.windows.first?.rootViewController else {
            throw AuthError.missingRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)

        // Si es la primera vez guarda en Firestore como user por defecto
        if authResult.additionalUserInfo?.isNewUser == true {
            let name = result.user.profile?.name ?? "Usuario"
            let email = authResult.user.email ?? ""

            let request = authResult.user.createProfileChangeRequest()
            request.displayName = name
            try await request.commitChanges()

            try await firestoreService.saveUsuario(
                id: authResult.user.uid,
                name: name,
                email: email,
                role: "user"
            )
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case missingClientID
    case missingRootViewController
    case missingToken

    var errorDescription: String? {
        switch self {
        case .missingClientID: return "Error de configuración de Google."
        case .missingRootViewController: return "No se pudo abrir el login de Google."
        case .missingToken: return "No se pudo obtener el token de Google."
        }
    }
}
