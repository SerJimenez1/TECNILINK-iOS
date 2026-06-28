import Foundation
import Combine

struct TecnicoPendiente: Identifiable {
    let id: String
    let name: String
    let email: String
    let specialty: String
    let phone: String
    let description: String
    let verificationStatus: String
    let dniFrontURL: String?
    let dniBackURL: String?
    let certificateURL: String?
    let selfieURL: String?
    let workPhotos: [String]
    let createdAt: Date
}

@MainActor
final class AdminViewModel: ObservableObject {

    @Published var tecnicosPendientes: [TecnicoPendiente] = []
    @Published var tecnicosVerificados: Int = 0
    @Published var tecnicosRechazados: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let firestoreService = FirestoreService.shared

    // MARK: - Load

    func loadTecnicosPendientes() async {
        isLoading = true
        errorMessage = nil

        do {
            let data = try await firestoreService.fetchTecnicosPorEstado("pending")
            tecnicosPendientes = data.compactMap { parseTecnico($0) }

            let verificados = try await firestoreService.fetchTecnicosPorEstado("verified")
            tecnicosVerificados = verificados.count

            let rechazados = try await firestoreService.fetchTecnicosPorEstado("rejected")
            tecnicosRechazados = rechazados.count

        } catch {
            errorMessage = "Error al cargar técnicos."
        }

        isLoading = false
    }

    // MARK: - Aprobar

    func aprobarTecnico(id: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await firestoreService.updateVerificationStatus(
                tecnicoId: id,
                status: "verified",
                reason: nil
            )
            successMessage = "Técnico verificado correctamente."
            await loadTecnicosPendientes()
        } catch {
            errorMessage = "Error al aprobar el técnico."
        }

        isLoading = false
    }

    // MARK: - Rechazar

    func rechazarTecnico(id: String, reason: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await firestoreService.updateVerificationStatus(
                tecnicoId: id,
                status: "rejected",
                reason: reason
            )
            successMessage = "Técnico rechazado."
            await loadTecnicosPendientes()
        } catch {
            errorMessage = "Error al rechazar el técnico."
        }

        isLoading = false
    }

    // MARK: - Parse

    private func parseTecnico(_ dict: [String: Any]) -> TecnicoPendiente? {
        guard
            let id = dict["id"] as? String,
            let name = dict["name"] as? String,
            let email = dict["email"] as? String,
            let specialty = dict["specialty"] as? String
        else { return nil }

        let docs = dict["documents"] as? [String: Any] ?? [:]

        return TecnicoPendiente(
            id: id,
            name: name,
            email: email,
            specialty: specialty,
            phone: dict["phone"] as? String ?? "",
            description: dict["description"] as? String ?? "",
            verificationStatus: dict["verificationStatus"] as? String ?? "pending",
            dniFrontURL: docs["dniFrontURL"] as? String,
            dniBackURL: docs["dniBackURL"] as? String,
            certificateURL: docs["certificateURL"] as? String,
            selfieURL: docs["selfieURL"] as? String,
            workPhotos: docs["workPhotos"] as? [String] ?? [],
            createdAt: (dict["createdAt"] as? Date) ?? Date()
        )
    }
}
