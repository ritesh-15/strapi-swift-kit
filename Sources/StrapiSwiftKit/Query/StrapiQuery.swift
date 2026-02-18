import Foundation

public final class StrapiQuery: @unchecked Sendable {

    private var filters: [StrapiFilter] = []
    private var sorts: [(String, StrapiSortOrder)] = []

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

    @discardableResult
    public func sort(_ field: String, _ order: StrapiSortOrder) -> Self {
        sorts.append((field, order))
        return self
    }

    public func build() -> [URLQueryItem] {
        var items: [URLQueryItem] = filtersQueryItems()
        items.append(contentsOf: sortQueryItems())
        return items
    }
}

extension StrapiQuery {

    private func sortQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        for (index, s) in sorts.enumerated() {
            items.append(
                URLQueryItem(
                    name: "sort[\(index)]",
                    value: "\(s.0):\(s.1.rawValue)"
                )
            )
        }

        return items
    }

    private func filtersQueryItems() -> [URLQueryItem] {
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
