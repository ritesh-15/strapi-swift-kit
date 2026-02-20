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

    @Test func testNotContainsFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.notContains("title", "ads"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[title][$notcontains]")
        #expect(items[0].value == "ads")
    }

    @Test func testNotEqualFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.notEqual("status", "draft"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[status][$ne]")
        #expect(items[0].value == "draft")
    }

    @Test func testGreaterFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.greater("views", "100"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[views][$gt]")
        #expect(items[0].value == "100")
    }

    @Test func testGreaterThanEqualFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.greaterThanEqual("views", "100"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[views][$gte]")
        #expect(items[0].value == "100")
    }

    @Test func testLesserFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.lesser("views", "200"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[views][$lt]")
        #expect(items[0].value == "200")
    }

    @Test func testLesserThanEqualFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.lesserThanEqual("views", "200"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[views][$lte]")
        #expect(items[0].value == "200")
    }

    @Test func testStartsWithFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.startsWith("slug", "ios-"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[slug][$startsWith]")
        #expect(items[0].value == "ios-")
    }

    @Test func testEndsWithFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.endsWith("slug", "-2024"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[slug][$endsWith]")
        #expect(items[0].value == "-2024")
    }

    @Test func testInFilterBuildsMultipleQueryItems() async throws {
        let query = StrapiQuery()
            .filter(.in("category", ["ios", "swift"]))

        let items = query.build()

        // For list values, we expect two query items with the same key
        #expect(items.count == 2)
        let keys = items.map { $0.name }
        #expect(keys.allSatisfy { $0 == "filters[category][$in]" })
        let values = items.compactMap { $0.value }
        #expect(values.contains("ios"))
        #expect(values.contains("swift"))
    }

    @Test func testNotInFilterBuildsMultipleQueryItems() async throws {
        let query = StrapiQuery()
            .filter(.notIn("category", ["android", "backend"]))

        let items = query.build()

        #expect(items.count == 2)
        let keys = items.map { $0.name }
        #expect(keys.allSatisfy { $0 == "filters[category][$notIn]" })
        let values = items.compactMap { $0.value }
        #expect(values.contains("android"))
        #expect(values.contains("backend"))
    }

    @Test func testNestedFieldComparisonFiltersBuildCorrectQueryItems() async throws {
        let query = StrapiQuery()
            .filter(.greater("metrics.views", "1000"))
            .filter(.lesserThanEqual("metrics.likes", "500"))

        let items = query.build()

        #expect(items.count == 2)
        #expect(items.contains { $0.name == "filters[metrics][views][$gt]" && $0.value == "1000" })
        #expect(items.contains { $0.name == "filters[metrics][likes][$lte]" && $0.value == "500" })
    }

    @Test func testInFilterWithEmptyArrayProducesNoItems() async throws {
        let query = StrapiQuery()
            .filter(.in("tags", []))

        let items = query.build()

        // Our builder currently iterates list and appends for each value; empty means no items.
        #expect(items.isEmpty)
    }

    @Test func testNotInFilterWithEmptyArrayProducesNoItems() async throws {
        let query = StrapiQuery()
            .filter(.notIn("tags", []))

        let items = query.build()

        #expect(items.isEmpty)
    }

    @Test func testComplexQueryWithAllOperatorsBuildsExpectedItems() async throws {
        let query = StrapiQuery()
            .filter(.contains("title", "swift"))
            .filter(.notContains("body", "deprecated"))
            .filter(.startsWith("slug", "swift-"))
            .filter(.endsWith("slug", "-guide"))
            .filter(.greater("metrics.views", "100"))
            .filter(.greaterThanEqual("metrics.likes", "10"))
            .filter(.lesser("metrics.bounce", "80"))
            .filter(.lesserThanEqual("metrics.shares", "50"))
            .filter(.equals("status", "published"))
            .filter(.notEqual("language", "objective-c"))
            .filter(.in("category", ["ios", "swift"]))
            .filter(.notIn("tags", ["old", "beta"]))
            .sort("publishedAt", .desc)
            .page(1, size: 10)
            .populate("author")
            .fields("title", "slug")

        let items = query.build()

        // Validate presence of key items without relying on order
        let dict = Dictionary(grouping: items, by: { $0.name })

        #expect(dict["filters[title][$containsi]"]?.first?.value == "swift")
        #expect(dict["filters[body][$notcontains]"]?.first?.value == "deprecated")
        #expect(dict["filters[slug][$startsWith]"]?.first?.value == "swift-")
        #expect(dict["filters[slug][$endsWith]"]?.first?.value == "-guide")
        #expect(dict["filters[metrics][views][$gt]"]?.first?.value == "100")
        #expect(dict["filters[metrics][likes][$gte]"]?.first?.value == "10")
        #expect(dict["filters[metrics][bounce][$lt]"]?.first?.value == "80")
        #expect(dict["filters[metrics][shares][$lte]"]?.first?.value == "50")
        #expect(dict["filters[status][$eq]"]?.first?.value == "published")
        #expect(dict["filters[language][$ne]"]?.first?.value == "objective-c")

        let inValues = dict["filters[category][$in]"]?.compactMap { $0.value } ?? []
        #expect(inValues.contains("ios"))
        #expect(inValues.contains("swift"))

        let notInValues = dict["filters[tags][$notIn]"]?.compactMap { $0.value } ?? []
        #expect(notInValues.contains("old"))
        #expect(notInValues.contains("beta"))

        #expect(dict["sort[0]"]?.first?.value == "publishedAt:desc")
        #expect(dict["pagination[page]"]?.first?.value == "1")
        #expect(dict["pagination[pageSize]"]?.first?.value == "10")
        #expect(dict["populate[0]"]?.first?.value == "author")

        // fields are indexed; verify both present
        #expect(items.contains { $0.name == "fields[0]" && $0.value == "title" })
        #expect(items.contains { $0.name == "fields[1]" && $0.value == "slug" })
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

    @Test
    func testFieldsBuildCorrectQueryItems() {
        let query = StrapiQuery()
            .fields("title", "slug", "publishedAt")

        let items = query.build()

        #expect(items.count == 3)

        #expect(items[0].name == "fields[0]")
        #expect(items[0].value == "title")

        #expect(items[1].name == "fields[1]")
        #expect(items[1].value == "slug")

        #expect(items[2].name == "fields[2]")
        #expect(items[2].value == "publishedAt")
    }

    @Test
    func testFieldsWorkWithFiltersAndSort() {
        let query = StrapiQuery()
            .fields("title", "slug")
            .filter(.equals("status", "published"))
            .sort("publishedAt", .desc)

        let items = query.build()

        let dict = Dictionary(
            uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") }
        )

        #expect(dict["fields[0]"] == "title")
        #expect(dict["fields[1]"] == "slug")
        #expect(dict["filters[status][$eq]"] == "published")
        #expect(dict["sort[0]"] == "publishedAt:desc")
    }

}
