# Vault and Consul Docker Containers Module
# Manages Vault and Consul containers using Docker provider

# Docker network (assumes it exists, or create it separately)
data "docker_network" "crice" {
  name = var.docker_network_name
}

# Vault container
resource "docker_container" "vault" {
  count = var.enable_vault ? 1 : 0

  name  = "devcontainer-vault"
  image = docker_image.vault[0].image_id

  ports {
    internal = 8200
    external = var.vault_port
  }

  env = [
    "VAULT_DEV_ROOT_TOKEN_ID=${var.vault_root_token}",
    "VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200",
    "VAULT_ADDR=http://0.0.0.0:8200"
  ]

  capabilities {
    add = ["IPC_LOCK"]
  }

  volumes {
    volume_name    = docker_volume.vault_data[0].name
    container_path = "/vault/file"
  }

  volumes {
    volume_name    = docker_volume.vault_logs[0].name
    container_path = "/vault/logs"
  }

  dynamic "volumes" {
    for_each = var.vault_config_path != "" ? [1] : []
    content {
      host_path      = abspath(var.vault_config_path)
      container_path = "/vault/config/vault.hcl"
      read_only      = true
    }
  }

  command = ["server"]

  networks_advanced {
    name = data.docker_network.crice.name
  }

  restart = "unless-stopped"

  healthcheck {
    test     = ["CMD-SHELL", "vault status || exit 0"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
    start_period = "10s"
  }
}

# Vault image
resource "docker_image" "vault" {
  count = var.enable_vault ? 1 : 0

  name = var.vault_image
}

# Vault data volume
resource "docker_volume" "vault_data" {
  count = var.enable_vault ? 1 : 0

  name = "devcontainer_vault-data"
}

# Vault logs volume
resource "docker_volume" "vault_logs" {
  count = var.enable_vault ? 1 : 0

  name = "devcontainer_vault-logs"
}

# Consul container
resource "docker_container" "consul" {
  count = var.enable_consul ? 1 : 0

  name  = "devcontainer-consul"
  image = docker_image.consul[0].image_id

  dynamic "ports" {
    for_each = var.consul_ports
    content {
      internal = ports.value.internal
      external = ports.value.external
      protocol = ports.value.protocol
    }
  }

  env = [
    "CONSUL_BIND_INTERFACE=eth0"
  ]

  command = ["agent", "-config-file=/consul/config/consul.hcl"]

  volumes {
    volume_name    = docker_volume.consul_data[0].name
    container_path = "/consul/data"
  }

  dynamic "volumes" {
    for_each = var.consul_config_path != "" ? [1] : []
    content {
      host_path      = abspath(var.consul_config_path)
      container_path = "/consul/config/consul.hcl"
      read_only      = true
    }
  }

  networks_advanced {
    name = data.docker_network.crice.name
  }

  restart = "unless-stopped"

  healthcheck {
    test     = ["CMD", "consul", "info"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
    start_period = "10s"
  }
}

# Consul image
resource "docker_image" "consul" {
  count = var.enable_consul ? 1 : 0

  name = var.consul_image
}

# Consul data volume
resource "docker_volume" "consul_data" {
  count = var.enable_consul ? 1 : 0

  name = "devcontainer_consul-data"
}

