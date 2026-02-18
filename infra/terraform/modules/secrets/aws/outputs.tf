# =============================================================================
# SECURITY MODULE - OUTPUTS
# =============================================================================

output "security_group_ids" {
  description = "IDs of all security groups"
  value = [
    aws_security_group.web.id,
    aws_security_group.database.id,
    aws_security_group.app.id
  ]
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}
