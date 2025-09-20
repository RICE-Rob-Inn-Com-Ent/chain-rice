# =============================================================================
# COMPUTE MODULE - OUTPUTS
# =============================================================================

output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = local.asg_id
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = local.launch_template_id
}

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = local.instance_ids
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = local.load_balancer_dns
}
