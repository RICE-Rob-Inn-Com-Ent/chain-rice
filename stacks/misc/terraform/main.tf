# =============================================================================
# INFRASTRUCTURE AS CODE - ADVANCED TERRAFORM CONFIGURATION
# =============================================================================
# 
# This is a comprehensive, production-ready Terraform configuration that
# demonstrates advanced Infrastructure as Code practices including:
# - Multi-environment support (dev, staging, prod)
# - Multi-cloud deployment (AWS, Azure, GCP)
# - Kubernetes orchestration
# - High-availability databases
# - Monitoring and observability
# - Security and compliance
# - CI/CD pipeline infrastructure
#
# Author: Infrastructure Team
# Version: 2.0.0
# Last Updated: 2024-01-15
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    # AWS Provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    # Azure Provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    
    # Google Cloud Provider
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    
    # Kubernetes Provider
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    
    # Helm Provider
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    
    # Random Provider
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    
    # Local Provider
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    
    # Null Provider
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
  
  # Remote State Configuration
  backend "s3" {
    # Configured via environment variables or backend config
    # bucket         = "terraform-state-bucket"
    # key            = "infrastructure/terraform.tfstate"
    # region         = "us-west-2"
    # encrypt        = true
    # dynamodb_table = "terraform-state-lock"
  }
}

# =============================================================================
# PROVIDER CONFIGURATIONS
# =============================================================================

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment   = var.environment
      Project       = var.project_name
      ManagedBy     = "Terraform"
      CreatedBy     = "Infrastructure Team"
      CostCenter    = var.cost_center
      Compliance    = var.compliance_level
    }
  }
}

# Azure Provider Configuration
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Google Cloud Provider Configuration
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  # Configuration will be set dynamically based on the cloud provider
  config_path = var.kubeconfig_path
}

# Helm Provider Configuration
provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Get current AWS caller identity
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-lts-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# LOCAL VALUES
# =============================================================================

locals {
  # Common naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Common tags
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "Terraform"
    CreatedBy     = "Infrastructure Team"
    CostCenter    = var.cost_center
    Compliance    = var.compliance_level
    LastModified  = timestamp()
  }
  
  # Environment-specific configurations
  environment_config = {
    dev = {
      instance_type     = "t3.medium"
      min_size         = 1
      max_size         = 3
      desired_capacity  = 2
      multi_az         = false
      backup_retention = 7
    }
    staging = {
      instance_type     = "t3.large"
      min_size         = 2
      max_size         = 5
      desired_capacity  = 3
      multi_az         = true
      backup_retention = 14
    }
    prod = {
      instance_type     = "t3.xlarge"
      min_size         = 3
      max_size         = 10
      desired_capacity  = 5
      multi_az         = true
      backup_retention = 30
    }
  }
  
  current_config = local.environment_config[var.environment]
  
  # Availability zones for multi-AZ deployment
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.multi_az ? 3 : 1)
}

# =============================================================================
# RANDOM RESOURCES
# =============================================================================

# Generate random password for database
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Generate random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# =============================================================================
# MODULE CALLS
# =============================================================================

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  # Input variables
  name_prefix        = local.name_prefix
  vpc_cidr          = var.vpc_cidr
  availability_zones = local.availability_zones
  environment        = var.environment
  project_name       = var.project_name
  
  # Tags
  tags = local.common_tags
  
  depends_on = []
}

# Security Module
module "security" {
  source = "./modules/security"
  
  # Input variables
  name_prefix = local.name_prefix
  vpc_id      = module.networking.vpc_id
  environment = var.environment
  
  # Tags
  tags = local.common_tags
  
  depends_on = [module.networking]
}

# Compute Module (EC2/ECS/EKS)
module "compute" {
  source = "./modules/compute"
  
  # Input variables
  name_prefix           = local.name_prefix
  vpc_id               = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  public_subnet_ids     = module.networking.public_subnet_ids
  security_group_ids   = module.security.security_group_ids
  environment          = var.environment
  instance_type        = local.current_config.instance_type
  min_size             = local.current_config.min_size
  max_size             = local.current_config.max_size
  desired_capacity     = local.current_config.desired_capacity
  key_pair_name        = var.key_pair_name
  ami_id               = data.aws_ami.amazon_linux.id
  
  # Tags
  tags = local.common_tags
  
  depends_on = [module.networking, module.security]
}

# Database Module
module "database" {
  source = "./modules/database"
  
  # Input variables
  name_prefix        = local.name_prefix
  vpc_id            = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_ids = module.security.security_group_ids
  environment        = var.environment
  multi_az          = local.current_config.multi_az
  backup_retention  = local.current_config.backup_retention
  db_password       = random_password.db_password.result
  
  # Tags
  tags = local.common_tags
  
  depends_on = [module.networking, module.security]
}

# Kubernetes Module
module "kubernetes" {
  source = "./modules/kubernetes"
  
  # Input variables
  name_prefix        = local.name_prefix
  vpc_id            = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
  environment        = var.environment
  node_group_config  = local.current_config
  
  # Tags
  tags = local.common_tags
  
  depends_on = [module.networking, module.security]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  # Input variables
  name_prefix = local.name_prefix
  environment = var.environment
  cluster_id  = module.kubernetes.cluster_id
  
  # Tags
  tags = local.common_tags
  
  depends_on = [module.kubernetes]
}

# CI/CD Module
module "cicd" {
  source = "./modules/cicd"
  
  # Input variables
  name_prefix = local.name_prefix
  environment = var.environment
  repository_url = var.repository_url
  
  # Tags
  tags = local.common_tags
  
  depends_on = [module.kubernetes]
}

# =============================================================================
# OUTPUTS
# =============================================================================

# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.networking.internet_gateway_id
}

# Security Outputs
output "security_group_ids" {
  description = "IDs of the security groups"
  value       = module.security.security_group_ids
}

# Compute Outputs
output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = module.compute.asg_id
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = module.compute.launch_template_id
}

# Database Outputs
output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "db_port" {
  description = "RDS instance port"
  value       = module.database.db_port
}

# Kubernetes Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.kubernetes.cluster_id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.kubernetes.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.kubernetes.cluster_security_group_id
}

# Monitoring Outputs
output "monitoring_dashboard_url" {
  description = "URL of the monitoring dashboard"
  value       = module.monitoring.dashboard_url
}

# CI/CD Outputs
output "pipeline_url" {
  description = "URL of the CI/CD pipeline"
  value       = module.cicd.pipeline_url
}

# General Outputs
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}
