# Database Service

High-performance Go backend service designed for **1M+ requests/hour**.

## 🚀 Tech Stack

### Database

- **PostgreSQL** with `pgx/v5` (fastest Go driver)
- **Connection pooling** optimized for high throughput
- **Migrations** with golang-migrate & goose
- **ORM** with Bun (optional, zero-allocation queries)

### HTTP Framework

- **Fiber v3** - Fastest Go web framework (built on fasthttp)
  - Up to 6M req/s on modern hardware
  - Zero-allocation routing
  - Built-in middleware
- **Chi v5** - Stdlib-compatible alternative
  - Lightweight, idiomatic Go
  - Excellent performance

### Authentication

- **JWT** with `golang-jwt/v5` and `lestrrat-go/jwx`
- **Session management** with SCS (PostgreSQL backed)
- **OAuth2/OIDC** ready
- **Rate limiting** per user/IP

### Performance Features

- **Redis caching** with go-redis
- **In-memory cache** with Ristretto (dgraph)
- **Connection pooling** (PostgreSQL + Redis)
- **Rate limiting** with multiple strategies
- **Prometheus metrics**
- **OpenTelemetry** tracing

### High-Traffic Optimizations

- **Zero-copy JSON** with sonic (bytedance)
- **Fast routing** with radix tree
- **Efficient middleware** chaining
- **Graceful shutdown** with signal handling
- **Horizontal scaling** ready

## 📊 Performance Targets

| Metric             | Target           | Notes                   |
| ------------------ | ---------------- | ----------------------- |
| **Throughput**     | 1M+ req/h        | 278 req/s sustained     |
| **Response Time**  | p95 < 50ms       | Database queries        |
| **Response Time**  | p99 < 100ms      | Complex operations      |
| **Concurrency**    | 10k+ connections | With connection pooling |
| **Database Pool**  | 100-200 conns    | Per instance            |
| **Cache Hit Rate** | > 80%            | Redis + in-memory       |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│  Load Balancer (Nginx/Traefik)                     │
└─────────────────┬───────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
    ┌───▼───┐         ┌─────▼──┐
    │ API 1 │   ...   │ API N  │  (Horizontal scaling)
    └───┬───┘         └─────┬──┘
        │                   │
        └─────────┬─────────┘
                  │
        ┌─────────▼─────────┐
        │                   │
    ┌───▼──────┐    ┌───────▼────┐
    │ Redis    │    │ PostgreSQL │
    │ (Cache)  │    │ (Primary)  │
    └──────────┘    └────────────┘
```

## 🔧 Quick Start

```bash
# Install dependencies
go mod download

# Run migrations
goose -dir migrations postgres "postgres://localhost/rice" up

# Start server
go run cmd/server/main.go

# Development with hot reload
air
```

## 🌐 API Endpoints

### Authentication

- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - Login (returns JWT)
- `POST /api/v1/auth/refresh` - Refresh token
- `POST /api/v1/auth/logout` - Logout
- `GET /api/v1/auth/me` - Current user profile

### Health & Monitoring

- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics
- `GET /api/docs` - Swagger documentation

## 📦 Project Structure

```
db/
├── cmd/
│   └── server/
│       └── main.go           # Entry point
├── internal/
│   ├── api/
│   │   ├── handlers/         # HTTP handlers
│   │   ├── middleware/       # Auth, CORS, logging
│   │   └── routes/           # Route definitions
│   ├── auth/
│   │   ├── jwt.go           # JWT generation/validation
│   │   └── session.go       # Session management
│   ├── database/
│   │   ├── postgres.go      # DB connection & pool
│   │   ├── queries/         # SQL queries
│   │   └── models/          # Data models
│   ├── cache/
│   │   ├── redis.go         # Redis client
│   │   └── memory.go        # In-memory cache
│   └── config/
│       └── config.go        # Configuration
├── migrations/              # Database migrations
├── pkg/
│   ├── errors/             # Error handling
│   └── response/           # Standard API responses
├── go.mod
└── README.md
```

## 🔐 Security Features

- **JWT** with RS256/ES256 signing
- **Password hashing** with bcrypt/argon2
- **Rate limiting** (per IP, per user, per endpoint)
- **CORS** protection
- **Helmet** security headers
- **SQL injection** prevention (parameterized queries)
- **XSS** protection
- **CSRF** tokens

## 📈 Scaling Strategy

### Vertical Scaling (single instance)

- Optimize connection pool (100-200 connections)
- Enable Redis caching
- Use in-memory cache (Ristretto)
- Profile with pprof

### Horizontal Scaling (multiple instances)

- Stateless API design
- JWT tokens (no server-side session)
- Redis for shared cache
- PostgreSQL read replicas
- Load balancer with sticky sessions (optional)

### Database Optimization

- Indexes on frequently queried columns
- Prepared statements
- Connection pooling
- Query result caching
- Read replicas for read-heavy operations

## 🧪 Testing

```bash
# Unit tests
go test ./...

# Integration tests (with dockertest)
go test -tags=integration ./...

# Load testing
hey -z 10s -c 100 http://localhost:8080/api/v1/health

# Benchmark
go test -bench=. -benchmem ./...
```

## 🔍 Monitoring

- **Prometheus** metrics at `/metrics`
- **OpenTelemetry** traces
- **Structured logging** with Zap/Zerolog
- **Health checks** at `/health`

## 📝 Environment Variables

```bash
# Database
DATABASE_URL=postgres://user:pass@localhost:5432/rice
DATABASE_MAX_CONNS=200
DATABASE_MIN_CONNS=10

# Redis
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=
REDIS_DB=0

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRY=24h

# Server
PORT=8080
ENV=production
LOG_LEVEL=info

# Rate Limiting
RATE_LIMIT_REQUESTS=1000
RATE_LIMIT_WINDOW=1h
```

## 🚀 Production Deployment

### Docker

```bash
docker build -t rice/db:latest .
docker run -p 8080:8080 rice/db:latest
```

### Kubernetes

```bash
kubectl apply -f k8s/
```

## 📚 Resources

- [Fiber Documentation](https://docs.gofiber.io/)
- [pgx Documentation](https://pkg.go.dev/github.com/jackc/pgx/v5)
- [JWT Best Practices](https://datatracker.ietf.org/doc/html/rfc8725)
