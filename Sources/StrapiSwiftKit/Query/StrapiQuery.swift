import Foundation

public struct StrapiQuery: Sendable {

    private var filters: [StrapiFilter] = []
    private var deepFilters: [FilterNode] = []
    private var populates: [String] = []
    private var fields: [String] = []
    private var sorts: [(String, StrapiSortOrder)] = []
    private var pageNumber: Int?
    private var pageSize: Int?

    public init() {}

    private init(filters: [StrapiFilter], deepFilters: [FilterNode], populates: [String], fields: [String], sorts: [(String, StrapiSortOrder)], pageNumber: Int?, pageSize: Int?) {
        self.filters = filters
        self.deepFilters = deepFilters
        self.populates = populates
        self.fields = fields
        self.sorts = sorts
        self.pageNumber = pageNumber
        self.pageSize = pageSize
    }

    @available(*, deprecated, renamed: "filters", message: "Use `filters` instead.")
    public func filter(_ f: StrapiFilter) -> Self {
        StrapiQuery(
            filters: filters + [f],
            deepFilters: deepFilters,
            populates: populates,
            fields: fields,
            sorts: sorts,
            pageNumber: pageNumber,
            pageSize: pageSize
        )
    }

    @discardableResult
    public func filters(_ block:(inout FilterQueryBuilder) -> Void) -> Self {
        var builder = FilterQueryBuilder()
        block(&builder)
        let wrapped = builder.nodes.count == 1 ? builder.nodes : [.and(builder.nodes)]
        return StrapiQuery(
            filters: filters,
            deepFilters: deepFilters + wrapped,
            populates: populates,
            fields: fields,
            sorts: sorts,
            pageNumber: pageNumber,
            pageSize: pageSize
        )
    }

    @discardableResult
    public func sort(_ field: String, _ order: StrapiSortOrder) -> Self {
        StrapiQuery(
            filters: filters,
            deepFilters: deepFilters,
            populates: populates,
            fields: fields,
            sorts: sorts + [(field, order)],
            pageNumber: pageNumber,
            pageSize: pageSize
        )
    }

    @discardableResult
    public func page(_ page: Int, size pageSize: Int) -> Self {
        StrapiQuery(
            filters: filters,
            deepFilters: deepFilters,
            populates: populates,
            fields: fields,
            sorts: sorts,
            pageNumber: page,
            pageSize: pageSize
        )
    }

    @discardableResult
    public func populate(_ field: String) -> Self {
        StrapiQuery(
            filters: filters,
            deepFilters: deepFilters,
            populates: populates + [field],
            fields: fields,
            sorts: sorts,
            pageNumber: pageNumber,
            pageSize: pageSize
        )
    }

    @discardableResult
    public func fields(_ field: String...) -> Self {
        StrapiQuery(
            filters: filters,
            deepFilters: deepFilters,
            populates: populates,
            fields: fields + field,
            sorts: sorts,
            pageNumber: pageNumber,
            pageSize: pageSize
        )
    }

    func build() -> [URLQueryItem] {
        var items: [URLQueryItem] = filtersQueryItems()
        items.append(contentsOf: FilterEncoder().encode(nodes: deepFilters))
        items.append(contentsOf: sortQueryItems())
        items.append(contentsOf: paginationQueryItems())
        items.append(contentsOf: populatesQueryItems())
        items.append(contentsOf: fieldsQueryItems())
        return items
    }
}

extension StrapiQuery {

    private func fieldsQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        for (index, field) in fields.enumerated() {
            items.append(
                URLQueryItem(
                    name: "fields[\(index)]",
                    value: field
                )
            )
        }

        return items
    }

    private func populatesQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        for (index, field) in populates.enumerated() {
            items.append(
                URLQueryItem(
                    name: "populate[\(index)]",
                    value: field
                )
            )
        }

        return items
    }

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

            switch filter.value {
            case .single(let value):
                items.append(URLQueryItem(name: key, value: value))
            case .list(let valuesList):
                for value in valuesList {
                    items.append(URLQueryItem(name: key, value: value))
                }
            }
        }

        return items
    }
}
