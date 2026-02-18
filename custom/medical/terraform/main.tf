terraform {
  required_version = ">= 1.9.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Docker provider for managing containers
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Local variables
locals {
  project_name  = "ceramix"
  image_tag     = var.image_tag != "" ? var.image_tag : "latest"
  build_context = "${path.module}/.."
}

# Docker image for ceramix-web
resource "docker_image" "ceramix_web" {
  name = "ceramix-web:${local.image_tag}"

  build {
    context    = local.build_context
    dockerfile = "${local.build_context}/web/Dockerfile"
    tag        = ["ceramix-web:${local.image_tag}"]
  }

  triggers = {
    # Trigger rebuild when Dockerfile changes
    dockerfile_hash = filemd5("${local.build_context}/web/Dockerfile")
    # Trigger rebuild when entrypoint changes
    entrypoint_hash = filemd5("${local.build_context}/web/entrypoint.sh")
    # Trigger rebuild when package.json changes
    package_json_hash = filemd5("${local.build_context}/web/package.json")
  }

  # Force replace on every apply to ensure latest code
  keep_locally = false
}

# Docker container for ceramix-web
resource "docker_container" "ceramix_web" {
  name  = "ceramix-web"
  image = docker_image.ceramix_web.image_id

  restart = "unless-stopped"

  # Port mapping (if needed for direct access)
  # In production, this should be removed and Traefik should be used
  dynamic "ports" {
    for_each = var.expose_ports ? [1] : []
    content {
      internal = 3002
      external = 3002
      ip       = "127.0.0.1" # Only accessible from localhost
    }
  }

  # Environment variables
  env = [
    "NODE_ENV=${var.node_env}",
    "PORT=3002",
    "NEXT_PUBLIC_APP_ID=ceramix-web",
    "NEXT_PUBLIC_BASE_URL=${var.base_url}",
    "POSTGRES_HOST=${var.postgres_host}",
    "POSTGRES_PORT=${var.postgres_port}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_DB=${var.postgres_db}",
    "DATABASE_URL=${var.database_url}",
  ]

  # Volume mounts for hot reload
  volumes {
    host_path      = "${local.build_context}/web"
    container_path = "/app/.project/ceramix/web"
  }

  volumes {
    host_path      = "${local.build_context}/../package.json"
    container_path = "/app/package.json"
    read_only      = true
  }

  volumes {
    host_path      = "${local.build_context}/../bun.lockb"
    container_path = "/app/bun.lockb"
    read_only      = true
  }

  volumes {
    volume_name    = "ceramix-web-node-modules"
    container_path = "/app/node_modules"
  }

  volumes {
    volume_name    = "ceramix-web-app-node-modules"
    container_path = "/app/.project/ceramix/web/node_modules"
  }

  volumes {
    volume_name    = "ceramix-web-next-cache"
    container_path = "/app/.project/ceramix/web/.next"
  }

  # Network
  networks_advanced {
    name = "crice"
  }

  # Extra hosts
  extra_hosts = ["host.docker.internal:host-gateway"]

  # Triggers to force recreate when image changes
  must_run = true

  # Lifecycle to always replace when image changes
  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      docker_image.ceramix_web.image_id
    ]
  }
}

# Docker volume for node_modules (preserve packages)
resource "docker_volume" "ceramix_web_node_modules" {
  name = "ceramix-web-node-modules"
}

resource "docker_volume" "ceramix_web_app_node_modules" {
  name = "ceramix-web-app-node-modules"
}

resource "docker_volume" "ceramix_web_next_cache" {
  name = "ceramix-web-next-cache"
}








