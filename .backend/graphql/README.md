# GraphQL Federation with Apollo Router

## Overview

GraphQL Federation allows you to compose multiple GraphQL services into a single unified graph. This implementation uses
Apollo Router for high-performance GraphQL gateway.

## Architecture

```
┌──────────────────────────────────────────────────┐
│              Apollo Router (Gateway)              │
│         Supergraph Schema + Query Planning        │
└──────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   Users       │ │   Products   │ │   Orders     │
│  Subgraph    │ │  Subgraph    │ │  Subgraph    │
└──────────────┘ └──────────────┘ └──────────────┘
```

## Features

- ✅ **Federation v2** - Latest Apollo Federation
- ✅ **Distributed Schema** - Multiple subgraphs
- ✅ **Entity References** - Cross-subgraph queries
- ✅ **Type Extensions** - Extend types across services
- ✅ **Subscriptions** - Real-time updates
- ✅ **Performance** - Rust-based Apollo Router

## Structure

```
graphql/
├── router/              # Apollo Router config
│   ├── router.yaml     # Router configuration
│   └── supergraph.yaml # Supergraph schema
├── subgraphs/          # GraphQL subgraphs
│   ├── users/          # Users service
│   ├── products/       # Products service
│   └── orders/         # Orders service
└── schema/             # Shared GraphQL schemas
```

## Subgraphs

### Users Subgraph

```graphql
type User @key(fields: "id") {
  id: ID!
  email: String!
  name: String!
}
```

### Products Subgraph

```graphql
type Product @key(fields: "id") {
  id: ID!
  name: String!
  price: Float!
}
```

### Orders Subgraph

```graphql
type Order @key(fields: "id") {
  id: ID!
  user: User!
  items: [OrderItem!]!
  total: Float!
}

type User @key(fields: "id", resolvable: false) {
  id: ID!
}
```

## Quick Start

### 1. Install Apollo Router

```bash
curl -sSL https://router.apollo.dev/download/nix/latest | sh
```

### 2. Start Subgraphs

```bash
# Users subgraph
cd subgraphs/users && go run main.go

# Products subgraph
cd subgraphs/products && go run main.go

# Orders subgraph
cd subgraphs/orders && go run main.go
```

### 3. Compose Supergraph

```bash
rover supergraph compose --config ./router/supergraph.yaml > supergraph-schema.graphql
```

### 4. Start Apollo Router

```bash
./router --config router/router.yaml --supergraph supergraph-schema.graphql
```

## Example Query

```graphql
query GetUserWithOrders {
  user(id: "123") {
    id
    email
    name
    orders {
      id
      total
      items {
        product {
          name
          price
        }
        quantity
      }
    }
  }
}
```

## Technologies

- **Apollo Router** - High-performance GraphQL gateway (Rust)
- **gqlgen** - GraphQL server for Go
- **Apollo Federation** - Schema composition
- **Redis** - Query caching

## References

- [Apollo Federation](https://www.apollographql.com/docs/federation/)
- [Apollo Router](https://www.apollographql.com/docs/router/)
