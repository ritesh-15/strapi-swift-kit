import Foundation

/**
 Test-only transport mock.
 nonisolated(unsafe) is acceptable here because:
 - test target only
 - deterministic usage
 - URLProtocol is legacy callback API
 */
typealias MockHandler = (URLRequest) throws -> (HTTPURLResponse, Data)

final class MockURLProtocol: URLProtocol {

    nonisolated(unsafe) static var handler: MockHandler?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        do {
            guard let handler = Self.handler else {
                fatalError("Hadler not set")
            }

            let (response, data) = try handler(self.request)

            client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed)

            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch let error {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // No-op
    }
}

// MARK: - Helper

func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}
