import Foundation
import Testing
@testable import StrapiSwiftKit

private struct DummyDTO: Decodable {}
private typealias DummyList = StrapiListResponse<DummyDTO>

@Suite("StrapiClientTests")
struct StrapiClientTests {

    // MARK: — Test Helpers

    @Test
    func testBuildsCorrectURL() async throws {
        let client = TestUtils.makeClient { request in
            #expect(
                request.url?.absoluteString ==
                "https://example.com/api/articles"
            )

            return (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        }

        let _: DummyList =
            try await client.send(StrapiEndpoint("/articles"))
    }

    @Test
    func testAddsAuthHeader() async throws {

        struct Auth: StrapiAuthProvider {
            let token: String? = "abc123"
        }

        let client = TestUtils.makeClient(handler: { request in
            #expect(
                request.value(forHTTPHeaderField: "Authorization")
                == "Bearer abc123"
            )

            return (TestUtils.okListJSON(), TestUtils.okResponse(for: request))
        },auth: Auth())

        let _: DummyList =
            try await client.send(StrapiEndpoint("/articles"))
    }

    @Test
    func testThrowsHTTPError() async {
        let client = TestUtils.makeClient { request in
            return (Data(), TestUtils.httpResponse(for: request, code: 500))
        }

        await #expect(throws: StrapiError.self) {
            let _: DummyList =
                try await client.send(StrapiEndpoint("/articles"))
        }
    }

    @Test
    func testThrowsDecodingError() async {
        let client = TestUtils.makeClient { request in
            (#"[]"#.data(using: .utf8)!, TestUtils.okResponse(for: request))
        }

        await #expect(throws: StrapiError.self) {
            let _: DummyList =
                try await client.send(StrapiEndpoint("/articles"))
        }
    }
}
