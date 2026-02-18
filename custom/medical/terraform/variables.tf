variable "image_tag" {
  description = "Docker image tag for ceramix-web"
  type        = string
  default     = ""
}

variable "node_env" {
  description = "Node.js environment"
  type        = string
  default     = "development"
}

variable "base_url" {
  description = "Base URL for the application"
  type        = string
  default     = "http://ceramix.ltd"
}

variable "expose_ports" {
  description = "Whether to expose ports directly (should be false in production with Traefik)"
  type        = bool
  default     = false
}

variable "postgres_host" {
  description = "PostgreSQL host"
  type        = string
  default     = "devcontainer-postgres"
}

variable "postgres_port" {
  description = "PostgreSQL port"
  type        = string
  default     = "5432"
}

variable "postgres_user" {
  description = "PostgreSQL user"
  type        = string
  default     = "ceramix_user"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "ceramix"
}

variable "database_url" {
  description = "Full PostgreSQL connection URL"
  type        = string
  default     = ""
  sensitive   = true
}








