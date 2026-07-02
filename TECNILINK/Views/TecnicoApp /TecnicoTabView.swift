import SwiftUI

struct TecnicoTabView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        TabView {
            TecnicoDashboardView()
                .environmentObject(authVM)
                .tabItem {
                    Label("Solicitudes", systemImage: "list.bullet.clipboard.fill")
                }

            TecnicoPerfilView()
                .environmentObject(authVM)
                .tabItem {
                    Label("Mi Perfil", systemImage: "person.circle.fill")
                }
        }
        .tint(.tecniPrimary)
    }
}
