# StrapiSwiftKit

![CI](https://github.com/ritesh-15/strapi-swift-kit/actions/workflows/CI.yaml/badge.svg)
![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)
![Platforms](https://img.shields.io/badge/platforms-iOS%2015%2B%20%7C%20macOS%2012%2B-blue.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)
![Strapi](https://img.shields.io/badge/Strapi-v5-blueviolet.svg)

A modular, type-safe Swift package for interacting with Strapi v5 REST APIs.

StrapiSwiftKit provides a clean Query DSL, a type-safe request layer, and a transport-abstracted client designed for Swift Concurrency and parallel-safe testing.

---

## ✨ Features

- **Type-safe Query DSL**
  - Filters with `$and` / `$or` nesting
  - All Strapi operators (`equals`, `contains`, `greaterThan`, `in`, `startsWith`, etc.)
  - Nested field support via dot notation (`author.name`)
  - Sorting
  - Pagination
  - Field selection
  - Deep populate with field selection, nested relations, filters, and sort
- **`StrapiRequest<Response>`** — type-safe requests with automatic response unwrapping
  - Single item: `StrapiRequest<ArticleDTO>`
  - List: `StrapiRequest<[ArticleDTO]>`
  - Pagination meta always available via `response.meta`
  - Custom headers per request
- Protocol-based auth (`StrapiAuthProvider`)
- Built-in OSLog-based logger (`DefaultStrapiLogger`) with correlation IDs
- Custom logger support via `StrapiLoggerProtocol`
- Transport abstraction (parallel-safe testing)
- Swift Concurrency compatible
- Fully unit tested
- Clean architecture friendly

---

## 📦 Installation

### Swift Package Manager

Add via Xcode: **File → Add Package Dependency**

Or add to your `Package.swift`:

```swift
.package(url: "https://github.com/ritesh-15/strapi-swift-kit", from: "0.1.0")
```

---

## 🚀 Quick Start

### Create a client

```swift
let client = StrapiClient(
    config: StrapiConfig(
        baseURL: URL(string: "https://your-strapi.com/api")!
    )
)
```

### Define a DTO

```swift
struct ArticleDTO: Codable, Sendable {
    let id: Int
    let title: String
    let description: String?
}
```

### Fetch a list

```swift
let response = try await client.execute(
    StrapiRequest<[ArticleDTO]>(
        endpoint: "/articles",
        query: StrapiQuery()
            .filters { $0.equals("status", "published") }
            .sort("publishedAt", .desc)
            .page(1, size: 10)
    )
)
let articles = response.data
let total = response.meta?.pagination?.total
let currentPage = response.meta?.pagination?.page
```

### Fetch a single item

```swift
let response = try await client.execute(
    StrapiRequest<ArticleDTO>(endpoint: "/articles/10")
)
let article = response.data
```

### Create

```swift
let response = try await client.execute(
    try StrapiRequest<ArticleDTO>(
        endpoint: "/articles",
        method: .POST,
        body: ArticleDTO(id: 0, title: "Hello", description: "World")
    )
)
let created = response.data
```

### Update

```swift
let response = try await client.execute(
    try StrapiRequest<ArticleDTO>(
        endpoint: "/articles/10",
        method: .PUT,
        body: ArticleDTO(id: 10, title: "Updated", description: "New")
    )
)
let updated = response.data
```

### Delete

```swift
let response = try await client.execute(
    StrapiRequest<ArticleDTO>(
        endpoint: "/articles/10",
        method: .DELETE
    )
)
```

---

## 🔐 Authentication

Authentication is handled via the `StrapiAuthProvider` protocol. Conform to it to provide a JWT token that is automatically attached as a `Bearer` token on every request.

### Protocol

```swift
public protocol StrapiAuthProvider: Sendable {
    var token: String? { get }
}
```

### Static token

```swift
struct StaticAuthProvider: StrapiAuthProvider {
    let token: String?
}

let client = StrapiClient(
    config: StrapiConfig(baseURL: URL(string: "https://your-strapi.com/api")!),
    authProvider: StaticAuthProvider(token: "your-jwt-token")
)
```

### Dynamic token (e.g. from Keychain or UserDefaults)

```swift
final class KeychainAuthProvider: StrapiAuthProvider {
    var token: String? {
        // Read from Keychain dynamically
        Keychain.shared.read(key: "strapi_token")
    }
}

let client = StrapiClient(
    config: StrapiConfig(baseURL: URL(string: "https://your-strapi.com/api")!),
    authProvider: KeychainAuthProvider()
)
```

### Per-request custom headers

For cases where you need request-specific headers:

```swift
let response = try await client.execute(
    StrapiRequest<[ArticleDTO]>(
        endpoint: "/articles",
        headers: ["X-Custom-Header": "value"]
    )
)
```

> **Note:** Sensitive headers like `Authorization`, `Cookie`, and any header containing `token` are automatically redacted in logs.

---

## 📋 Logging

StrapiSwiftKit includes a built-in OSLog-based logger that logs requests, responses, and errors with correlation IDs for easy tracing.

### Using the default logger

```swift
let client = StrapiClient(
    config: StrapiConfig(baseURL: URL(string: "https://your-strapi.com/api")!),
    logger: DefaultStrapiLogger()
)
```

### Custom subsystem and category

```swift
let client = StrapiClient(
    config: StrapiConfig(baseURL: URL(string: "https://your-strapi.com/api")!),
    logger: DefaultStrapiLogger(
        subsystem: "com.myapp",
        category: "StrapiAPI"
    )
)
```

### What gets logged

Each request gets a unique correlation ID (UUID) so you can trace a full request/response cycle in Console.app or Xcode logs.

**Request log:**
```
[abc-123] → Request GET https://your-strapi.com/api/articles
[abc-123] Request timeout: 30.0s, cachePolicy: useProtocolCachePolicy
[abc-123] Headers: Accept: application/json, Authorization: REDACTED
[abc-123] Body: none
```

**Response log:**
```
[abc-123] ← Response 200 https://your-strapi.com/api/articles (142 ms, 1024 bytes)
[abc-123] Response JSON: { "data": [...], "meta": {...} }
```

**Error log:**
```
[abc-123] ✕ Network error after 142 ms for https://your-strapi.com/api/articles: [404] NotFoundError: Article not found
```

### Custom logger

Implement `StrapiLoggerProtocol` to integrate with your own logging system (e.g. Firebase Crashlytics, Datadog, or OSLog with custom privacy levels):

```swift
public protocol StrapiLoggerProtocol: Sendable {
    func logRequest(_ request: URLRequest, correlationID: String)
    func logResponse(response: HTTPURLResponse, data: Data, correlationID: String, durationMs: Int)
    func logNetworkError(_ error: Error, correlationID: String, request: URLRequest, since start: Date)
}
```

Example custom logger:

```swift
struct MyLogger: StrapiLoggerProtocol {
    func logRequest(_ request: URLRequest, correlationID: String) {
        print("[\(correlationID)] → \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
    }

    func logResponse(response: HTTPURLResponse, data: Data, correlationID: String, durationMs: Int) {
        print("[\(correlationID)] ← \(response.statusCode) (\(durationMs)ms)")
    }

    func logNetworkError(_ error: Error, correlationID: String, request: URLRequest, since start: Date) {
        print("[\(correlationID)] ✕ \(error.localizedDescription)")
    }
}

let client = StrapiClient(
    config: StrapiConfig(baseURL: URL(string: "https://your-strapi.com/api")!),
    logger: MyLogger()
)
```

### Disabling logging

Simply don't pass a logger — it's optional and defaults to `nil`:

```swift
let client = StrapiClient(
    config: StrapiConfig(baseURL: URL(string: "https://your-strapi.com/api")!)
)
```

---

## ⚠️ Error Handling

```swift
public enum StrapiError: Error, Sendable {
    case invalidURL
    case invalidResponse
    case server(status: Int, name: String, message: String)
    case decoding(String)
    case transport(String)
}
```

```swift
do {
    let response = try await client.execute(
        StrapiRequest<ArticleDTO>(endpoint: "/articles/10")
    )
} catch let error as StrapiError {
    switch error {
    case .server(let status, let name, let message):
        print("Server error \(status) - \(name): \(message)")
    case .decoding(let message):
        print("Decoding failed: \(message)")
    case .transport(let message):
        print("Transport error: \(message)")
    case .invalidURL:
        print("Invalid URL")
    case .invalidResponse:
        print("Invalid response")
    }
}
```

---

## 💡 Why StrapiRequest instead of a Repository?

Previous versions of this package used a `StrapiRepository<DTO>` pattern where the endpoint and DTO were bound at init:

```swift
// Old approach — avoid this
let repository = StrapiRepository<ArticleDTO>(
    client: client,
    endpoint: StrapiEndpoint("/articles")
)
let articles = try await repository.list(query: query)
```

`StrapiRequest` is the recommended approach instead:

| | `StrapiRepository` | `StrapiRequest` |
|---|---|---|
| Endpoint binding | Fixed at init | Per call |
| Custom endpoints | Hard | Easy (`/articles/slug/my-article`) |
| Control | Low | Full |
| Boilerplate | More setup | Less |
| Testability | Requires mock repository | Mock transport only |
| Flexibility | One DTO per repository | Any DTO per call |

---

## 🔍 Filters

Filters use an `inout`-based DSL with `$0` — consistent, discoverable via autocomplete, and requiring no knowledge of internal types.

### Simple filters

```swift
StrapiQuery()
    .filters {
        $0.equals("status", "published")
        $0.greaterThanEqual("views", "100")
    }
```

### `$or` — match any condition

```swift
StrapiQuery()
    .filters {
        $0.or {
            $0.equals("category", "shoes")
            $0.equals("category", "bags")
        }
    }
```

### `$and` — match all conditions

```swift
StrapiQuery()
    .filters {
        $0.and {
            $0.greaterThanEqual("price", "50")
            $0.lesserThanEqual("price", "200")
            $0.equals("inStock", "true")
        }
    }
```

### Nested `$and` / `$or`

```swift
StrapiQuery()
    .filters {
        $0.and {
            $0.or {
                $0.equals("category", "shoes")
                $0.equals("category", "bags")
            }
            $0.or {
                $0.equals("brand", "nike")
                $0.equals("brand", "adidas")
            }
            $0.equals("inStock", "true")
        }
    }
```

### Available operators

| Method | Strapi operator |
|---|---|
| `equals` | `$eq` |
| `notEqual` | `$ne` |
| `contains` | `$contains` |
| `notContains` | `$notcontains` |
| `greater` | `$gt` |
| `greaterThanEqual` | `$gte` |
| `lesser` | `$lt` |
| `lesserThanEqual` | `$lte` |
| `startsWith` | `$startsWith` |
| `endsWith` | `$endsWith` |
| `in` | `$in` |
| `notIn` | `$notIn` |

### Nested field support

Use dot notation to filter on relation fields:

```swift
$0.equals("author.name", "Alice")
$0.equals("category.slug", "tech")
```

---

## 🌿 Populate

### Simple relation

```swift
StrapiQuery()
    .populate("author")
// populate[author]=*
```

### With field selection

```swift
StrapiQuery()
    .populate("author") {
        $0.fields("name", "email")
    }
// populate[author][fields][0]=name
// populate[author][fields][1]=email
```

### With filters and sort

```swift
StrapiQuery()
    .populate("comments") {
        $0.fields("content", "createdAt")
        $0.filters {
            $0.equals("status", "approved")
        }
        $0.sort("createdAt", .desc)
    }
```

### Deep nested populate

```swift
StrapiQuery()
    .populate("expenses") {
        $0.fields("id", "description", "amount")
        $0.populate("splitShares") {
            $0.fields("id")
            $0.populate("ownedBy") {
                $0.fields("id", "username")
            }
        }
        $0.populate("paidBy") {
            $0.fields("id")
        }
    }
```

Generates:
```
populate[expenses][fields][0]=id
populate[expenses][fields][1]=description
populate[expenses][fields][2]=amount
populate[expenses][populate][splitShares][fields][0]=id
populate[expenses][populate][splitShares][populate][ownedBy][fields][0]=id
populate[expenses][populate][splitShares][populate][ownedBy][fields][1]=username
populate[expenses][populate][paidBy][fields][0]=id
```

---

## 🔗 Combining everything

```swift
let client = StrapiClient(
    config: StrapiConfig(baseURL: URL(string: "https://your-strapi.com/api")!),
    authProvider: KeychainAuthProvider(),
    logger: DefaultStrapiLogger(subsystem: "com.myapp", category: "API")
)

let response = try await client.execute(
    StrapiRequest<[ArticleDTO]>(
        endpoint: "/articles",
        query: StrapiQuery()
            .filters {
                $0.and {
                    $0.equals("status", "published")
                    $0.or {
                        $0.equals("category", "swift")
                        $0.equals("category", "ios")
                    }
                }
            }
            .populate("author") {
                $0.fields("name", "avatar")
            }
            .populate("tags") {
                $0.fields("name", "slug")
            }
            .fields("title", "description", "publishedAt")
            .sort("publishedAt", .desc)
            .page(1, size: 20)
    )
)

let articles = response.data
let pagination = response.meta?.pagination
```

---

## 🧪 Testing

The package uses Swift Testing and a mock transport abstraction to ensure:

- Deterministic tests
- No shared global state
- Parallel test execution safety

Run tests with:

```bash
swift test
```

---

## 🛠 Requirements

- iOS 15+
- macOS 12+
- Swift 6.2+
- Strapi v5+

---

# 🤝 Contributing

Contributions are welcome and appreciated! Whether it's a bug fix, a new feature, or an improvement to the docs — feel free to open a PR.

### Ideas for future contributions

- **GraphQL support** — extend the client to support Strapi's GraphQL API alongside REST
- **Retry logic** — configurable retry with exponential backoff for transient failures
- **Caching layer** — protocol-based response caching with TTL support
- **Upload support** — multipart form data for file/media uploads to Strapi's Media Library
- **Webhook support** — helpers for parsing and validating incoming Strapi webhook payloads
- **Swift 6 strict concurrency** — full strict concurrency audit and adoption
- **Combine publishers** — `AnyPublisher`-based alternatives to async/await methods

### How to contribute

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes and add tests
4. Ensure all tests pass: `swift test`
5. Open a pull request with a clear description of what changed and why

### Guidelines

- Follow the existing code style and DSL conventions
- Add tests for any new functionality
- Update the README if your change affects the public API
- Keep PRs focused — one feature or fix per PR

### Reporting issues

Found a bug or have a feature request? Open an issue on GitHub with as much detail as possible — Strapi version, iOS/macOS version, a minimal reproduction, and what you expected vs what happened.

---

## 📄 License

MIT
