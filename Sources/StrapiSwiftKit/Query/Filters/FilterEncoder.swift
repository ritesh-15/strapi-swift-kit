//
//  File.swift
//  StrapiSwiftKit
//
//  Created by Ritesh Khore on 21/02/26.
//

import Foundation

public struct FilterEncoder: Sendable {

    func encode(nodes: [FilterNode]) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if nodes.count == 1 {
            encode(node: nodes[0], prefix: "filters", items: &items)
        } else {
            // combine the multiple nodes present at the top level into $and
            let parentNode = FilterNode.and(nodes)
            encode(node: parentNode, prefix: "filters", items: &items)
        }
        return items
    }

    private func encode(node: FilterNode, prefix: String, items: inout [URLQueryItem]) {
        switch node {
        case .condition(let filter):
            var key = prefix
            for p in filter.path {
                key += "[\(p)]"
            }
            key += "[\(filter.op.rawValue)]"

            switch filter.value {
            case .single(let value):
                items.append(URLQueryItem(name: key, value: value))
            case .list(let valuesList):
                valuesList.enumerated().forEach { index, value in
                    items.append(URLQueryItem(name: "\(key)[\(index)]", value: value))
                }
            }
        case .or(let nodes):
            nodes.enumerated().forEach { index, node in
                encode(node: node, prefix: "\(prefix)[$or][\(index)]", items: &items)
            }
        case .and(let nodes):
            nodes.enumerated().forEach { index, node in
                encode(node: node, prefix: "\(prefix)[$and][\(index)]", items: &items)
            }
        }
    }
}
