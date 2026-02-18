# =============================================================================
# TERRAFORM VARIABLES CONFIGURATION
# =============================================================================
#
# This file defines all input variables for the Terraform configuration.
# Variables are organized by category for better maintainability.
#
# Author: Infrastructure Team
# Version: 2.0.0
# Last Updated: 2024-01-15
# =============================================================================

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

variable "project_name" {
  description = "Name of the project (from PROJECT_SLUG env var)"
  type        = string
  default     = ""

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 20
    error_message = "Project name must be between 1 and 20 characters long."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "cost_center" {
  description = "Cost center for billing and resource tagging"
  type        = string
  default     = "engineering"
}

variable "compliance_level" {
  description = "Compliance level for security and governance"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["basic", "standard", "high", "critical"], var.compliance_level)
    error_message = "Compliance level must be one of: basic, standard, high, critical."
  }
}

# =============================================================================
# CLOUD ENABLEMENT
# =============================================================================

variable "enable_aws" {
  description = "Enable provisioning of AWS resources"
  type        = bool
  default     = true
}

variable "enable_azure" {
  description = "Enable provisioning of Azure resources"
  type        = bool
  default     = false
}

variable "enable_gcp" {
  description = "Enable provisioning of Google Cloud resources"
  type        = bool
  default     = false
}

# =============================================================================
# AWS CONFIGURATION
# =============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = false
}

variable "key_pair_name" {
  description = "Name of the AWS key pair for EC2 instances"
  type        = string
  default     = ""

  validation {
    condition     = var.key_pair_name == "" || can(regex("^[a-zA-Z0-9-]+$", var.key_pair_name))
    error_message = "Key pair name must be alphanumeric with hyphens only."
  }
}

# =============================================================================
# AZURE CONFIGURATION
# =============================================================================

variable "azure_location" {
  description = "Azure region for resources"
  type        = string
  default     = "West US 2"
}

variable "azure_resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = ""
}

# =============================================================================
# GOOGLE CLOUD CONFIGURATION
# =============================================================================

variable "gcp_project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = ""

  validation {
    condition     = var.gcp_project_id == "" || can(regex("^[a-z0-9-]+$", var.gcp_project_id))
    error_message = "GCP Project ID must be lowercase alphanumeric with hyphens only."
  }
}

variable "gcp_region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-west2"
}

# =============================================================================
# KUBERNETES CONFIGURATION
# =============================================================================

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Kubernetes version must be in format X.Y (e.g., 1.28)."
  }
}

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 1000
    error_message = "Database allocated storage must be between 20 and 1000 GB."
  }
}

variable "db_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "13.7"
}

# =============================================================================
# MONITORING CONFIGURATION
# =============================================================================

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "monitoring_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30

  validation {
    condition     = var.monitoring_retention_days >= 1 && var.monitoring_retention_days <= 3653
    error_message = "Monitoring retention must be between 1 and 3653 days."
  }
}

# =============================================================================
# CI/CD CONFIGURATION
# =============================================================================

variable "repository_url" {
  description = "Git repository URL for CI/CD pipeline"
  type        = string
  default     = ""

  validation {
    condition     = var.repository_url == "" || can(regex("^https://.*\\.git$", var.repository_url))
    error_message = "Repository URL must be a valid HTTPS Git URL ending with .git."
  }
}

variable "branch_name" {
  description = "Git branch name for deployment"
  type        = string
  default     = "main"
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access resources"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.allowed_cidr_blocks) > 0
    error_message = "At least one CIDR block must be specified."
  }
}

variable "enable_encryption" {
  description = "Enable encryption for all resources"
  type        = bool
  default     = true
}

# =============================================================================
# TAGS CONFIGURATION
# =============================================================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# FEATURE FLAGS
# =============================================================================

variable "enable_kubernetes" {
  description = "Enable Kubernetes cluster deployment"
  type        = bool
  default     = true
}

variable "enable_database" {
  description = "Enable RDS database deployment"
  type        = bool
  default     = true
}

variable "enable_monitoring_stack" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = false
}

variable "enable_cicd_pipeline" {
  description = "Enable CI/CD pipeline deployment"
  type        = bool
  default     = false
}

# =============================================================================
# DOCKER CONTAINERS CONFIGURATION
# =============================================================================

variable "enable_vault" {
  description = "Enable Vault container"
  type        = bool
  default     = true
}

variable "enable_consul" {
  description = "Enable Consul container"
  type        = bool
  default     = true
}

variable "vault_image" {
  description = "Vault Docker image"
  type        = string
  default     = "hashicorp/vault:1.17.2"
}

variable "vault_port" {
  description = "External port for Vault"
  type        = number
  default     = 8200
}

variable "vault_root_token" {
  description = "Vault root token for dev mode"
  type        = string
  default     = "root-token-dev"
  sensitive   = true
}

variable "vault_config_path" {
  description = "Path to Vault config file (relative to terraform directory)"
  type        = string
  default     = "../graphql/config/vault.hcl"
}

variable "consul_image" {
  description = "Consul Docker image"
  type        = string
  default     = "hashicorp/consul:latest"
}

variable "consul_ports" {
  description = "List of port mappings for Consul"
  type = list(object({
    internal = number
    external = number
    protocol = string
  }))
  default = [
    { internal = 8500, external = 8500, protocol = "tcp" },
    { internal = 8300, external = 8300, protocol = "tcp" },
    { internal = 8301, external = 8301, protocol = "tcp" },
    { internal = 8301, external = 8301, protocol = "udp" },
    { internal = 8302, external = 8302, protocol = "tcp" },
    { internal = 8302, external = 8302, protocol = "udp" },
    { internal = 8502, external = 8502, protocol = "tcp" }
  ]
}

variable "consul_config_path" {
  description = "Path to Consul config file (relative to terraform directory)"
  type        = string
  default     = "../graphql/config/consul.hcl"
}

variable "docker_network_name" {
  description = "Docker network name"
  type        = string
  default     = "crice"
}

# =============================================================================
# KUBERNETES CONFIGURATION
# =============================================================================

variable "kubernetes_endpoint_private_access" {
  description = "Enable private API server endpoint for Kubernetes"
  type        = bool
  default     = true
}

variable "kubernetes_endpoint_public_access" {
  description = "Enable public API server endpoint for Kubernetes"
  type        = bool
  default     = true
}

variable "kubernetes_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public Kubernetes endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "kubernetes_enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "kubernetes_log_retention_days" {
  description = "CloudWatch log retention in days for Kubernetes"
  type        = number
  default     = 7
}

variable "kubernetes_aws_node_groups" {
  description = "AWS EKS node groups configuration"
  type = map(object({
    instance_types  = list(string)
    capacity_type   = string
    ami_type        = string
    desired_size    = number
    max_size        = number
    min_size        = number
    max_unavailable = number
    labels          = map(string)
    taints          = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags = map(string)
  }))
  default = {}
}

variable "kubernetes_aws_addons" {
  description = "AWS EKS addons configuration"
  type = map(object({
    version                  = string
    resolve_conflicts        = string
    service_account_role_arn = string
  }))
  default = {}
}

variable "kubernetes_gcp_network_name" {
  description = "GCP network name for GKE"
  type        = string
  default     = ""
}

variable "kubernetes_gcp_subnetwork_name" {
  description = "GCP subnetwork name for GKE"
  type        = string
  default     = ""
}

variable "kubernetes_gcp_cluster_secondary_range_name" {
  description = "GCP cluster secondary range name for pods"
  type        = string
  default     = ""
}

variable "kubernetes_gcp_services_secondary_range_name" {
  description = "GCP services secondary range name"
  type        = string
  default     = ""
}

variable "kubernetes_enable_private_nodes" {
  description = "Enable private nodes for GKE"
  type        = bool
  default     = true
}

variable "kubernetes_enable_private_endpoint" {
  description = "Enable private endpoint for GKE"
  type        = bool
  default     = false
}

variable "kubernetes_master_ipv4_cidr_block" {
  description = "CIDR block for the GKE master network"
  type        = string
  default     = "172.16.0.0/28"
}

variable "kubernetes_enable_network_policy" {
  description = "Enable network policy for Kubernetes"
  type        = bool
  default     = true
}

variable "kubernetes_release_channel" {
  description = "GKE release channel (UNSPECIFIED, RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "kubernetes_enable_vertical_pod_autoscaling" {
  description = "Enable Vertical Pod Autoscaling for GKE"
  type        = bool
  default     = true
}

variable "kubernetes_enable_horizontal_pod_autoscaling" {
  description = "Enable Horizontal Pod Autoscaling for Kubernetes"
  type        = bool
  default     = true
}

variable "kubernetes_gcp_node_pools" {
  description = "GCP GKE node pools configuration"
  type = map(object({
    node_count                  = number
    min_node_count              = number
    max_node_count              = number
    machine_type                = string
    disk_size_gb                = number
    disk_type                   = string
    image_type                  = string
    preemptible                 = bool
    auto_repair                 = bool
    auto_upgrade                = bool
    enable_secure_boot          = bool
    enable_integrity_monitoring = bool
    max_surge                   = number
    max_unavailable             = number
    labels                      = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = {}
}

variable "kubernetes_azure_subnet_id" {
  description = "Azure subnet ID for AKS"
  type        = string
  default     = ""
}

variable "kubernetes_network_plugin" {
  description = "Network plugin for AKS (azure, kubenet)"
  type        = string
  default     = "azure"
}

variable "kubernetes_network_policy" {
  description = "Network policy for AKS (azure, calico)"
  type        = string
  default     = "azure"
}

variable "kubernetes_service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_dns_service_ip" {
  description = "IP address for DNS service"
  type        = string
  default     = "10.0.0.10"
}

variable "kubernetes_docker_bridge_cidr" {
  description = "CIDR for Docker bridge"
  type        = string
  default     = "172.17.0.1/16"
}

variable "kubernetes_load_balancer_sku" {
  description = "Load balancer SKU for AKS (Basic, Standard)"
  type        = string
  default     = "Standard"
}

variable "kubernetes_enable_rbac" {
  description = "Enable RBAC for Kubernetes"
  type        = bool
  default     = true
}

variable "kubernetes_enable_private_cluster" {
  description = "Enable private cluster for AKS"
  type        = bool
  default     = false
}

variable "kubernetes_enable_oms_agent" {
  description = "Enable OMS agent for AKS"
  type        = bool
  default     = true
}

variable "kubernetes_azure_log_analytics_workspace_id" {
  description = "Azure Log Analytics workspace ID for AKS"
  type        = string
  default     = ""
}

variable "kubernetes_azure_node_pools" {
  description = "Azure AKS node pools configuration"
  type = map(object({
    vm_size            = string
    node_count         = number
    min_count          = number
    max_count          = number
    enable_auto_scaling = bool
    os_disk_size_gb    = number
    os_type            = string
    os_sku             = string
    labels             = map(string)
    taints             = list(string)
    tags               = map(string)
  }))
  default = {}
}
