# StrapiSwiftKit

A modular, type-safe Swift package for interacting with Strapi REST APIs.

StrapiSwiftKit provides a clean Query DSL, a generic Repository layer with full CRUD support, and a transport-abstracted client designed for Swift Concurrency and parallel-safe testing.

---

## ✨ Features

- Type-safe Query DSL
  - Filters (`contains`, `equals`)
  - Nested field support
  - Sorting
  - Pagination
  - Populate
  - Field selection
- Generic `StrapiRepository` with full CRUD support
  - `list`
  - `get`
  - `create`
  - `update`
  - `delete`
- Transport abstraction (parallel-safe testing)
- Swift Concurrency compatible
- Fully unit tested
- Clean architecture friendly

---

## 📦 Installation

### Swift Package Manager

Add via Xcode:

**File → Add Package Dependency**

Or add to your `Package.swift`:

```swift
.package(url: "https://github.com/ritesh-15/strapi-swift-kit", from: "0.1.0")
```

---

## 🚀 Quick Start

### Create a client

```
let config = StrapiConfig(
    baseURL: URL(string: "https://your-strapi-url.com")!
)

let client = StrapiClient(config: config)
```

### Define DTO

```
struct ArticleDTO: Codable, Sendable, Identifiable {
    let id: Int
    let title: String
    let description: String?
}
```

### Create a repository

```
let repository = StrapiRepository<ArticleDTO>(
    client: client,
    endpoint: StrapiEndpoint("/articles")
)
```

### Fetch List

```
let query = StrapiQuery()
    .fields("title", "description")
    .sort("publishedAt", .desc)
    .page(1, size: 10)

let articles = try await repository.list(query: query)
```

### Fetch Single Item

```
let article = try await repository.get(id: 10, query:nil)
```

### Create

```
let newArticle = try await repository.create(
    ArticleDTO(id: 0, title: "Hello", description: "World")
)
```

### Update

```
let updated = try await repository.update(
    id: 10,
    ArticleDTO(id: 10, title: "Updated", description: "New")
)
```

### Delete

```
let deleted = try await repository.delete(id: 10)
```

## 🧪 Testing

The package uses Swift Testing and a mock transport abstraction to ensure:

- Deterministic tests
- No shared global state=
- Parallel test execution safety

Run test with:
``` 
swift test
```

## 🛠 Requirements

iOS 15+

macOS 12+

Swift 5.9+

## License

MIT