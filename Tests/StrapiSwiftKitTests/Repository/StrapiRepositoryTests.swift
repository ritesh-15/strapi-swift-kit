import Foundation
import Testing
@testable import StrapiSwiftKit

@Suite("StrapiRepositoryTests")
struct StrapiRepositoryTests {

    private struct RepoDTO: Codable, Sendable {
        let id: Int
    }

    private struct CreateRecordDTO: Codable, Sendable {
        let id: Int
        let name: String
        let email: String
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

    @Test func testCreatingData() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.httpMethod == "POST")

            let body = request.httpBody
            assert(body != nil, "Request body should not be nil")

            let decoded = try JSONDecoder().decode(StrapiCreateRequest<CreateRecordDTO>.self, from: body!)

            #expect(decoded.data.id == 1)
            #expect(decoded.data.name == "John doe")
            #expect(decoded.data.email == "johndoe@gmail.com")

            let json = """
                {
                    "data": { "id": 1, "name": "John doe", "email": "johndoe@gmail.com" },
                }
                """.data(using: .utf8)

            return (json!, TestUtils.okResponse(for: request))
        }

        let repository = StrapiRepository<CreateRecordDTO>(client: client, endpoint: .init("/articles", method: .POST))
        let result = try await repository.create(dto: CreateRecordDTO(id: 1, name: "John doe", email: "johndoe@gmail.com"))

        #expect(result.data.id == 1)
        #expect(result.data.name == "John doe")
        #expect(result.data.email == "johndoe@gmail.com")
    }

    @Test func testUpdatingData() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.httpMethod == "PUT")
            #expect(request.url?.absoluteString == "https://example.com/api/articles/1")

            let body = request.httpBody
            assert(body != nil, "Request body should not be nil")

            let decoded = try JSONDecoder().decode(StrapiCreateRequest<CreateRecordDTO>.self, from: body!)

            #expect(decoded.data.id == 1)
            #expect(decoded.data.name == "John doe")
            #expect(decoded.data.email == "johndoe@gmail.com")

            let json = """
                {
                    "data": { "id": 1, "name": "John doe", "email": "johndoe@gmail.com" },
                }
                """.data(using: .utf8)

            return (json!, TestUtils.okResponse(for: request))
        }

        let repository = StrapiRepository<CreateRecordDTO>(client: client, endpoint: .init("/articles", method: .PUT))
        let result = try await repository.put(id:"1", dto: CreateRecordDTO(id: 1, name: "John doe", email: "johndoe@gmail.com"))

        #expect(result.data.id == 1)
        #expect(result.data.name == "John doe")
        #expect(result.data.email == "johndoe@gmail.com")
    }

    @Test func testDeletingData() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.httpMethod == "DELETE")
            #expect(request.url?.absoluteString.hasSuffix("/articles/1") == true)

            let json = """
                {
                    "data": { "id":1}
                }
                """.data(using: .utf8)

            return (json!, TestUtils.okResponse(for: request))
        }

        let repository = StrapiRepository<RepoDTO>(client: client, endpoint: .init("/articles", method: .DELETE))
        let result = try await repository.delete(id: "1")
        #expect(result.data.id == 1)
    }
}
