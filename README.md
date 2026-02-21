# StrapiSwiftKit

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
- Transport abstraction (parallel-safe testing)
- Correlation ID and request/response logging
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
        baseURL: URL(string: "https://your-strapi.com/api")!,
        token: "your-jwt-token"
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
    StrapiRequest<ArticleDTO>(
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
    StrapiRequest<ArticleDTO>(
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

### Custom headers

```swift
let response = try await client.execute(
    StrapiRequest<[ArticleDTO]>(
        endpoint: "/articles",
        headers: ["X-Custom-Header": "value"]
    )
)
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

### Multiple relations

```swift
StrapiQuery()
    .populate("author") {
        $0.fields("name", "bio")
    }
    .populate("tags") {
        $0.fields("name", "slug")
    }
    .populate("category") {
        $0.fields("name")
    }
```

---

## 🔗 Combining everything

```swift
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
- Swift 5.9+
- Strapi v5+

---

## 📄 License

MIT
