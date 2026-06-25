import Foundation
import Combine

@MainActor
final class TecnicoViewModel: ObservableObject {

    @Published var tecnicos: [Tecnico] = []
    @Published var filteredTecnicos: [Tecnico] = []
    @Published var selectedSpecialty: Specialty?
    @Published var searchQuery = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService: APIService
    private var cancellables = Set<AnyCancellable>()

    init(apiService: APIService = APIService()) {
        self.apiService = apiService
        setupReactiveFiltering()
    }

    // MARK: - Public actions

    func fetchTecnicos() async {
        isLoading = true
        errorMessage = nil
        do {
            tecnicos = try await apiService.fetchTecnicos()
        } catch APIError.noConnection {
            errorMessage = "Sin red: mostrando datos locales."
            tecnicos = Tecnico.mockData
        } catch {
            errorMessage = "No se pudo cargar técnicos."
            tecnicos = Tecnico.mockData
        }
        applyFilters()
        isLoading = false
    }

    func toggleSpecialty(_ specialty: Specialty) {
        selectedSpecialty = selectedSpecialty == specialty ? nil : specialty
    }

    // MARK: - Private

    private func setupReactiveFiltering() {
        Publishers.CombineLatest($searchQuery, $selectedSpecialty)
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in self?.applyFilters() }
            .store(in: &cancellables)
    }

    private func applyFilters() {
        var result = tecnicos
        if let specialty = selectedSpecialty {
            result = result.filter { $0.specialty == specialty }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.specialty.rawValue.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        filteredTecnicos = result
    }
}
