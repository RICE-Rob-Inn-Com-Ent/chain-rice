ui = true

storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1  # For development only! Enable TLS in production
}

api_addr = "http://0.0.0.0:8200"

# Enable Prometheus metrics
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}

# Audit logging
# audit "file" {
#   file_path = "/vault/logs/audit.log"
# }
