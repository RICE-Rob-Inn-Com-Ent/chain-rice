package docker

import "strings"

// db.cue — `.docker/db/` (platform hardcoded; init SQL from params.db.init.sql via CHIEF docker.rice).

_dbInitSQL: strings.Join([for line in params.db.init.sql {"\n" + line}], "")

_dbValkeyConf: strings.Join([
	"# Valkey — maxmemory from CHIEF (params.compose.redis)",
	"bind 0.0.0.0",
	"port 6379",
	"protected-mode no",
	"daemonize no",
	"tcp-keepalive 300",
	"timeout 0",
	"maxmemory \(params.compose.redis.maxmemory)",
	"maxmemory-policy allkeys-lru",
	"appendonly yes",
	"appendfsync everysec",
	"save 3600 1 300 100 60 10000",
	"activerehashing yes",
	"lazyfree-lazy-eviction yes",
	"lazyfree-lazy-expire yes",
	"slowlog-log-slower-than 10000",
	"loglevel notice",
], "\n")

_dbQdrantYAML: """
log_level: INFO
telemetry_disabled: true
storage:
  storage_path: /qdrant/storage
  snapshots_path: /qdrant/snapshots
  hnsw_index:
    m: \(params.compose.qdrant.hnswM)
    ef_construct: \(params.compose.qdrant.efConstruct)
  quantization:
    scalar:
      type: "\(params.compose.qdrant.quantization)"
service:
  http_port: 6333
  grpc_port: 6334
  max_request_size_mb: \(params.compose.qdrant.maxRequestSizeMb)
"""

_dbDockerfileYugabyte: strings.Join([
	"# syntax=docker/dockerfile:1",
	"ARG YUGABYTE_VERSION=2024.2.2.0-b140",
	"FROM yugabytedb/yugabyte:${YUGABYTE_VERSION}",
	"USER root",
	"RUN mkdir -p /opt/app-init",
	"COPY .docker/db/init.sql /opt/app-init/init.sql",
	"USER yugabyte",
	"EXPOSE 5433 9042 7000 9000",
	"HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=10 \\",
	"  CMD [\"yugabyted\", \"status\"]",
	"CMD [\"bin/yugabyted\", \"start\", \"--background=false\", \"--ui\", \"true\"]",
], "\n")

_dbDockerfileValkey: strings.Join([
	"# syntax=docker/dockerfile:1",
	"ARG VALKEY_VERSION=8.0",
	"FROM valkey/valkey:${VALKEY_VERSION}-alpine",
	"COPY .docker/db/valkey.conf /etc/valkey/valkey.conf",
	"EXPOSE 6379",
	"HEALTHCHECK --interval=5s --timeout=3s --retries=5 \\",
	"  CMD [\"valkey-cli\", \"ping\"]",
	"CMD [\"valkey-server\", \"/etc/valkey/valkey.conf\"]",
], "\n")

_dbDockerfileQdrant: strings.Join([
	"# syntax=docker/dockerfile:1",
	"ARG QDRANT_VERSION=v1.12.5",
	"FROM qdrant/qdrant:${QDRANT_VERSION}",
	"COPY .docker/db/qdrant.yaml /qdrant/config/production.yaml",
	"ENV QDRANT__CONFIG_PATH=/qdrant/config/production.yaml",
	"EXPOSE 6333 6334",
	"HEALTHCHECK --interval=5s --timeout=3s --retries=5 \\",
	"  CMD curl -sf http://127.0.0.1:6333/healthz || exit 1",
], "\n")

_dbYugabyteConf: """
	# Yugabyte notes — not mounted in compose.
	"""

_dbQdrantConf: """
	# Qdrant notes — runtime: qdrant.yaml.
	"""
