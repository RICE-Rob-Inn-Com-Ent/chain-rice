# =============================================================================
# AKS MODULE VARIABLES
# =============================================================================

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region for the cluster"
  type        = string
  default     = "West US 2"
}

variable "resource_group_name" {
  description = "Name of the resource group. If empty, a new one will be created"
  type        = string
  default     = ""
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28"
}

variable "subnet_id" {
  description = "Subnet ID for the cluster"
  type        = string
}

variable "network_plugin" {
  description = "Network plugin (azure, kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy (azure, calico)"
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
  description = "Load balancer SKU (Basic, Standard)"
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
  description = "Enable OMS agent (Azure Monitor)"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = ""
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy addon"
  type        = bool
  default     = false
}

variable "automatic_channel_upgrade" {
  description = "Automatic channel upgrade (patch, rapid, node-image, stable, none)"
  type        = string
  default     = "patch"
}

variable "maintenance_day" {
  description = "Maintenance window day (Sunday, Monday, etc.)"
  type        = string
  default     = "Sunday"
}

variable "maintenance_hours" {
  description = "Maintenance window hours"
  type        = list(number)
  default     = [3, 4, 5]
}

variable "maintenance_not_allowed_start" {
  description = "Maintenance not allowed start time (RFC3339)"
  type        = string
  default     = ""
}

variable "maintenance_not_allowed_end" {
  description = "Maintenance not allowed end time (RFC3339)"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "node_pools" {
  description = "Map of node pool configurations"
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
  default = {
    default = {
      vm_size            = "Standard_D2s_v3"
      node_count         = 2
      min_count          = 1
      max_count          = 4
      enable_auto_scaling = true
      os_disk_size_gb    = 100
      os_type            = "Linux"
      os_sku             = "Ubuntu"
      labels             = {}
      taints             = []
      tags               = {}
    }
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

