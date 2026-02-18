# =============================================================================
# GKE MODULE VARIABLES
# =============================================================================

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
  default     = "us-west2"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnetwork_name" {
  description = "Name of the subnetwork"
  type        = string
}

variable "cluster_secondary_range_name" {
  description = "Name of the secondary range for pods"
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the secondary range for services"
  type        = string
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
  description = "Release channel (UNSPECIFIED, RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "binary_authorization_mode" {
  description = "Binary authorization mode (DISABLED, PROJECT_SINGLETON_POLICY_ENFORCE)"
  type        = string
  default     = "DISABLED"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "maintenance_start_time" {
  description = "Maintenance window start time (RFC3339)"
  type        = string
  default     = "2024-01-01T03:00:00Z"
}

variable "maintenance_end_time" {
  description = "Maintenance window end time (RFC3339)"
  type        = string
  default     = "2024-01-01T05:00:00Z"
}

variable "maintenance_recurrence" {
  description = "Maintenance window recurrence (RFC5545)"
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SU"
}

variable "logging_service" {
  description = "Logging service (logging.googleapis.com/kubernetes, none)"
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "Monitoring service (monitoring.googleapis.com/kubernetes, none)"
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
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
  description = "Database encryption state (ENCRYPTED, DECRYPTED)"
  type        = string
  default     = "ENCRYPTED"
}

variable "database_encryption_key_name" {
  description = "KMS key name for database encryption"
  type        = string
  default     = ""
}

variable "node_pools" {
  description = "Map of node pool configurations"
  type = map(object({
    node_count              = number
    min_node_count          = number
    max_node_count          = number
    machine_type            = string
    disk_size_gb            = number
    disk_type               = string
    image_type              = string
    preemptible             = bool
    auto_repair             = bool
    auto_upgrade            = bool
    enable_secure_boot      = bool
    enable_integrity_monitoring = bool
    max_surge               = number
    max_unavailable         = number
    labels                  = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = {
    default = {
      node_count                  = 2
      min_node_count              = 1
      max_node_count              = 4
      machine_type                = "e2-medium"
      disk_size_gb                = 100
      disk_type                   = "pd-standard"
      image_type                  = "COS_CONTAINERD"
      preemptible                 = false
      auto_repair                 = true
      auto_upgrade                = true
      enable_secure_boot          = false
      enable_integrity_monitoring = true
      max_surge                   = 1
      max_unavailable             = 0
      labels                      = {}
      taints                      = []
    }
  }
}

