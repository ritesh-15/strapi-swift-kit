import Foundation

public struct StrapiListResponse<T: Decodable & Sendable>: Decodable, Sendable {
    public let data: [T]
    public let meta: Meta

    public struct Meta: Decodable, Sendable {
        public let pagination: PaginationMeta
    }
}
