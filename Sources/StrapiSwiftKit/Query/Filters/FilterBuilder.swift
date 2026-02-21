//
//  FilterBuilder.swift
//  StrapiSwiftKit
//
//  Created by Ritesh Khore on 21/02/26.
//

import Foundation

public struct FilterQueryBuilder: Sendable {

    private(set) var nodes: [FilterNode] = []

    public mutating func and(_ block: (inout FilterQueryBuilder) -> Void) {
        var child = FilterQueryBuilder()
        block(&child)
        nodes.append(.and(child.nodes))
    }

    public mutating func or(_ block: (inout FilterQueryBuilder) -> Void) {
        var child = FilterQueryBuilder()
        block(&child)
        nodes.append(.or(child.nodes))
    }

    // Child filters

    public mutating func equals(_ field: String, _ value: String) {
        condition(.equals(field, value))
    }

    public mutating func notEqual(_ field: String, _ value: String) {
        condition(.notEqual(field, value))
    }

    public mutating func contains(_ field: String, _ value: String) {
        condition(.contains(field, value))
    }

    public mutating func notContains(_ field: String, _ value: String) {
        condition(.notContains(field, value))
    }

    public mutating func greater(_ field: String, _ value: String) {
        condition(.greater(field, value))
    }

    public mutating func greaterThanEqual(_ field: String, _ value: String) {
        condition(.greaterThanEqual(field, value))
    }

    public mutating func lesser(_ field: String, _ value: String) {
        condition(.lesser(field, value))
    }


    public mutating func lesserThanEqual(_ field: String, _ value: String) {
        condition(.lesserThanEqual(field, value))
    }

    public mutating func startsWith(_ field: String, _ value: String) {
        condition(.startsWith(field, value))
    }

    public mutating func endsWith(_ field: String, _ value: String) {
        condition(.endsWith(field, value))
    }

    public mutating func `in`(_ field: String, _ values: [String]) {
        condition(.in(field, values))
    }

    public mutating func notIn(_ field: String, _ values: [String]) {
        condition(.notIn(field, values))
    }

    // MARK: - Private methods

    private mutating func condition(_ filter: StrapiFilter) {
        nodes.append(.condition(filter))
    }
}
