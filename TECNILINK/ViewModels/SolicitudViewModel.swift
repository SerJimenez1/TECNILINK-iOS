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
    private let firestoreService: FirestoreService

    init(coreDataManager: CoreDataManager = .shared,
         firestoreService: FirestoreService = .shared) {
        self.coreDataManager = coreDataManager
        self.firestoreService = firestoreService
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

        // Guardar localmente siempre — nunca falla
        coreDataManager.saveServicio(servicio)

        // Guardar en Firestore (nube)
        do {
            try await firestoreService.saveServicio(servicio)
            successMessage = "¡Solicitud enviada! El técnico confirmará en breve."
        } catch {
            // Quedó guardado localmente, se sincronizará después
            successMessage = "¡Solicitud guardada! Se sincronizará cuando haya conexión."
        }

        isLoading = false
        if successMessage != nil { resetForm() }
    }

    // MARK: - Read history

    func loadHistory(for userId: String) async {
        isLoading = true

        // Intentar cargar desde Firestore primero
        do {
            let data = try await firestoreService.fetchServicios(for: userId)
            servicios = data.compactMap { dict -> Servicio? in
                guard
                    let id = dict["id"] as? String,
                    let technicianId = dict["technicianId"] as? String,
                    let technicianName = dict["technicianName"] as? String,
                    let specialtyRaw = dict["specialty"] as? String,
                    let specialty = Specialty(rawValue: specialtyRaw),
                    let desc = dict["description"] as? String,
                    let price = dict["estimatedPrice"] as? Double,
                    let scheduledTimestamp = dict["scheduledDate"] as? Any,
                    let statusRaw = dict["status"] as? String,
                    let status = ServiceStatus(rawValue: statusRaw),
                    let escrowRaw = dict["escrowStatus"] as? String,
                    let escrow = EscrowStatus(rawValue: escrowRaw)
                else { return nil }

                let date: Date
                if let timestamp = scheduledTimestamp as? Date {
                    date = timestamp
                } else {
                    date = Date()
                }

                return Servicio(
                    id: id, specialty: specialty,
                    description: desc, estimatedPrice: price,
                    scheduledDate: date, status: status,
                    technicianId: technicianId, userId: userId,
                    technicianName: technicianName, escrowStatus: escrow
                )
            }
        } catch {
            // Si Firestore falla, cargar desde Core Data local
            servicios = coreDataManager.fetchServicios(for: userId)
        }

        isLoading = false
    }

    // MARK: - Delete

    func deleteServicio(id: String, userId: String) async {
        // Eliminar localmente
        coreDataManager.deleteServicio(id: id)

        // Eliminar en Firestore
        do {
            try await firestoreService.deleteServicio(id: id)
        } catch {
            // Si falla en Firestore, ya se eliminó localmente
        }

        await loadHistory(for: userId)
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
