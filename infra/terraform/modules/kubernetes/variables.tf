# =============================================================================
# KUBERNETES MODULE VARIABLES - Multi-Cloud
# =============================================================================

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28"
}

variable "enable_aws" {
  description = "Enable AWS EKS cluster"
  type        = bool
  default     = false
}

variable "enable_gcp" {
  description = "Enable GCP GKE cluster"
  type        = bool
  default     = false
}

variable "enable_azure" {
  description = "Enable Azure AKS cluster"
  type        = bool
  default     = false
}

# AWS EKS Variables
variable "aws_vpc_id" {
  description = "AWS VPC ID"
  type        = string
  default     = ""
}

variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR"
  type        = string
  default     = ""
}

variable "aws_subnet_ids" {
  description = "AWS subnet IDs"
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "aws_kms_key_id" {
  description = "AWS KMS key ID for encryption"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = ""
}

variable "aws_node_groups" {
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

variable "aws_addons" {
  description = "AWS EKS addons configuration"
  type = map(object({
    version                  = string
    resolve_conflicts        = string
    service_account_role_arn = string
  }))
  default = {}
}

# GCP GKE Variables
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-west2"
}

variable "gcp_network_name" {
  description = "GCP network name"
  type        = string
  default     = ""
}

variable "gcp_subnetwork_name" {
  description = "GCP subnetwork name"
  type        = string
  default     = ""
}

variable "gcp_cluster_secondary_range_name" {
  description = "GCP cluster secondary range name"
  type        = string
  default     = ""
}

variable "gcp_services_secondary_range_name" {
  description = "GCP services secondary range name"
  type        = string
  default     = ""
}

variable "enable_private_nodes" {
  description = "Enable private nodes"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the master network"
  type        = string
  default     = "172.16.0.0/28"
}

variable "enable_network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = true
}

variable "master_authorized_networks" {
  description = "List of authorized networks for master access"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = null
}

variable "release_channel" {
  description = "Release channel"
  type        = string
  default     = "REGULAR"
}

variable "binary_authorization_mode" {
  description = "Binary authorization mode"
  type        = string
  default     = "DISABLED"
}

variable "enable_vertical_pod_autoscaling" {
  description = "Enable Vertical Pod Autoscaling"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable Horizontal Pod Autoscaling"
  type        = bool
  default     = true
}

variable "enable_http_load_balancing" {
  description = "Enable HTTP Load Balancing addon"
  type        = bool
  default     = true
}

variable "database_encryption_state" {
  description = "Database encryption state"
  type        = string
  default     = "ENCRYPTED"
}

variable "gcp_database_encryption_key_name" {
  description = "GCP KMS key name for database encryption"
  type        = string
  default     = ""
}

variable "logging_service" {
  description = "Logging service"
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "Monitoring service"
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "maintenance_start_time" {
  description = "Maintenance window start time"
  type        = string
  default     = "2024-01-01T03:00:00Z"
}

variable "maintenance_end_time" {
  description = "Maintenance window end time"
  type        = string
  default     = "2024-01-01T05:00:00Z"
}

variable "maintenance_recurrence" {
  description = "Maintenance window recurrence"
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SU"
}

variable "gcp_node_pools" {
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

# Azure AKS Variables
variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "West US 2"
}

variable "azure_resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = ""
}

variable "dns_prefix" {
  description = "DNS prefix"
  type        = string
  default     = ""
}

variable "azure_subnet_id" {
  description = "Azure subnet ID"
  type        = string
  default     = ""
}

variable "network_plugin" {
  description = "Network plugin"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy"
  type        = string
  default     = "azure"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for DNS service"
  type        = string
  default     = "10.0.0.10"
}

variable "docker_bridge_cidr" {
  description = "CIDR for Docker bridge"
  type        = string
  default     = "172.17.0.1/16"
}

variable "load_balancer_sku" {
  description = "Load balancer SKU"
  type        = string
  default     = "Standard"
}

variable "enable_rbac" {
  description = "Enable RBAC"
  type        = bool
  default     = true
}

variable "api_server_authorized_ip_ranges" {
  description = "List of authorized IP ranges for API server"
  type        = list(string)
  default     = []
}

variable "enable_private_cluster" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "enable_http_application_routing" {
  description = "Enable HTTP application routing addon"
  type        = bool
  default     = false
}

variable "enable_oms_agent" {
  description = "Enable OMS agent"
  type        = bool
  default     = true
}

variable "azure_log_analytics_workspace_id" {
  description = "Azure Log Analytics workspace ID"
  type        = string
  default     = ""
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy addon"
  type        = bool
  default     = false
}

variable "automatic_channel_upgrade" {
  description = "Automatic channel upgrade"
  type        = string
  default     = "patch"
}

variable "maintenance_day" {
  description = "Maintenance window day"
  type        = string
  default     = "Sunday"
}

variable "maintenance_hours" {
  description = "Maintenance window hours"
  type        = list(number)
  default     = [3, 4, 5]
}

variable "maintenance_not_allowed_start" {
  description = "Maintenance not allowed start time"
  type        = string
  default     = ""
}

variable "maintenance_not_allowed_end" {
  description = "Maintenance not allowed end time"
  type        = string
  default     = ""
}

variable "azure_node_pools" {
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

