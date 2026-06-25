import Foundation

struct Tecnico: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let specialty: Specialty
    let rating: Double
    let isVerified: Bool
    let photoURL: String?
    let description: String
    let phone: String
    let location: String
    let reviewCount: Int
    let completedJobs: Int
    let reviews: [Review]
    let galleryURLs: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, specialty, rating, description, phone, location, reviews
        case isVerified    = "is_verified"
        case photoURL      = "photo_url"
        case reviewCount   = "review_count"
        case completedJobs = "completed_jobs"
        case galleryURLs   = "gallery_urls"
    }
}

enum Specialty: String, Codable, CaseIterable, Hashable {
    case electricity = "Electricidad"
    case plumbing    = "Gasfitería"
    case carpentry   = "Carpintería"
    case locksmith   = "Cerrajería"
    case appliances  = "Electrodomésticos"
    case painting    = "Pintura/Albañilería"

    var icon: String {
        switch self {
        case .electricity: return "bolt.fill"
        case .plumbing:    return "drop.fill"
        case .carpentry:   return "hammer.fill"
        case .locksmith:   return "lock.fill"
        case .appliances:  return "washer.fill"
        case .painting:    return "paintbrush.fill"
        }
    }
}

struct Review: Identifiable, Codable, Hashable {
    let id: String
    let authorName: String
    let rating: Double
    let comment: String
    let date: Date

    enum CodingKeys: String, CodingKey {
        case id, rating, comment, date
        case authorName = "author_name"
    }
}

// MARK: - Mock data (used when API is unavailable)
extension Tecnico {
    static let mockData: [Tecnico] = [
        Tecnico(id: "1", name: "Carlos Mendoza Ríos", specialty: .electricity,
                rating: 4.8, isVerified: true, photoURL: nil,
                description: "Electricista titulado con 10 años en instalaciones residenciales y comerciales. Certificado por el MEM.",
                phone: "959 123 456", location: "J.L.B. y Rivero", reviewCount: 127,
                completedJobs: 245, reviews: Review.mockData, galleryURLs: []),
        Tecnico(id: "2", name: "Miguel Quispe Turpo", specialty: .plumbing,
                rating: 4.7, isVerified: true, photoURL: nil,
                description: "Gasfitero con especialización en detección de fugas y sistemas de agua caliente.",
                phone: "958 234 567", location: "J.L.B. y Rivero", reviewCount: 89,
                completedJobs: 173, reviews: [], galleryURLs: []),
        Tecnico(id: "3", name: "Roberto Salas Flores", specialty: .carpentry,
                rating: 4.6, isVerified: true, photoURL: nil,
                description: "Carpintero especialista en muebles a medida y reparación de estructuras de madera.",
                phone: "957 345 678", location: "J.L.B. y Rivero", reviewCount: 64,
                completedJobs: 118, reviews: [], galleryURLs: []),
        Tecnico(id: "4", name: "Juan Apaza Mamani", specialty: .locksmith,
                rating: 4.9, isVerified: true, photoURL: nil,
                description: "Cerrajero 24/7. Apertura de emergencia, cambio de llaves y sistemas de seguridad.",
                phone: "956 456 789", location: "J.L.B. y Rivero", reviewCount: 201,
                completedJobs: 389, reviews: [], galleryURLs: []),
        Tecnico(id: "5", name: "Pedro Cáceres Llerena", specialty: .appliances,
                rating: 4.5, isVerified: true, photoURL: nil,
                description: "Técnico en refrigeración y electrodomésticos. Todas las marcas.",
                phone: "955 567 890", location: "J.L.B. y Rivero", reviewCount: 143,
                completedJobs: 267, reviews: [], galleryURLs: []),
        Tecnico(id: "6", name: "Luis Herrera Vilca", specialty: .painting,
                rating: 4.4, isVerified: false, photoURL: nil,
                description: "Pintor y albañil con experiencia en acabados interiores y exteriores.",
                phone: "954 678 901", location: "J.L.B. y Rivero", reviewCount: 37,
                completedJobs: 72, reviews: [], galleryURLs: [])
    ]
}

extension Review {
    static let mockData: [Review] = [
        Review(id: "r1", authorName: "Ana Torres", rating: 5.0,
               comment: "Excelente trabajo, muy puntual y profesional.", date: Date()),
        Review(id: "r2", authorName: "Marco Díaz", rating: 4.5,
               comment: "Resolvió el problema rápido. Lo recomiendo.", date: Date())
    ]
}
