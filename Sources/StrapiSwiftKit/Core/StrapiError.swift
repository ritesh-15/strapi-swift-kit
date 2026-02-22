import Foundation

public enum StrapiError: Error, Sendable, Equatable {
    case invalidURL
    case invalidResponse

    case server(
        status: Int,
        name: String,
        message: String
    )

    case decoding(String)
    case transport(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .server(let status, let name, let message):
            return "[\(status)] \(name): \(message)"
        case .decoding(let message):
            return "Decoding error: \(message)"
        case .transport(let message):
            return "Transport error: \(message)"
        }
    }
}
