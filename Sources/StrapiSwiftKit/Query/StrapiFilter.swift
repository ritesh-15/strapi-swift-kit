import Foundation

public enum FilterValue: Sendable {
    case single(String)
    case list([String])
}

public struct StrapiFilter: Sendable {

    let path: [String]
    let op: StrapiOperators
    let value: FilterValue

    public init(path: [String], op: StrapiOperators, value: FilterValue) {
        self.path = path
        self.op = op
        self.value = value
    }
}

extension StrapiFilter {

    public static func contains(
        _ field: String,
        _ value: String
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .containsi,
            value: .single(value)
        )
    }

    public static func equals(
        _ field: String,
        _ value: String
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .eq,
            value: .single(value)
        )
    }

    public static func notContains(
        _ field: String,
        _ value: String
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .notcontains,
            value: .single(value)
        )
    }

    public static func notEqual(
        _ field: String,
        _ value: String
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .ne,
            value: .single(value)
        )
    }

    public static func greater(
        _ field: String,
        _ value: String
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .gt,
            value: .single(value)
        )
    }

    public static func greaterThanEqual(
        _ field: String,
        _ value: String
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .gte,
            value: .single(value)
        )
    }

    public static func lesser(
        _ field: String,
        _ value: String
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .lt,
            value: .single(value)
        )
    }

    public static func lesserThanEqual(
        _ field: String,
        _ value: String
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .lte,
            value: .single(value)
        )
    }

    public static func startsWith(
        _ field: String,
        _ value: String
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .startsWith,
            value: .single(value)
        )
    }

    public static func endsWith(
        _ field: String,
        _ value: String
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .endsWith,
            value: .single(value)
        )
    }

    public static func `in`(
        _ field: String,
        _ value: [String]
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .in,
            value: .list(value)
        )
    }

    public static func notIn(
        _ field: String,
        _ value: [String]
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .notIn,
            value: .list(value)
        )
    }
}
