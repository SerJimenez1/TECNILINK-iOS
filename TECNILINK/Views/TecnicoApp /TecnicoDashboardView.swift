import SwiftUI

struct TecnicoDashboardView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var vm = TecnicoDashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerBanner
                    statsRow
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    solicitudesSection
                        .padding(.top, 24)
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .task {
                let tecnicoId = authVM.tecnicoDocumentId
                if !tecnicoId.isEmpty {
                    await vm.loadSolicitudes(tecnicoId: tecnicoId)
                } else {
                    await authVM.loadTecnicoStatus()
                    let id = authVM.tecnicoDocumentId
                    if !id.isEmpty {
                        await vm.loadSolicitudes(tecnicoId: id)
                    }
                }
            }
        }
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [.tecniPrimary, .tecniAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hola,")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text(authVM.currentUser?.name ?? "Técnico")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Text(String(authVM.currentUser?.name.prefix(1) ?? "T"))
                                .font(.title3.bold())
                                .foregroundColor(.white)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.tecniMint)
                        .font(.caption)
                    Text("TÉCNICO VERIFICADO")
                        .font(.caption.bold())
                        .foregroundColor(.tecniMint)
                        .tracking(1)
                    Spacer()
                    Button {
                        authVM.logout()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Salir")
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatPill(
                value: "\(vm.solicitudesPendientes.count)",
                label: "Nuevas",
                icon: "bell.fill",
                color: .orange
            )
            StatPill(
                value: "\(vm.solicitudesAceptadas.count)",
                label: "En curso",
                icon: "wrench.fill",
                color: .tecniAccent
            )
            StatPill(
                value: "\(vm.solicitudesCompletadas)",
                label: "Hechos",
                icon: "checkmark.circle.fill",
                color: .tecniMint
            )
        }
    }

    // MARK: - Solicitudes

    private var solicitudesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Solicitudes nuevas")
                    .font(.headline)
                Spacer()
                if vm.solicitudesPendientes.count > 0 {
                    Text("\(vm.solicitudesPendientes.count) pendiente\(vm.solicitudesPendientes.count > 1 ? "s" : "")")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal, 20)

            if vm.isLoading {
                ProgressView("Cargando...")
                    .frame(maxWidth: .infinity)
                    .padding(40)
            } else if vm.solicitudesPendientes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.tecniGray.opacity(0.4))
                    Text("Sin solicitudes por ahora")
                        .font(.subheadline.bold())
                        .foregroundColor(.tecniGray)
                    Text("Cuando un cliente te solicite aparecerá aquí")
                        .font(.caption)
                        .foregroundColor(.tecniGray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.solicitudesPendientes) { solicitud in
                        SolicitudCard(solicitud: solicitud) {
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

// MARK: - Stat Pill

private struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.tecniGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Solicitud Card

private struct SolicitudCard: View {
    let solicitud: SolicitudIncoming
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.tecniAccent.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundColor(.tecniAccent)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(solicitud.specialty)
                        .font(.subheadline.bold())
                    Text(solicitud.userName)
                        .font(.caption)
                        .foregroundColor(.tecniGray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("S/ \(Int(solicitud.estimatedPrice))")
                        .font(.headline.bold())
                        .foregroundColor(.tecniPrimary)
                    Text("estimado")
                        .font(.caption2)
                        .foregroundColor(.tecniGray)
                }
            }

            Text(solicitud.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.horizontal, 4)

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.tecniGray)
                Text(solicitud.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.tecniGray)
            }

            Divider()

            HStack(spacing: 10) {
                Button(action: onReject) {
                    Text("Rechazar")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(10)
                }

                Button(action: onAccept) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.subheadline.bold())
                        Text("Aceptar")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.tecniMint)
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
