import Foundation

public protocol StrapiAuthProvider: Sendable {
    var token: String? { get }
}
