import Foundation

public final class StrapiClient: @unchecked Sendable {

    private let config: StrapiConfig
    private let transport: HTTPTransportProtocol
    private let authProvider: StrapiAuthProvider?

    public init(
        config: StrapiConfig,
        transport: HTTPTransportProtocol = URLSessionTransport(),
        authProvider: StrapiAuthProvider? = nil
    ) {
        self.config = config
        self.transport = transport
        self.authProvider = authProvider
    }
}

public extension StrapiClient {

    func send<T: Decodable>(
        _ endpoint: StrapiEndpoint,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let request = try buildRequest(
            endpoint: endpoint,
            queryItems: queryItems
        )

        do {
            let (data, response) = try await transport.send(request)

            try validate(response)

            return try JSONDecoder.strapi.decode(T.self, from: data)
        } catch is DecodingError {
            throw StrapiError.decoding
        } catch let e as StrapiError {
            throw e
        } catch {
            throw StrapiError.transport
        }
    }
}

private extension StrapiClient {

    func buildRequest(
        endpoint: StrapiEndpoint,
        queryItems: [URLQueryItem]?
    ) throws -> URLRequest {
        var components = URLComponents(
            url: config.baseURL,
            resolvingAgainstBaseURL: false
        )

        components?.path = config.apiPath + endpoint.path
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw StrapiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        if let token = authProvider?.token {
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        return request
    }

    func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw StrapiError.invalidResponse
        }

        guard 200..<300 ~= http.statusCode else {
            throw StrapiError.httpStatus(http.statusCode)
        }
    }
}
