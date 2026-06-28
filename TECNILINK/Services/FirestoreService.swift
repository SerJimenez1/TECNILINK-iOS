import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirestoreService {

    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Usuarios

    func saveUsuario(id: String, name: String, email: String) async throws {
        let data: [String: Any] = [
            "id": id,
            "name": name,
            "email": email,
            "role": "user",
            "registeredAt": Timestamp(date: Date())
        ]
        try await db.collection("usuarios").document(id).setData(data, merge: true)
    }

    func fetchUsuario(id: String) async throws -> [String: Any]? {
        let doc = try await db.collection("usuarios").document(id).getDocument()
        return doc.data()
    }

    // MARK: - Servicios / Historial

    func saveServicio(_ servicio: Servicio) async throws {
        let data: [String: Any] = [
            "id": servicio.id,
            "userId": servicio.userId,
            "technicianId": servicio.technicianId,
            "technicianName": servicio.technicianName,
            "specialty": servicio.specialty.rawValue,
            "description": servicio.description,
            "estimatedPrice": servicio.estimatedPrice,
            "scheduledDate": Timestamp(date: servicio.scheduledDate),
            "status": servicio.status.rawValue,
            "escrowStatus": servicio.escrowStatus.rawValue,
            "createdAt": Timestamp(date: Date())
        ]
        try await db.collection("servicios").document(servicio.id).setData(data)
    }

    func fetchServicios(for userId: String) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("servicios")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.map { $0.data() }
    }

    func deleteServicio(id: String) async throws {
        try await db.collection("servicios").document(id).delete()
    }

    // MARK: - Tecnicos

    func fetchTecnicos() async throws -> [[String: Any]] {
        let snapshot = try await db.collection("tecnicos")
            .whereField("verificationStatus", isEqualTo: "verified")
            .order(by: "rating", descending: true)
            .getDocuments()
        return snapshot.documents.map { $0.data() }
    }

    func fetchTecnicosPorEstado(_ status: String) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("tecnicos")
            .whereField("verificationStatus", isEqualTo: status)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.map { $0.data() }
    }

    func updateVerificationStatus(tecnicoId: String, status: String, reason: String?) async throws {
        var data: [String: Any] = [
            "verificationStatus": status,
            "isVerified": status == "verified",
            "updatedAt": Timestamp(date: Date())
        ]
        if let reason = reason {
            data["rejectionReason"] = reason
        }
        if status == "verified" {
            data["verifiedAt"] = Timestamp(date: Date())
        }
        try await db.collection("tecnicos").document(tecnicoId).updateData(data)
    }

    func saveTecnico(_ data: [String: Any]) async throws {
        guard let id = data["id"] as? String else { return }
        try await db.collection("tecnicos").document(id).setData(data)
    }
}
