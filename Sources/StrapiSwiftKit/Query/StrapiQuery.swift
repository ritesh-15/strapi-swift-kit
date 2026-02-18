import Foundation

public final class StrapiQuery: @unchecked Sendable {

    private var filters: [StrapiFilter] = []

    public init() {}

    @discardableResult
    public func filter(_ f: StrapiFilter) -> Self {
        filters.append(f)
        return self
    }

    @discardableResult
    public func equal(_ f: StrapiFilter) -> Self {
        filters.append(f)
        return self
    }

    public func build() -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        for filter in filters {
            var key = "filters"

            for p in filter.path {
                key += "[\(p)]"
            }

            key += "[\(filter.op.rawValue)]"
            items.append(URLQueryItem(name: key, value: filter.value))
        }

        return items
    }
}
