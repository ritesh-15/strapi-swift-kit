import Foundation
import Testing
@testable import StrapiSwiftKit

class TestUtils {
    static func makeClient(
        handler: @escaping MockTransportHandler,
        auth: StrapiAuthProvider? = nil
    ) -> StrapiClient {
        let transport = MockTransport(handler: handler)
        return StrapiClient(
            config: .init(baseURL: URL(string:"https://example.com")!),
            transport: transport,
            authProvider: auth
        )
    }

    static func okResponse(for req: URLRequest) -> HTTPURLResponse {
        httpResponse(for: req, code: 200)
    }

    static func httpResponse(
        for req: URLRequest,
        code: Int
    ) -> HTTPURLResponse {
        HTTPURLResponse(
            url: req.url!,
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    static func okListJSON() -> Data {
        """
        {
          "data": [],
          "meta": {
            "pagination": {
              "page": 1,
              "pageSize": 10,
              "pageCount": 1,
              "total": 0
            }
          }
        }
        """.data(using: .utf8)!
    }
}
