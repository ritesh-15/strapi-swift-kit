import Foundation
import Testing
@testable import StrapiSwiftKit

@Suite("StrapiQueryTests")
struct StrapiQueryTests {

    @Test func testContainsFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.contains("title", "ios"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[title][$containsi]")
        #expect(items[0].value == "ios")
    }

    @Test func testNestedFieldContainsBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.contains("title", "iOS"))
            .filter(.contains("author.name", "john"))

        let items = query.build()

        #expect(items.count == 2)
        #expect(items[0].name == "filters[title][$containsi]")
        #expect(items[0].value == "iOS")
        #expect(items[1].name == "filters[author][name][$containsi]")
        #expect(items[1].value == "john")
    }

    @Test func testEqualsFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.equals("title", "iOS"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[title][$eq]")
        #expect(items[0].value == "iOS")
    }
}
