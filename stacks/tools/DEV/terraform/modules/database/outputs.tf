# =============================================================================
# DATABASE MODULE - OUTPUTS
# =============================================================================

output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = local.db_endpoint
  sensitive   = true
}

output "db_port" {
  description = "RDS instance port"
  value       = local.db_port
}

output "db_name" {
  description = "RDS database name"
  value       = local.db_name
}

output "db_username" {
  description = "RDS master username"
  value       = local.db_username
  sensitive   = true
}
