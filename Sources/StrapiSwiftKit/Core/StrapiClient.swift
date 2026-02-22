import Foundation

public final class StrapiClient: @unchecked Sendable {

    private let config: StrapiConfig
    private let transport: HTTPTransportProtocol
    private let authProvider: StrapiAuthProvider?
    private let logger: StrapiLoggerProtocol?

    public init(
        config: StrapiConfig,
        transport: HTTPTransportProtocol = URLSessionTransport(),
        authProvider: StrapiAuthProvider? = nil,
        logger: StrapiLoggerProtocol? = nil
    ) {
        self.config = config
        self.transport = transport
        self.authProvider = authProvider
        self.logger = logger
    }
}

public extension StrapiClient {

    func send<T: Decodable>(
        _ endpoint: StrapiEndpoint,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let requestID = UUID().uuidString
        let start = Date()

        let request = try buildRequest(
            endpoint: endpoint,
            queryItems: queryItems
        )

        logger?.logRequest(request, correlationID: requestID)

        do {
            let (data, response) = try await transport.send(request)

            let httpResponse = try validate(response, data)
            let durationMs = Int(Date().timeIntervalSince(start) * 1000)
            logger?.logResponse(response: httpResponse, data: data, correlationID: requestID, durationMs: durationMs)

            return try JSONDecoder.strapi.decode(T.self, from: data)
        } catch let e as DecodingError {
            logger?.logNetworkError(e, correlationID: requestID, request: request, since: start)
            throw StrapiError.decoding(e.localizedDescription)
        } catch let e as StrapiError {
            logger?.logNetworkError(e, correlationID: requestID, request: request, since: start)
            throw e
        } catch let e {
            logger?.logNetworkError(e, correlationID: requestID, request: request, since: start)
            throw StrapiError.transport(e.localizedDescription)
        }
    }

    func send<T: Decodable, Body: Encodable>(
        _ endpoint: StrapiEndpoint,
        body: Body
    ) async throws -> T {
        let requestID = UUID().uuidString
        let start = Date()

        let request = try buildRequest(
            endpoint: endpoint,
            queryItems: nil,
            body: JSONEncoder().encode(body)
        )

        logger?.logRequest(request, correlationID: requestID)

        do {
            let (data, response) = try await transport.send(request)

            let httpResponse = try validate(response, data)
            let durationMs = Int(Date().timeIntervalSince(start) * 1000)
            logger?.logResponse(response: httpResponse, data: data, correlationID: requestID, durationMs: durationMs)

            return try JSONDecoder.strapi.decode(T.self, from: data)
        } catch let e as DecodingError {
            logger?.logNetworkError(e, correlationID: requestID, request: request, since: start)
            throw StrapiError.decoding(e.localizedDescription)
        } catch let e as StrapiError {
            logger?.logNetworkError(e, correlationID: requestID, request: request, since: start)
            throw e
        } catch let e {
            logger?.logNetworkError(e, correlationID: requestID, request: request, since: start)
            throw StrapiError.transport(e.localizedDescription)
        }
    }

    func execute<Response: Decodable & Sendable>(
        _ request: StrapiRequest<Response>
    ) async throws -> StrapiResponse<Response> {
        let requestID = UUID().uuidString
        let start = Date()

        var urlRequest = try buildRequest(
            endpoint: StrapiEndpoint(request.endpoint, method: request.method),
            queryItems: request.query?.build(),
            body: request.body
        )

        // Forward custom headers
        request.headers?.forEach {
            urlRequest.setValue($0.value, forHTTPHeaderField: $0.key)
        }

        logger?.logRequest(urlRequest, correlationID: requestID)

        do {
            let (data, response) = try await transport.send(urlRequest)
            let httpResponse = try validate(response, data)
            let durationMs = Int(Date().timeIntervalSince(start) * 1000)
            logger?.logResponse(response: httpResponse, data: data, correlationID: requestID, durationMs: durationMs)

            let wrapper = try JSONDecoder.strapi.decode(StrapiResponseWrapper<Response>.self, from: data)
            return StrapiResponse(data: wrapper.data, meta: wrapper.meta)
        } catch let e as DecodingError {
            logger?.logNetworkError(e, correlationID: requestID, request: urlRequest, since: start)
            throw StrapiError.decoding(e.localizedDescription)
        } catch let e as StrapiError {
            logger?.logNetworkError(e, correlationID: requestID, request: urlRequest, since: start)
            throw e
        } catch {
            logger?.logNetworkError(error, correlationID: requestID, request: urlRequest, since: start)
            throw StrapiError.transport(error.localizedDescription)
        }
    }
}

private extension StrapiClient {

    func buildRequest(
        endpoint: StrapiEndpoint,
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil
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

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

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

    func validate(_ response: URLResponse, _ data: Data) throws -> HTTPURLResponse {
        guard let http = response as? HTTPURLResponse else {
            throw StrapiError.invalidResponse
        }

        guard 200..<300 ~= http.statusCode else {
            // Attempt to decode Strapi error response
            if let strapiError = try? JSONDecoder().decode(StrapiErrorResponse.self, from: data) {
                throw StrapiError.server(
                    status: strapiError.error.status,
                    name: strapiError.error.name,
                    message: strapiError.error.message
                )
            }

            // Fallback if response is not Strapi-formatted
            throw StrapiError.server(
                status: http.statusCode,
                name: "HTTPError",
                message: HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            )
        }

        return http
    }
}
