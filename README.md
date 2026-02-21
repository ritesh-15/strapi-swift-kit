# StrapiSwiftKit

A modular, type-safe Swift package for interacting with Strapi REST APIs.

StrapiSwiftKit provides a clean Query DSL, a generic Repository layer with full CRUD support, and a transport-abstracted client designed for Swift Concurrency and parallel-safe testing.

---

## ✨ Features

- **Type-safe Query DSL**
  - Filters with `$and` / `$or` nesting
  - All Strapi operators (`equals`, `contains`, `greaterThan`, `in`, `startsWith`, etc.)
  - Nested field support via dot notation (`author.name`)
  - Sorting
  - Pagination
  - Field selection
  - Deep populate with field selection, filters, and sort
- **Generic `StrapiRepository`** with full CRUD support
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

Add via Xcode: **File → Add Package Dependency**

Or add to your `Package.swift`:

```swift
.package(url: "https://github.com/ritesh-15/strapi-swift-kit", from: "0.1.0")
```

---

## 🚀 Quick Start

### Create a client

```swift
let config = StrapiConfig(
    baseURL: URL(string: "https://your-strapi-url.com")!
)
let client = StrapiClient(config: config)
```

### Define a DTO

```swift
struct ArticleDTO: Codable, Sendable, Identifiable {
    let id: Int
    let title: String
    let description: String?
}
```

### Create a repository

```swift
let repository = StrapiRepository<ArticleDTO>(
    client: client,
    endpoint: StrapiEndpoint("/articles")
)
```

### Fetch a list

```swift
let query = StrapiQuery()
    .fields("title", "description")
    .sort("publishedAt", .desc)
    .page(1, size: 10)

let articles = try await repository.list(query: query)
```

### Fetch a single item

```swift
let article = try await repository.get(id: 10, query: nil)
```

### Create

```swift
let newArticle = try await repository.create(
    ArticleDTO(id: 0, title: "Hello", description: "World")
)
```

### Update

```swift
let updated = try await repository.update(
    id: 10,
    ArticleDTO(id: 10, title: "Updated", description: "New")
)
```

### Delete

```swift
let deleted = try await repository.delete(id: 10)
```

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
```

### With field selection

```swift
StrapiQuery()
    .populate("author") {
        $0.fields("name", "email")
    }
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
StrapiQuery()
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

---

## 📄 License

MIT
