variable "project_id" {
  description = "GCP project that owns the security resources"
  type        = string
}

variable "network" {
  description = "Name of the target VPC network"
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Labels to attach to security resources"
  type        = map(string)
  default     = {}
}

