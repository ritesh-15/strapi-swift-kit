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

    @Test
    func testSingleSortBuildsCorrectQueryItem() {
        let query = StrapiQuery()
            .sort("publishedAt", .desc)

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "sort[0]")
        #expect(items[0].value == "publishedAt:desc")
    }

    @Test
    func testMultipleSortsBuildCorrectOrder() {
        let query = StrapiQuery()
            .sort("publishedAt", .desc)
            .sort("title", .asc)

        let items = query.build()

        #expect(items.count == 2)

        #expect(items[0].name == "sort[0]")
        #expect(items[0].value == "publishedAt:desc")
        #expect(items[1].name == "sort[1]")
        #expect(items[1].value == "title:asc")
    }

    @Test
    func testPaginationBuildsCorrectQueryItems() {
        let query = StrapiQuery()
            .page(2, size: 25)
        let items = query.build()

        #expect(items.count == 2)

        #expect(items.contains {
            $0.name == "pagination[page]" && $0.value == "2"
        })

        #expect(items.contains {
            $0.name == "pagination[pageSize]" && $0.value == "25"
        })
    }

    @Test
    func testComplexQueryBuildsExpectedItems() {
        let query = StrapiQuery()
            .filter(.contains("title", "ios"))
            .filter(.equals("status", "published"))
            .filter(.contains("author.profile.city", "pune"))
            .sort("publishedAt", .desc)
            .sort("title", .asc)
            .page(3, size: 50)

        let items = query.build()

        // Ensure total count matches expected pieces
        #expect(items.count == 7)

        let dict = Dictionary(
            uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") }
        )

        // filters
        #expect(dict["filters[title][$containsi]"] == "ios")
        #expect(dict["filters[status][$eq]"] == "published")
        #expect(dict["filters[author][profile][city][$containsi]"] == "pune")

        // sorting
        #expect(dict["sort[0]"] == "publishedAt:desc")
        #expect(dict["sort[1]"] == "title:asc")

        // pagination
        #expect(dict["pagination[page]"] == "3")
        #expect(dict["pagination[pageSize]"] == "50")
    }

    @Test
    func testSinglePopulateBuildsCorrectQueryItem() {
        let query = StrapiQuery()
            .populate("author")
        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "populate[0]")
        #expect(items[0].value == "author")
    }

    @Test
    func testMultiplePopulateBuildCorrectOrder() {
        let query = StrapiQuery()
            .populate("author")
            .populate("comments")

        let items = query.build()

        #expect(items.count == 2)

        #expect(items[0].name == "populate[0]")
        #expect(items[0].value == "author")

        #expect(items[1].name == "populate[1]")
        #expect(items[1].value == "comments")
    }
}
