import SwiftUI

struct AdminTecnicoDetailView: View {
    let tecnico: TecnicoPendiente
    @ObservedObject var vm: AdminViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showRejectSheet = false
    @State private var rejectReason = ""
    @State private var showApproveConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                infoSection
                documentsSection
                actionButtons
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Verificar Técnico")
        .navigationBarTitleDisplayMode(.inline)
        .alert("¿Aprobar técnico?", isPresented: $showApproveConfirm) {
            Button("Aprobar", role: .none) {
                Task {
                    await vm.aprobarTecnico(id: tecnico.id)
                    dismiss()
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("El técnico aparecerá en la app con el badge VERIFICADO.")
        }
        .sheet(isPresented: $showRejectSheet) {
            rejectSheet
        }
        .overlay {
            if vm.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Procesando...")
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 88, height: 88)
                .overlay(
                    Text(String(tecnico.name.prefix(1)))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                )

            Text(tecnico.name)
                .font(.title2.bold())
            Text(tecnico.specialty)
                .font(.subheadline)
                .foregroundColor(.tecniAccent)
            Text(tecnico.email)
                .font(.caption)
                .foregroundColor(.tecniGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Información del técnico")
                .font(.headline)
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 10) {
                InfoRow(icon: "phone.fill", label: "Teléfono", value: tecnico.phone)
                InfoRow(icon: "text.alignleft", label: "Descripción", value: tecnico.description.isEmpty ? "Sin descripción" : tecnico.description)
                InfoRow(icon: "calendar", label: "Registrado", value: tecnico.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
            .padding()
            .tecniCard()
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Documents

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Documentos subidos")
                .font(.headline)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                DocumentRow(icon: "creditcard.fill", label: "DNI Frontal", url: tecnico.dniFrontURL)
                DocumentRow(icon: "creditcard", label: "DNI Posterior", url: tecnico.dniBackURL)
                DocumentRow(icon: "doc.fill", label: "Certificado técnico", url: tecnico.certificateURL)
                DocumentRow(icon: "person.fill.viewfinder", label: "Selfie con DNI", url: tecnico.selfieURL)
            }
            .padding()
            .tecniCard()
            .padding(.horizontal, 20)

            if !tecnico.workPhotos.isEmpty {
                Text("Fotos de trabajos (\(tecnico.workPhotos.count))")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(tecnico.workPhotos, id: \.self) { url in
                            AsyncImage(url: URL(string: url)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.tecniPrimary.opacity(0.1)
                                    .overlay(ProgressView())
                            }
                            .frame(width: 120, height: 120)
                            .cornerRadius(10)
                            .clipped()
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showApproveConfirm = true
            } label: {
                Label("Aprobar Técnico", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Color.tecniMint)
                    .cornerRadius(12)
            }

            Button {
                showRejectSheet = true
            } label: {
                Label("Rechazar Técnico", systemImage: "xmark.seal.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Reject Sheet

    private var rejectSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Indica el motivo del rechazo")
                    .font(.subheadline)
                    .foregroundColor(.tecniGray)

                TextEditor(text: $rejectReason)
                    .frame(height: 150)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.tecniGray.opacity(0.3), lineWidth: 1)
                    )

                Button {
                    guard !rejectReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    showRejectSheet = false
                    Task {
                        await vm.rechazarTecnico(id: tecnico.id, reason: rejectReason)
                        dismiss()
                    }
                } label: {
                    Text("Confirmar rechazo")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(rejectReason.isEmpty ? Color.red.opacity(0.4) : Color.red.opacity(0.8))
                        .cornerRadius(12)
                }
                .disabled(rejectReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Rechazar técnico")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { showRejectSheet = false }
                }
            }
        }
    }
}

// MARK: - Sub views

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.tecniAccent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.tecniGray)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

private struct DocumentRow: View {
    let icon: String
    let label: String
    let url: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.tecniAccent)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
            Spacer()
            if url != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.tecniMint)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.6))
            }
        }
    }
}
