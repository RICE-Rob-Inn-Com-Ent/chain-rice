# =============================================================================
# KUBERNETES MODULE - VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Common name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "node_group_config" {
  description = "Node group configuration"
  type        = map(any)
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
