import Foundation

public struct PopulateQueryBuilder: Sendable {
    private(set) var nodes: [PopulateNode] = []

    public init() {}

    public mutating func all() {
        nodes.append(.all)
    }

    public mutating func field(_ name: String) {
        nodes.append(.field(name))
    }

    public mutating func fields(_ fields: String...) {
        fields.forEach { nodes.append(.field($0)) }
    }

    public mutating func sort(_ field: String, _ order: StrapiSortOrder) {
        nodes.append(.sort(field, order))
    }

    public mutating func filters(_ block: (inout FilterQueryBuilder) -> Void) {
        var builder = FilterQueryBuilder()
        block(&builder)
        let wrapped = builder.nodes.count == 1 ? builder.nodes : [.and(builder.nodes)]
        nodes.append(.filters(wrapped))
    }

    public mutating func populate(_ name: String, _ block: (inout PopulateQueryBuilder) -> Void = { _ in }) {
        var child = PopulateQueryBuilder()
        block(&child)
        nodes.append(.relation(name, child.nodes))
    }
}
