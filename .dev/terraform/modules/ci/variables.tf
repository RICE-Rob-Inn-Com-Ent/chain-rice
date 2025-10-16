# =============================================================================
# CI/CD MODULE - VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Common name prefix for resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "repository_url" {
  description = "Git repository URL"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
