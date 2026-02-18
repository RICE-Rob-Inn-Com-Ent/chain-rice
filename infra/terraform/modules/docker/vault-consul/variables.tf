variable "vault_image" {
  description = "Vault Docker image"
  type        = string
  default     = "hashicorp/vault:1.17.2"
}

variable "vault_port" {
  description = "External port for Vault"
  type        = number
  default     = 8200
}

variable "vault_root_token" {
  description = "Vault root token for dev mode"
  type        = string
  default     = "root-token-dev"
  sensitive   = true
}

variable "vault_config_path" {
  description = "Path to Vault config file (optional)"
  type        = string
  default     = ""
}

variable "consul_image" {
  description = "Consul Docker image"
  type        = string
  default     = "hashicorp/consul:latest"
}

variable "consul_ports" {
  description = "List of port mappings for Consul"
  type = list(object({
    internal = number
    external = number
    protocol = string
  }))
  default = [
    { internal = 8500, external = 8500, protocol = "tcp" },
    { internal = 8300, external = 8300, protocol = "tcp" },
    { internal = 8301, external = 8301, protocol = "tcp" },
    { internal = 8301, external = 8301, protocol = "udp" },
    { internal = 8302, external = 8302, protocol = "tcp" },
    { internal = 8302, external = 8302, protocol = "udp" },
    { internal = 8502, external = 8502, protocol = "tcp" }
  ]
}

variable "consul_config_path" {
  description = "Path to Consul config file (optional)"
  type        = string
  default     = ""
}

variable "docker_network_name" {
  description = "Docker network name"
  type        = string
  default     = "crice"
}

variable "enable_vault" {
  description = "Enable Vault container"
  type        = bool
  default     = true
}

variable "enable_consul" {
  description = "Enable Consul container"
  type        = bool
  default     = true
}

