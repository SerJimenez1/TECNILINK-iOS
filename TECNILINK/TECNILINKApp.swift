// Antes de compilar, agrega Firebase via Swift Package Manager:
// File → Add Package Dependencies → https://github.com/firebase/firebase-ios-sdk
// Selecciona: FirebaseAuth
import SwiftUI
import FirebaseCore

@main
struct TECNILINKApp: App {

    @StateObject private var authVM = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
        }
    }
}
