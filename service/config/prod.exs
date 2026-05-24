import Config

# Production: least surprise in logs; details via OTel / remote aggregation.
config :logger, level: :warning

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :community_id, :otel_trace_id]

# --- Phoenix / Bandit — tuned for very large Channel fan-out (mini-communities) ---
# Also set Linux `ulimit -n`, `somaxconn`, and sysctl TCP buffers at the host; BEAM vm.args below.
config :service, Smith.Core.Endpoint,
  url: [host: System.get_env("PHX_HOST", "example.com"), port: 443, scheme: "https"],
  check_origin: true,
  server: true,
  http: [
    ip: {0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT", "4000")),
    thousand_island_options: [
      num_acceptors: 100
    ],
    websocket_options: [
      compress: true,
      max_frame_size: 16_777_216
    ]
  ],
  websocket: [
    timeout: 120_000,
    transport_log: false
  ]

# --- Post-quantum material (immutable paths; mount real ML-DSA / ML-KEM PEMs from secrets — never commit keys) ---
config :service, Service.Crypto.PQ,
  material: [
    ml_dsa65_sign_sk_path: "/etc/rice/pqc/ml-dsa-65-sk.pem",
    ml_kem768_sk_path: "/etc/rice/pqc/ml-kem-768-sk.pem",
    hybrid_x509_chain_path: "/etc/rice/pqc/hybrid-chain.pem"
  ],
  hash: [
    algorithm: :hybrid_argon2id_mlwe,
    time_cost: 5,
    memory_kib: 262_144,
    parallelism: 4,
    salt_bytes: 32,
    output_bytes: 64
  ],
  signature_suite: :ML_DSA_65,
  verify_only_public_material: false

# --- Distributed Erlang: TLS distribution with hybrid / PQC-ready cert chain ---
config :service, Smith.Connection,
  enabled: true,
  tls_distribution: [
    enabled: true,
    verify: :verify_peer,
    fail_if_no_peer_cert: true,
    cacertfile: "/etc/rice/erl_dist/ca.crt",
    certfile: "/etc/rice/erl_dist/node.crt",
    keyfile: "/etc/rice/erl_dist/node.key",
    secure_renegotiate: true,
    customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)],
    signature_algs: [:"ecdsa_secp384r1_sha384", :"rsa_pss_rsae_sha384"]
  ]

# --- Anti-Manifesto (RICE-Web reads `RICE_WEB_*`; Elixir side keeps durable trigger state) ---
config :service, Service.AntiManifesto,
  persistent_triggers: true,
  ledger_path: "/var/lib/rice/anti_manifesto_ledger.bin",
  env_mode: "RICE_WEB_ANTIMANIFESTO",
  env_min_consensus: "RICE_WEB_ANTIMANIFESTO_MIN_CONSENSUS"

config :service, Smith.Pipeline.Nats,
  connection_settings: [
    %{
      host: System.get_env("RICE_NATS_HOST", "nats.service.consul"),
      port: String.to_integer(System.get_env("RICE_NATS_PORT", "4222"))
    }
  ]

config :service, Service.Messaging,
  adapter: Service.Messaging.NATSCommunityFanout,
  topic_prefix: "rice.community.prod"

config :service, Service.RICE.Web,
  grpc: [
    host: System.get_env("RICE_WEB_GRPC_HOST", "127.0.0.1"),
    port: String.to_integer(System.get_env("RICE_WEB_GRPC_PORT", "50051")),
    transport: :tls,
    tls_opts: [
      verify: :verify_peer,
      cacertfile: System.get_env("RICE_WEB_GRPC_CA", "/etc/rice/grpc/ca.pem"),
      certfile: System.get_env("RICE_WEB_GRPC_CERT", "/etc/rice/grpc/client.pem"),
      keyfile: System.get_env("RICE_WEB_GRPC_KEY", "/etc/rice/grpc/client-key.pem")
    ]
  ],
  connect_base_url: System.get_env("RICE_CONNECT_BASE_URL", "https://web.rice.internal")

config :service, Service.SAGE, truth_filter: [trace_sampling: 0.01, log_training_decisions: false]

config :service, Service.Guard,
  pipeline_enabled: true,
  watcher_poll_ms: 2_000

# --- BEAM tuning for heavy CLERK / AI / numeric workloads (apply via release vm.args) ---
# Recommended vm.args (non-exhaustive):
#   +P 5000000
#   +Q 65536
#   +S 8:8
#   +SDio 8
#   +sbwt none +sbwtdcpu none +sbwtdio none
#   -kernel inet_dist_use_interface {0,0,0,0}
