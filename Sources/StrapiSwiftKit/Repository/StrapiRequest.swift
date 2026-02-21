//
//  StrapiRequest.swift
//  StrapiSwiftKit
//
//  Created by Ritesh Khore on 21/02/26.
//

import Foundation

public struct StrapiResponse<Response: Decodable & Sendable>: Sendable {
    public let data: Response
    public let meta: Meta?
}

// Internal Decodable wrapper — user never sees this
internal struct StrapiResponseWrapper<Response: Decodable>: Decodable {
    let data: Response
    let meta: Meta?
}

public struct StrapiRequest<Response: Decodable & Sendable>: Sendable {
    public let endpoint: String
    public let method: StrapiEndpoint.Method
    public let query: StrapiQuery?
    public let body: (any Encodable & Sendable)?
    public let headers: [String: String]?

    public init(
        endpoint: String,
        method: StrapiEndpoint.Method = .GET,
        query: StrapiQuery? = nil,
        body: (any Encodable & Sendable)? = nil,
        headers: [String: String]? = nil
    ) {
        self.endpoint = endpoint
        self.method = method
        self.query = query
        self.body = body
        self.headers = headers
    }
}
