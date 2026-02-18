variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access resources"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_encryption" {
  description = "Enable creation of a dedicated KMS key"
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Enable AWS WAF"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

