//
//  File.swift
//  StrapiSwiftKit
//
//  Created by Ritesh Khore on 21/02/26.
//

import Foundation
import Testing
@testable import StrapiSwiftKit

@Suite("StrapiQueryDeepPopulateTests")
struct StrapiQueryDeepPopulateTests {

    @Test("simplePopulate")
    func simplePopulate() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("author") { _ in }
                .build()
        )
        #expect(result["populate[author]"] != nil || result.keys.contains(where: { $0.hasPrefix("populate[author]") }))
    }

    @Test("simpleFieldPopulate")
    func simpleFieldPopulate() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("author") {
                    $0.fields("name", "email")
                }
                .build()
        )
        #expect(result["populate[author][fields][0]"] == "name")
        #expect(result["populate[author][fields][1]"] == "email")
    }

    // MARK: - Fields, Filters, Sort

    @Test("populateWithSort")
    func populateWithSort() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("comments") {
                    $0.fields("content", "createdAt")
                    $0.sort("createdAt", .desc)
                }
                .build()
        )
        #expect(result["populate[comments][fields][0]"] == "content")
        #expect(result["populate[comments][fields][1]"] == "createdAt")
        #expect(result["populate[comments][sort][0]"] == "createdAt:desc")
    }

    @Test("populateWithFilters")
    func populateWithFilters() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("comments") {
                    $0.fields("content")
                    $0.filters {
                        $0.equals("status", "approved")
                    }
                }
                .build()
        )
        #expect(result["populate[comments][fields][0]"] == "content")
        #expect(result["populate[comments][filters][status][$eq]"] == "approved")
    }

    @Test("populateWithFieldsFiltersAndSort")
    func populateWithFieldsFiltersAndSort() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("comments") {
                    $0.fields("content", "createdAt")
                    $0.filters {
                        $0.equals("status", "approved")
                    }
                    $0.sort("createdAt", .desc)
                }
                .build()
        )
        #expect(result["populate[comments][fields][0]"] == "content")
        #expect(result["populate[comments][fields][1]"] == "createdAt")
        #expect(result["populate[comments][filters][status][$eq]"] == "approved")
        #expect(result["populate[comments][sort][0]"] == "createdAt:desc")
    }

    // MARK: - Nested Populate

    @Test("nestedPopulate")
    func nestedPopulate() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("comments") {
                    $0.fields("content")
                    $0.populate("author") {
                        $0.fields("name", "email")
                    }
                }
                .build()
        )
        #expect(result["populate[comments][fields][0]"] == "content")
        #expect(result["populate[comments][populate][author][fields][0]"] == "name")
        #expect(result["populate[comments][populate][author][fields][1]"] == "email")
    }

    @Test("deepNestedPopulate")
    func deepNestedPopulate() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("expenses") {
                    $0.fields("id", "description", "amount")
                    $0.populate("splitShares") {
                        $0.fields("id")
                        $0.populate("ownedBy") {
                            $0.fields("id")
                        }
                    }
                    $0.populate("paidBy") {
                        $0.fields("id")
                    }
                }
                .build()
        )
        #expect(result["populate[expenses][fields][0]"] == "id")
        #expect(result["populate[expenses][fields][1]"] == "description")
        #expect(result["populate[expenses][fields][2]"] == "amount")
        #expect(result["populate[expenses][populate][splitShares][fields][0]"] == "id")
        #expect(result["populate[expenses][populate][splitShares][populate][ownedBy][fields][0]"] == "id")
        #expect(result["populate[expenses][populate][paidBy][fields][0]"] == "id")
    }

    @Test("deepNestedPopulateWithFiltersAndSort")
    func deepNestedPopulateWithFiltersAndSort() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("comments") {
                    $0.fields("content", "createdAt")
                    $0.filters {
                        $0.equals("status", "approved")
                    }
                    $0.sort("createdAt", .desc)
                    $0.populate("author") {
                        $0.fields("name", "email")
                        $0.sort("name", .asc)
                    }
                }
                .build()
        )
        #expect(result["populate[comments][fields][0]"] == "content")
        #expect(result["populate[comments][fields][1]"] == "createdAt")
        #expect(result["populate[comments][filters][status][$eq]"] == "approved")
        #expect(result["populate[comments][sort][0]"] == "createdAt:desc")
        #expect(result["populate[comments][populate][author][fields][0]"] == "name")
        #expect(result["populate[comments][populate][author][fields][1]"] == "email")
        #expect(result["populate[comments][populate][author][sort][0]"] == "name:asc")
    }

    // MARK: - Multiple Relations

    @Test("multiplePopulate")
    func multiplePopulate() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("author") {
                    $0.fields("name", "email")
                }
                .populate("tags") {
                    $0.fields("name", "slug")
                }
                .build()
        )
        #expect(result["populate[author][fields][0]"] == "name")
        #expect(result["populate[author][fields][1]"] == "email")
        #expect(result["populate[tags][fields][0]"] == "name")
        #expect(result["populate[tags][fields][1]"] == "slug")
    }

    // MARK: - Real World Scenarios

    /// Blog: populate author with avatar and tags
    @Test("blogPostPopulate")
    func blogPostPopulate() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("author") {
                    $0.fields("name", "bio")
                    $0.populate("avatar") {
                        $0.fields("url", "width", "height")
                    }
                }
                .populate("tags") {
                    $0.fields("name", "slug")
                }
                .populate("category") {
                    $0.fields("name")
                }
                .build()
        )
        #expect(result["populate[author][fields][0]"] == "name")
        #expect(result["populate[author][fields][1]"] == "bio")
        #expect(result["populate[author][populate][avatar][fields][0]"] == "url")
        #expect(result["populate[author][populate][avatar][fields][1]"] == "width")
        #expect(result["populate[author][populate][avatar][fields][2]"] == "height")
        #expect(result["populate[tags][fields][0]"] == "name")
        #expect(result["populate[tags][fields][1]"] == "slug")
        #expect(result["populate[category][fields][0]"] == "name")
    }

    /// Expense tracker: matches the real Strapi query from docs
    @Test("expenseTrackerPopulate")
    func expenseTrackerPopulate() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("creator") {
                    $0.fields("id", "username")
                }
                .populate("members") {
                    $0.fields("id", "username")
                }
                .populate("expenses") {
                    $0.fields("id", "description", "amount")
                    $0.populate("splitShares") {
                        $0.fields("id")
                        $0.populate("ownedBy") {
                            $0.fields("id")
                        }
                    }
                    $0.populate("paidBy") {
                        $0.fields("id")
                    }
                }
                .build()
        )
        #expect(result["populate[creator][fields][0]"] == "id")
        #expect(result["populate[creator][fields][1]"] == "username")
        #expect(result["populate[members][fields][0]"] == "id")
        #expect(result["populate[members][fields][1]"] == "username")
        #expect(result["populate[expenses][fields][0]"] == "id")
        #expect(result["populate[expenses][fields][1]"] == "description")
        #expect(result["populate[expenses][fields][2]"] == "amount")
        #expect(result["populate[expenses][populate][splitShares][fields][0]"] == "id")
        #expect(result["populate[expenses][populate][splitShares][populate][ownedBy][fields][0]"] == "id")
        #expect(result["populate[expenses][populate][paidBy][fields][0]"] == "id")
    }

    /// E-commerce: populate reviews with approved filter and nested author
    @Test("ecommerceProductPopulate")
    func ecommerceProductPopulate() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("reviews") {
                    $0.fields("rating", "comment")
                    $0.filters {
                        $0.equals("approved", "true")
                    }
                    $0.sort("createdAt", .desc)
                    $0.populate("user") {
                        $0.fields("username", "avatar")
                    }
                }
                .populate("images") {
                    $0.fields("url", "alt")
                }
                .build()
        )
        #expect(result["populate[reviews][fields][0]"] == "rating")
        #expect(result["populate[reviews][fields][1]"] == "comment")
        #expect(result["populate[reviews][filters][approved][$eq]"] == "true")
        #expect(result["populate[reviews][sort][0]"] == "createdAt:desc")
        #expect(result["populate[reviews][populate][user][fields][0]"] == "username")
        #expect(result["populate[reviews][populate][user][fields][1]"] == "avatar")
        #expect(result["populate[images][fields][0]"] == "url")
        #expect(result["populate[images][fields][1]"] == "alt")
    }

    // MARK: - Populate with $and / $or Filters

    @Test("populateWithAndFilter")
    func populateWithAndFilter() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("comments") {
                    $0.fields("content", "createdAt")
                    $0.filters {
                        $0.and {
                            $0.equals("status", "approved")
                            $0.equals("visible", "true")
                        }
                    }
                }
                .build()
        )
        #expect(result["populate[comments][fields][0]"] == "content")
        #expect(result["populate[comments][fields][1]"] == "createdAt")
        #expect(result["populate[comments][filters][$and][0][status][$eq]"] == "approved")
        #expect(result["populate[comments][filters][$and][1][visible][$eq]"] == "true")
    }

    @Test("populateWithOrFilter")
    func populateWithOrFilter() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("comments") {
                    $0.fields("content")
                    $0.filters {
                        $0.or {
                            $0.equals("status", "approved")
                            $0.equals("status", "pending")
                        }
                    }
                }
                .build()
        )
        #expect(result["populate[comments][fields][0]"] == "content")
        #expect(result["populate[comments][filters][$or][0][status][$eq]"] == "approved")
        #expect(result["populate[comments][filters][$or][1][status][$eq]"] == "pending")
    }

    @Test("populateWithAndOrCombinedFilter")
    func populateWithAndOrCombinedFilter() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("reviews") {
                    $0.fields("rating", "comment")
                    $0.filters {
                        $0.and {
                            $0.or {
                                $0.equals("status", "approved")
                                $0.equals("status", "featured")
                            }
                            $0.greaterThanEqual("rating", "3")
                        }
                    }
                }
                .build()
        )
        #expect(result["populate[reviews][fields][0]"] == "rating")
        #expect(result["populate[reviews][fields][1]"] == "comment")
        #expect(result["populate[reviews][filters][$and][0][$or][0][status][$eq]"] == "approved")
        #expect(result["populate[reviews][filters][$and][0][$or][1][status][$eq]"] == "featured")
        #expect(result["populate[reviews][filters][$and][1][rating][$gte]"] == "3")
    }

    @Test("nestedPopulateWithAndOrFilter")
    func nestedPopulateWithAndOrFilter() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("expenses") {
                    $0.fields("id", "amount")
                    $0.filters {
                        $0.greaterThanEqual("amount", "0")
                    }
                    $0.populate("splitShares") {
                        $0.fields("id")
                        $0.filters {
                            $0.or {
                                $0.equals("status", "pending")
                                $0.equals("status", "settled")
                            }
                        }
                        $0.populate("ownedBy") {
                            $0.fields("id", "username")
                            $0.filters {
                                $0.and {
                                    $0.equals("active", "true")
                                    $0.equals("verified", "true")
                                }
                            }
                        }
                    }
                }
                .build()
        )
        #expect(result["populate[expenses][fields][0]"] == "id")
        #expect(result["populate[expenses][fields][1]"] == "amount")
        #expect(result["populate[expenses][filters][amount][$gte]"] == "0")
        #expect(result["populate[expenses][populate][splitShares][fields][0]"] == "id")
        #expect(result["populate[expenses][populate][splitShares][filters][$or][0][status][$eq]"] == "pending")
        #expect(result["populate[expenses][populate][splitShares][filters][$or][1][status][$eq]"] == "settled")
        #expect(result["populate[expenses][populate][splitShares][populate][ownedBy][fields][0]"] == "id")
        #expect(result["populate[expenses][populate][splitShares][populate][ownedBy][fields][1]"] == "username")
        #expect(result["populate[expenses][populate][splitShares][populate][ownedBy][filters][$and][0][active][$eq]"] == "true")
        #expect(result["populate[expenses][populate][splitShares][populate][ownedBy][filters][$and][1][verified][$eq]"] == "true")
    }

    @Test("multiplePopulateEachWithFiltersAndSort")
    func multiplePopulateEachWithFiltersAndSort() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("comments") {
                    $0.fields("content")
                    $0.filters { $0.equals("status", "approved") }
                    $0.sort("createdAt", .desc)
                }
                .populate("tags") {
                    $0.fields("name", "slug")
                    $0.filters { $0.equals("active", "true") }
                    $0.sort("name", .asc)
                }
                .build()
        )
        #expect(result["populate[comments][fields][0]"] == "content")
        #expect(result["populate[comments][filters][status][$eq]"] == "approved")
        #expect(result["populate[comments][sort][0]"] == "createdAt:desc")
        #expect(result["populate[tags][fields][0]"] == "name")
        #expect(result["populate[tags][fields][1]"] == "slug")
        #expect(result["populate[tags][filters][active][$eq]"] == "true")
        #expect(result["populate[tags][sort][0]"] == "name:asc")
    }

    @Test("populateCombinedWithFullQuery")
    func populateCombinedWithFullQuery() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .filters {
                    $0.equals("status", "published")
                }
                .populate("author") {
                    $0.fields("name", "email")
                }
                .sort("createdAt", .desc)
                .page(1, size: 10)
                .build()
        )
        #expect(result["filters[status][$eq]"] == "published")
        #expect(result["populate[author][fields][0]"] == "name")
        #expect(result["populate[author][fields][1]"] == "email")
        #expect(result["sort[0]"] == "createdAt:desc")
        #expect(result["pagination[page]"] == "1")
        #expect(result["pagination[pageSize]"] == "10")
    }

    @Test("populateWithMultipleSorts")
    func populateWithMultipleSorts() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("comments") {
                    $0.fields("content")
                    $0.sort("createdAt", .desc)
                    $0.sort("rating", .asc)
                }
                .build()
        )
        #expect(result["populate[comments][fields][0]"] == "content")
        #expect(result["populate[comments][sort][0]"] == "createdAt:desc")
        #expect(result["populate[comments][sort][1]"] == "rating:asc")
    }

    @Test("populateWithMultipleFilters")
    func populateWithMultipleFilters() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("comments") {
                    $0.fields("content")
                    $0.filters {
                        $0.equals("status", "approved")
                        $0.greaterThanEqual("rating", "3")
                    }
                }
                .build()
        )
        #expect(result["populate[comments][filters][$and][0][status][$eq]"] == "approved")
        #expect(result["populate[comments][filters][$and][1][rating][$gte]"] == "3")
    }

    @Test("emptyPopulateBlock")
    func emptyPopulateBlock() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("author")
                .build()
        )
        #expect(result["populate[author]"] == "*")
    }

    @Test("threeLevelDeepPopulate")
    func threeLevelDeepPopulate() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("post") {
                    $0.fields("title")
                    $0.populate("author") {
                        $0.fields("name")
                        $0.populate("avatar") {
                            $0.fields("url")
                        }
                    }
                }
                .build()
        )
        #expect(result["populate[post][fields][0]"] == "title")
        #expect(result["populate[post][populate][author][fields][0]"] == "name")
        #expect(result["populate[post][populate][author][populate][avatar][fields][0]"] == "url")
    }

    @Test("noKeyCollisionOnSameRelationName")
    func noKeyCollisionOnSameRelationName() {
        let result = TestUtils.asDict(
            StrapiQuery()
                .populate("post") {
                    $0.populate("author") {
                        $0.fields("name")
                    }
                }
                .populate("comment") {
                    $0.populate("author") {
                        $0.fields("email")
                    }
                }
                .build()
        )
        #expect(result["populate[post][populate][author][fields][0]"] == "name")
        #expect(result["populate[comment][populate][author][fields][0]"] == "email")
    }
}
