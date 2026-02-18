# =============================================================================
# GKE MODULE OUTPUTS
# =============================================================================

output "cluster_id" {
  description = "GKE cluster ID"
  value       = google_container_cluster.main.id
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for GKE control plane"
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = google_container_cluster.main.master_version
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Location of the cluster"
  value       = google_container_cluster.main.location
}

output "cluster_network" {
  description = "Network name of the cluster"
  value       = google_container_cluster.main.network
}

output "cluster_subnetwork" {
  description = "Subnetwork name of the cluster"
  value       = google_container_cluster.main.subnetwork
}

output "node_service_account_email" {
  description = "Service account email for nodes"
  value       = google_service_account.node.email
}

output "kubeconfig" {
  description = "Kubeconfig file content"
  value = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = google_container_cluster.main.name
      cluster = {
        certificate-authority-data = google_container_cluster.main.master_auth[0].cluster_ca_certificate
        server                     = "https://${google_container_cluster.main.endpoint}"
      }
    }]
    contexts = [{
      name = google_container_cluster.main.name
      context = {
        cluster = google_container_cluster.main.name
        user    = google_container_cluster.main.name
      }
    }]
    "current-context" = google_container_cluster.main.name
    users = [{
      name = google_container_cluster.main.name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "gke-gcloud-auth-plugin"
        }
      }
    }]
  })
  sensitive = true
}

