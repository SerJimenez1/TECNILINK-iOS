import SwiftUI

struct SolicitudView: View {
    let tecnico: Tecnico
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var vm = SolicitudViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var priceText: String = "200"
    @FocusState private var priceFieldFocused: Bool

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
        .alert("Solicitud enviada", isPresented: .constant(vm.successMessage != nil)) {
            Button("Entendido") {
                vm.successMessage = nil
                dismiss()
            }
        } message: {
            Text("Tu solicitud fue enviada al técnico. Cuando la acepte, podrás proceder con el pago desde \"Mis Servicios\".")
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onAppear {
            priceText = String(Int(vm.estimatedPrice))
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

            VStack(spacing: 12) {
                HStack {
                    Text("S/")
                        .font(.title2.bold())
                        .foregroundColor(.tecniPrimary)

                    TextField("0", text: $priceText)
                        .font(.title2.bold())
                        .foregroundColor(.tecniPrimary)
                        .keyboardType(.numberPad)
                        .focused($priceFieldFocused)
                        .onChange(of: priceText) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue { priceText = filtered }

                            if let value = Double(filtered) {
                                let clamped = min(max(value, 0), 3_000)
                                vm.estimatedPrice = clamped
                            } else {
                                vm.estimatedPrice = 0
                            }
                        }

                    Spacer()

                    Text("promedio S/ 200")
                        .font(.caption)
                        .foregroundColor(.tecniGray)
                }

                Slider(
                    value: Binding(
                        get: { vm.estimatedPrice },
                        set: { newValue in
                            vm.estimatedPrice = newValue
                            priceText = String(Int(newValue))
                        }
                    ),
                    in: 0...3_000,
                    step: 10
                )
                .tint(.tecniAccent)

                HStack {
                    Text("S/ 0").font(.caption2).foregroundColor(.tecniGray)
                    Spacer()
                    Text("S/ 3,000").font(.caption2).foregroundColor(.tecniGray)
                }
            }
            .padding()
            .tecniCard()

            Text("El pago se retiene en Escrow hasta confirmar el trabajo completado.")
                .font(.caption).foregroundColor(.tecniGray)
                .padding(.horizontal, 4)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") { priceFieldFocused = false }
            }
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
        .disabled(vm.isLoading || vm.estimatedPrice <= 0)
    }
}
