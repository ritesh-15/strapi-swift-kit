import Foundation

public enum StrapiError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding
    case transport
}
