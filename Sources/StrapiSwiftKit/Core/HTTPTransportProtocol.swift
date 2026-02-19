import Foundation

public protocol HTTPTransportProtocol {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}
