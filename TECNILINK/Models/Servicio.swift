import Foundation

struct Servicio: Identifiable, Codable {
    let id: String
    let specialty: Specialty
    let description: String
    let estimatedPrice: Double
    let scheduledDate: Date
    let status: ServiceStatus
    let technicianId: String
    let userId: String
    let technicianName: String?
    let escrowStatus: EscrowStatus

    enum CodingKeys: String, CodingKey {
        case id, specialty, description, status
        case estimatedPrice  = "estimated_price"
        case scheduledDate   = "scheduled_date"
        case technicianId    = "technician_id"
        case userId          = "user_id"
        case technicianName  = "technician_name"
        case escrowStatus    = "escrow_status"
    }
}

enum ServiceStatus: String, Codable {
    case pending    = "pending"
    case accepted   = "accepted"
    case inProgress = "in_progress"
    case completed  = "completed"
    case cancelled  = "cancelled"
    case rejected   = "rejected"

    var displayName: String {
        switch self {
        case .pending:    return "Pendiente"
        case .accepted:   return "Aceptado"
        case .inProgress: return "En Progreso"
        case .completed:  return "Completado"
        case .cancelled:  return "Cancelado"
        case .rejected:   return "Rechazado"
        }
    }

    var colorHex: String {
        switch self {
        case .pending:    return "FFA500"
        case .accepted:   return "028090"
        case .inProgress: return "02C39A"
        case .completed:  return "1A3C6E"
        case .cancelled:  return "FF4444"
        case .rejected:   return "FF4444"
        }
    }
}

enum EscrowStatus: String, Codable {
    case notInitiated = "not_initiated"
    case held         = "held"
    case released     = "released"
    case refunded     = "refunded"

    var displayName: String {
        switch self {
        case .notInitiated: return "Sin iniciar"
        case .held:         return "Dinero retenido"
        case .released:     return "Pago liberado"
        case .refunded:     return "Reembolsado"
        }
    }

    var icon: String {
        switch self {
        case .notInitiated: return "clock"
        case .held:         return "lock.shield.fill"
        case .released:     return "checkmark.shield.fill"
        case .refunded:     return "arrow.uturn.left.circle.fill"
        }
    }
}
