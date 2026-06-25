import Foundation

enum APIError: LocalizedError {
    case noConnection
    case invalidResponse(statusCode: Int)
    case decodingError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noConnection:              return "Sin conexión a internet."
        case .invalidResponse(let code): return "Error del servidor (\(code))."
        case .decodingError:             return "Error al procesar los datos recibidos."
        case .unknown(let e):            return e.localizedDescription
        }
    }
}

final class APIService {

    private let baseURL = "https://api.tecnilink.pe/v1"
    private let session: URLSession

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchTecnicos() async throws -> [Tecnico] {
        let url = try buildURL(path: "/tecnicos")
        return try await performGET(url: url)
    }

    func createServicio(_ servicio: Servicio) async throws {
        let url = try buildURL(path: "/servicios")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(servicio)

        let (_, response) = try await withConnectionCheck { try await self.session.data(for: request) }
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    // MARK: - Private helpers

    private func performGET<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await withConnectionCheck { try await self.session.data(from: url) }
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse(statusCode: 0) }
        guard (200...299).contains(http.statusCode) else { throw APIError.invalidResponse(statusCode: http.statusCode) }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func withConnectionCheck<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw APIError.noConnection
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.unknown(error)
        }
    }

    private func buildURL(path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidResponse(statusCode: 0)
        }
        return url
    }
}
