import SwiftUI

struct TecnicoPerfilView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    infoSection
                    statsSection
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

    private var headerSection: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 88, height: 88)
                .overlay(
                    Text(String(authVM.currentUser?.name.prefix(1) ?? "T"))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                )

            Text(authVM.currentUser?.name ?? "Técnico")
                .font(.title2.bold())

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.tecniMint)
                    .font(.caption)
                Text("TÉCNICO VERIFICADO")
                    .font(.caption.bold())
                    .foregroundColor(.tecniMint)
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(spacing: 10) {
            InfoRow(icon: "envelope.fill", title: "Correo electrónico",
                    value: authVM.currentUser?.email ?? "")
            InfoRow(icon: "calendar", title: "Miembro desde",
                    value: (authVM.currentUser?.registeredAt ?? Date())
                        .formatted(date: .abbreviated, time: .omitted))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mi actividad")
                .font(.headline)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                StatCard(value: "0", label: "Completados", icon: "checkmark.seal.fill", color: .tecniMint)
                StatCard(value: "0.0", label: "Calificación", icon: "star.fill", color: .orange)
                StatCard(value: "0", label: "Reseñas", icon: "bubble.left.fill", color: .tecniAccent)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Logout

    private var logoutButton: some View {
        Button(role: .destructive) {
            authVM.logout()
        } label: {
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

// MARK: - Sub views

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

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.tecniGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .tecniCard()
    }
}
