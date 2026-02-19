import Foundation

public struct StrapiSingleResponse<T: Decodable & Sendable>: Decodable, Sendable {
    public let data: T
}
