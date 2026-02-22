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

    @Test("execute GET sets accept header")
    func executeGetSetsAcceptHeader() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            return (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
            StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
        )
    }

    // MARK: - Single Response

    @Test("execute returns single item data")
    func executeReturnsSingleItemData() async throws {
        let client = TestUtils.makeClient { request in
            (TestUtils.okSingleJSON(), TestUtils.okResponse(for: request))
        }
        let response: StrapiResponse<ArticleDTO> = try await client.execute(
            StrapiRequest<ArticleDTO>(endpoint: "/articles/1")
        )
        #expect(response.data.id == 1)
        #expect(response.data.title == "Test Article")
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

    @Test("execute handles missing meta gracefully")
    func executeHandlesMissingMeta() async throws {
        let client = TestUtils.makeClient { request in
            ("""
            { "data": [] }
            """.data(using: .utf8)!, TestUtils.okResponse(for: request))
        }
        let response: StrapiResponse<[ArticleDTO]> = try await client.execute(
            StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
        )
        #expect(response.data.isEmpty)
        #expect(response.meta == nil)
    }

    @Test("execute handles empty list")
    func executeHandlesEmptyList() async throws {
        let client = TestUtils.makeClient { request in
            (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        }
        let response: StrapiResponse<[ArticleDTO]> = try await client.execute(
            StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
        )
        #expect(response.data.isEmpty)
    }

    // MARK: - POST

    @Test("execute POST sets correct method")
    func executePostSetsCorrectMethod() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.httpMethod == "POST")
            return (TestUtils.okSingleJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<ArticleDTO> = try await client.execute(
            try StrapiRequest<ArticleDTO>(
                endpoint: "/articles",
                method: .POST,
                body: ArticleDTO(id: 0, title: "Hello")
            )
        )
    }

    @Test("execute POST wraps body in data key")
    func executePostWrapsBodyInDataKey() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.httpBody != nil)
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let json = try? JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any]
            #expect(json?["data"] != nil)
            let data = json?["data"] as? [String: Any]
            #expect(data?["title"] as? String == "Hello")
            return (TestUtils.okSingleJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<ArticleDTO> = try await client.execute(
            try StrapiRequest<ArticleDTO>(
                endpoint: "/articles",
                method: .POST,
                body: ArticleDTO(id: 0, title: "Hello")
            )
        )
    }

    @Test("execute POST with no body sends no body")
    func executePostWithNoBody() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.httpBody == nil)
            return (TestUtils.okSingleJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<ArticleDTO> = try await client.execute(
            StrapiRequest<ArticleDTO>(
                endpoint: "/articles",
                method: .POST
            )
        )
    }

    // MARK: - PUT

    @Test("execute PUT sets correct method and wraps body in data key")
    func executePutSetsCorrectMethodAndWrapsBody() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.httpMethod == "PUT")
            #expect(request.httpBody != nil)
            let json = try? JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any]
            #expect(json?["data"] != nil)
            let data = json?["data"] as? [String: Any]
            #expect(data?["title"] as? String == "Updated")
            return (TestUtils.okSingleJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<ArticleDTO> = try await client.execute(
            try StrapiRequest<ArticleDTO>(
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

    // MARK: - Auth

    @Test("execute adds auth header when token present")
    func executeAddsAuthHeader() async throws {
        struct Auth: StrapiAuthProvider {
            let token: String? = "test-token"
        }
        let client = TestUtils.makeClient(handler: { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
            return (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        }, auth: Auth())
        let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
            StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
        )
    }

    @Test("execute does not add auth header when no token")
    func executeNoAuthHeaderWhenNoToken() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            return (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
            StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
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

    @Test("execute forwards multiple custom headers")
    func executeForwardsMultipleCustomHeaders() async throws {
        let client = TestUtils.makeClient { request in
            #expect(request.value(forHTTPHeaderField: "X-Header-One") == "value-one")
            #expect(request.value(forHTTPHeaderField: "X-Header-Two") == "value-two")
            return (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
            StrapiRequest<[ArticleDTO]>(
                endpoint: "/articles",
                headers: [
                    "X-Header-One": "value-one",
                    "X-Header-Two": "value-two"
                ]
            )
        )
    }

    @Test("execute with no custom headers does not crash")
    func executeWithNoCustomHeaders() async throws {
        let client = TestUtils.makeClient { request in
            (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        }
        let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
            StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
        )
    }

    // MARK: - Error Handling

    @Test("execute throws HTTP error on 400")
    func executeThrowsHTTPErrorOn400() async {
        let client = TestUtils.makeClient { request in
            (Data(), TestUtils.httpResponse(for: request, code: 400))
        }
        await #expect(throws: StrapiError.self) {
            let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
                StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
            )
        }
    }

    @Test("execute throws HTTP error on 401")
    func executeThrowsHTTPErrorOn401() async {
        let client = TestUtils.makeClient { request in
            (Data(), TestUtils.httpResponse(for: request, code: 401))
        }
        await #expect(throws: StrapiError.self) {
            let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
                StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
            )
        }
    }

    @Test("execute throws HTTP error on 403")
    func executeThrowsHTTPErrorOn403() async {
        let client = TestUtils.makeClient { request in
            (Data(), TestUtils.httpResponse(for: request, code: 403))
        }
        await #expect(throws: StrapiError.self) {
            let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
                StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
            )
        }
    }

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
    func executeThrowsDecodingErrorOnInvalidJSON() async {
        let client = TestUtils.makeClient { request in
            (#"{ "invalid": true }"#.data(using: .utf8)!, TestUtils.okResponse(for: request))
        }
        await #expect(throws: StrapiError.self) {
            let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
                StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
            )
        }
    }

    @Test("execute throws decoding error on empty data")
    func executeThrowsDecodingErrorOnEmptyData() async {
        let client = TestUtils.makeClient { request in
            (Data(), TestUtils.okResponse(for: request))
        }
        await #expect(throws: StrapiError.self) {
            let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
                StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
            )
        }
    }

    @Test("execute throws decoding error on malformed JSON")
    func executeThrowsDecodingErrorOnMalformedJSON() async {
        let client = TestUtils.makeClient { request in
            ("not json at all".data(using: .utf8)!, TestUtils.okResponse(for: request))
        }
        await #expect(throws: StrapiError.self) {
            let _: StrapiResponse<[ArticleDTO]> = try await client.execute(
                StrapiRequest<[ArticleDTO]>(endpoint: "/articles")
            )
        }
    }

    // MARK: - Body encoding throws

    @Test("execute convenience init throws on encoding failure")
    func executeConvenienceInitThrowsOnEncodingFailure() {
        struct BadDTO: Encodable, Sendable {
            func encode(to encoder: Encoder) throws {
                throw EncodingError.invalidValue("bad", .init(codingPath: [], debugDescription: "forced failure"))
            }
        }
        #expect(throws: Error.self) {
            _ = try StrapiRequest<ArticleDTO>(
                endpoint: "/articles",
                method: .POST,
                body: BadDTO()
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
          "meta": {
            "pagination": {
              "page": 1,
              "pageSize": 10,
              "pageCount": 1,
              "total": 1
            }
          }
        }
        """.data(using: .utf8)!
    }
}
