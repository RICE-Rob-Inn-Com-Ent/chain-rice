# Multi-stage build for backend services (db and token)
FROM golang:1.25-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make gcc musl-dev linux-headers curl

WORKDIR /build

# Copy go mod files
COPY .devcontainer/backend/go.mod .devcontainer/backend/go.sum ./
RUN go mod download

# Copy source code
COPY .devcontainer/backend/ ./

# Build binaries based on BUILD_TARGET environment variable
# Default to tokenchaind if not specified
ARG BUILD_TARGET=tokenchaind
RUN if [ "$BUILD_TARGET" = "tokenchaind" ]; then \
  CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -tags musl -o tokenchaind ./cmd/tokenchaind; \
  elif [ "$BUILD_TARGET" = "server" ]; then \
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server ./cmd/main_api_server.go; \
  elif [ "$BUILD_TARGET" = "graphql" ]; then \
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o graphql ./cmd/graphql; \
  elif [ "$BUILD_TARGET" = "traefik-proxy" ]; then \
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o traefik-proxy ./cmd/traefik-proxy; \
  elif [ "$BUILD_TARGET" = "monitoring-gateway" ]; then \
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o monitoring-gateway ./cmd/monitoring-gateway; \
  elif [ "$BUILD_TARGET" = "database-gateway" ]; then \
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o database-gateway ./cmd/database-gateway; \
  elif [ "$BUILD_TARGET" = "admin-gateway" ]; then \
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o admin-gateway ./cmd/admin-gateway; \
  elif [ "$BUILD_TARGET" = "elasticsearch-proxy" ]; then \
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o elasticsearch-proxy ./cmd/elasticsearch-proxy; \
  fi

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates curl

WORKDIR /app

# Copy binary from builder based on BUILD_TARGET
ARG BUILD_TARGET=tokenchaind
COPY --from=builder /build/${BUILD_TARGET} /usr/local/bin/${BUILD_TARGET}
RUN chmod +x /usr/local/bin/${BUILD_TARGET}

# Set executable name based on BUILD_TARGET for CMD
ENV BINARY_NAME=${BUILD_TARGET}

# Create directories for blockchain data (if tokenchaind)
RUN if [ "$BUILD_TARGET" = "tokenchaind" ]; then \
  mkdir -p /app/.tokenchaind/config /app/.tokenchaind/data; \
  fi

# Expose ports
# For tokenchaind: 26656 - P2P, 26657 - RPC, 1317 - REST API, 9090 - gRPC
# For db services: 8080 - HTTP API
# For graphql: 4000 - GraphQL endpoint
# NOTE: AI Bot API is provided by bot/ service (FastAPI) - see bot/Dockerfile
# NOTE: Contract bridges functionality is provided by contract/ service
# For traefik-proxy: 8080 - HTTP API
# For monitoring-gateway: 8083 - HTTP API
# For database-gateway: 8084 - HTTP API
# For admin-gateway: 8085 - HTTP API
# For elasticsearch-proxy: 8087 - HTTP API
EXPOSE 26656 26657 1317 9090 8080 4000 8201 8083 8084 8085 8087

# Default command - will be overridden by docker-compose
ARG BUILD_TARGET=tokenchaind
CMD if [ "$BUILD_TARGET" = "tokenchaind" ]; then \
  exec tokenchaind start; \
  elif [ "$BUILD_TARGET" = "server" ]; then \
  exec server; \
  elif [ "$BUILD_TARGET" = "graphql" ]; then \
  exec graphql; \
  elif [ "$BUILD_TARGET" = "traefik-proxy" ]; then \
  exec traefik-proxy; \
  elif [ "$BUILD_TARGET" = "monitoring-gateway" ]; then \
  exec monitoring-gateway; \
  elif [ "$BUILD_TARGET" = "database-gateway" ]; then \
  exec database-gateway; \
  elif [ "$BUILD_TARGET" = "admin-gateway" ]; then \
  exec admin-gateway; \
  elif [ "$BUILD_TARGET" = "elasticsearch-proxy" ]; then \
  exec elasticsearch-proxy; \
  else \
  echo "Unknown BUILD_TARGET: $BUILD_TARGET"; \
  exit 1; \
  fi

