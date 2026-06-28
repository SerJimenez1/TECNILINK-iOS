import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var vm = AdminViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    statsSection
                    tecnicosPendientesSection
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Panel Admin")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar sesión") { authVM.logout() }
                        .foregroundColor(.red)
                }
            }
            .task {
                await vm.loadTecnicosPendientes()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                )
            Text("SuperAdmin")
                .font(.title2.bold())
            Text(authVM.currentUser?.email ?? "")
                .font(.subheadline)
                .foregroundColor(.tecniGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            AdminStatCard(
                value: "\(vm.tecnicosPendientes.count)",
                label: "Pendientes",
                icon: "clock.fill",
                color: .orange
            )
            AdminStatCard(
                value: "\(vm.tecnicosVerificados)",
                label: "Verificados",
                icon: "checkmark.seal.fill",
                color: .tecniMint
            )
            AdminStatCard(
                value: "\(vm.tecnicosRechazados)",
                label: "Rechazados",
                icon: "xmark.seal.fill",
                color: .red
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Tecnicos Pendientes

    private var tecnicosPendientesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Técnicos pendientes de verificación")
                .font(.headline)
                .padding(.horizontal, 20)

            if vm.isLoading {
                ProgressView("Cargando...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if vm.tecnicosPendientes.isEmpty {
                EmptyStateView(
                    icon: "checkmark.seal.fill",
                    title: "Todo al día",
                    subtitle: "No hay técnicos pendientes de verificación."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.tecnicosPendientes) { tecnico in
                        NavigationLink(destination: AdminTecnicoDetailView(tecnico: tecnico, vm: vm)) {
                            AdminTecnicoRow(tecnico: tecnico)
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Admin Stat Card

private struct AdminStatCard: View {
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
                .font(.title2.bold())
                .foregroundColor(.tecniPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(.tecniGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .tecniCard()
    }
}

// MARK: - Admin Tecnico Row

private struct AdminTecnicoRow: View {
    let tecnico: TecnicoPendiente

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.orange.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(tecnico.name.prefix(1)))
                        .font(.title3.bold())
                        .foregroundColor(.orange)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(tecnico.name)
                    .font(.subheadline.bold())
                Text(tecnico.specialty)
                    .font(.caption)
                    .foregroundColor(.tecniGray)
                Text(tecnico.email)
                    .font(.caption)
                    .foregroundColor(.tecniGray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Pendiente")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tecniGray)
            }
        }
        .padding()
        .tecniCard()
    }
}
