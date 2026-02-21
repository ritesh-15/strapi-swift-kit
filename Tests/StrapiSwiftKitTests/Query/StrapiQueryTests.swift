// StrapiQueryTests.swift
// Tests for the StrapiQuery DSL building URLQueryItems.
// Covers filters, nested fields, sorting, pagination, populate, fields,
// and complex mixed scenarios, with emphasis on key formation and values.

import Foundation
import Testing
@testable import StrapiSwiftKit

// MARK: - StrapiQuery DSL Tests

/// Verifies that StrapiQuery encodes filters, sorts, pagination, populate,
/// and fields into URLQueryItem arrays correctly. Ensures:
/// - Correct operator key mapping ($containsi, $eq, $ne, $gt, $gte, $lt, $lte, etc.)
/// - Proper deep path splitting (e.g., metrics.views -> [metrics][views])
/// - Stable ordering and indexing for arrays (sort, populate, fields)
/// - Multiple items for list-based operators like `$in` / `$notIn`
@Suite("StrapiQueryTests")
struct StrapiQueryTests {

    // MARK: Filters — Contains/Equals

    /// Builds a contains filter on a simple field.
    /// Expects: filters[title][$containsi] == "ios" and single item.
    @Test func testContainsFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.contains("title", "ios"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[title][$contains]")
        #expect(items[0].value == "ios")
    }

    /// Builds contains filters on both a top-level and nested field.
    /// Expects two items, with nested key for author.name.
    @Test func testNestedFieldContainsBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.contains("title", "iOS"))
            .filter(.contains("author.name", "john"))

        let items = query.build()

        #expect(items.count == 2)
        #expect(items[0].name == "filters[title][$contains]")
        #expect(items[0].value == "iOS")
        #expect(items[1].name == "filters[author][name][$contains]")
        #expect(items[1].value == "john")
    }

    /// Builds an equality filter for a simple field.
    /// Expects: filters[title][$eq] == "iOS".
    @Test func testEqualsFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.equals("title", "iOS"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[title][$eq]")
        #expect(items[0].value == "iOS")
    }

    // MARK: Filters — Negative / Inequality

    /// Builds a negative contains filter.
    /// Expects: filters[title][$notcontains] == "ads".
    @Test func testNotContainsFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.notContains("title", "ads"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[title][$notcontains]")
        #expect(items[0].value == "ads")
    }

    /// Builds an inequality filter.
    /// Expects: filters[status][$ne] == "draft".
    @Test func testNotEqualFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.notEqual("status", "draft"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[status][$ne]")
        #expect(items[0].value == "draft")
    }

    // MARK: Filters — Comparisons

    /// Builds a greater-than comparison.
    /// Expects: filters[views][$gt] == "100".
    @Test func testGreaterFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.greater("views", "100"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[views][$gt]")
        #expect(items[0].value == "100")
    }

    /// Builds a greater-than-or-equal comparison.
    /// Expects: filters[views][$gte] == "100".
    @Test func testGreaterThanEqualFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.greaterThanEqual("views", "100"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[views][$gte]")
        #expect(items[0].value == "100")
    }

    /// Builds a less-than comparison.
    /// Expects: filters[views][$lt] == "200".
    @Test func testLesserFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.lesser("views", "200"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[views][$lt]")
        #expect(items[0].value == "200")
    }

    /// Builds a less-than-or-equal comparison.
    /// Expects: filters[views][$lte] == "200".
    @Test func testLesserThanEqualFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.lesserThanEqual("views", "200"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[views][$lte]")
        #expect(items[0].value == "200")
    }

    /// Builds a startsWith filter.
    /// Expects: filters[slug][$startsWith] == "ios-".
    @Test func testStartsWithFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.startsWith("slug", "ios-"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[slug][$startsWith]")
        #expect(items[0].value == "ios-")
    }

    /// Builds an endsWith filter.
    /// Expects: filters[slug][$endsWith] == "-2024".
    @Test func testEndsWithFilterBuildsCorrectQueryItem() async throws {
        let query = StrapiQuery()
            .filter(.endsWith("slug", "-2024"))

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "filters[slug][$endsWith]")
        #expect(items[0].value == "-2024")
    }

    // MARK: Filters — List operators

    /// Builds an `$in` filter with two values.
    /// Expects two items sharing the same key and both values present.
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

    /// Builds a `$notIn` filter with two values.
    /// Expects two items sharing the same key and both values present.
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

    // MARK: Filters — Nested fields

    /// Builds comparison filters on nested fields.
    /// Expects proper deep key formation for metrics.views and metrics.likes.
    @Test func testNestedFieldComparisonFiltersBuildCorrectQueryItems() async throws {
        let query = StrapiQuery()
            .filter(.greater("metrics.views", "1000"))
            .filter(.lesserThanEqual("metrics.likes", "500"))

        let items = query.build()

        #expect(items.count == 2)
        #expect(items.contains { $0.name == "filters[metrics][views][$gt]" && $0.value == "1000" })
        #expect(items.contains { $0.name == "filters[metrics][likes][$lte]" && $0.value == "500" })
    }

    /// Uses `$in` with an empty array.
    /// Expects zero items emitted by the builder.
    @Test func testInFilterWithEmptyArrayProducesNoItems() async throws {
        let query = StrapiQuery()
            .filter(.in("tags", []))

        let items = query.build()

        // Our builder currently iterates list and appends for each value; empty means no items.
        #expect(items.isEmpty)
    }

    /// Uses `$notIn` with an empty array.
    /// Expects zero items emitted by the builder.
    @Test func testNotInFilterWithEmptyArrayProducesNoItems() async throws {
        let query = StrapiQuery()
            .filter(.notIn("tags", []))

        let items = query.build()

        #expect(items.isEmpty)
    }

    // MARK: Complex / Mixed

    /// Builds a complex query with many operators and options.
    /// Expects presence of key items without relying on order, including
    /// filters, sorts, pagination, populate, and fields.
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

        #expect(dict["filters[title][$contains]"]?.first?.value == "swift")
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

    // MARK: Sorting

    /// Adds a single sort.
    /// Expects sort[0] == "publishedAt:desc".
    @Test
    func testSingleSortBuildsCorrectQueryItem() {
        let query = StrapiQuery()
            .sort("publishedAt", .desc)

        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "sort[0]")
        #expect(items[0].value == "publishedAt:desc")
    }

    /// Adds multiple sorts.
    /// Expects stable index order for sort[0] and sort[1].
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

    // MARK: Pagination

    /// Applies pagination.
    /// Expects pagination[page] and pagination[pageSize] present with values.
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

    /// Builds a mid-complexity query mixing filters, sorts, pagination.
    /// Expects exact key/value pairs for each component.
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
        #expect(dict["filters[title][$contains]"] == "ios")
        #expect(dict["filters[status][$eq]"] == "published")
        #expect(dict["filters[author][profile][city][$contains]"] == "pune")

        // sorting
        #expect(dict["sort[0]"] == "publishedAt:desc")
        #expect(dict["sort[1]"] == "title:asc")

        // pagination
        #expect(dict["pagination[page]"] == "3")
        #expect(dict["pagination[pageSize]"] == "50")
    }

    // MARK: Populate

    /// Adds a single populate field.
    /// Expects populate[0] == "author".
    @Test
    func testSinglePopulateBuildsCorrectQueryItem() {
        let query = StrapiQuery()
            .populate("author")
        let items = query.build()

        #expect(items.count == 1)
        #expect(items[0].name == "populate[0]")
        #expect(items[0].value == "author")
    }

    /// Adds multiple populate fields.
    /// Expects stable index order populate[0], populate[1].
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

    // MARK: Fields

    /// Adds multiple fields.
    /// Expects stable index order fields[0], fields[1], fields[2].
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

    /// Combines fields with filters and sort.
    /// Expects all parts encoded correctly and coexisting in the output.
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

    /// Builder with no calls should produce no items.
    @Test
    func testEmptyBuilderProducesNoItems() {
        let query = StrapiQuery()
        let items = query.build()
        #expect(items.isEmpty)
    }

    /// Interleaving filters, sorts, fields, and populate should maintain their own index orders.
    @Test
    func testInterleavedCallsMaintainStableIndexing() {
        let query = StrapiQuery()
            .sort("createdAt", .asc)
            .fields("id")
            .populate("author")
            .sort("title", .desc)
            .fields("title")
            .populate("comments")

        let items = query.build()
        // sort indices
        #expect(items.contains { $0.name == "sort[0]" && $0.value == "createdAt:asc" })
        #expect(items.contains { $0.name == "sort[1]" && $0.value == "title:desc" })
        // fields indices
        #expect(items.contains { $0.name == "fields[0]" && $0.value == "id" })
        #expect(items.contains { $0.name == "fields[1]" && $0.value == "title" })
        // populate indices
        #expect(items.contains { $0.name == "populate[0]" && $0.value == "author" })
        #expect(items.contains { $0.name == "populate[1]" && $0.value == "comments" })
    }

    /// Duplicate filters on the same key should emit multiple items with same key.
    @Test
    func testDuplicateFiltersOnSameFieldEmitMultipleItems() {
        let query = StrapiQuery()
            .filter(.contains("title", "swift"))
            .filter(.contains("title", "ios"))

        let items = query.build()
        let keys = items.map { $0.name }
        #expect(items.count == 2)
        #expect(keys.allSatisfy { $0 == "filters[title][$contains]" })
        let values = items.compactMap { $0.value }
        #expect(values.contains("swift"))
        #expect(values.contains("ios"))
    }

    /// Special characters in values should be preserved in the value field, letting URL encoding handle them later.
    @Test
    func testSpecialCharactersInValues() {
        let query = StrapiQuery()
            .filter(.contains("title", "swift & iOS + tips"))
            .filter(.equals("slug", "swift/ios-guide"))

        let items = query.build()
        #expect(items.contains { $0.name == "filters[title][$contains]" && $0.value == "swift & iOS + tips" })
        #expect(items.contains { $0.name == "filters[slug][$eq]" && $0.value == "swift/ios-guide" })
    }

    /// Pagination with zero or negative values should still encode verbatim (behavioral contract).
    @Test
    func testPaginationWithZeroOrNegativeValues() {
        let zero = StrapiQuery().page(0, size: 0).build()
        #expect(zero.contains { $0.name == "pagination[page]" && $0.value == "0" })
        #expect(zero.contains { $0.name == "pagination[pageSize]" && $0.value == "0" })

        let negative = StrapiQuery().page(-1, size: -10).build()
        #expect(negative.contains { $0.name == "pagination[page]" && $0.value == "-1" })
        #expect(negative.contains { $0.name == "pagination[pageSize]" && $0.value == "-10" })
    }

    /// Empty field list should produce no items.
    @Test
    func testEmptyFieldsProducesNoItems() {
        let query = StrapiQuery()
        // Intentionally pass nothing; API takes variadics, so we don't call fields at all
        let items = query.build()
        #expect(items.isEmpty)
    }

    /// Populate with the same relation twice should create two entries with stable indices.
    @Test
    func testDuplicatePopulateCreatesTwoEntries() {
        let query = StrapiQuery()
            .populate("author")
            .populate("author")
        let items = query.build()
        #expect(items.contains { $0.name == "populate[0]" && $0.value == "author" })
        #expect(items.contains { $0.name == "populate[1]" && $0.value == "author" })
    }

    /// Mixed nested path filters ensure deep path splitting across multiple depths.
    @Test
    func testDeepNestedPathSplitting() {
        let query = StrapiQuery()
            .filter(.equals("a.b.c.d", "1"))
            .filter(.greater("a.b.c.e", "2"))
        let items = query.build()
        #expect(items.contains { $0.name == "filters[a][b][c][d][$eq]" && $0.value == "1" })
        #expect(items.contains { $0.name == "filters[a][b][c][e][$gt]" && $0.value == "2" })
    }
}
