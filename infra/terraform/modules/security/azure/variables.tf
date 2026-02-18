variable "resource_group" {
  description = "Azure resource group for security artifacts"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West US 2"
}

variable "tags" {
  description = "Tags to apply to Azure security resources"
  type        = map(string)
  default     = {}
}

