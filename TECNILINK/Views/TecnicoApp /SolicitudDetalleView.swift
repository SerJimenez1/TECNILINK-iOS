import SwiftUI

struct SolicitudDetalleView: View {
    let solicitud: SolicitudIncoming
    let onAccept: () -> Void
    let onReject: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showRejectConfirm = false
    @State private var showCompleteConfirm = false
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                detalleSection
                if solicitud.status == "pending" {
                    actionButtons
                } else if solicitud.status == "accepted" {
                    completarButton
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Detalle de solicitud")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("¿Rechazar esta solicitud?", isPresented: $showRejectConfirm) {
            Button("Rechazar", role: .destructive) {
                onReject()
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        }
        .confirmationDialog("¿Marcar trabajo como completado?", isPresented: $showCompleteConfirm) {
            Button("Sí, completado") {
                Task { await marcarCompletado() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("El cliente recibirá una notificación para confirmar y liberar el pago.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                Text(String(solicitud.userName.prefix(1)))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 24)

            Text(solicitud.userName)
                .font(.title3.bold())

            Text(solicitud.specialty)
                .font(.subheadline)
                .foregroundColor(.tecniAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.tecniAccent.opacity(0.1))
                .cornerRadius(20)

            StatusChip(status: solicitud.status)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Detalle

    private var detalleSection: some View {
        VStack(spacing: 16) {
            DetalleCard(icon: "text.alignleft", title: "Descripción del problema", color: .tecniPrimary) {
                Text(solicitud.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            DetalleCard(icon: "calendar", title: "Fecha y hora programada", color: .tecniAccent) {
                Text(solicitud.scheduledDate.formatted(date: .long, time: .shortened))
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }

            DetalleCard(icon: "creditcard.fill", title: "Precio estimado por el cliente", color: .tecniMint) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("S/")
                        .font(.subheadline)
                        .foregroundColor(.tecniGray)
                    Text("\(Int(solicitud.estimatedPrice))")
                        .font(.title2.bold())
                        .foregroundColor(.tecniMint)
                }
            }

            DetalleCard(icon: "info.circle.fill", title: "Información del Escrow", color: .orange) {
                Text("El pago quedará retenido por TECNILINK hasta que el cliente confirme que el trabajo fue completado correctamente.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Action Buttons (pending)

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onAccept()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Aceptar solicitud").font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(Color.tecniMint)
                .cornerRadius(12)
            }

            Button {
                showRejectConfirm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Rechazar solicitud").font(.headline)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(Color.red.opacity(0.08))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Completar Button (accepted)

    private var completarButton: some View {
        VStack(spacing: 12) {
            Button {
                showCompleteConfirm = true
            } label: {
                ZStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Marcar como completado").font(.headline)
                        }
                        .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(Color.tecniPrimary)
                .cornerRadius(12)
            }
            .disabled(isLoading)

            Text("Al marcar como completado, el cliente recibirá una solicitud de confirmación para liberar el pago.")
                .font(.caption)
                .foregroundColor(.tecniGray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Completar

    private func marcarCompletado() async {
        isLoading = true
        do {
            try await FirestoreService.shared.updateServicioStatus(
                id: solicitud.id,
                status: "completed"
            )
            dismiss()
        } catch {
            isLoading = false
        }
    }
}

// MARK: - Sub views

private struct DetalleCard<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.subheadline.bold()).foregroundColor(.primary)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

private struct StatusChip: View {
    let status: String

    var label: String {
        switch status {
        case "pending":   return "Pendiente de respuesta"
        case "accepted":  return "Aceptada"
        case "rejected":  return "Rechazada"
        case "completed": return "Completada"
        default:          return status
        }
    }

    var color: Color {
        switch status {
        case "pending":   return .orange
        case "accepted":  return .tecniMint
        case "rejected":  return .red
        case "completed": return .tecniPrimary
        default:          return .tecniGray
        }
    }

    var body: some View {
        Text(label)
            .font(.caption.bold())
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .cornerRadius(20)
    }
}
    