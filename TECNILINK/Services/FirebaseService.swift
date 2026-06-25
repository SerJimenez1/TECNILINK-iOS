// Requiere Firebase SDK via Swift Package Manager:
// https://github.com/firebase/firebase-ios-sdk  →  FirebaseAuth
import Foundation
import FirebaseCore
import FirebaseAuth

final class FirebaseService {

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(name: String, email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let request = result.user.createProfileChangeRequest()
        request.displayName = name
        try await request.commitChanges()
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
}
