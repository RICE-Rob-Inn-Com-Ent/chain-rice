terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.63"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = var.aws_region
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

locals {
  name_prefix = lower(join("-", [var.project_name, var.environment]))
  tags = merge({
    Project     = var.project_name
    Environment = var.environment
    CostCenter  = var.cost_center
    Compliance  = var.compliance_level
    },
    var.additional_tags
  )
}

module "connection_aws" {
  count  = var.enable_aws ? 1 : 0
  source = "./modules/connection/aws"

  providers = {
    aws = aws.primary
  }

  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  tags        = local.tags
}

module "security_aws" {
  count  = length(module.connection_aws)
  source = "./modules/security/aws"

  providers = {
    aws = aws.primary
  }

  name_prefix         = local.name_prefix
  vpc_id              = module.connection_aws[0].vpc_id
  allowed_cidr_blocks = var.allowed_cidr_blocks
  enable_encryption   = var.enable_encryption
  enable_waf          = var.enable_monitoring_stack
  tags                = local.tags
}

# Docker containers for Vault and Consul
module "vault_consul" {
  source = "./modules/docker/vault-consul"

  vault_image           = var.vault_image
  vault_port            = var.vault_port
  vault_root_token      = var.vault_root_token
  vault_config_path     = var.vault_config_path
  consul_image          = var.consul_image
  consul_ports          = var.consul_ports
  consul_config_path    = var.consul_config_path
  docker_network_name   = var.docker_network_name
  enable_vault          = var.enable_vault
  enable_consul         = var.enable_consul
}

# Kubernetes Clusters (EKS/GKE/AKS)
module "kubernetes" {
  count  = var.enable_kubernetes ? 1 : 0
  source = "./modules/kubernetes"

  cluster_name       = "${local.name_prefix}-k8s"
  kubernetes_version = var.kubernetes_version

  enable_aws   = var.enable_aws
  enable_gcp   = var.enable_gcp
  enable_azure = var.enable_azure

  # AWS EKS Configuration
  aws_vpc_id   = length(module.connection_aws) > 0 ? module.connection_aws[0].vpc_id : ""
  aws_vpc_cidr = var.vpc_cidr
  aws_subnet_ids = length(module.connection_aws) > 0 ? concat(
    module.connection_aws[0].public_subnet_ids,
    module.connection_aws[0].private_subnet_ids
  ) : []

  endpoint_private_access = var.kubernetes_endpoint_private_access
  endpoint_public_access  = var.kubernetes_endpoint_public_access
  public_access_cidrs     = var.kubernetes_public_access_cidrs

  enabled_cluster_log_types = var.kubernetes_enabled_cluster_log_types
  log_retention_days        = var.kubernetes_log_retention_days
  key_pair_name             = var.key_pair_name

  aws_node_groups = var.kubernetes_aws_node_groups
  aws_addons      = var.kubernetes_aws_addons

  # GCP GKE Configuration
  gcp_project_id         = var.gcp_project_id
  gcp_region             = var.gcp_region
  gcp_network_name       = var.kubernetes_gcp_network_name
  gcp_subnetwork_name    = var.kubernetes_gcp_subnetwork_name
  gcp_cluster_secondary_range_name  = var.kubernetes_gcp_cluster_secondary_range_name
  gcp_services_secondary_range_name = var.kubernetes_gcp_services_secondary_range_name

  enable_private_nodes    = var.kubernetes_enable_private_nodes
  enable_private_endpoint = var.kubernetes_enable_private_endpoint
  master_ipv4_cidr_block  = var.kubernetes_master_ipv4_cidr_block

  enable_network_policy           = var.kubernetes_enable_network_policy
  release_channel                  = var.kubernetes_release_channel
  enable_vertical_pod_autoscaling = var.kubernetes_enable_vertical_pod_autoscaling
  enable_horizontal_pod_autoscaling = var.kubernetes_enable_horizontal_pod_autoscaling

  gcp_node_pools = var.kubernetes_gcp_node_pools

  # Azure AKS Configuration
  azure_location           = var.azure_location
  azure_resource_group_name = var.azure_resource_group_name
  azure_subnet_id          = var.kubernetes_azure_subnet_id

  network_plugin    = var.kubernetes_network_plugin
  network_policy     = var.kubernetes_network_policy
  service_cidr       = var.kubernetes_service_cidr
  dns_service_ip     = var.kubernetes_dns_service_ip
  docker_bridge_cidr  = var.kubernetes_docker_bridge_cidr
  load_balancer_sku   = var.kubernetes_load_balancer_sku

  enable_rbac                  = var.kubernetes_enable_rbac
  enable_private_cluster       = var.kubernetes_enable_private_cluster
  enable_oms_agent             = var.kubernetes_enable_oms_agent
  azure_log_analytics_workspace_id = var.kubernetes_azure_log_analytics_workspace_id

  azure_node_pools = var.kubernetes_azure_node_pools

  tags = local.tags
}
