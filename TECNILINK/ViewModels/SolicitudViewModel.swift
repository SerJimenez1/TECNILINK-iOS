import Foundation
import Combine

@MainActor
final class SolicitudViewModel: ObservableObject {

    @Published var servicios: [Servicio] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // Form fields
    @Published var selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @Published var description = ""
    @Published var estimatedPrice: Double = 150

    private let coreDataManager: CoreDataManager
    private let apiService: APIService

    init(coreDataManager: CoreDataManager = .shared, apiService: APIService = APIService()) {
        self.coreDataManager = coreDataManager
        self.apiService = apiService
    }

    // MARK: - Create

    func createSolicitud(technicianId: String, technicianName: String,
                         specialty: Specialty, userId: String) async {
        guard validateForm() else { return }
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let servicio = Servicio(
            id: UUID().uuidString, specialty: specialty,
            description: description, estimatedPrice: estimatedPrice,
            scheduledDate: selectedDate, status: .pending,
            technicianId: technicianId, userId: userId,
            technicianName: technicianName, escrowStatus: .notInitiated
        )

        // Primero guardar localmente siempre — nunca falla
        coreDataManager.saveServicio(servicio)

        // Luego intentar sincronizar con la API
        do {
            try await apiService.createServicio(servicio)
            successMessage = "¡Solicitud enviada! El técnico confirmará en breve."
        } catch {
            // La API falló pero el dato ya está guardado localmente
            successMessage = "¡Solicitud guardada! Se sincronizará cuando haya conexión."
        }

        isLoading = false
        if successMessage != nil { resetForm() }
    }

    // MARK: - Read history

    func loadHistory(for userId: String) {
        servicios = coreDataManager.fetchServicios(for: userId)
    }

    // MARK: - Delete

    func deleteServicio(id: String, userId: String) {
        coreDataManager.deleteServicio(id: id)
        loadHistory(for: userId)
    }

    // MARK: - Private

    private func validateForm() -> Bool {
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Describe el servicio que necesitas."
            return false
        }
        if selectedDate < Date() {
            errorMessage = "La fecha debe ser en el futuro."
            return false
        }
        if estimatedPrice <= 0 {
            errorMessage = "Ingresa un precio estimado válido."
            return false
        }
        return true
    }

    private func resetForm() {
        description = ""
        estimatedPrice = 150
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
}
