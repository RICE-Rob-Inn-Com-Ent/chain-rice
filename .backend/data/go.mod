module github.com/chainrice/rice/backend/db

go 1.25.2

require (
	// Database - PostgreSQL high-performance driver
	github.com/jackc/pgx/v5 v5.7.1

	// Database migration & schema
	github.com/golang-migrate/migrate/v4 v4.18.1
	github.com/pressly/goose/v3 v3.22.0

	// ORM/Query Builder (optional, lightweight)
	github.com/uptrace/bun v1.2.3
	github.com/uptrace/bun/dialect/pgdialect v1.2.3

	// Authentication & Authorization
	github.com/golang-jwt/jwt/v5 v5.2.1
	github.com/lestrrat-go/jwx/v2 v2.1.2
	golang.org/x/crypto v0.31.0

	// HTTP Framework - Fiber (fastest Go web framework)
	github.com/gofiber/fiber/v2 v2.52.5

	// HTTP Router alternative - Chi (stdlib-like)
	github.com/go-chi/chi/v5 v5.1.0
	github.com/go-chi/cors v1.2.1
	github.com/go-chi/httprate v0.14.1

	// API Documentation
	github.com/swaggo/swag v1.16.3
	github.com/swaggo/http-swagger v1.3.4

	// Validation
	github.com/go-playground/validator/v10 v10.22.1
	github.com/go-ozzo/ozzo-validation/v4 v4.3.0

	// Cache - Redis
	github.com/redis/go-redis/v9 v9.7.0
	github.com/dgraph-io/ristretto v0.1.1

	// Session Management
	github.com/gorilla/sessions v1.4.0
	github.com/alexedwards/scs/v2 v2.8.0

	// Rate Limiting & Throttling
	golang.org/x/time v0.8.0
	github.com/ulule/limiter/v3 v3.11.2

	// Logging - Structured
	go.uber.org/zap v1.27.0
	github.com/rs/zerolog v1.33.0

	// Metrics & Monitoring
	github.com/prometheus/client_golang v1.20.5
	go.opentelemetry.io/otel v1.32.0
	go.opentelemetry.io/otel/trace v1.32.0
	go.opentelemetry.io/otel/metric v1.32.0

	// Configuration
	github.com/spf13/viper v1.19.0
	github.com/joho/godotenv v1.5.1
	github.com/kelseyhightower/envconfig v1.4.0

	// Email/Notifications
	github.com/sendgrid/sendgrid-go v3.16.0+incompatible
	github.com/mailgun/mailgun-go/v4 v4.18.3

	// Task Queue - Background Jobs
	github.com/hibiken/asynq v0.24.1

	// WebSocket
	github.com/gorilla/websocket v1.5.3
	github.com/olahol/melody v1.2.1

	// gRPC
	google.golang.org/grpc v1.68.0
	google.golang.org/protobuf v1.35.1
	github.com/grpc-ecosystem/grpc-gateway/v2 v2.23.0

	// Utilities
	github.com/google/uuid v1.6.0
	github.com/oklog/ulid/v2 v2.1.0
	github.com/segmentio/ksuid v1.0.4

	// JSON
	github.com/goccy/go-json v0.10.3
	github.com/bytedance/sonic v1.12.4

	// HTTP Client
	github.com/go-resty/resty/v2 v2.15.3

	// Testing
	github.com/stretchr/testify v1.9.0
	github.com/DATA-DOG/go-sqlmock v1.5.2
	github.com/ory/dockertest/v3 v3.11.0

	// Error Handling
	github.com/pkg/errors v0.9.1
	github.com/rotisserie/eris v0.5.4

	// Context & Graceful Shutdown
	github.com/oklog/run v1.1.0

	// Concurrency
	golang.org/x/sync v0.9.0
	github.com/sourcegraph/conc v0.3.0
)
