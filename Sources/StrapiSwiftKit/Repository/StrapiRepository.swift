import Foundation

final class StrapiRepository<DTO: Decodable & Sendable>: Sendable  {

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
        let items: [URLQueryItem] = query?.build() ?? []
        let response: StrapiSingleResponse<DTO> = try await client.send(endpoint, queryItems: items)
        return response
    }
}
