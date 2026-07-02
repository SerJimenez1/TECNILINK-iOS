import SwiftUI

struct MisServiciosView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var vm = SolicitudViewModel()
    @State private var showDeleteConfirm = false
    @State private var selectedServicioId: String?
    @State private var showCalificacion = false
    @State private var servicioACalificar: Servicio?

    var pendientes: [Servicio] { vm.servicios.filter { $0.status == .pending } }
    var aceptadas: [Servicio] { vm.servicios.filter { $0.status == .accepted } }
    var completadas: [Servicio] { vm.servicios.filter { $0.status == .completed } }
    var rechazadas: [Servicio] { vm.servicios.filter { $0.status == .rejected } }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statsCards
                if vm.isLoading {
                    ProgressView("Cargando...")
                        .frame(maxWidth: .infinity)
                        .padding(40)
                } else if vm.servicios.isEmpty {
                    EmptyStateView(icon: "tray",
                                   title: "Sin servicios aún",
                                   subtitle: "Solicita tu primer técnico desde la pantalla de inicio.")
                } else {
                    if !pendientes.isEmpty {
                        seccionServicios(titulo: "Pendientes", icono: "clock.fill",
                                         color: .orange, servicios: pendientes)
                    }
                    if !aceptadas.isEmpty {
                        seccionServicios(titulo: "Aceptadas", icono: "checkmark.circle.fill",
                                         color: .tecniMint, servicios: aceptadas)
                    }
                    if !completadas.isEmpty {
                        seccionCompletadas()
                    }
                    if !rechazadas.isEmpty {
                        seccionServicios(titulo: "Rechazadas", icono: "xmark.circle.fill",
                                         color: .red, servicios: rechazadas)
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Mis Servicios")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await vm.loadHistory(for: authVM.currentUser?.id ?? "")
        }
        .task {
            await vm.loadHistory(for: authVM.currentUser?.id ?? "")
        }
        .sheet(isPresented: $showCalificacion) {
            if let servicio = servicioACalificar {
                CalificacionView(servicio: servicio) {
                    Task { await vm.loadHistory(for: authVM.currentUser?.id ?? "") }
                }
            }
        }
        .confirmationDialog("¿Eliminar esta solicitud?", isPresented: $showDeleteConfirm) {
            Button("Eliminar", role: .destructive) {
                if let id = selectedServicioId {
                    Task {
                        await vm.deleteServicio(id: id, userId: authVM.currentUser?.id ?? "")
                    }
                }
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Stats

    private var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(pendientes.count)", label: "Pendientes", color: .orange)
            StatCard(value: "\(aceptadas.count)", label: "Aceptadas", color: .tecniMint)
            StatCard(value: "\(completadas.count)", label: "Completadas", color: .tecniPrimary)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Sección normal

    private func seccionServicios(titulo: String, icono: String, color: Color, servicios: [Servicio]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icono).foregroundColor(color).font(.subheadline)
                Text(titulo).font(.headline)
                Text("\(servicios.count)")
                    .font(.caption.bold()).foregroundColor(color)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(color.opacity(0.12)).cornerRadius(10)
            }
            .padding(.horizontal, 20)

            LazyVStack(spacing: 10) {
                ForEach(servicios) { servicio in
                    ServicioHistoryRow(servicio: servicio) {
                        selectedServicioId = servicio.id
                        showDeleteConfirm = true
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Sección completadas

    private func seccionCompletadas() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill").foregroundColor(.tecniPrimary).font(.subheadline)
                Text("Completadas").font(.headline)
                Text("\(completadas.count)")
                    .font(.caption.bold()).foregroundColor(.tecniPrimary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.tecniPrimary.opacity(0.12)).cornerRadius(10)
            }
            .padding(.horizontal, 20)

            LazyVStack(spacing: 10) {
                ForEach(completadas) { servicio in
                    CompletadaRow(servicio: servicio) {
                        Task {
                            try? await FirestoreService.shared.updateServicioStatus(
                                id: servicio.id, status: "confirmed"
                            )
                            servicioACalificar = servicio
                            showCalificacion = true
                            await vm.loadHistory(for: authVM.currentUser?.id ?? "")
                        }
                    } onDelete: {
                        selectedServicioId = servicio.id
                        showDeleteConfirm = true
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Sub-views

private struct StatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.headline.bold()).foregroundColor(color)
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
                Text(servicio.technicianName ?? "Técnico")
                    .font(.caption).foregroundColor(.tecniGray)
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

private struct CompletadaRow: View {
    let servicio: Servicio
    let onConfirm: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: servicio.specialty.icon)
                    .font(.title3).foregroundColor(.tecniPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.tecniPrimary.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(servicio.specialty.rawValue).font(.subheadline.bold())
                    Text(servicio.technicianName ?? "Técnico")
                        .font(.caption).foregroundColor(.tecniGray)
                    Text("S/ \(String(format: "%.0f", servicio.estimatedPrice))")
                        .font(.caption).foregroundColor(.tecniPrimary)
                }

                Spacer()

                Button { onDelete() } label: {
                    Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.7))
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.tecniPrimary).font(.caption)
                Text("El técnico marcó este trabajo como completado")
                    .font(.caption).foregroundColor(.tecniGray)
            }

            Button(action: onConfirm) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("Confirmar trabajo completado")
                        .font(.subheadline.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(Color.tecniPrimary)
                .cornerRadius(10)
            }
        }
        .padding()
        .tecniCard()
    }
}
