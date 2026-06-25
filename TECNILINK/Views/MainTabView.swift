import SwiftUI
import Combine

struct MainTabView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Inicio", systemImage: "house.fill")
            }

            NavigationStack {
                TecnicoListView(preselectedSpecialty: nil)
                    .environmentObject(TecnicoViewModel())
            }
            .tabItem {
                Label("Técnicos", systemImage: "person.2.fill")
            }

            NavigationStack {
                PerfilView()
            }
            .tabItem {
                Label("Mi Perfil", systemImage: "person.circle.fill")
            }
        }
        .tint(.tecniPrimary)
    }
}
