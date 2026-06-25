import SwiftUI

struct SolicitudView: View {
    let tecnico: Tecnico
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var vm = SolicitudViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showPago = false
    @State private var createdServicio: Servicio?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                technicianCard
                formSection
                priceSection
                sendButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Solicitar Servicio")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showPago) {
            if let servicio = createdServicio {
                PagoView(servicio: servicio, tecnico: tecnico)
            }
        }
        .alert("Solicitud enviada", isPresented: .constant(vm.successMessage != nil)) {
            Button("Ver pago") {
                createdServicio = buildPreviewServicio()
                showPago = true
                vm.successMessage = nil
            }
            Button("Volver al inicio", role: .cancel) {
                vm.successMessage = nil
                dismiss()
            }
        } message: {
            Text(vm.successMessage ?? "")
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Technician summary card

    private var technicianCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.tecniPrimary.opacity(0.1))
                .frame(width: 54, height: 54)
                .overlay(Text(String(tecnico.name.prefix(1))).font(.title2.bold()).foregroundColor(.tecniPrimary))
            VStack(alignment: .leading, spacing: 4) {
                Text(tecnico.name).font(.subheadline.bold())
                HStack(spacing: 5) {
                    Image(systemName: tecnico.specialty.icon).foregroundColor(.tecniAccent).font(.caption)
                    Text(tecnico.specialty.rawValue).font(.caption).foregroundColor(.tecniGray)
                }
            }
            Spacer()
            if tecnico.isVerified { VerifiedBadge() }
        }
        .padding()
        .tecniCard()
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detalles del servicio").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Label("Fecha y hora", systemImage: "calendar").font(.subheadline.bold()).foregroundColor(.tecniPrimary)
                DatePicker("", selection: $vm.selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
            .padding()
            .tecniCard()

            VStack(alignment: .leading, spacing: 8) {
                Label("Descripción del problema", systemImage: "text.alignleft").font(.subheadline.bold()).foregroundColor(.tecniPrimary)
                TextEditor(text: $vm.description)
                    .frame(minHeight: 100)
                    .overlay(
                        Group {
                            if vm.description.isEmpty {
                                Text("Describe brevemente qué necesitas (ej: cambiar tomacorriente, arreglar tubería, etc.)")
                                    .foregroundColor(.secondary).font(.caption)
                                    .padding(8)
                                    .allowsHitTesting(false)
                            }
                        }, alignment: .topLeading
                    )
            }
            .padding()
            .tecniCard()
        }
    }

    // MARK: - Price

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Precio estimado").font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Text("S/ \(Int(vm.estimatedPrice))").font(.title2.bold()).foregroundColor(.tecniPrimary)
                    Spacer()
                    Text("promedio S/ 200").font(.caption).foregroundColor(.tecniGray)
                }
                Slider(value: $vm.estimatedPrice, in: 50...1000, step: 10)
                    .tint(.tecniAccent)
                HStack {
                    Text("S/ 50").font(.caption2).foregroundColor(.tecniGray)
                    Spacer()
                    Text("S/ 1,000").font(.caption2).foregroundColor(.tecniGray)
                }
            }
            .padding()
            .tecniCard()

            Text("El pago se retiene en Escrow hasta confirmar el trabajo completado.")
                .font(.caption).foregroundColor(.tecniGray)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Send

    private var sendButton: some View {
        Button {
            Task {
                await vm.createSolicitud(
                    technicianId: tecnico.id,
                    technicianName: tecnico.name,
                    specialty: tecnico.specialty,
                    userId: authVM.currentUser?.id ?? ""
                )
            }
        } label: {
            ZStack {
                if vm.isLoading { ProgressView().tint(.white) }
                else { Label("Enviar Solicitud", systemImage: "paperplane.fill").font(.headline).foregroundColor(.white) }
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(Color.tecniMint)
            .cornerRadius(12)
        }
        .disabled(vm.isLoading)
    }

    // MARK: - Helper

    private func buildPreviewServicio() -> Servicio {
        Servicio(id: UUID().uuidString, specialty: tecnico.specialty,
                 description: vm.description, estimatedPrice: vm.estimatedPrice,
                 scheduledDate: vm.selectedDate, status: .pending,
                 technicianId: tecnico.id, userId: authVM.currentUser?.id ?? "",
                 technicianName: tecnico.name, escrowStatus: .held)
    }
}
