import Foundation
@testable import StrapiSwiftKit

typealias MockTransportHandler = @Sendable (URLRequest) throws -> (Data, URLResponse)

struct MockTransport: HTTPTransportProtocol {

    let handler: MockTransportHandler

    func send(
        _ request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try handler(request)
    }
}
