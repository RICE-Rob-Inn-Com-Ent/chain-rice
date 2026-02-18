datacenter = "dc1"
data_dir = "/consul/data"

ui_config {
  enabled = true
}

server = true
bootstrap_expect = 1

addresses {
  http = "0.0.0.0"
  https = "0.0.0.0"
  grpc = "0.0.0.0"
}

ports {
  http = 8500
  serf_lan = 8301
  serf_wan = 8302
  server = 8300
  grpc = 8502
}

connect {
  enabled = true
}

telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}

acl = {
  enabled = false
}

