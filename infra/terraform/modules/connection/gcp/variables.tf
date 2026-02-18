variable "project_id" {
  description = "GCP project that owns the network"
  type        = string
}

variable "region" {
  description = "Default region for subnets"
  type        = string
  default     = "us-west2"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "default"
}

variable "subnets" {
  description = "List of subnet configurations"
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Labels to apply to networking resources"
  type        = map(string)
  default     = {}
}

