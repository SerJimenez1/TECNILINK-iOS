import Foundation
import Combine

struct SolicitudIncoming: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let specialty: String
    let description: String
    let estimatedPrice: Double
    let scheduledDate: Date
    let status: String
}

@MainActor
final class TecnicoDashboardViewModel: ObservableObject {

    @Published var solicitudesPendientes: [SolicitudIncoming] = []
    @Published var solicitudesAceptadas: [SolicitudIncoming] = []
    @Published var solicitudesRechazadas: [SolicitudIncoming] = []
    @Published var solicitudesCompletadas: [SolicitudIncoming] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared
    private var currentTecnicoId: String = ""

    func loadSolicitudes(tecnicoId: String) async {
        guard !tecnicoId.isEmpty else { return }
        currentTecnicoId = tecnicoId
        isLoading = true

        do {
            let pendientes = try await firestoreService.fetchSolicitudesPorTecnico(
                tecnicoId: tecnicoId, status: "pending"
            )
            solicitudesPendientes = pendientes.compactMap { parseSolicitud($0) }

            let aceptadas = try await firestoreService.fetchSolicitudesPorTecnico(
                tecnicoId: tecnicoId, status: "accepted"
            )
            solicitudesAceptadas = aceptadas.compactMap { parseSolicitud($0) }

            let rechazadas = try await firestoreService.fetchSolicitudesPorTecnico(
                tecnicoId: tecnicoId, status: "rejected"
            )
            solicitudesRechazadas = rechazadas.compactMap { parseSolicitud($0) }

            let completadas = try await firestoreService.fetchSolicitudesPorTecnico(
                tecnicoId: tecnicoId, status: "completed"
            )
            solicitudesCompletadas = completadas.compactMap { parseSolicitud($0) }

        } catch {
            errorMessage = "Error al cargar solicitudes."
        }
        isLoading = false
    }

    func aceptarSolicitud(id: String) async {
        do {
            try await firestoreService.updateServicioStatus(id: id, status: "accepted")
            await loadSolicitudes(tecnicoId: currentTecnicoId)
        } catch {
            errorMessage = "Error al aceptar la solicitud."
        }
    }

    func rechazarSolicitud(id: String) async {
        do {
            try await firestoreService.updateServicioStatus(id: id, status: "rejected")
            await loadSolicitudes(tecnicoId: currentTecnicoId)
        } catch {
            errorMessage = "Error al rechazar la solicitud."
        }
    }

    private func parseSolicitud(_ dict: [String: Any]) -> SolicitudIncoming? {
        guard
            let id = dict["id"] as? String,
            let userId = dict["userId"] as? String,
            let specialty = dict["specialty"] as? String,
            let description = dict["description"] as? String,
            let price = dict["estimatedPrice"] as? Double,
            let status = dict["status"] as? String
        else { return nil }

        let date: Date
        if let ts = dict["scheduledDate"] as? Date {
            date = ts
        } else {
            date = Date()
        }

        return SolicitudIncoming(
            id: id,
            userId: userId,
            userName: dict["userName"] as? String ?? "Cliente",
            specialty: specialty,
            description: description,
            estimatedPrice: price,
            scheduledDate: date,
            status: status
        )
    }
}
