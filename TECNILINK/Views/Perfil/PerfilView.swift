import SwiftUI

struct PerfilView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    infoSection
                    logoutButton
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 88, height: 88)
                .overlay(
                    Text(String(authVM.currentUser?.name.prefix(1) ?? "U"))
                        .font(.system(size: 40, weight: .bold)).foregroundColor(.white)
                )

            Text(authVM.currentUser?.name ?? "Usuario")
                .font(.title2.bold())
            Text(authVM.currentUser?.email ?? "")
                .font(.subheadline).foregroundColor(.tecniGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(spacing: 10) {
            InfoRow(icon: "envelope.fill", title: "Correo electrónico", value: authVM.currentUser?.email ?? "")
            InfoRow(icon: "calendar", title: "Miembro desde",
                    value: (authVM.currentUser?.registeredAt ?? Date()).formatted(date: .abbreviated, time: .omitted))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Logout

    private var logoutButton: some View {
        Button(role: .destructive) { authVM.logout() } label: {
            Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(Color.red.opacity(0.8))
                .cornerRadius(12)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.tecniAccent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.tecniGray)
                Text(value).font(.subheadline.bold())
            }
            Spacer()
        }
        .padding()
        .tecniCard()
    }
}
