import Foundation

public struct PopulateEncoder: Sendable {
    public init() {}

    public func encode(_ nodes: [PopulateNode]) -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        if nodes.contains(where: { if case .all = $0 { return true }; return false }) {
            items.append(URLQueryItem(name: "populate", value: "*"))
            return items
        }

        for node in nodes {
            encode(node, prefix: "populate", into: &items)
        }

        return items
    }

    private func encode(_ node: PopulateNode, prefix: String, into items: inout [URLQueryItem]) {
        switch node {
        case .all:
            items.append(URLQueryItem(name: prefix, value: "*"))
        case .field(let name):
            let index = items.filter { $0.name.hasPrefix("\(prefix)[fields]") }.count
            items.append(URLQueryItem(name: "\(prefix)[fields][\(index)]", value: name))
        case .sort(let field, let order):
            let index = items.filter { $0.name.hasPrefix("\(prefix)[sort]") }.count
            items.append(URLQueryItem(name: "\(prefix)[sort][\(index)]", value: "\(field):\(order.rawValue)"))
        case .filters(let filterNodes):
            let filterEncoder = FilterEncoder()
            let filterItems = filterEncoder.encode(nodes: filterNodes)
            for item in filterItems {
                let newName = item.name.replacingOccurrences(of: "filters", with: "\(prefix)[filters]", options: .anchored)
                items.append(URLQueryItem(name: newName, value: item.value))
            }
        case .relation(let name, let children):
            let base = "\(prefix)[\(name)]"
            if children.isEmpty {
                // simple relation with no fields — encode as populate[name]=*
                items.append(URLQueryItem(name: base, value: "*"))
                return
            }

            for child in children {
                switch child {
                case .relation:
                    // nested relation goes under [populate]
                    encode(child, prefix: "\(base)[populate]", into: &items)
                default:
                    // fields, filters, sort go directly under base
                    encode(child, prefix: base, into: &items)
                }
            }
        }
    }
}
