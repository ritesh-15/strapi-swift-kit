import Foundation

public struct PaginationMeta: Decodable, Sendable {
    public let page: Int
    public let pageSize: Int
    public let pageCount: Int
    public let total: Int
}
