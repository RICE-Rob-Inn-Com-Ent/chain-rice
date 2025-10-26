FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o cache-manager ./cmd/manager

# Final stage
FROM alpine:latest

RUN apk add --no-cache ca-certificates curl docker-cli

WORKDIR /app

COPY --from=builder /app/cache-manager .

EXPOSE 9090

CMD ["./cache-manager"]
