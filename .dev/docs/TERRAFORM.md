# 🏗️ Terraform Infrastructure Guide

Complete guide for infrastructure provisioning with Terraform in the Rice-Mono project.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Modules](#modules)
- [State Management](#state-management)
- [Environments](#environments)
- [Workspaces](#workspaces)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

Our Terraform setup provides:

- **Multi-Cloud Support** - AWS, Azure, GCP
- **Modular Design** - Reusable infrastructure components
- **Environment Isolation** - Dev, Staging, Production
- **State Management** - S3 backend with DynamoDB locking
- **Security** - KMS encryption, WAF, Security Groups
- **Automation** - Scripts for common operations

---

## 🏗️ Architecture

```
terraform/
├── main.tf                 # Root configuration
├── variables.tf           # Input variables
├── outputs.tf            # Output values
├── terraform.lock.hcl    # Provider lock file
│
├── backends/             # State backend configs
│   └── s3.tf            # S3 + DynamoDB backend
│
├── environments/         # Environment-specific configs
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
│
└── modules/             # Reusable modules
    ├── network/         # VPC, Subnets, Routing
    ├── security/        # Security Groups, IAM, KMS
    ├── compute/         # EC2, ASG, ELB
    ├── database/        # RDS, Aurora
    ├── kubernetes/      # EKS Cluster
    ├── monitoring/      # CloudWatch, Prometheus
    ├── ci/             # CodePipeline, CodeBuild
    └── storage/        # S3, EFS, EBS
```

---

## 🚀 Quick Start

### 1. Install Terraform

```bash
# Download Terraform
wget https://releases.hashicorp.com/terraform/1.10.0/terraform_1.10.0_linux_amd64.zip
unzip terraform_1.10.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
```

### 2. Configure AWS Credentials

```bash
# Using AWS CLI
aws configure

# Or export environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"  # pragma: allowlist secret
export AWS_DEFAULT_REGION="us-west-2"
```

### 3. Initialize Terraform

```bash
cd .dev/terraform

# Initialize (download providers)
terraform init

# Initialize with backend migration
terraform init -migrate-state
```

### 4. Deploy Infrastructure

```bash
# Plan changes (dev environment)
terraform plan -var-file="environments/dev.tfvars"

# Apply changes
terraform apply -var-file="environments/dev.tfvars"

# Auto-approve (non-interactive)
terraform apply -var-file="environments/dev.tfvars" -auto-approve
```

---

## 📦 Modules

### Network Module

Creates VPC, subnets, routing, NAT gateways.

```hcl
module "network" {
  source = "./modules/network"

  name_prefix          = "rice-mono-dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = false

  tags = {
    Environment = "dev"
    Project     = "rice-mono"
  }
}
```

**Resources Created:**

- VPC with DNS support
- Internet Gateway
- Public & Private Subnets
- NAT Gateways (multi-AZ or single)
- Route Tables
- VPC Flow Logs (optional)

### Security Module

Creates security groups, IAM roles, KMS keys, WAF.

```hcl
module "security" {
  source = "./modules/security"

  name_prefix         = "rice-mono-dev"
  vpc_id              = module.network.vpc_id
  allowed_cidr_blocks = ["10.0.0.0/8"]
  enable_encryption   = true
  enable_waf          = true

  tags = {
    Environment = "dev"
  }
}
```

**Resources Created:**

- Security Groups (Web, Database, Kubernetes)
- KMS Keys for encryption
- IAM Roles & Instance Profiles
- WAF Web ACL with rules

### Database Module

Creates RDS instances with high availability.

```hcl
module "database" {
  source = "./modules/db"

  name_prefix          = "rice-mono-dev"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15.3"
  database_name        = "rice_db"
  master_username      = "admin"
  multi_az             = false
  vpc_id               = module.network.vpc_id
  subnet_ids           = module.network.private_subnet_ids
  security_group_ids   = [module.security.database_security_group_id]

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
}
```

### Kubernetes Module

Creates EKS cluster with managed node groups.

```hcl
module "kubernetes" {
  source = "./modules/kubernetes"

  cluster_name     = "rice-mono-dev"
  cluster_version  = "1.30"
  vpc_id           = module.network.vpc_id
  subnet_ids       = module.network.private_subnet_ids

  node_groups = {
    general = {
      desired_size = 3
      max_size     = 10
      min_size     = 1
      instance_types = ["t3.medium"]
    }
  }
}
```

### CI/CD Module

Creates CodePipeline and CodeBuild projects.

```hcl
module "cicd" {
  source = "./modules/ci"

  project_name   = "rice-mono"
  repository_url = "https://github.com/rice-mono/rice-mono.git"
  branch_name    = "main"

  buildspec_path = "buildspec.yml"

  environment_variables = {
    ENVIRONMENT = "dev"
    AWS_REGION  = "us-west-2"
  }
}
```

---

## 💾 State Management

### S3 Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket         = "rice-mono-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "rice-mono-terraform-locks"
    encrypt        = true
    kms_key_id     = "alias/terraform-state"
  }
}
```

### Initialize Backend

```bash
# First-time setup - create S3 bucket and DynamoDB table
cd backends
terraform init
terraform apply

# Then configure backend in main config
cd ..
terraform init -migrate-state
```

### State Commands

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show module.network.aws_vpc.main

# Move resource in state
terraform state mv aws_instance.old aws_instance.new

# Remove resource from state
terraform state rm aws_instance.unused

# Pull remote state
terraform state pull > terraform.tfstate.backup

# Push local state
terraform state push terraform.tfstate
```

---

## 🌍 Environments

### Environment-Specific Variables

**Dev Environment:**

```hcl
# environments/dev.tfvars
environment          = "dev"
vpc_cidr             = "10.0.0.0/16"
db_instance_class    = "db.t3.micro"
multi_az             = false
```

**Staging Environment:**

```hcl
# environments/staging.tfvars
environment          = "staging"
vpc_cidr             = "10.1.0.0/16"
db_instance_class    = "db.t3.small"
multi_az             = true
```

**Production Environment:**

```hcl
# environments/prod.tfvars
environment          = "prod"
vpc_cidr             = "10.2.0.0/16"
db_instance_class    = "db.r6g.large"
multi_az             = true
```

### Deploying to Different Environments

```bash
# Development
terraform workspace select dev
terraform apply -var-file="environments/dev.tfvars"

# Staging
terraform workspace select staging
terraform apply -var-file="environments/staging.tfvars"

# Production
terraform workspace select prod
terraform apply -var-file="environments/prod.tfvars"
```

---

## 🔄 Workspaces

Terraform workspaces allow multiple state files.

### Workspace Commands

```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new staging

# Select workspace
terraform workspace select dev

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete old-env
```

### Using Workspaces in Configuration

```hcl
locals {
  environment = terraform.workspace

  # Environment-specific configs
  instance_type = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.large"
  }
}

resource "aws_instance" "app" {
  instance_type = local.instance_type[local.environment]
}
```

---

## ✅ Best Practices

### 1. Use Modules

**✅ Good:**

```hcl
module "vpc" {
  source = "./modules/network"

  vpc_cidr = var.vpc_cidr
  name     = var.project_name
}
```

**❌ Bad:**

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
# ... 50 more resources
```

### 2. Pin Provider Versions

```hcl
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Lock to major version
    }
  }
}
```

### 3. Use Variables and Outputs

```hcl
# Input variables
variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}
```

### 4. Organize with Locals

```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

### 5. Use Data Sources

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

### 6. Validate Before Apply

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Security scan (tfsec)
tfsec .

# Plan with output
terraform plan -out=tfplan

# Apply from plan
terraform apply tfplan
```

---

## 🔍 Troubleshooting

### Common Issues

#### State Lock Error

```bash
# Error: Error acquiring the state lock
# Solution: Force unlock (use with caution)
terraform force-unlock <lock-id>
```

#### Provider Plugin Issues

```bash
# Clear plugin cache
rm -rf .terraform
terraform init -upgrade
```

#### Resource Already Exists

```bash
# Import existing resource
terraform import aws_vpc.main vpc-12345678

# Or remove from state
terraform state rm aws_vpc.main
```

#### Dependency Errors

```hcl
# Add explicit dependency
resource "aws_instance" "app" {
  # ...

  depends_on = [aws_vpc.main]
}
```

### Debug Mode

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log

# Run command
terraform apply

# Disable debug
unset TF_LOG
unset TF_LOG_PATH
```

### Drift Detection

```bash
# Check for drift
terraform plan -refresh-only

# Show differences
terraform show

# Refresh state
terraform refresh
```

---

## 🔐 Security

### Secrets Management

**Never commit secrets!**

```hcl
# ❌ Bad
variable "database_password" {
  default = "my-secret-password"
}

# ✅ Good - Use AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/database/password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

### Sensitive Outputs

```hcl
output "database_password" {
  value     = aws_db_instance.main.password
  sensitive = true  # Won't show in console
}
```

### State Encryption

```hcl
terraform {
  backend "s3" {
    bucket     = "terraform-state"
    key        = "terraform.tfstate"
    region     = "us-west-2"
    encrypt    = true
    kms_key_id = "alias/terraform-state"
  }
}
```

---

## 📚 Additional Resources

### Documentation

- [Terraform Official Docs](https://www.terraform.io/docs/)
- [AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

### Useful Commands Reference

```bash
# Formatting
terraform fmt -recursive
terraform fmt -check

# Validation
terraform validate
terraform validate -json

# Planning
terraform plan
terraform plan -out=tfplan
terraform plan -target=module.network

# Applying
terraform apply
terraform apply -auto-approve
terraform apply tfplan

# Destroying
terraform destroy
terraform destroy -target=module.database

# Outputs
terraform output
terraform output vpc_id
terraform output -json

# Graphing
terraform graph | dot -Tsvg > graph.svg

# Console (REPL)
terraform console
```

---

## 🔄 Automation Scripts

Use helper scripts for common tasks:

```bash
# Switch environment
./scripts/terraform/switch-env.sh dev

# Deploy all
./scripts/terraform/deploy.sh dev

# Destroy safely
./scripts/terraform/destroy.sh dev --confirm
```

---

**For support, see the [main README](../README.md) or contact the DevOps team.**
