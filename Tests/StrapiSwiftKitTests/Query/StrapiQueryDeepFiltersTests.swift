// StrapiQueryDeepFiltersTests.swift
// Tests for deep filtering query building in StrapiSwiftKit.
// This suite verifies correct parameter key construction, nesting, indexing,
// and operator encoding for complex and edge-case deep filter scenarios.

import Foundation
import Testing
@testable import StrapiSwiftKit

// MARK: - Deep Filtering Query Tests

/// Verifies Strapi deep filter encoding into URLQueryItem arrays. Ensures:
/// - Correct nesting of `$and`/`$or` groups
/// - Proper splitting of deep paths (e.g., `author.name` -> `[author][name]`)
/// - Stable index ordering for sibling conditions
/// - Accurate operator keys (e.g., `$eq`, `$ne`, `$in`, `$gte`, `$lte`, `$null`)
/// - Edge case behavior for empty groups and conflicting conditions
@Suite
struct StrapiDeepFilteringTests {

    /// Converts an array of URLQueryItem into a name->value dictionary for
    /// easy assertions in tests. Missing values are treated as empty strings.
    private func asDict(_ items: [URLQueryItem]) -> [String: String] {
        var dict: [String: String] = [:]
        for item in items {
            dict[item.name] = item.value ?? ""
        }
        return dict
    }

    // MARK: Basic deep equality

    /// Encodes a single deep path equality inside a top-level `$and` group.
    /// Expects: filters[$and][0][author][name][$eq] == "Alice"
    @Test func testSingleTopLevelDeepFilter() async throws {
        let items = StrapiQuery()
            .filters {
                $0.and {
                    $0.equals("author.name", "Alice")
                }
            }
            .build()

        let dict = asDict(items)
        #expect(dict["filters[$and][0][author][name][$eq]"] == "Alice")
    }

    /// Encodes multiple deep equality filters within the same `$and` group.
    /// Expects stable indices for each sibling condition.
    @Test func testMultipleDeepFiltersInAndGroup() async throws {
        let items = StrapiQuery()
            .filters {
                $0.and {
                    $0.equals("author.name", "Alice")
                    $0.equals("category.slug", "news")
                }
            }
            .build()

        let dict = asDict(items)
        #expect(dict["filters[$and][0][author][name][$eq]"] == "Alice")
        #expect(dict["filters[$and][1][category][slug][$eq]"] == "news")
    }

    /// Encodes nested `$and` containing an `$or` group with two deep path checks.
    /// Expects correct key nesting and sibling indices within `$or`.
    @Test func testNestedAndOrDeepFilters() async throws {
        let items = StrapiQuery()
            .filters {
                $0.and {
                    $0.equals("author.name", "Alice")
                    $0.or {
                        $0.equals("category.slug", "news")
                        $0.equals("category.slug", "sports")
                    }
                }
            }
            .build()

        let dict = asDict(items)
        #expect(dict["filters[$and][0][author][name][$eq]"] == "Alice")
        #expect(dict["filters[$and][1][$or][0][category][slug][$eq]"] == "news")
        #expect(dict["filters[$and][1][$or][1][category][slug][$eq]"] == "sports")
    }

    // MARK: Comparison operators

    /// Uses numeric comparison operators on deep paths within an `$and` group.
    /// Expects `$gte` and `$lte` operator keys with correct values.
    @Test func testDeepFilterWithComparisonOperators() async throws {
        let items = StrapiQuery()
            .filters {
                $0.and {
                    $0.greaterThanEqual("comments.count", "10")
                    $0.lesserThanEqual("rating.average", "4.5")
                }
            }
            .build()

        let dict = asDict(items)
        #expect(dict["filters[$and][0][comments][count][$gte]"] == "10")
        #expect(dict["filters[$and][1][rating][average][$lte]"] == "4.5")
    }

    // MARK: Collection operators

    /// Uses collection operators `$in` and `$notIn` on deep paths within `$or`.
    /// Expects array indices to be encoded as sequential numeric keys.
    @Test func testDeepFilterWithInAndNotIn() async throws {
        let items = StrapiQuery()
            .filters {
                $0.or {
                    $0.in("tags.slug", ["swift", "ios"])
                    $0.notIn("author.role", ["guest", "banned"])
                }
            }
            .build()

        let dict = asDict(items)
        #expect(dict["filters[$or][0][tags][slug][$in][0]"] == "swift")
        #expect(dict["filters[$or][0][tags][slug][$in][1]"] == "ios")
        #expect(dict["filters[$or][1][author][role][$notIn][0]"] == "guest")
        #expect(dict["filters[$or][1][author][role][$notIn][1]"] == "banned")
    }

    // MARK: Path depth

    /// Encodes a value match for a path several levels deep (a.b.c.d).
    /// Expects each path segment to map to a nested bracket in the key.
    @Test func testMultipleLevelsDeepPath() async throws {
        let items = StrapiQuery()
            .filters {
                $0.equals("a.b.c.d", "value")
            }
            .build()

        let dict = asDict(items)
        #expect(dict["filters[a][b][c][d][$eq]"] == "value")
    }

    // MARK: Edge cases

    /// Ensures empty `$and`/`$or` groups do not produce any query items.
    /// Expects: no URLQueryItem output when groups have no conditions.
    @Test func testEmptyAndOrGroupsProduceNoFilters() async throws {
        let items = StrapiQuery()
            .filters { builder in
                builder.and { _ in }
                builder.or { _ in }
            }
            .build()

        // Expect that empty groups don't emit parameters
        #expect(items.isEmpty)
    }

    /// Adds two conditions for the same deep key to validate stable ordering.
    /// Expects preserved indices (0 and 1) for duplicate path conditions.
    @Test func testConflictingDeepFiltersKeepOrder() async throws {
        let items = StrapiQuery()
            .filters {
                $0.and {
                    $0.equals("author.name", "Alice")
                    $0.equals("author.name", "Bob")
                }
            }
            .build()

        // Ensure both entries exist with preserved indices
        let keys = items.map { $0.name }
        #expect(keys.contains("filters[$and][0][author][name][$eq]"))
        #expect(keys.contains("filters[$and][1][author][name][$eq]"))
    }

    /// Mixes equality, inequality, and comparison operators across nested groups.
    /// Expects correct operator keys and nested group indices.
    @Test func testMixedOperatorsWithinNestedGroups() async throws {
        let items = StrapiQuery()
            .filters {
                $0.or {
                    $0.equals("author.name", "Alice")
                    $0.and {
                        $0.notEqual("category.slug", "archive")
                        $0.greaterThanEqual("stats.views", "100")
                    }
                }
            }
            .build()

        let dict = asDict(items)
        #expect(dict["filters[$or][0][author][name][$eq]"] == "Alice")
        #expect(dict["filters[$or][1][$and][0][category][slug][$ne]"] == "archive")
        #expect(dict["filters[$or][1][$and][1][stats][views][$gte]"] == "100")
    }

    /// Verifies sibling conditions within `$and` receive sequential indices.
    /// Expects indices 0, 1, 2 mapped to each deep path.
    @Test func testIndexingAcrossSiblings() async throws {
        let items = StrapiQuery()
            .filters {
                $0.and {
                    $0.equals("a.b", "1")
                    $0.equals("c.d", "2")
                    $0.equals("e.f", "3")
                }
            }
            .build()

        let dict = asDict(items)
        #expect(dict["filters[$and][0][a][b][$eq]"] == "1")
        #expect(dict["filters[$and][1][c][d][$eq]"] == "2")
        #expect(dict["filters[$and][2][e][f][$eq]"] == "3")
    }

    @Test("singleTopLevelOrPassesThroughUnwrapped")
    func singleTopLevelOrPassesThroughUnwrapped() {
        let result = asDict(
            StrapiQuery()
                .filters {
                    $0.or {
                        $0.equals("category", "shoes")
                        $0.equals("category", "bags")
                    }
                }
                .build()
        )
        #expect(result["filters[$or][0][category][$eq]"] == "shoes")
        #expect(result["filters[$or][1][category][$eq]"] == "bags")
    }

    @Test("multipleTopLevelOrWrappedInAnd")
    func multipleTopLevelOrWrappedInAnd() {
        let result = asDict(
            StrapiQuery()
                .filters {
                    $0.or {
                        $0.equals("category", "shoes")
                        $0.equals("category", "bags")
                    }
                    $0.or {
                        $0.equals("brand", "nike")
                        $0.equals("brand", "adidas")
                    }
                }
                .build()
        )
        #expect(result["filters[$and][0][$or][0][category][$eq]"] == "shoes")
        #expect(result["filters[$and][0][$or][1][category][$eq]"] == "bags")
        #expect(result["filters[$and][1][$or][0][brand][$eq]"] == "nike")
        #expect(result["filters[$and][1][$or][1][brand][$eq]"] == "adidas")
    }

    @Test("multipleTopLevelAndWrappedInAnd")
    func multipleTopLevelAndWrappedInAnd() {
        let result = asDict(
            StrapiQuery()
                .filters {
                    $0.and {
                        $0.equals("category", "shoes")
                        $0.equals("inStock", "true")
                    }
                    $0.and {
                        $0.equals("brand", "nike")
                        $0.equals("verified", "true")
                    }
                }
                .build()
        )
        #expect(result["filters[$and][0][$and][0][category][$eq]"] == "shoes")
        #expect(result["filters[$and][0][$and][1][inStock][$eq]"] == "true")
        #expect(result["filters[$and][1][$and][0][brand][$eq]"] == "nike")
        #expect(result["filters[$and][1][$and][1][verified][$eq]"] == "true")
    }

    @Test("multipleTopLevelMixedWrappedInAnd")
    func multipleTopLevelMixedWrappedInAnd() {
        let result = asDict(
            StrapiQuery()
                .filters {
                    $0.or {
                        $0.equals("category", "shoes")
                        $0.equals("category", "bags")
                    }
                    $0.and {
                        $0.greaterThanEqual("price", "50")
                        $0.lesserThanEqual("price", "200")
                    }
                    $0.equals("inStock", "true")
                }
                .build()
        )
        #expect(result["filters[$and][0][$or][0][category][$eq]"] == "shoes")
        #expect(result["filters[$and][0][$or][1][category][$eq]"] == "bags")
        #expect(result["filters[$and][1][$and][0][price][$gte]"] == "50")
        #expect(result["filters[$and][1][$and][1][price][$lte]"] == "200")
        #expect(result["filters[$and][2][inStock][$eq]"] == "true")
    }

    // MARK: Additional operator coverage

    /// Tests not-equal operator on a deep path.
    @Test func testDeepNotEqualOperator() async throws {
        let dict = asDict(
            StrapiQuery()
                .filters {
                    $0.notEqual("author.name", "Charlie")
                }
                .build()
        )
        #expect(dict["filters[author][name][$ne]"] == "Charlie")
    }

    /// Tests greater-than and less-than operators on deep paths.
    @Test func testDeepGreaterThanAndLessThanOperators() async throws {
        let dict = asDict(
            StrapiQuery()
                .filters {
                    $0.greater("stats.likes", "100")
                    $0.lesser("stats.dislikes", "10")
                }
                .build()
        )
        #expect(dict["filters[$and][0][stats][likes][$gt]"] == "100")
        #expect(dict["filters[$and][1][stats][dislikes][$lt]"] == "10")
    }

    /// Tests contains and notContains operators (case-sensitive) on deep paths.
    @Test func testDeepContainsAndNotContainsOperators() async throws {
        let dict = asDict(
            StrapiQuery()
                .filters {
                    $0.contains("title.text", "Swift")
                    $0.notContains("title.text", "Kotlin")
                }
                .build()
        )
        #expect(dict["filters[$and][0][title][text][$contains]"] == "Swift")
        #expect(dict["filters[$and][1][title][text][$notcontains]"] == "Kotlin")
    }

    /// Tests startsWith and endsWith operators on deep paths.
    @Test func testDeepStartsWithAndEndsWithOperators() async throws {
        let dict = asDict(
            StrapiQuery()
                .filters {
                    $0.startsWith("slug.value", "news-")
                    $0.endsWith("slug.value", "-2025")
                }
                .build()
        )
        #expect(dict["filters[$and][0][slug][value][$startsWith]"] == "news-")
        #expect(dict["filters[$and][1][slug][value][$endsWith]"] == "-2025")
    }

    /// Tests $in and $notIn again on shallow path for completeness.
    @Test func testShallowInAndNotInOperators() async throws {
        let dict = asDict(
            StrapiQuery()
                .filters {
                    $0.in("state", ["draft", "published"]) 
                    $0.notIn("role", ["guest", "banned"]) 
                }
                .build()
        )
        #expect(dict["filters[$and][0][state][$in][0]"] == "draft")
        #expect(dict["filters[$and][0][state][$in][1]"] == "published")
        #expect(dict["filters[$and][1][role][$notIn][0]"] == "guest")
        #expect(dict["filters[$and][1][role][$notIn][1]"] == "banned")
    }
}
