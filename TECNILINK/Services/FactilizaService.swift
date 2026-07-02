import Foundation

// Wrapper de la respuesta
struct FactilizaResponse: Codable {
    let status: Int?
    let message: String?
    let success: Bool?
    let data: DNIResponse?
}

struct DNIResponse: Codable {
    let numero: String?
    let nombres: String?
    let apellidoPaterno: String?
    let apellidoMaterno: String?
    let nombreCompleto: String?
    let departamento: String?
    let provincia: String?
    let distrito: String?
    let direccion: String?
    let direccionCompleta: String?

    enum CodingKeys: String, CodingKey {
        case numero
        case nombres
        case apellidoPaterno = "apellido_paterno"
        case apellidoMaterno = "apellido_materno"
        case nombreCompleto = "nombre_completo"
        case departamento
        case provincia
        case distrito
        case direccion
        case direccionCompleta = "direccion_completa"
    }
}

final class FactilizaService {

    static let shared = FactilizaService()
    private let token = FactilizaConfig.token

    private init() {}

    func consultarDNI(_ dni: String) async throws -> DNIResponse {
        guard dni.count == 8, dni.allSatisfy({ $0.isNumber }) else {
            throw FactilizaError.dniInvalido
        }

        let url = URL(string: "https://api.factiliza.com/v1/dni/info/\(dni)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FactilizaError.errorRed
        }

        switch httpResponse.statusCode {
        case 200:
            let wrapper = try JSONDecoder().decode(FactilizaResponse.self, from: data)
            guard let dniData = wrapper.data else {
                throw FactilizaError.dniNoEncontrado
            }
            return dniData
        case 401:
            throw FactilizaError.tokenInvalido
        case 404:
            throw FactilizaError.dniNoEncontrado
        default:
            throw FactilizaError.errorServidor
        }
    }

    func verificarCoincidencia(dni: DNIResponse, nombreRegistrado: String) -> Bool {
        guard let nombreCompleto = dni.nombreCompleto else { return false }
        let nombreNormalizado = nombreCompleto
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        let registradoNormalizado = nombreRegistrado
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        let partesNombre = nombreNormalizado.components(separatedBy: " ")
        let partesRegistrado = registradoNormalizado.components(separatedBy: " ")

        return partesRegistrado.allSatisfy { parte in
            partesNombre.contains(parte)
        }
    }
}

enum FactilizaError: LocalizedError {
    case dniInvalido
    case dniNoEncontrado
    case tokenInvalido
    case errorRed
    case errorServidor

    var errorDescription: String? {
        switch self {
        case .dniInvalido:      return "El DNI debe tener 8 dígitos."
        case .dniNoEncontrado:  return "DNI no encontrado en RENIEC."
        case .tokenInvalido:    return "Error de autenticación con RENIEC."
        case .errorRed:         return "Sin conexión. Verifica tu red."
        case .errorServidor:    return "Error del servidor. Intenta de nuevo."
        }
    }
}
