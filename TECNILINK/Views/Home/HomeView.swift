import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var tecnicoVM = TecnicoViewModel()
    @State private var navigateToList = false
    @State private var selectedSpecialtyForNav: Specialty?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerBanner
                    searchBar
                    categoriesSection
                    featuredSection
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToList) {
                TecnicoListView(preselectedSpecialty: selectedSpecialtyForNav)
                    .environmentObject(tecnicoVM)
            }
            .task { await tecnicoVM.fetchTecnicos() }
        }
    }

    // MARK: - Header

    private var headerBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 180)
                .cornerRadius(0)

            VStack(alignment: .leading, spacing: 6) {
                Text("Hola, \(authVM.currentUser?.name.components(separatedBy: " ").first ?? "Usuario") 👋")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("¿Qué servicio necesitas hoy?")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        Button {
            selectedSpecialtyForNav = nil
            navigateToList = true
        } label: {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.tecniGray)
                Text("Buscar técnico o servicio…").foregroundColor(.tecniGray)
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, -16)
    }

    // MARK: - Categories

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Categorías").font(.headline).padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Specialty.allCases, id: \.self) { specialty in
                        CategoryCard(specialty: specialty) {
                            selectedSpecialtyForNav = specialty
                            navigateToList = true
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Featured Technicians

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Técnicos Destacados").font(.headline)
                Spacer()
                Button("Ver todos") {
                    selectedSpecialtyForNav = nil
                    navigateToList = true
                }
                .font(.subheadline).foregroundColor(.tecniAccent)
            }
            .padding(.horizontal, 20)

            if tecnicoVM.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if tecnicoVM.tecnicos.isEmpty {
                EmptyStateView(icon: "person.2", title: "Sin técnicos",
                               subtitle: "No hay técnicos disponibles en este momento.")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(tecnicoVM.tecnicos.prefix(4)) { tecnico in
                        NavigationLink(destination: TecnicoDetailView(tecnico: tecnico)) {
                            FeaturedTecnicoRow(tecnico: tecnico)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

// MARK: - Category Card

private struct CategoryCard: View {
    let specialty: Specialty
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: specialty.icon)
                    .font(.system(size: 26))
                    .foregroundColor(.tecniAccent)
                    .frame(width: 54, height: 54)
                    .background(Color.tecniAccent.opacity(0.1))
                    .cornerRadius(14)
                Text(specialty.rawValue)
                    .font(.caption).bold()
                    .foregroundColor(.tecniPrimary)
                    .multilineTextAlignment(.center)
                    .frame(width: 72)
            }
        }
    }
}

// MARK: - Featured Row

private struct FeaturedTecnicoRow: View {
    let tecnico: Tecnico

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.tecniPrimary.opacity(0.1))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(tecnico.name.prefix(1)))
                        .font(.title2.bold()).foregroundColor(.tecniPrimary)
                )
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tecnico.name).font(.subheadline.bold()).lineLimit(1)
                    if tecnico.isVerified { VerifiedBadge() }
                }
                Text(tecnico.specialty.rawValue).font(.caption).foregroundColor(.tecniGray)
                StarRatingView(rating: tecnico.rating)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(tecnico.completedJobs)").font(.headline).foregroundColor(.tecniPrimary)
                Text("trabajos").font(.caption2).foregroundColor(.tecniGray)
            }
        }
        .padding()
        .tecniCard()
    }
}
