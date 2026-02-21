//
//  FilterNode.swift
//  StrapiSwiftKit
//
//  Created by Ritesh Khore on 21/02/26.
//

import Foundation

public indirect enum FilterNode: Sendable {
    case condition(StrapiFilter)
    case or([FilterNode])
    case and([FilterNode])
}
