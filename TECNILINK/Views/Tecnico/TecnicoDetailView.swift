import SwiftUI

struct TecnicoDetailView: View {
    let tecnico: Tecnico
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showSolicitud = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                    .padding(.bottom, 20)

                statsRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                if !tecnico.description.isEmpty {
                    infoSection(title: "Sobre el técnico") {
                        Text(tecnico.description).font(.body).foregroundColor(.secondary)
                    }
                }

                infoSection(title: "Contacto") {
                    HStack {
                        Image(systemName: "phone.fill").foregroundColor(.tecniMint)
                        Text(tecnico.phone).font(.subheadline)
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "mappin.circle.fill").foregroundColor(.tecniAccent)
                        Text(tecnico.location).font(.subheadline)
                        Spacer()
                    }
                }

                if !tecnico.reviews.isEmpty {
                    reviewsSection
                }

                requestButton
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(tecnico.specialty.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSolicitud) {
            SolicitudView(tecnico: tecnico)
                .environmentObject(authVM)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [.tecniPrimary, .tecniAccent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 110)

                // Avatar
                Circle()
                    .fill(Color.white)
                    .frame(width: 96, height: 96)
                    .overlay(
                        Circle()
                            .fill(LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 88, height: 88)
                    )
                    .overlay(
                        Text(String(tecnico.name.prefix(1)))
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(y: 55)
            }
            .frame(height: 110)

            // Espacio reservado para que el avatar no se encime con el texto
            Spacer().frame(height: 50)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(tecnico.name)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    if tecnico.isVerified {
                        VerifiedBadge()
                    }
                }

                StarRatingView(rating: tecnico.rating)

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.tecniMint)
                        .font(.caption)
                    Text("DNI Validado")
                        .font(.caption.bold())
                        .foregroundColor(.tecniMint)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: "\(tecnico.completedJobs)", label: "Trabajos")
            Divider().frame(height: 40)
            statItem(value: String(format: "%.1f", tecnico.rating), label: "Calificación")
            Divider().frame(height: 40)
            statItem(value: "\(tecnico.reviewCount)", label: "Reseñas")
        }
        .padding()
        .tecniCard()
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline.bold()).foregroundColor(.tecniPrimary)
            Text(label).font(.caption).foregroundColor(.tecniGray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Info Section

    private func infoSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).padding(.horizontal, 20)
            VStack(alignment: .leading, spacing: 10) { content() }
                .padding()
                .tecniCard()
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Reviews

    private var reviewsSection: some View {
        infoSection(title: "Reseñas (\(tecnico.reviewCount))") {
            ForEach(tecnico.reviews.prefix(3)) { review in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(review.authorName).font(.subheadline.bold())
                        Spacer()
                        StarRatingView(rating: review.rating)
                    }
                    Text(review.comment).font(.caption).foregroundColor(.secondary)
                }
                if review.id != tecnico.reviews.prefix(3).last?.id {
                    Divider()
                }
            }
        }
    }

    // MARK: - CTA

    private var requestButton: some View {
        Button { showSolicitud = true } label: {
            Label("Solicitar Servicio", systemImage: "calendar.badge.plus")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(Color.tecniMint)
                .cornerRadius(12)
        }
    }
}
    