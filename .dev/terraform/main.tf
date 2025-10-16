# =============================================================================
# SIMPLE TERRAFORM CONFIGURATION FOR DEPENDENCY LOCKING
# =============================================================================
#
# This is a simplified Terraform configuration for locking provider dependencies
# without complex module references that require additional infrastructure.
#
# Author: Infrastructure Team
# Version: 1.0.0
# Last Updated: 2025-01-15
# =============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    # Kubernetes Provider
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }

    # Helm Provider
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }

    # Null Provider (for testing)
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    # Local Provider (for local file operations)
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }

    # Random Provider (for generating random values)
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Simple resource to test provider functionality
resource "random_id" "test" {
  byte_length = 8
}

# Output the random ID
output "random_id" {
  value = random_id.test.hex
}
