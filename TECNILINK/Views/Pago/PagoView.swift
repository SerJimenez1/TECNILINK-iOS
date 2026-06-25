import SwiftUI

struct PagoView: View {
    let servicio: Servicio
    let tecnico: Tecnico
    @State private var selectedMethod: PaymentMethod = .yape
    @State private var showConfirmation = false
    @State private var isPaying = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                escrowStatusCard
                serviceDetailCard
                paymentMethodSection
                totalCard
                payButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Pago Seguro")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Pago registrado", isPresented: $showConfirmation) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("Tu pago está retenido de forma segura. Se liberará al técnico cuando confirmes que el trabajo fue completado.")
        }
    }

    // MARK: - Escrow Status

    private var escrowStatusCard: some View {
        VStack(spacing: 14) {
            Image(systemName: servicio.escrowStatus.icon)
                .font(.system(size: 40))
                .foregroundColor(.tecniMint)
            Text(servicio.escrowStatus.displayName)
                .font(.title3.bold()).foregroundColor(.tecniPrimary)
            Text("El dinero permanece retenido hasta que confirmes la finalización del servicio.")
                .font(.caption).foregroundColor(.tecniGray).multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .tecniCard()
    }

    // MARK: - Service Detail

    private var serviceDetailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resumen del servicio").font(.headline)

            VStack(spacing: 10) {
                DetailRow(icon: "person.fill", label: "Técnico", value: tecnico.name)
                DetailRow(icon: tecnico.specialty.icon, label: "Servicio", value: tecnico.specialty.rawValue)
                DetailRow(icon: "calendar", label: "Fecha",
                          value: servicio.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                DetailRow(icon: "text.alignleft", label: "Descripción", value: servicio.description)
                Divider()
                HStack {
                    Text("Comisión TECNILINK (15%)").font(.caption).foregroundColor(.tecniGray)
                    Spacer()
                    Text("S/ \(String(format: "%.2f", servicio.estimatedPrice * 0.15))").font(.caption).foregroundColor(.tecniGray)
                }
                HStack {
                    Text("Al técnico").font(.caption).foregroundColor(.tecniGray)
                    Spacer()
                    Text("S/ \(String(format: "%.2f", servicio.estimatedPrice * 0.85))").font(.caption).foregroundColor(.tecniGray)
                }
            }
            .padding()
            .tecniCard()
        }
    }

    // MARK: - Payment Methods

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Método de pago").font(.headline)

            VStack(spacing: 10) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    PaymentMethodRow(method: method, isSelected: selectedMethod == method) {
                        selectedMethod = method
                    }
                }
            }
            .padding()
            .tecniCard()
        }
    }

    // MARK: - Total

    private var totalCard: some View {
        HStack {
            Text("Total a pagar").font(.headline)
            Spacer()
            Text("S/ \(String(format: "%.2f", servicio.estimatedPrice))")
                .font(.title2.bold()).foregroundColor(.tecniPrimary)
        }
        .padding()
        .tecniCard()
    }

    // MARK: - Pay Button

    private var payButton: some View {
        Button {
            isPaying = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPaying = false
                showConfirmation = true
            }
        } label: {
            ZStack {
                if isPaying { ProgressView().tint(.white) }
                else {
                    Label("Pagar S/ \(String(format: "%.0f", servicio.estimatedPrice)) vía \(selectedMethod.displayName)",
                          systemImage: "lock.shield.fill")
                        .font(.subheadline.bold()).foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(Color.tecniPrimary)
            .cornerRadius(12)
        }
        .disabled(isPaying)
    }
}

// MARK: - Payment Method Enum

enum PaymentMethod: CaseIterable {
    case yape, plin, card

    var displayName: String {
        switch self { case .yape: return "Yape" ; case .plin: return "Plin" ; case .card: return "Tarjeta" }
    }
    var icon: String {
        switch self { case .yape: return "qrcode" ; case .plin: return "wave.3.right" ; case .card: return "creditcard.fill" }
    }
}

// MARK: - Sub-views

private struct DetailRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundColor(.tecniAccent).frame(width: 18)
            Text(label).font(.caption).foregroundColor(.tecniGray).frame(width: 80, alignment: .leading)
            Text(value).font(.caption).lineLimit(2)
            Spacer()
        }
    }
}

private struct PaymentMethodRow: View {
    let method: PaymentMethod; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: method.icon).foregroundColor(.tecniAccent).frame(width: 24)
                Text(method.displayName).font(.subheadline)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .tecniMint : .tecniGray)
            }
        }
        .foregroundColor(.primary)
    }
}
