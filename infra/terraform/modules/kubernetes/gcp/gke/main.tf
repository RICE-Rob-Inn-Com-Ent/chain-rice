# =============================================================================
# GCP GKE CLUSTER MODULE
# =============================================================================

# GKE Cluster
resource "google_container_cluster" "main" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_name
  subnetwork = var.subnetwork_name

  # Enable private cluster
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Network policy
  network_policy {
    enabled = var.enable_network_policy
  }

  # IP allocation policy
  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = var.master_authorized_networks != null ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Release channel
  release_channel {
    channel = var.release_channel
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Binary Authorization
  binary_authorization {
    evaluation_mode = var.binary_authorization_mode
  }

  # Resource labels
  resource_labels = var.labels

  # Maintenance window
  maintenance_policy {
    recurring_window {
      start_time = var.maintenance_start_time
      end_time   = var.maintenance_end_time
      recurrence = var.maintenance_recurrence
    }
  }

  # Logging and monitoring
  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service

  # Vertical Pod Autoscaling
  vertical_pod_autoscaling {
    enabled = var.enable_vertical_pod_autoscaling
  }

  # Horizontal Pod Autoscaling
  enable_horizontal_pod_autoscaling = var.enable_horizontal_pod_autoscaling

  # HTTP Load Balancing
  addons_config {
    http_load_balancing {
      disabled = !var.enable_http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !var.enable_horizontal_pod_autoscaling
    }
    network_policy_config {
      disabled = !var.enable_network_policy
    }
  }

  # Master auth
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Database encryption
  database_encryption {
    state    = var.database_encryption_state
    key_name = var.database_encryption_key_name
  }

  lifecycle {
    ignore_changes = [
      node_pool,
    ]
  }

  depends_on = [google_project_service.container]
}

# Enable required APIs
resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"

  disable_on_destroy = false
}

# Node Pools
resource "google_container_node_pool" "main" {
  for_each = var.node_pools

  name       = each.key
  location   = var.region
  cluster    = google_container_cluster.main.name
  project    = var.project_id
  node_count = each.value.node_count

  autoscaling {
    min_node_count = each.value.min_node_count
    max_node_count = each.value.max_node_count
    location_policy = "BALANCED"  # BALANCED or ANY
  }

  management {
    auto_repair  = each.value.auto_repair
    auto_upgrade = each.value.auto_upgrade
  }

  node_config {
    machine_type    = each.value.machine_type
    disk_size_gb    = each.value.disk_size_gb
    disk_type       = each.value.disk_type
    image_type      = each.value.image_type
    preemptible     = each.value.preemptible
    service_account = google_service_account.node.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = merge(
      var.labels,
      each.value.labels
    )

    taint = each.value.taints

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded nodes
    shielded_instance_config {
      enable_secure_boot          = each.value.enable_secure_boot
      enable_integrity_monitoring = each.value.enable_integrity_monitoring
    }
  }

  upgrade_settings {
    max_surge       = each.value.max_surge
    max_unavailable = each.value.max_unavailable
  }
}

# Service Account for Nodes
resource "google_service_account" "node" {
  account_id   = "${var.cluster_name}-node-sa"
  display_name = "GKE Node Service Account for ${var.cluster_name}"
  project      = var.project_id
}

resource "google_project_iam_member" "node" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/container.nodeServiceAccount",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.node.email}"
}

