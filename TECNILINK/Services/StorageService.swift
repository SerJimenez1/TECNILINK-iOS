import Foundation
import UIKit
import CommonCrypto

final class StorageService {

    static let shared = StorageService()

    // MARK: - Cloudinary Config
    private let cloudName = CloudinaryConfig.cloudName
    private let apiKey = CloudinaryConfig.apiKey
    private let apiSecret = CloudinaryConfig.apiSecret

    private init() {}

    // MARK: - Upload Image

    func uploadImage(_ image: UIImage, folder: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.invalidImage
        }
            
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let signature = generateSignature(folder: folder, timestamp: timestamp)
        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // api_key
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"api_key\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(apiKey)\r\n".data(using: .utf8)!)

        // timestamp
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"timestamp\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(timestamp)\r\n".data(using: .utf8)!)

        // folder
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"folder\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(folder)\r\n".data(using: .utf8)!)

        // signature
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"signature\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(signature)\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StorageError.uploadFailed
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let secureUrl = json["secure_url"] as? String else {
            throw StorageError.invalidResponse
        }

        return secureUrl
    }

    // MARK: - Upload Tecnico Document

    func uploadTecnicoDocument(_ image: UIImage, tecnicoId: String, documentType: String) async throws -> String {
        return try await uploadImage(image, folder: "tecnilink/tecnicos/\(tecnicoId)/documentos")
    }

    // MARK: - Upload Work Photo

    func uploadWorkPhoto(_ image: UIImage, tecnicoId: String, index: Int) async throws -> String {
        return try await uploadImage(image, folder: "tecnilink/tecnicos/\(tecnicoId)/trabajos")
    }

    // MARK: - Signature

    private func generateSignature(folder: String, timestamp: String) -> String {
        let params = "folder=\(folder)&timestamp=\(timestamp)\(apiSecret)"
        return params.sha1()
    }
}

// MARK: - Storage Errors

enum StorageError: LocalizedError {
    case invalidImage
    case uploadFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "No se pudo procesar la imagen."
        case .uploadFailed: return "Error al subir la imagen."
        case .invalidResponse: return "Respuesta inválida del servidor."
        }
    }
}

// MARK: - String SHA1

extension String {
    func sha1() -> String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: 20)
        data.withUnsafeBytes { ptr in
            _ = CC_SHA1(ptr.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
