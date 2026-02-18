# =============================================================================
# EKS MODULE VARIABLES
# =============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cluster"
  type        = list(string)
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

variable "kms_key_id" {
  description = "KMS key ID for encryption. If empty, a new key will be created"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access to nodes"
  type        = string
  default     = ""
}

variable "node_groups" {
  description = "Map of node group configurations"
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
  default = {
    default = {
      instance_types  = ["t3.medium"]
      capacity_type   = "ON_DEMAND"
      ami_type        = "AL2_x86_64"
      desired_size    = 2
      max_size        = 4
      min_size        = 1
      max_unavailable = 1
      labels          = {}
      taints          = []
      tags            = {}
    }
  }
}

variable "addons" {
  description = "Map of EKS add-ons to install"
  type = map(object({
    version                  = string
    resolve_conflicts        = string
    service_account_role_arn = string
  }))
  default = {
    vpc-cni = {
      version                  = "latest"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = ""
    }
    kube-proxy = {
      version                  = "latest"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = ""
    }
    coredns = {
      version                  = "latest"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = ""
    }
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

