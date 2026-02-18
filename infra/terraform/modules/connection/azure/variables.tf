variable "name_prefix" {
  description = "Prefix for Azure resources"
  type        = string
}

variable "location" {
  description = "Azure region for networking resources"
  type        = string
  default     = "West US 2"
}

variable "address_space" {
  description = "CIDR blocks for the virtual network"
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "subnets" {
  description = "Map of subnet names to CIDR blocks"
  type        = map(object({
    address_prefix = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to Azure resources"
  type        = map(string)
  default     = {}
}

