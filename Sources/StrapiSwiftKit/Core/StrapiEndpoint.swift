import Foundation

public struct StrapiEndpoint: Sendable {

    public enum Method: String, Sendable {
        case GET
        case POST
        case PUT
        case DELETE
    }

    public let path: String
    public let method: Method

    public init(
        _ path: String,
        method: Method = .GET
    ) {
        self.path = path
        self.method = method
    }
}
