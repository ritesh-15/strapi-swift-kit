import Foundation

final class StrapiRepository<DTO: Codable & Sendable>: Sendable  {

    private let client: StrapiClient
    private let endpoint: StrapiEndpoint

    init(client: StrapiClient, endpoint: StrapiEndpoint) {
        self.client = client
        self.endpoint = endpoint
    }

    func list(query: StrapiQuery?) async throws -> StrapiListResponse<DTO> {
        let items: [URLQueryItem] = query?.build() ?? []
        let response: StrapiListResponse<DTO> = try await client.send(endpoint, queryItems: items)
        return response
    }

    func get(id: String, query: StrapiQuery? = nil) async throws -> StrapiSingleResponse<DTO> {
        let singleEndpoint = StrapiEndpoint(
            endpoint.path + "/\(id)",
            method: endpoint.method
        )

        let items: [URLQueryItem] = query?.build() ?? []
        let response: StrapiSingleResponse<DTO> = try await client.send(singleEndpoint, queryItems: items)
        return response
    }

    func create(dto: DTO) async throws -> StrapiSingleResponse<DTO> {
        let body = StrapiCreateRequest(data: dto)

        let response: StrapiSingleResponse<DTO> =
        try await client.send(
            endpoint,
            body: body
        )

        return response
    }

    func put(id: String, dto: DTO) async throws -> StrapiSingleResponse<DTO> {
        let singleEndpoint = StrapiEndpoint(
            endpoint.path + "/\(id)",
            method: endpoint.method
        )

        let body = StrapiCreateRequest(data: dto)
        let response: StrapiSingleResponse<DTO> =
        try await client.send(
            singleEndpoint,
            body: body
        )

        return response
    }
}
