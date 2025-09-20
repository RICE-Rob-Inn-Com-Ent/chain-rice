# =============================================================================
# KUBERNETES MODULE - OUTPUTS
# =============================================================================

output "cluster_id" {
  description = "EKS cluster ID"
  value       = local.cluster_id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = local.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = local.cluster_security_group_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = local.cluster_arn
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = local.cluster_version
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = local.node_group_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = "placeholder-certificate-data"
}
