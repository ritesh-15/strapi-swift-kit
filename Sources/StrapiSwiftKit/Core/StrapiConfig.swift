import Foundation

public final class StrapiConfig: Sendable {

    public let baseURL: URL
    public let apiPath: String
    public let jwtToken: String?

    init(baseURL: URL, apiPath: String = "/api", jwtToken: String? = nil) {
        self.baseURL = baseURL
        self.apiPath = apiPath
        self.jwtToken = jwtToken
    }
}
