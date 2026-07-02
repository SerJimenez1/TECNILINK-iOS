import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                switch authVM.currentUser?.role {
                case "admin":
                    AdminDashboardView()
                case "tecnico":
                    tecnicoView
                default:
                    MainTabView()
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authVM.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authVM.tecnicoStatus)
    }

    // MARK: - Tecnico View

    @ViewBuilder
    private var tecnicoView: some View {
        switch authVM.tecnicoStatus {
        case "verified":
            TecnicoTabView()
                .environmentObject(authVM)

        case "pending":
            TecnicoEsperaView()
                .environmentObject(authVM)

        case "rejected":
            TecnicoRechazadoView()
                .environmentObject(authVM)

        case "pending_documents", "":
            NavigationStack {
                TecnicoRegistroView()
                    .environmentObject(authVM)
            }

        default:
            TecnicoEsperaView()
                .environmentObject(authVM)
        }
    }
}
