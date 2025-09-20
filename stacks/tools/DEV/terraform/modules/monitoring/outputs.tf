# =============================================================================
# MONITORING MODULE - OUTPUTS
# =============================================================================

output "dashboard_url" {
  description = "URL of the monitoring dashboard"
  value       = local.dashboard_url
}

output "prometheus_endpoint" {
  description = "Prometheus endpoint URL"
  value       = local.prometheus_endpoint
}

output "grafana_endpoint" {
  description = "Grafana endpoint URL"
  value       = local.grafana_endpoint
}
