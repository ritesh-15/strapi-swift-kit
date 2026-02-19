import Foundation
import Testing
@testable import StrapiSwiftKit

@Suite("StrapiRepositoryTests")
struct StrapiRepositoryTests {

    private struct RepoDTO: Decodable, Sendable {
        let id: Int
    }

    @Test func testReturnListDecodedDTOs() async throws {
        let client = TestUtils.makeClient { request in
            let json = """
                {
                              "data": [
                                { "id": 1 },
                                { "id": 2 }
                              ],
                              "meta": {
                                "pagination": {
                                  "page": 1,
                                  "pageSize": 10,
                                  "pageCount": 1,
                                  "total": 2
                                }
                              }
                            }
                """.data(using: .utf8)

            return (json!, TestUtils.okResponse(for: request))
        }
        let repository = StrapiRepository<RepoDTO>(client: client, endpoint: .init("/articles"))

        let result = try await repository.list(query: nil)

        #expect(result.data.count == 2)
        #expect(result.data[0].id == 1)
        #expect(result.data[1].id == 2)
    }

    @Test func testReturnSingleDecodedDTO() async throws {
        let client = TestUtils.makeClient { request in
            let json = """
                {
                              "data": { "id": 1 },
                              "meta": {
                                "pagination": {
                                  "page": 1,
                                  "pageSize": 10,
                                  "pageCount": 1,
                                  "total": 2
                                }
                              }
                            }
                """.data(using: .utf8)

            return (json!, TestUtils.okResponse(for: request))
        }
        let repository = StrapiRepository<RepoDTO>(client: client, endpoint: .init("/articles"))

        let result = try await repository.get(id: "123")

        #expect(result.data.id == 1)
    }
}
