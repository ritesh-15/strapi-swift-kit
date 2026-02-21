import Foundation
import Testing
@testable import StrapiSwiftKit

private struct ArticleDTO: Codable, Sendable {
    let id: Int
    let title: String
}

@Suite("StrapiExecuteTests")
struct StrapiExecuteTests {

    // MARK: - GET

    @Test("execute GET builds correct URL")
    func executeGetBuildsCorrectURL() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.url?.path == "/api/articles")
            #expect(request.httpMethod == "GET")
            return (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
            StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
        )
    }

    @Test("execute GET appends query items")
    func executeGetAppendsQueryItems() async throws {
        let client = TestUtils.makeClient { request in
            let query = request.url?.query ?? ""
            #expect(query.contains("filters"))
            #expect(query.contains("sort"))
            #expect(query.contains("pagination"))
            return (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
            StrapiRequest<[ArticleDTO]>(
                endpoint: "/articles",
                query: StrapiQuery()
                    .filters { $0.equals("status", "published") }
                    .sort("publishedAt", .desc)
                    .page(1, size: 10)
            )
        )
    }

    @Test("execute GET with no query builds clean URL")
    func executeGetWithNoQuery() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.url?.query == nil)
            return (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
            StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
        )
    }

    // MARK: - Pagination Meta

    @Test("execute returns pagination meta")
    func executeReturnsPaginationMeta() async throws {
        let client = TestUtils.makeClient { request in
            (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        }
        let response: StrapiResponse<[ArticleDTO]> = try await client.execute(
            StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
        )
        #expect(response.meta?.pagination?.page == 1)
        #expect(response.meta?.pagination?.pageSize == 10)
        #expect(response.meta?.pagination?.total == 0)
        #expect(response.meta?.pagination?.pageCount == 1)
    }

    @Test("execute returns data and meta together")
    func executeReturnsDataAndMeta() async throws {
        let client = TestUtils.makeClient { request in
            (TestUtils.okSingleJSON(), TestUtils.okResponse(for: request))
        }
        let response: StrapiResponse<ArticleDTO> = try await client.execute(
            StrapiRequest<ArticleDTO>(endpoint: "/articles/1")
        )
        #expect(response.data.id == 1)
        #expect(response.data.title == "Test Article")
        #expect(response.meta != nil)
    }

    // MARK: - POST

    @Test("execute POST sets correct method")
    func executePostSetsCorrectMethod() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.httpMethod == "POST")
            return (TestUtils.okSingleJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<ArticleDTO> = try await client.execute(
            StrapiRequest<ArticleDTO>(
                endpoint: "/articles",
                method: .POST,
                body: ArticleDTO(id: 0, title: "Hello")
            )
        )
    }

    @Test("execute POST encodes and sends body")
    func executePostSendsBody() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.httpBody != nil)
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let body = try? JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any]
            #expect(body?["title"] as? String == "Hello")
            return (TestUtils.okSingleJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<ArticleDTO> = try await client.execute(
            StrapiRequest<ArticleDTO>(
                endpoint: "/articles",
                method: .POST,
                body: ArticleDTO(id: 0, title: "Hello")
            )
        )
    }

    // MARK: - PUT

    @Test("execute PUT sets correct method and sends body")
    func executePutSetsCorrectMethod() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.httpMethod == "PUT")
            #expect(request.httpBody != nil)
            return (TestUtils.okSingleJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<ArticleDTO> = try await client.execute(
            StrapiRequest<ArticleDTO>(
                endpoint: "/articles/10",
                method: .PUT,
                body: ArticleDTO(id: 10, title: "Updated")
            )
        )
    }

    // MARK: - DELETE

    @Test("execute DELETE sets correct method with no body")
    func executeDeleteSetsCorrectMethod() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.httpMethod == "DELETE")
            #expect(request.httpBody == nil)
            return (TestUtils.okSingleJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<ArticleDTO> = try await client.execute(
            StrapiRequest<ArticleDTO>(
                endpoint: "/articles/10",
                method: .DELETE
            )
        )
    }

    // MARK: - Custom Headers

    @Test("execute forwards custom headers")
    func executeForwardsCustomHeaders() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.value(forHTTPHeaderField: "X-Custom-Header") == "test-value")
            return (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
            StrapiRequest<[ArticleDTO]>(
                endpoint: "/articles",
                headers: ["X-Custom-Header": "test-value"]
            )
        )
    }

    // MARK: - Error Handling

    @Test("execute throws HTTP error on 404")
    func executeThrowsHTTPErrorOn404() async {
        let client = TestUtils.makeClient { request in
            (Data(), TestUtils.httpResponse(for: request, code: 404))
        }
        await #expect(throws: StrapiError.self) {
            let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
                StrapiRequest<[ArticleDTO]>(endpoint: "/articles/999")
            )
        }
    }

    @Test("execute throws HTTP error on 500")
    func executeThrowsHTTPErrorOn500() async {
        let client = TestUtils.makeClient { request in
            (Data(), TestUtils.httpResponse(for: request, code: 500))
        }
        await #expect(throws: StrapiError.self) {
            let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
                StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
            )
        }
    }

    @Test("execute throws decoding error on invalid JSON")
    func executeThrowsDecodingError() async {
        let client = TestUtils.makeClient { request in
            (#"{ "invalid": true }"#.data(using: .utf8)!, TestUtils.okResponse(for: request))
        }
        await #expect(throws: StrapiError.self) {
            let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
                StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
            )
        }
    }
}

// MARK: - TestUtils extension

extension TestUtils {
    static func okSingleJSON() -> Data {
        """
        {
          "data": {
            "id": 1,
            "title": "Test Article"
          },
          "meta": {}
        }
        """.data(using: .utf8)!
    }
}
