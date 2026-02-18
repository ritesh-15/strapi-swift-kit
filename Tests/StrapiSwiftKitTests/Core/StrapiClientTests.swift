import Foundation
import Testing
@testable import StrapiSwiftKit

private struct DummyDTO: Decodable {}
private typealias DummyList = StrapiListResponse<DummyDTO>

@Suite(.serialized)
struct StrapiClientTests {

    // MARK: — Test Helpers

    private func makeClient(
        auth: StrapiAuthProvider? = nil
    ) -> StrapiClient {
        StrapiClient(
            config: .init(baseURL: URL(string:"https://example.com")!),
            session: makeMockSession(),
            authProvider: auth
    )
    }

    private func okResponse(for req: URLRequest) -> HTTPURLResponse {
        httpResponse(for: req, code: 200)
    }

    private func httpResponse(
        for req: URLRequest,
        code: Int
    ) -> HTTPURLResponse {
        HTTPURLResponse(
            url: req.url!,
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    private func okListJSON() -> Data {
        """
        {
          "data": [],
          "meta": {
            "pagination": {
              "page": 1,
              "pageSize": 10,
              "pageCount": 1,
              "total": 0
            }
          }
        }
        """.data(using: .utf8)!
    }


    @Test
    func testBuildsCorrectURL() async throws {

        MockURLProtocol.handler = { request in
            #expect(
                request.url?.absoluteString ==
                "https://example.com/api/articles"
            )

            return (okResponse(for: request), okListJSON())
        }

        let client = makeClient()

        let _: DummyList =
            try await client.send(StrapiEndpoint("/articles"))
    }

    @Test
    func testAddsAuthHeader() async throws {

        struct Auth: StrapiAuthProvider {
            let token: String? = "abc123"
        }

        MockURLProtocol.handler = { request in

            #expect(
                request.value(forHTTPHeaderField: "Authorization")
                == "Bearer abc123"
            )

            return (okResponse(for: request), okListJSON())
        }

        let client = makeClient(auth: Auth())

        let _: DummyList =
            try await client.send(StrapiEndpoint("/articles"))
    }

    @Test
    func testThrowsHTTPError() async {

        MockURLProtocol.handler = { request in
            (httpResponse(for: request, code: 500), Data())
        }

        let client = makeClient()

        await #expect(throws: StrapiError.self) {
            let _: DummyList =
                try await client.send(StrapiEndpoint("/articles"))
        }
    }

    @Test
    func testThrowsDecodingError() async {

        MockURLProtocol.handler = { request in
            (okResponse(for: request),
             #"[]"#.data(using: .utf8)!)
        }

        let client = makeClient()

        await #expect(throws: StrapiError.self) {
            let _: DummyList =
                try await client.send(StrapiEndpoint("/articles"))
        }
    }
}
