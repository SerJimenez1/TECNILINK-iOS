import SwiftUI

struct TecnicoListView: View {
    @EnvironmentObject private var tecnicoVM: TecnicoViewModel
    var preselectedSpecialty: Specialty?

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            specialtyFilter
            resultList
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Técnicos")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let specialty = preselectedSpecialty {
                tecnicoVM.selectedSpecialty = specialty
            }
            if tecnicoVM.tecnicos.isEmpty {
                await tecnicoVM.fetchTecnicos()
            }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.tecniGray)
            TextField("Buscar por nombre o servicio…", text: $tecnicoVM.searchQuery)
                .autocapitalization(.none)
            if !tecnicoVM.searchQuery.isEmpty {
                Button { tecnicoVM.searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.tecniGray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var specialtyFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(label: "Todos", isSelected: tecnicoVM.selectedSpecialty == nil) {
                    tecnicoVM.selectedSpecialty = nil
                }
                ForEach(Specialty.allCases, id: \.self) { specialty in
                    FilterChip(label: specialty.rawValue, icon: specialty.icon,
                               isSelected: tecnicoVM.selectedSpecialty == specialty) {
                        tecnicoVM.toggleSpecialty(specialty)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var resultList: some View {
        if tecnicoVM.isLoading {
            Spacer()
            ProgressView("Cargando técnicos…").padding()
            Spacer()
        } else if tecnicoVM.filteredTecnicos.isEmpty {
            Spacer()
            EmptyStateView(icon: "person.fill.questionmark",
                           title: "Sin resultados",
                           subtitle: "Intenta con otro nombre o categoría.")
            Spacer()
        } else {
            List(tecnicoVM.filteredTecnicos) { tecnico in
                NavigationLink(destination: TecnicoDetailView(tecnico: tecnico)) {
                    TecnicoListRow(tecnico: tecnico)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .listStyle(.plain)
            .animation(.easeInOut(duration: 0.25), value: tecnicoVM.filteredTecnicos.count)
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon).font(.caption) }
                Text(label).font(.caption.bold())
            }
            .foregroundColor(isSelected ? .white : .tecniPrimary)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(isSelected ? Color.tecniPrimary : Color.tecniPrimary.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

// MARK: - List Row

private struct TecnicoListRow: View {
    let tecnico: Tecnico

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.tecniPrimary.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(Text(String(tecnico.name.prefix(1))).font(.title2.bold()).foregroundColor(.tecniPrimary))

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    Text(tecnico.name).font(.subheadline.bold()).lineLimit(1)
                    Spacer()
                    if tecnico.isVerified { VerifiedBadge() }
                }
                HStack(spacing: 6) {
                    Image(systemName: tecnico.specialty.icon).font(.caption).foregroundColor(.tecniAccent)
                    Text(tecnico.specialty.rawValue).font(.caption).foregroundColor(.tecniGray)
                }
                HStack(spacing: 10) {
                    StarRatingView(rating: tecnico.rating)
                    Text("(\(tecnico.reviewCount))").font(.caption2).foregroundColor(.tecniGray)
                }
            }
        }
        .padding()
        .tecniCard()
    }
}
