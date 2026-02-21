import Foundation

public enum StrapiOperators: String, Sendable {
    // Comparison
    case eq = "$eq"
    case ne = "$ne"
    case gt = "$gt"
    case gte = "$gte"
    case lt = "$lt"
    case lte = "$lte"

    // String
    case contains = "$contains"
    case containsi = "$containsi"
    case notcontainsi = "$notcontainsi"
    case notcontains = "$notcontains"
    case startsWith = "$startsWith"
    case endsWith = "$endsWith"

    // Array
    case `in` = "$in"
    case notIn = "$notIn"
}
