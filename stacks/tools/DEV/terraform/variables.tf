# =============================================================================
# TERRAFORM VARIABLES CONFIGURATION
# =============================================================================
# 
# This file defines all input variables for the Terraform configuration.
# Variables are organized by category for better maintainability.
#
# Author: Infrastructure Team
# Version: 2.0.0
# Last Updated: 2024-01-15
# =============================================================================

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "rice-dev"
  
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 20
    error_message = "Project name must be between 1 and 20 characters long."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "cost_center" {
  description = "Cost center for billing and resource tagging"
  type        = string
  default     = "engineering"
}

variable "compliance_level" {
  description = "Compliance level for security and governance"
  type        = string
  default     = "standard"
  
  validation {
    condition     = contains(["basic", "standard", "high", "critical"], var.compliance_level)
    error_message = "Compliance level must be one of: basic, standard, high, critical."
  }
}

# =============================================================================
# AWS CONFIGURATION
# =============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = false
}

variable "key_pair_name" {
  description = "Name of the AWS key pair for EC2 instances"
  type        = string
  default     = ""
  
  validation {
    condition     = var.key_pair_name == "" || can(regex("^[a-zA-Z0-9-]+$", var.key_pair_name))
    error_message = "Key pair name must be alphanumeric with hyphens only."
  }
}

# =============================================================================
# AZURE CONFIGURATION
# =============================================================================

variable "azure_location" {
  description = "Azure region for resources"
  type        = string
  default     = "West US 2"
}

variable "azure_resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = ""
}

# =============================================================================
# GOOGLE CLOUD CONFIGURATION
# =============================================================================

variable "gcp_project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = ""
  
  validation {
    condition     = var.gcp_project_id == "" || can(regex("^[a-z0-9-]+$", var.gcp_project_id))
    error_message = "GCP Project ID must be lowercase alphanumeric with hyphens only."
  }
}

variable "gcp_region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-west2"
}

# =============================================================================
# KUBERNETES CONFIGURATION
# =============================================================================

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
  
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Kubernetes version must be in format X.Y (e.g., 1.28)."
  }
}

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 1000
    error_message = "Database allocated storage must be between 20 and 1000 GB."
  }
}

variable "db_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "13.7"
}

# =============================================================================
# MONITORING CONFIGURATION
# =============================================================================

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "monitoring_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
  
  validation {
    condition     = var.monitoring_retention_days >= 1 && var.monitoring_retention_days <= 3653
    error_message = "Monitoring retention must be between 1 and 3653 days."
  }
}

# =============================================================================
# CI/CD CONFIGURATION
# =============================================================================

variable "repository_url" {
  description = "Git repository URL for CI/CD pipeline"
  type        = string
  default     = ""
  
  validation {
    condition     = var.repository_url == "" || can(regex("^https://.*\\.git$", var.repository_url))
    error_message = "Repository URL must be a valid HTTPS Git URL ending with .git."
  }
}

variable "branch_name" {
  description = "Git branch name for deployment"
  type        = string
  default     = "main"
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access resources"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition     = length(var.allowed_cidr_blocks) > 0
    error_message = "At least one CIDR block must be specified."
  }
}

variable "enable_encryption" {
  description = "Enable encryption for all resources"
  type        = bool
  default     = true
}

# =============================================================================
# TAGS CONFIGURATION
# =============================================================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# FEATURE FLAGS
# =============================================================================

variable "enable_kubernetes" {
  description = "Enable Kubernetes cluster deployment"
  type        = bool
  default     = true
}

variable "enable_database" {
  description = "Enable RDS database deployment"
  type        = bool
  default     = true
}

variable "enable_monitoring_stack" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = false
}

variable "enable_cicd_pipeline" {
  description = "Enable CI/CD pipeline deployment"
  type        = bool
  default     = false
}
