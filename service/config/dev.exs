import Config

# Maximum visibility: verbose logs, stack traces, dev instrumentation.
config :logger, level: :debug

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [
    :request_id,
    :community_id,
    :telepathy_route,
    :role,
    :otel_trace_id,
    :mfa,
    :file,
    :line
  ]

config :phoenix, :stacktrace_depth, 50

# Hot code reloading for Phoenix (endpoint + LiveView); Channels reload with the code reloader.
# `code_reloader: true` reloads Channel/Socket modules on the next join/message after recompile.
config :service, Smith.Core.Endpoint,
  code_reloader: true,
  check_origin: false

config :service, Smith.Core, dashboard_dev_open: true

# Local messaging: in-memory / loopback adapter simulating inter-community traffic (no real NATS required).
config :service, Service.Messaging,
  adapter: Service.Messaging.LocalCommunityBus,
  simulate_latency_ms: {0, 5},
  topic_prefix: "rice.community.dev"

config :service, Smith.Pipeline.Nats,
  connection_settings: [%{host: "127.0.0.1", port: 4222}],
  backoff_period: 500

# RICE-Web (Go) on localhost — gRPC + HTTP Connect as wired in service/web.
config :service, Service.RICE.Web,
  grpc: [host: "127.0.0.1", port: 50051, transport: :tcp],
  connect_base_url: System.get_env("RICE_CONNECT_BASE_URL", "http://127.0.0.1:8080")

# SAGE — “truth filter” / training visibility (telemetry + optional verbose hook payloads).
config :service, Service.SAGE,
  truth_filter: [
    trace_sampling: 1.0,
    log_training_decisions: true,
    log_feature_attribution: true,
    emit_telemetry: true
  ]

config :service, Service.Guard, pipeline_enabled: true

config :service, Smith.Guard.Metrics,
  console_reporter: true
