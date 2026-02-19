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
}
