import Config

# --- Phoenix (global defaults for the .rice Elixir umbrella) ---
config :phoenix, :json_library, Jason

config :phoenix, :filter_parameters, ~w(password pass token secret api_key pqc_private pem)

# --- Centralized logging (SMITH / Guard / Connection emit through here) ---
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :community_id, :telepathy_route, :role, :otel_trace_id]

config :logger, level: :info

# --- RICE-Web gRPC / Connect bridge (Elixir ↔ Go transport; ports overridable per env) ---
config :service, Service.RICE.Web,
  grpc: [
    host: "127.0.0.1",
    port: 50051,
    # Optional h2c / TLS: `:tls` uses `certfile` / `keyfile` from env at runtime (see prod.exs).
    transport: :tcp
  ],
  connect_base_url: "http://127.0.0.1:8080",
  metadata_prefixes: [
    "rice.telepathy.origin",
    "rice.telepathy.dest",
    "rice.telepathy.entanglement_id"
  ]

# --- Telepathy routing plane (labels align with RICE-Web telepathy metadata keys) ---
config :service, Service.Telepathy,
  enabled: true,
  default_ttl_ms: 60_000,
  collapse_probe_interval_ms: 5_000,
  max_entanglements_per_node: 65_536,
  route_metadata_keys: %{
    origin: "rice.telepathy.origin",
    dest: "rice.telepathy.dest",
    entanglement: "rice.telepathy.entanglement_id"
  }

# --- Dead Man's Switch (author heartbeat); mirrors Go `RICE_DMS_OFFLINE_DAYS` default of 7 ---
config :service, Service.DeadMansSwitch,
  offline_threshold_days: 7,
  env_offline_days: "RICE_DMS_OFFLINE_DAYS",
  ping_path_env: "RICE_DMS_PING_PATH"

# --- Quantum-resistant hashing / KDF parameters (production rounds tightened in prod.exs) ---
config :service, Service.Crypto.PQ,
  hash: [
    algorithm: :hybrid_argon2id_mlwe,
    time_cost: 3,
    memory_kib: 194_560,
    parallelism: 4,
    salt_bytes: 32,
    output_bytes: 64
  ],
  signature_suite: :ML_DSA_65,
  verify_only_public_material: false

# SMITH core — Phoenix endpoint + PubSub (see service/core/*.ex)
config :service, Smith.Core.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  pubsub_server: Smith.Core.PubSub,
  live_view: [signing_salt: "service_lv_signing_salt"],
  secret_key_base:
    "dev_only_replace_in_prod_01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901"

config :service, Smith.Core.PubSub, name: Smith.Core.PubSub

config :service, Smith.Core,
  dashboard_dev_open: false

config :service, Smith.Core.Channel, codec: Smith.Messages.Json

# SMITH pipeline — Broadway + GNAT + Membrane (see service/pipeline/*.ex)
config :service, Smith.Pipeline.Nats,
  name: :smith_pipeline_nats,
  connection_settings: [%{host: "127.0.0.1", port: 4222}],
  backoff_period: 2_000,
  request_defaults: [receive_timeout: 15_000]

config :service, Smith.Pipeline,
  producer: [
    subscription_topic: "service.>",
    connection_name: :smith_pipeline_nats
  ],
  consumer: [
    output_subject: "service.pipeline.out",
    dead_letter_subject: "service.pipeline.dlq"
  ],
  batchers: [
    default: [
      batch_size: 10,
      batch_timeout: 500,
      concurrency: 2
    ]
  ]

config :service, Smith.Pipeline.Application, start_broadway: false

# SMITH connection — libcluster + Horde (see service/connection/lib/*.ex)
config :service, Smith.Connection,
  enabled: false,
  discovery: :epmd,
  sync_horde_members_on_boot: true,
  topologies: [
    service: [
      strategy: Cluster.Strategy.Epmd,
      config: [
        hosts: []
      ]
    ]
  ],
  horde: [
    registry_name: Smith.Connection.HordeRegistry,
    dynamic_supervisor_name: Smith.Connection.HordeDynamicSupervisor,
    distribution_strategy: Smith.Connection.Strategy.LeastRunQueue
  ],
  handoff: [
    on_node_up_mfa: nil,
    on_node_down_mfa: nil
  ]

# SMITH guard — supervision shell, healing, OTel hooks, alerts (see service/guard/*.ex)
config :service, Service.Guard,
  pipeline_enabled: false,
  watcher_poll_ms: 5_000,
  healer_initial_backoff_ms: 500,
  healer_max_backoff_ms: 60_000,
  healer_max_failures: 5,
  deadman_check_ms: 15_000,
  deadman_grace_s: 60,
  alert_topic: "service.guard.alerts",
  bard_incident_topic: "rice.bard.guard.incidents",
  odin_ports: []

# Watcher: telemetry thresholds → Alert + Healer (see Smith.Guard.Watcher).
config :service, Smith.Guard.Watcher,
  enabled: true,
  error_window_ms: 60_000,
  error_threshold: 5,
  latency_threshold_ms: 10_000,
  breach_cooldown_ms: 30_000,
  healer_component: {:smith, :guard_pipeline}

# Alert: NATS JSON incidents for BARD + rate limits (see Smith.Guard.Alert).
config :service, Smith.Guard.Alert,
  rate_limit_window_ms: 60_000,
  rate_limit_max_per_window: 30

# Metal: CPU/mem/GPU samples for .rice / SAGE (see Smith.Guard.Metal).
config :service, Smith.Guard.Metal,
  sample_period_ms: 3_000,
  nvidia_smi: true,
  nvidia_smi_timeout_ms: 2_000,
  rice_hardware_json_path: nil

# Healer: pipeline restart, NATS queue hint, KING auto-repair HTTP (see Smith.Guard.Healer).
config :service, Smith.Guard.Healer,
  king_repair_base_url: System.get_env("RICE_KING_REPAIR_URL", "http://127.0.0.1:9100"),
  king_repair_path: "/mesh/auto-repair",
  king_repair_timeout_ms: 8_000,
  finch: Service.Finch,
  heal_queue_control_topic: "smith.pipeline.control",
  heal_event_topic: "events.smith.heal"

# SMITH connection — Finch + Jason + proto (see service/connection/*.ex)
config :service, Service.Connection,
  finch: Service.Finch,
  default_receive_timeout: 15_000,
  roles: %{
    smith: [base_url: "http://127.0.0.1:9100"],
    sage: [base_url: "http://127.0.0.1:9101"],
    bard: [base_url: "http://127.0.0.1:9102"],
    clerk: [base_url: "http://127.0.0.1:9103"]
  }

config :service, Service.Connection.Proto, registry: %{}

# :messages app (Smith.Messages.*) — Finch pool for KING / mesh HTTP
config :messages, Smith.Messages.Http,
  finch: Smith.Messages.Finch,
  default_receive_timeout: 15_000,
  pool_timeout: 5_000

config :messages, Smith.Messages.Proto, registry: %{}

config :messages, :finch_pools, %{
  default: [
    protocols: [:http1, :http2],
    size: 25,
    count: 1
  ]
}

# OpenTelemetry — used by Smith.Guard.Tracer + Smith.Guard.Telemetry (OTLP via opentelemetry_exporter)
config :opentelemetry,
  span_processor: :batch,
  traces_exporter: :otlp

config :opentelemetry_exporter,
  otlp_protocol: :http_protobuf,
  otlp_endpoint: System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT", "http://127.0.0.1:4318")

config :service, Smith.Guard.Telemetry,
  vm_sample_period_ms: 5_000

# Telemetry.Metrics definitions + optional ConsoleReporter (enable in dev.exs).
config :service, Smith.Guard.Metrics,
  console_reporter: false

import_config "#{config_env()}.exs"
