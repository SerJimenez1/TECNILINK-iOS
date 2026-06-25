import SwiftUI

struct PerfilView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var vm = SolicitudViewModel()
    @State private var showDeleteConfirm = false
    @State private var selectedServicioId: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    statsCards
                    historySection
                    logoutButton
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { vm.loadHistory(for: authVM.currentUser?.id ?? "") }
            .confirmationDialog("¿Eliminar esta solicitud?", isPresented: $showDeleteConfirm) {
                Button("Eliminar", role: .destructive) {
                    if let id = selectedServicioId {
                        vm.deleteServicio(id: id, userId: authVM.currentUser?.id ?? "")
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
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

    // MARK: - Stats

    private var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(vm.servicios.count)", label: "Servicios")
            StatCard(value: "\(vm.servicios.filter { $0.status == .completed }.count)", label: "Completados")
            StatCard(
                value: "S/ \(Int(vm.servicios.map(\.estimatedPrice).reduce(0, +)))",
                label: "Total pagado"
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Historial de servicios")
                .font(.headline).padding(.horizontal, 20)

            if vm.servicios.isEmpty {
                EmptyStateView(icon: "tray",
                               title: "Sin servicios aún",
                               subtitle: "Solicita tu primer técnico desde la pantalla de inicio.")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(vm.servicios) { servicio in
                        ServicioHistoryRow(servicio: servicio) {
                            selectedServicioId = servicio.id
                            showDeleteConfirm = true
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
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

// MARK: - Sub-views

private struct StatCard: View {
    let value: String; let label: String
    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.headline.bold()).foregroundColor(.tecniPrimary)
            Text(label).font(.caption).foregroundColor(.tecniGray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .tecniCard()
    }
}

private struct ServicioHistoryRow: View {
    let servicio: Servicio
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: servicio.specialty.icon)
                .font(.title3).foregroundColor(.tecniAccent)
                .frame(width: 44, height: 44)
                .background(Color.tecniAccent.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(servicio.specialty.rawValue).font(.subheadline.bold())
                Text(servicio.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundColor(.tecniGray)
                Text("S/ \(String(format: "%.0f", servicio.estimatedPrice))")
                    .font(.caption).foregroundColor(.tecniPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                StatusBadge(status: servicio.status)
                Button { onDelete() } label: {
                    Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.7))
                }
            }
        }
        .padding()
        .tecniCard()
    }
}
