import Config

# When a `Service.Repo` (or Yugabyte-backed repo) is added, set `pool: Ecto.Adapters.SQL.Sandbox`
# and `ownership` in `test_helper.exs` so tests never hit a live database.

# Minimal logging so bench / ExUnit timings stay representative.
config :opentelemetry, traces_exporter: :none

config :service, Smith.Guard.Metrics,
  console_reporter: false

config :service, Smith.Guard.Watcher,
  enabled: false

config :service, Smith.Guard.Healer,
  king_repair_base_url: "",
  heal_queue_control_topic: nil,
  heal_event_topic: nil

config :service, Smith.Guard.Metal,
  sample_period_ms: 60_000,
  nvidia_smi: false

config :logger, level: :emergency

config :logger, :console, format: "$message\n"

config :service, Smith.Core.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  server: false,
  check_origin: false

# Fast KDF / hash rounds; PQ signatures resolved via mocks in test helpers (see `mox` / stub verifier).
config :service, Service.Crypto.PQ,
  hash: [
    algorithm: :hybrid_argon2id_mlwe,
    time_cost: 1,
    memory_kib: 2048,
    parallelism: 1,
    salt_bytes: 16,
    output_bytes: 32
  ],
  signature_suite: :ML_DSA_65,
  mock_signatures: true,
  verify_only_public_material: true

# No outbound calls — Finch pools and role URLs neutralized; gRPC targets closed port + disabled flag.
config :service, Service.Connection,
  default_receive_timeout: 1,
  roles: %{},
  disable_external_http: true

config :service, Service.RICE.Web,
  disabled: true,
  grpc: [host: "127.0.0.1", port: 49_999, transport: :tcp],
  connect_base_url: "http://127.0.0.1:1"

# Sandboxed persistence + in-memory community bus (no NATS / no real queue I/O).
config :service, Service.Messaging,
  adapter: Service.Messaging.MemorySandbox,
  topic_prefix: "rice.community.test"

config :service, Smith.Pipeline.Nats,
  connection_settings: [%{host: "127.0.0.1", port: 49_998}],
  backoff_period: 60_000

# Dead Man's Switch: sub-minute threshold for automated tests (Elixir tests; Go still uses days unless env set).
config :service, Service.DeadMansSwitch,
  offline_threshold_days: 0,
  offline_threshold_seconds: 30,
  test_mode: true

config :service, Service.SAGE,
  truth_filter: [
    trace_sampling: 0.0,
    log_training_decisions: false,
    log_feature_attribution: false,
    emit_telemetry: false
  ]

config :service, Service.Guard, pipeline_enabled: false

config :service, Smith.Connection, enabled: false
