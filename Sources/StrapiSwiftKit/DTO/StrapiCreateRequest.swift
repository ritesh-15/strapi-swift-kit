import Foundation

public struct StrapiCreateRequest<T: Codable & Sendable>: Codable, Sendable {
    public let data: T

    public init(data: T) {
        self.data = data
    }
}
