import Config

config :phoenix, :json_library, Jason

# SMITH core — Phoenix endpoint + PubSub (see service/core/*.ex)
config :service, Service.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  pubsub_server: Service.PubSub,
  live_view: [signing_salt: "service_lv_signing_salt"],
  secret_key_base: "dev_only_replace_in_prod_01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901"

config :service, Service.PubSub, name: Service.PubSub

config :service, Service.Presence, pubsub_server: Service.PubSub

# SMITH pipeline — Broadway + GNAT + Membrane (see service/pipeline/*.ex)
config :service, Service.Pipeline.NATS,
  name: :service_pipeline_nats,
  connection_settings: [%{host: "127.0.0.1", port: 4222}],
  backoff_period: 2_000

config :service, Service.Pipeline,
  producer: [
    subscription_topic: "service.>",
    connection_name: :service_pipeline_nats
  ]

# SMITH cluster — libcluster + Horde (see service/cluster/*.ex)
config :service, Service.Cluster,
  enabled: false,
  topologies: [
    service: [
      strategy: Cluster.Strategy.Epmd,
      config: [
        hosts: []
      ]
    ]
  ],
  horde: [
    registry_name: Service.Cluster.HordeRegistry,
    dynamic_supervisor_name: Service.Cluster.HordeDynamicSupervisor,
    distribution_strategy: Horde.UniformDistribution
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
  odin_ports: []

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

import_config "#{config_env()}.exs"
