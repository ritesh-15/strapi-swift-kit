//
//  File.swift
//  StrapiSwiftKit
//
//  Created by Ritesh Khore on 19/02/26.
//

import Foundation

public protocol StrapiLoggerProtocol: Sendable {
    func logRequest(_ request: URLRequest, correlationID: String)
    func logResponse(response: HTTPURLResponse, data: Data, correlationID: String, durationMs: Int)
    func logNetworkError(_ error: Error, correlationID: String, request: URLRequest, since start: Date)
}
