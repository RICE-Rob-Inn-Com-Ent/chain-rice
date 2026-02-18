# =============================================================================
# KUBERNETES MODULE OUTPUTS - Multi-Cloud
# =============================================================================

# AWS EKS Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = var.enable_aws ? module.eks[0].cluster_id : null
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = var.enable_aws ? module.eks[0].cluster_endpoint : null
  sensitive   = true
}

output "eks_kubeconfig" {
  description = "EKS kubeconfig"
  value       = var.enable_aws ? module.eks[0].kubeconfig : null
  sensitive   = true
}

# GCP GKE Outputs
output "gke_cluster_id" {
  description = "GKE cluster ID"
  value       = var.enable_gcp ? module.gke[0].cluster_id : null
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = var.enable_gcp ? module.gke[0].cluster_endpoint : null
  sensitive   = true
}

output "gke_kubeconfig" {
  description = "GKE kubeconfig"
  value       = var.enable_gcp ? module.gke[0].kubeconfig : null
  sensitive   = true
}

# Azure AKS Outputs
output "aks_cluster_id" {
  description = "AKS cluster ID"
  value       = var.enable_azure ? module.aks[0].cluster_id : null
}

output "aks_cluster_endpoint" {
  description = "AKS cluster endpoint"
  value       = var.enable_azure ? module.aks[0].cluster_endpoint : null
  sensitive   = true
}

output "aks_kubeconfig" {
  description = "AKS kubeconfig"
  value       = var.enable_azure ? module.aks[0].kubeconfig : null
  sensitive   = true
}

# Unified Outputs
output "cluster_endpoints" {
  description = "Map of cluster endpoints by provider"
  value = {
    aws   = var.enable_aws ? module.eks[0].cluster_endpoint : null
    gcp   = var.enable_gcp ? module.gke[0].cluster_endpoint : null
    azure = var.enable_azure ? module.aks[0].cluster_endpoint : null
  }
  sensitive = true
}

output "kubeconfigs" {
  description = "Map of kubeconfigs by provider"
  value = {
    aws   = var.enable_aws ? module.eks[0].kubeconfig : null
    gcp   = var.enable_gcp ? module.gke[0].kubeconfig : null
    azure = var.enable_azure ? module.aks[0].kubeconfig : null
  }
  sensitive = true
}

