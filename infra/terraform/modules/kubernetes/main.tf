# =============================================================================
# KUBERNETES MODULE - Multi-Cloud Unified Interface
# =============================================================================

# EKS Cluster (AWS)
module "eks" {
  count  = var.enable_aws ? 1 : 0
  source = "./aws/eks"

  providers = {
    aws = aws.primary
  }

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = var.aws_vpc_id
  vpc_cidr           = var.aws_vpc_cidr
  subnet_ids         = var.aws_subnet_ids

  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  public_access_cidrs     = var.public_access_cidrs

  enabled_cluster_log_types = var.enabled_cluster_log_types
  log_retention_days        = var.log_retention_days
  kms_key_id                = var.aws_kms_key_id
  key_pair_name             = var.key_pair_name

  node_groups = var.aws_node_groups
  addons      = var.aws_addons

  tags = var.tags
}

# GKE Cluster (GCP)
module "gke" {
  count  = var.enable_gcp ? 1 : 0
  source = "./gcp/gke"

  cluster_name       = var.cluster_name
  project_id         = var.gcp_project_id
  region             = var.gcp_region
  kubernetes_version = var.kubernetes_version

  network_name                  = var.gcp_network_name
  subnetwork_name               = var.gcp_subnetwork_name
  cluster_secondary_range_name  = var.gcp_cluster_secondary_range_name
  services_secondary_range_name = var.gcp_services_secondary_range_name

  enable_private_nodes    = var.enable_private_nodes
  enable_private_endpoint = var.enable_private_endpoint
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block

  enable_network_policy           = var.enable_network_policy
  master_authorized_networks      = var.master_authorized_networks
  release_channel                 = var.release_channel
  binary_authorization_mode       = var.binary_authorization_mode
  enable_vertical_pod_autoscaling = var.enable_vertical_pod_autoscaling
  enable_horizontal_pod_autoscaling = var.enable_horizontal_pod_autoscaling
  enable_http_load_balancing      = var.enable_http_load_balancing

  database_encryption_state    = var.database_encryption_state
  database_encryption_key_name = var.gcp_database_encryption_key_name

  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service

  maintenance_start_time = var.maintenance_start_time
  maintenance_end_time   = var.maintenance_end_time
  maintenance_recurrence = var.maintenance_recurrence

  node_pools = var.gcp_node_pools
  labels     = var.tags
}

# AKS Cluster (Azure)
module "aks" {
  count  = var.enable_azure ? 1 : 0
  source = "./azure/aks"

  cluster_name       = var.cluster_name
  location           = var.azure_location
  resource_group_name = var.azure_resource_group_name
  dns_prefix         = var.dns_prefix
  kubernetes_version = var.kubernetes_version

  subnet_id = var.azure_subnet_id

  network_plugin    = var.network_plugin
  network_policy    = var.network_policy
  service_cidr      = var.service_cidr
  dns_service_ip    = var.dns_service_ip
  docker_bridge_cidr = var.docker_bridge_cidr
  load_balancer_sku  = var.load_balancer_sku

  enable_rbac                  = var.enable_rbac
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  enable_private_cluster      = var.enable_private_cluster

  enable_http_application_routing = var.enable_http_application_routing
  enable_oms_agent              = var.enable_oms_agent
  log_analytics_workspace_id     = var.azure_log_analytics_workspace_id
  enable_azure_policy           = var.enable_azure_policy

  automatic_channel_upgrade = var.automatic_channel_upgrade

  maintenance_day    = var.maintenance_day
  maintenance_hours  = var.maintenance_hours
  maintenance_not_allowed_start = var.maintenance_not_allowed_start
  maintenance_not_allowed_end   = var.maintenance_not_allowed_end

  node_pools = var.azure_node_pools
  labels     = var.tags
  tags       = var.tags
}

