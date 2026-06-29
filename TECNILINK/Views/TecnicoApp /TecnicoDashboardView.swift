import SwiftUI

struct TecnicoDashboardView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var vm = TecnicoDashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    statsSection
                    solicitudesSection
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mi Panel")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        authVM.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .task {
                if let userId = authVM.currentUser?.id {
                    await vm.loadSolicitudes(tecnicoId: userId)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(authVM.currentUser?.name.prefix(1) ?? "T"))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                )

            Text(authVM.currentUser?.name ?? "Técnico")
                .font(.title2.bold())

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.tecniMint)
                Text("Técnico Verificado")
                    .font(.subheadline)
                    .foregroundColor(.tecniMint)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            TecnicoDashStatCard(
                value: "\(vm.solicitudesPendientes.count)",
                label: "Pendientes",
                icon: "clock.fill",
                color: .orange
            )
            TecnicoDashStatCard(
                value: "\(vm.solicitudesAceptadas.count)",
                label: "Aceptadas",
                icon: "checkmark.circle.fill",
                color: .tecniMint
            )
            TecnicoDashStatCard(
                value: "\(vm.solicitudesCompletadas)",
                label: "Completadas",
                icon: "star.fill",
                color: .tecniPrimary
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Solicitudes

    private var solicitudesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Solicitudes pendientes")
                .font(.headline)
                .padding(.horizontal, 20)

            if vm.isLoading {
                ProgressView("Cargando solicitudes...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if vm.solicitudesPendientes.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "Sin solicitudes",
                    subtitle: "Cuando un cliente te solicite un servicio aparecerá aquí."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.solicitudesPendientes) { solicitud in
                        SolicitudIncomingRow(solicitud: solicitud) {
                            Task { await vm.aceptarSolicitud(id: solicitud.id) }
                        } onReject: {
                            Task { await vm.rechazarSolicitud(id: solicitud.id) }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

// MARK: - Stat Card

private struct TecnicoDashStatCard: View {
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

// MARK: - Solicitud Incoming Row

private struct SolicitudIncomingRow: View {
    let solicitud: SolicitudIncoming
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(solicitud.specialty)
                        .font(.subheadline.bold())
                    Text(solicitud.userName)
                        .font(.caption)
                        .foregroundColor(.tecniGray)
                    Text(solicitud.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.tecniGray)
                }
                Spacer()
                Text("S/ \(Int(solicitud.estimatedPrice))")
                    .font(.headline.bold())
                    .foregroundColor(.tecniPrimary)
            }

            Text(solicitud.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 12) {
                Button(action: onReject) {
                    Text("Rechazar")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }

                Button(action: onAccept) {
                    Text("Aceptar")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(Color.tecniMint)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .tecniCard()
    }
}
