import Foundation

public struct StrapiFilter: Sendable {

    let path: [String]
    let op: StrapiOperators
    let value: String

    public init(path: [String], op: StrapiOperators, value: String) {
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
            value: value
        )
    }

    public static func equals(
        _ field: String,
        _ value: String
    ) -> StrapiFilter {
        .init(
            path: field.split(separator: ".").map(String.init),
            op: .eq,
            value: value
        )
    }
}
