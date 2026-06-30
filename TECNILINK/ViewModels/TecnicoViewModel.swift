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

    private let firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupReactiveFiltering()
    }

    // MARK: - Public actions

    func fetchTecnicos() async {
        isLoading = true
        errorMessage = nil

        do {
            let data = try await firestoreService.fetchTecnicos()
            let tecnicosFirestore = data.compactMap { parseTecnico($0) }

            if tecnicosFirestore.isEmpty {
                tecnicos = Tecnico.mockData
            } else {
                let mockSinDuplicados = Tecnico.mockData.filter { mock in
                    !tecnicosFirestore.contains(where: { $0.id == mock.id })
                }
                tecnicos = tecnicosFirestore + mockSinDuplicados
            }
        } catch {
            tecnicos = Tecnico.mockData
            errorMessage = nil
        }

        applyFilters()
        isLoading = false
    }

    func toggleSpecialty(_ specialty: Specialty) {
        selectedSpecialty = selectedSpecialty == specialty ? nil : specialty
    }

    // MARK: - Parse Firestore

    private func parseTecnico(_ dict: [String: Any]) -> Tecnico? {
        guard
            let id = dict["id"] as? String,
            let name = dict["name"] as? String,
            let specialtyRaw = dict["specialty"] as? String,
            let specialty = Specialty(rawValue: specialtyRaw),
            let phone = dict["phone"] as? String,
            let location = dict["location"] as? String
        else { return nil }

        let documents = dict["documents"] as? [String: Any] ?? [:]
        let workPhotosString = documents["workPhotos"] as? String ?? ""
        let galleryURLs: [String] = workPhotosString.isEmpty ? [] : workPhotosString.components(separatedBy: ",")

        return Tecnico(
            id: id,
            name: name,
            specialty: specialty,
            rating: dict["rating"] as? Double ?? 0.0,
            isVerified: dict["isVerified"] as? Bool ?? false,
            photoURL: documents["selfieURL"] as? String,
            description: dict["description"] as? String ?? "",
            phone: phone,
            location: location,
            reviewCount: dict["reviewCount"] as? Int ?? 0,
            completedJobs: dict["completedJobs"] as? Int ?? 0,
            reviews: [],
            galleryURLs: galleryURLs
        )
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
