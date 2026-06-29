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
            TecnicoDashboardView()
                .environmentObject(authVM)

        case "pending":
            TecnicoEsperaView()
                .environmentObject(authVM)

        case "rejected":
            TecnicoRechazadoView()
                .environmentObject(authVM)

        case "pending_documents", "":
            // Sin documentos todavía → flujo de registro
            NavigationStack {
                TecnicoRegistroView()
                    .environmentObject(authVM)
            }

        default:
            // Estado desconocido → pantalla de espera
            TecnicoEsperaView()
                .environmentObject(authVM)
        }
    }
}
