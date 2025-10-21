# CQRS + Event Sourcing Implementation

## Overview

This module implements **Command Query Responsibility Segregation (CQRS)** and **Event Sourcing** patterns for scalable,
event-driven architecture.

## Architecture

```
┌─────────────┐         ┌──────────────┐
│   Command   │────────>│ Command Bus  │
│   Handler   │         └──────────────┘
└─────────────┘                │
                               ▼
                        ┌──────────────┐
                        │  Event Store │
                        └──────────────┘
                               │
                               ▼
                        ┌──────────────┐
                        │  Event Bus   │
                        └──────────────┘
                               │
                  ┌────────────┴────────────┐
                  ▼                         ▼
          ┌───────────────┐         ┌──────────────┐
          │ Query Handler │         │  Projections │
          └───────────────┘         └──────────────┘
                  │                         │
                  ▼                         ▼
          ┌───────────────┐         ┌──────────────┐
          │   Read Store  │         │  Read Models │
          └───────────────┘         └──────────────┘
```

## Features

- ✅ **Event Sourcing** - Store all changes as events
- ✅ **CQRS** - Separate read and write models
- ✅ **Event Store** - PostgreSQL-based event store
- ✅ **Projections** - Automatic read model updates
- ✅ **Snapshots** - Performance optimization
- ✅ **Event Versioning** - Schema evolution support

## Structure

```
cqrs/
├── cmd/
│   └── server/          # CQRS server entry point
├── commands/            # Command handlers
├── events/              # Event definitions
├── queries/             # Query handlers
├── projections/         # Event projections
├── store/              # Event store implementation
└── examples/           # Usage examples
```

## Technologies

- **Language**: Go 1.25+
- **Event Store**: PostgreSQL with JSONB
- **Message Bus**: Kafka / NATS
- **Cache**: Redis

## Quick Start

```bash
# Run CQRS server
cd .backend/cqrs
go run cmd/server/main.go

# Run with Docker
docker-compose up cqrs-server
```

## Example Usage

### Command Side (Write)

```go
cmd := commands.CreateUserCommand{
    UserID: "user-123",
    Email: "user@example.com",
}
err := commandBus.Execute(ctx, cmd)
```

### Query Side (Read)

```go
query := queries.GetUserByIDQuery{
    UserID: "user-123",
}
user, err := queryBus.Execute(ctx, query)
```

## Event Store Schema

```sql
CREATE TABLE events (
    id BIGSERIAL PRIMARY KEY,
    aggregate_id UUID NOT NULL,
    aggregate_type VARCHAR(255) NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    event_data JSONB NOT NULL,
    metadata JSONB,
    version INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(aggregate_id, version)
);
```

## References

- [CQRS Pattern](https://martinfowler.com/bliki/CQRS.html)
- [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html)
