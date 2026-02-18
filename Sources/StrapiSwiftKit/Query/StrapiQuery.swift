import Foundation

public final class StrapiQuery: @unchecked Sendable {

    private var filters: [StrapiFilter] = []
    private var sorts: [(String, StrapiSortOrder)] = []
    private var pageNumber: Int?
    private var pageSize: Int?

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

    @discardableResult
    public func page(_ page: Int, size pageSize: Int) -> Self {
        self.pageSize = pageSize
        self.pageNumber = page
        return self
    }


    public func build() -> [URLQueryItem] {
        var items: [URLQueryItem] = filtersQueryItems()
        items.append(contentsOf: sortQueryItems())
        items.append(contentsOf: paginationQueryItems())
        return items
    }
}

extension StrapiQuery {

    private func paginationQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let pageNumber {
            items.append(
                URLQueryItem(
                    name: "pagination[page]",
                    value: String(pageNumber)
                )
            )
        }
        if let pageSize {
            items.append(
                URLQueryItem(
                    name: "pagination[pageSize]",
                    value: String(pageSize)
                )
            )
        }
        return items
    }

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
