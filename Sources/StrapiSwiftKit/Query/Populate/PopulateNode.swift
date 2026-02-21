//
//  PopulateNode.swift
//  StrapiSwiftKit
//
//  Created by Ritesh Khore on 21/02/26.
//

import Foundation

public indirect enum PopulateNode: Sendable {
    case all
    case field(String)
    case sort(String, StrapiSortOrder)
    case relation(String, [PopulateNode])
    case filters([FilterNode])
}
