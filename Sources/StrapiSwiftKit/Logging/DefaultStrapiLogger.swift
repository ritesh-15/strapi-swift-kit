//
//  File.swift
//  StrapiSwiftKit
//
//  Created by Ritesh Khore on 19/02/26.
//

import Foundation
import os

public struct DefaultStrapiLogger: StrapiLoggerProtocol {

    private let logger: Logger

    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "StrapiSwiftKit",
        category: String = "Networking",
    ) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func logRequest(_ request: URLRequest, correlationID: String) {
        let method = request.httpMethod ?? "UNKNOWN"
        let urlString = request.url?.absoluteString ?? "Unknown URL"
        let timeout = request.timeoutInterval
        let cachePolicy = String(describing: request.cachePolicy)

        logger.log("[\(correlationID)] → Request \(method, privacy: .public) \(urlString, privacy: .public)")
        logger.debug("[\(correlationID)] Request timeout: \(timeout, privacy: .public)s, cachePolicy: \(cachePolicy, privacy: .public)")

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logger.debug("[\(correlationID)] Headers: \(self.redactedHeaders(headers), privacy: .public)")
        } else {
            logger.debug("[\(correlationID)] Headers: none")
        }

        if let body = request.httpBody, !body.isEmpty {
            if let pretty = prettyPrintedJSONString(from: body) {
                logger.debug("[\(correlationID)] Body JSON: \(pretty, privacy: .public)")
            } else {
                logger.debug("[\(correlationID)] Body: \(body.count, privacy: .public) bytes")
            }
        } else {
            logger.debug("[\(correlationID)] Body: none")
        }
    }

    public func logResponse(response: HTTPURLResponse, data: Data, correlationID: String, durationMs: Int) {
        let urlString = response.url?.absoluteString ?? "Unknown URL"
        logger.log("[\(correlationID)] ← Response \(response.statusCode, privacy: .public) \(urlString, privacy: .public) (\(durationMs, privacy: .public) ms, \(data.count, privacy: .public) bytes)")

        if !response.allHeaderFields.isEmpty {
            let headers = response.allHeaderFields.reduce(into: [String: String]()) { dict, pair in
                if let key = pair.key as? String, let value = pair.value as? CustomStringConvertible {
                    dict[key] = String(describing: value)
                }
            }
            logger.debug("[\(correlationID)] Response headers: \(self.redactedHeaders(headers), privacy: .public)")
        } else {
            logger.debug("[\(correlationID)] Response headers: none")
        }

        if !data.isEmpty {
            if let pretty = prettyPrintedJSONString(from: data) {
                logger.debug("[\(correlationID)] Response JSON: \(pretty, privacy: .public)")
            } else if let text = String(data: data, encoding: .utf8), text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                logger.debug("[\(correlationID)] Response text: \(text, privacy: .public)")
            } else {
                logger.debug("[\(correlationID)] Response body: \(data.count, privacy: .public) bytes (non-text)")
            }
        } else {
            logger.debug("[\(correlationID)] Response body: none")
        }
    }

    public func logNetworkError(_ error: Error, correlationID: String, request: URLRequest, since start: Date) {
        let durationMs = Int(Date().timeIntervalSince(start) * 1000)
        let urlString = request.url?.absoluteString ?? "Unknown URL"
        logger.error("[\(correlationID)] ✕ Network error after \(durationMs, privacy: .public) ms for \(urlString, privacy: .public): \(error.localizedDescription, privacy: .public)")

        let nsError = error as NSError
        logger.debug("[\(correlationID)] Error domain: \(nsError.domain, privacy: .public), code: \(nsError.code, privacy: .public)")
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            logger.debug("[\(correlationID)] Underlying: \(underlying.domain, privacy: .public) (\(underlying.code, privacy: .public)) - \(underlying.localizedDescription, privacy: .public)")
        }
    }

    private func redactedHeaders(_ headers: [String: String]) -> String {
        var safe = headers
        for key in headers.keys {
            if key.caseInsensitiveCompare("Authorization") == .orderedSame ||
                key.caseInsensitiveCompare("Cookie") == .orderedSame ||
                key.lowercased().contains("token") {
                safe[key] = "REDACTED"
            }
        }
        return safe.map { "\($0): \($1)" }
            .sorted()
            .joined(separator: ", ")
    }

    private func prettyPrintedJSONString(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
              JSONSerialization.isValidJSONObject(object) || object is [Any] || object is [String: Any] else {
            // Try to print if it's at least UTF-8 text
            if let text = String(data: data, encoding: .utf8) {
                return text
            }
            return nil
        }
        let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .withoutEscapingSlashes])
        return prettyData.flatMap { String(data: $0, encoding: .utf8) }
    }
}
