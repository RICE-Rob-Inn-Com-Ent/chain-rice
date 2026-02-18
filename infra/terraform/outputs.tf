output "aws_vpc_id" {
  description = "AWS VPC ID (null if AWS is disabled)."
  value       = length(module.connection_aws) > 0 ? module.connection_aws[0].vpc_id : null
}

output "aws_public_subnet_ids" {
  description = "AWS public subnet IDs."
  value       = length(module.connection_aws) > 0 ? module.connection_aws[0].public_subnet_ids : []
}

output "aws_private_subnet_ids" {
  description = "AWS private subnet IDs."
  value       = length(module.connection_aws) > 0 ? module.connection_aws[0].private_subnet_ids : []
}

output "aws_security_group_ids" {
  description = "AWS security group IDs."
  value       = length(module.security_aws) > 0 ? module.security_aws[0].security_group_ids : {}
}

# Docker containers outputs
output "vault_address" {
  description = "Vault address"
  value       = module.vault_consul.vault_address
}

output "vault_container_name" {
  description = "Vault container name"
  value       = module.vault_consul.vault_container_name
}

output "consul_address" {
  description = "Consul address"
  value       = module.vault_consul.consul_address
}

output "consul_container_name" {
  description = "Consul container name"
  value       = module.vault_consul.consul_container_name
}

# Kubernetes Cluster Outputs
output "kubernetes_cluster_endpoints" {
  description = "Map of Kubernetes cluster endpoints by provider"
  value       = var.enable_kubernetes ? module.kubernetes[0].cluster_endpoints : {}
  sensitive   = true
}

output "kubernetes_kubeconfigs" {
  description = "Map of Kubernetes kubeconfigs by provider"
  value       = var.enable_kubernetes ? module.kubernetes[0].kubeconfigs : {}
  sensitive   = true
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = var.enable_kubernetes && var.enable_aws ? module.kubernetes[0].eks_cluster_id : null
}

output "gke_cluster_id" {
  description = "GKE cluster ID"
  value       = var.enable_kubernetes && var.enable_gcp ? module.kubernetes[0].gke_cluster_id : null
}

output "aks_cluster_id" {
  description = "AKS cluster ID"
  value       = var.enable_kubernetes && var.enable_azure ? module.kubernetes[0].aks_cluster_id : null
}
