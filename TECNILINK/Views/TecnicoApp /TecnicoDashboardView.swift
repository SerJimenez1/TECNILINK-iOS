import SwiftUI

enum FiltroSolicitud: String, CaseIterable {
    case pendientes = "Nuevas"
    case aceptadas = "En curso"
    case rechazadas = "Rechazadas"
    case completadas = "Completadas"

    var icono: String {
        switch self {
        case .pendientes:  return "bell.fill"
        case .aceptadas:   return "wrench.fill"
        case .rechazadas:  return "xmark.circle.fill"
        case .completadas: return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .pendientes:  return .orange
        case .aceptadas:   return .tecniAccent
        case .rechazadas:  return .red
        case .completadas: return .tecniPrimary
        }
    }
}

struct TecnicoDashboardView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var vm = TecnicoDashboardViewModel()
    @State private var filtroActivo: FiltroSolicitud = .pendientes

    var solicitudesFiltradas: [SolicitudIncoming] {
        switch filtroActivo {
        case .pendientes:  return vm.solicitudesPendientes
        case .aceptadas:   return vm.solicitudesAceptadas
        case .rechazadas:  return vm.solicitudesRechazadas
        case .completadas: return vm.solicitudesCompletadas
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBanner
                filtrosBar
                    .padding(.vertical, 12)
                    .background(Color(.systemGroupedBackground))

                if vm.isLoading {
                    Spacer()
                    ProgressView("Cargando...")
                    Spacer()
                } else if solicitudesFiltradas.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(solicitudesFiltradas) { solicitud in
                                NavigationLink(destination: SolicitudDetalleView(
                                    solicitud: solicitud,
                                    onAccept: { Task { await vm.aceptarSolicitud(id: solicitud.id) } },
                                    onReject: { Task { await vm.rechazarSolicitud(id: solicitud.id) } }
                                )) {
                                    SolicitudCard(solicitud: solicitud, color: filtroActivo.color)
                                        .padding(.horizontal, 20)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.bottom, 32)
                    }
                    .background(Color(.systemGroupedBackground))
                }
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
            .frame(height: 160)

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
                            Text("Salir").font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Filtros Bar

    private var filtrosBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(FiltroSolicitud.allCases, id: \.self) { filtro in
                    let count = conteo(filtro)
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            filtroActivo = filtro
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: filtro.icono)
                                .font(.caption)
                            Text(filtro.rawValue)
                                .font(.subheadline.bold())
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption2.bold())
                                    .foregroundColor(filtroActivo == filtro ? filtro.color : .white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(filtroActivo == filtro ? filtro.color.opacity(0.2) : Color.white.opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                        .foregroundColor(filtroActivo == filtro ? filtro.color : .tecniGray)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(filtroActivo == filtro ? filtro.color.opacity(0.1) : Color(.systemBackground))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(filtroActivo == filtro ? filtro.color : Color.clear, lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: filtroActivo == .pendientes ? "moon.zzz.fill" : "tray.fill")
                .font(.system(size: 44))
                .foregroundColor(.tecniGray.opacity(0.4))
            Text(filtroActivo == .pendientes ? "Sin solicitudes nuevas" : "Sin solicitudes \(filtroActivo.rawValue.lowercased())")
                .font(.subheadline.bold())
                .foregroundColor(.tecniGray)
            Text(filtroActivo == .pendientes ? "Cuando un cliente te solicite aparecerá aquí" : "")
                .font(.caption)
                .foregroundColor(.tecniGray.opacity(0.7))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Conteo helper

    private func conteo(_ filtro: FiltroSolicitud) -> Int {
        switch filtro {
        case .pendientes:  return vm.solicitudesPendientes.count
        case .aceptadas:   return vm.solicitudesAceptadas.count
        case .rechazadas:  return vm.solicitudesRechazadas.count
        case .completadas: return vm.solicitudesCompletadas.count
        }
    }
}

// MARK: - Solicitud Card

private struct SolicitudCard: View {
    let solicitud: SolicitudIncoming
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(color)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(solicitud.specialty).font(.subheadline.bold())
                Text(solicitud.userName).font(.caption).foregroundColor(.tecniGray)
                Text(solicitud.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundColor(.tecniGray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("S/ \(Int(solicitud.estimatedPrice))")
                    .font(.subheadline.bold())
                    .foregroundColor(color)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tecniGray)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
