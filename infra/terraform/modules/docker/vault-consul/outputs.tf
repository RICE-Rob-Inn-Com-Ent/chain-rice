output "vault_container_id" {
  description = "Vault container ID"
  value       = var.enable_vault ? docker_container.vault[0].id : null
}

output "vault_container_name" {
  description = "Vault container name"
  value       = var.enable_vault ? docker_container.vault[0].name : null
}

output "vault_address" {
  description = "Vault address"
  value       = var.enable_vault ? "http://localhost:${var.vault_port}" : null
}

output "consul_container_id" {
  description = "Consul container ID"
  value       = var.enable_consul ? docker_container.consul[0].id : null
}

output "consul_container_name" {
  description = "Consul container name"
  value       = var.enable_consul ? docker_container.consul[0].name : null
}

output "consul_address" {
  description = "Consul address"
  value       = var.enable_consul ? "http://localhost:8500" : null
}

