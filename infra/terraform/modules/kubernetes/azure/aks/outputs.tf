# =============================================================================
# AKS MODULE OUTPUTS
# =============================================================================

output "cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_endpoint" {
  description = "Endpoint for AKS control plane"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = azurerm_kubernetes_cluster.main.kubernetes_version
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_client_key" {
  description = "Base64 encoded private key used by clients to authenticate to the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  sensitive   = true
}

output "cluster_client_certificate" {
  description = "Base64 encoded public certificate used by clients to authenticate to the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  sensitive   = true
}

output "cluster_resource_group_name" {
  description = "Resource group name of the cluster"
  value       = azurerm_kubernetes_cluster.main.resource_group_name
}

output "kubeconfig" {
  description = "Kubeconfig file content"
  value = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = azurerm_kubernetes_cluster.main.name
      cluster = {
        certificate-authority-data = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
        server                     = "https://${azurerm_kubernetes_cluster.main.kube_config[0].host}"
      }
    }]
    contexts = [{
      name = azurerm_kubernetes_cluster.main.name
      context = {
        cluster = azurerm_kubernetes_cluster.main.name
        user    = azurerm_kubernetes_cluster.main.name
      }
    }]
    "current-context" = azurerm_kubernetes_cluster.main.name
    users = [{
      name = azurerm_kubernetes_cluster.main.name
      user = {
        client-certificate-data = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
        client-key-data         = azurerm_kubernetes_cluster.main.kube_config[0].client_key
      }
    }]
  })
  sensitive = true
}

