# =============================================================================
# DATABASE MODULE - VARIABLES
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

variable "security_group_ids" {
  description = "IDs of the security groups"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
}

variable "backup_retention" {
  description = "Backup retention period in days"
  type        = number
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
