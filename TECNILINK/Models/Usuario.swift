import Foundation

struct Usuario: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let profilePhotoURL: String?
    let serviceHistory: [String]
    let registeredAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone
        case profilePhotoURL = "profile_photo_url"
        case serviceHistory  = "service_history"
        case registeredAt    = "registered_at"
    }
}
