//
//  File.swift
//  StrapiSwiftKit
//
//  Created by Ritesh Khore on 19/02/26.
//

import Foundation

public struct StrapiErrorResponse: Codable, Sendable {
    public let data: EmptyData?
    public let error: StrapiErrorPayload
}

public struct StrapiErrorPayload: Codable, Sendable {
    public let status: Int
    public let name: String
    public let message: String
    public let details: StrapiErrorDetails?
}

public struct StrapiErrorDetails: Codable, Sendable {
    // Keep flexible for now
}

public struct EmptyData: Codable, Sendable {}
