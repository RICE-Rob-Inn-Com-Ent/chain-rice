package docker

import "strings"

// main.cue — docker-compose.yml + .dockerignore (platform hardcoded; business from params).

_dockerignoreEntries: [
	".git",
	".github",
	".pixi",
	".buck-cache",
	"buck-out",
	"__pycache__",
	".dart_tool",
	"_build",
	"deps",
	".model-cache",
	"*.md",
	"!README.md",
	".cursor",
	".vscode",
	"custom",
	"frontend",
	if !stack.otp.enabled {"service"},
	if !stack.otp.enabled {"function"},
	"infra",
	"base",
	"**/*.log",
	"**/.env",
	"**/.env.*",
	"!secrets.enc.env",
]

_composeYAML: """
# docker-compose.yml — generated from infra/docker/_tool.cue (cue cmd genDocker)
# Run: docker compose -f .docker/docker-compose.yml up -d

name: \(params.compose.projectName)

x-logging: &stack-logging
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"

x-defaults: &stack-defaults
  restart: unless-stopped
  init: true
  security_opt:
    - no-new-privileges:true
  logging: *stack-logging

networks:
  edge:
    driver: bridge
  data:
    driver: bridge
    internal: true
  inference:
    driver: bridge
    internal: true
  mail:
    driver: bridge
    internal: true

volumes:
  yugabyte-data:
  redis-data:
  nats-data:
  temporal-data:
  qdrant-data:
\( _optionalVolumeLines )
  mailpit-data:

services:
  yugabyte:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/db/Dockerfile.yugabyte
    container_name: yugabyte
    ports:
      - "5433:5433"
      - "9042:9042"
      - "7000:7000"
      - "9000:9000"
    volumes:
      - yugabyte-data:/home/yugabyte/yb_data
    environment:
      POSTGRES_DB: \(params.compose.db.name)
      POSTGRES_USER: \(params.compose.db.user)
      POSTGRES_PASSWORD: "${YUGABYTE_PASSWORD:?set YUGABYTE_PASSWORD}"
    networks: [data, edge]
    deploy:
      resources:
        limits:
          memory: \(params.compose.yugabyte.memoryLimit)
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    healthcheck:
      test: ["CMD", "yugabyted", "status"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 45s

  redis:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/db/Dockerfile.valkey
    container_name: redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
      - ./db/valkey.conf:/etc/valkey/valkey.conf:ro
    networks: [data, edge]
    deploy:
      resources:
        limits:
          memory: \(params.compose.redis.memoryLimit)
    healthcheck:
      test: ["CMD", "valkey-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  qdrant:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/db/Dockerfile.qdrant
    container_name: qdrant
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant-data:/qdrant/storage
    networks: [data, inference, edge]
    deploy:
      resources:
        limits:
          memory: \(params.compose.qdrant.memoryLimit)
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://127.0.0.1:6333/healthz || exit 1"]
      interval: 5s
      timeout: 3s
      retries: 5

  nats:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/messaging/Dockerfile.nats
    container_name: nats
    ports:
      - "4222:4222"
      - "8222:8222"
      - "6222:6222"
    volumes:
      - nats-data:/data
      - ./messaging/nats.conf:/etc/nats/nats.conf:ro
    command: ["--config", "/etc/nats/nats.conf"]
    networks: [data, edge]
    deploy:
      resources:
        limits:
          memory: \(params.compose.nats.memoryLimit)
    healthcheck:
      test: ["CMD", "wget", "-q", "-O-", "http://127.0.0.1:8222/healthz"]
      interval: 5s
      timeout: 3s
      retries: 5

  temporal:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/messaging/Dockerfile.temporal
    container_name: temporal
    ports:
      - "7233:7233"
      - "8088:8088"
    volumes:
      - temporal-data:/etc/temporal
      - ./messaging/temporal-dynamic.yaml:/etc/temporal/config/development.yaml:ro
    environment:
      DB: postgresql
      DB_PORT: "5433"
      POSTGRES_USER: \(params.compose.db.user)
      POSTGRES_PWD: "${YUGABYTE_PASSWORD:?set YUGABYTE_PASSWORD}"
      POSTGRES_SEEDS: yugabyte
      DYNAMIC_CONFIG_FILE_PATH: /etc/temporal/config/development.yaml
      BIND_ON_IP: 0.0.0.0
    networks: [data, edge]
    depends_on:
      yugabyte:
        condition: service_healthy
    deploy:
      resources:
        limits:
          memory: \(params.compose.temporal.memoryLimit)
    healthcheck:
      test: ["CMD", "temporal", "operator", "cluster", "health"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s

  mailpit:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/mail/Dockerfile.mailpit
    container_name: mailpit
    ports:
      - "1025:1025"
      - "8025:8025"
    environment:
      MP_MAX_MESSAGES: \(params.compose.mailpit.maxMessages)
      MP_DATABASE: \(params.compose.mailpit.database)
    volumes:
      - mailpit-data:/data
    networks: [mail, edge]
    profiles: [\(params.compose.mailpit.profile)]
    healthcheck:
      test: ["CMD", "wget", "-q", "-O-", "http://127.0.0.1:8025/livez"]
      interval: 5s
      timeout: 3s
      retries: 3
\(_optionalServices)
"""

_dockerignore: strings.Join([for e in _dockerignoreEntries {e}], "\n")
