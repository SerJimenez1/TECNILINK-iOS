import SwiftUI

struct CalificacionView: View {
    let servicio: Servicio
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int = 5
    @State private var comment = ""
    @State private var isLoading = false
    @FocusState private var commentFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    ratingSection
                    commentSection
                    submitButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calificar técnico")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Omitir") {
                        onComplete()
                        dismiss()
                    }
                    .foregroundColor(.tecniGray)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(servicio.technicianName?.prefix(1) ?? "T"))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                )

            Text(servicio.technicianName ?? "Técnico")
                .font(.title3.bold())

            Text(servicio.specialty.rawValue)
                .font(.subheadline)
                .foregroundColor(.tecniAccent)

            Text("¿Cómo fue tu experiencia?")
                .font(.subheadline)
                .foregroundColor(.tecniGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Rating

    private var ratingSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            rating = star
                        }
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 36))
                            .foregroundColor(star <= rating ? .orange : .tecniGray.opacity(0.4))
                            .scaleEffect(star <= rating ? 1.1 : 1.0)
                    }
                }
            }

            Text(ratingLabel)
                .font(.subheadline.bold())
                .foregroundColor(.orange)
                .animation(.easeInOut, value: rating)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .tecniCard()
    }

    private var ratingLabel: String {
        switch rating {
        case 1: return "Muy malo"
        case 2: return "Malo"
        case 3: return "Regular"
        case 4: return "Bueno"
        case 5: return "Excelente"
        default: return ""
        }
    }

    // MARK: - Comment

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comentario (opcional)")
                .font(.subheadline.bold())

            ZStack(alignment: .topLeading) {
                if comment.isEmpty {
                    Text("Cuéntanos cómo fue el servicio...")
                        .foregroundColor(.tecniGray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $comment)
                    .frame(height: 100)
                    .padding(4)
                    .focused($commentFocused)
                    .scrollContentBackground(.hidden)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.tecniGray.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            Task { await submitCalificacion() }
        } label: {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                        Text("Enviar calificación").font(.headline)
                    }
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(Color.tecniPrimary)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }

    // MARK: - Submit Action

    private func submitCalificacion() async {
        isLoading = true
        do {
            try await FirestoreService.shared.saveCalificacion(
                tecnicoId: servicio.technicianId,
                userId: servicio.userId,
                servicioId: servicio.id,
                rating: rating,
                comment: comment
            )
            onComplete()
            dismiss()
        } catch {
            isLoading = false
        }
    }
}
