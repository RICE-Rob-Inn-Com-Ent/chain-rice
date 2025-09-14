# =============================================================================
# TERRAFORM VARIABLES CONFIGURATION
# =============================================================================
# 
# This file contains all variable definitions for the infrastructure
# configuration. Variables are organized by category and include
# comprehensive descriptions and validation rules.
#
# Usage:
#   terraform plan -var-file="dev.tfvars"
#   terraform apply -var-file="prod.tfvars"
# =============================================================================

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "advanced-infra"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.project_name))
    error_message = "Project name must start with a letter and contain only alphanumeric characters and hyphens."
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
  description = "Cost center for billing and resource tracking"
  type        = string
  default     = "engineering"
}

variable "compliance_level" {
  description = "Compliance level (basic, standard, high)"
  type        = string
  default     = "standard"
  
  validation {
    condition     = contains(["basic", "standard", "high"], var.compliance_level)
    error_message = "Compliance level must be one of: basic, standard, high."
  }
}

# =============================================================================
# CLOUD PROVIDER CONFIGURATION
# =============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
  
  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1",
      "ap-southeast-1", "ap-southeast-2", "ap-northeast-1",
      "ca-central-1", "sa-east-1"
    ], var.aws_region)
    error_message = "AWS region must be a valid AWS region."
  }
}

variable "gcp_project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-central1"
}

variable "azure_location" {
  description = "Azure location/region"
  type        = string
  default     = "East US"
}

# =============================================================================
# NETWORKING CONFIGURATION
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

variable "multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = true
}

# =============================================================================
# COMPUTE CONFIGURATION
# =============================================================================

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1
  
  validation {
    condition     = var.min_size >= 0
    error_message = "Minimum size must be non-negative."
  }
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_size >= var.min_size
    error_message = "Maximum size must be greater than or equal to minimum size."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 2
  
  validation {
    condition     = var.desired_capacity >= var.min_size && var.desired_capacity <= var.max_size
    error_message = "Desired capacity must be between minimum and maximum size."
  }
}

variable "key_pair_name" {
  description = "Name of the AWS key pair"
  type        = string
  default     = ""
}

variable "enable_spot_instances" {
  description = "Enable spot instances for cost optimization"
  type        = bool
  default     = false
}

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
  
  validation {
    condition     = contains(["postgres", "mysql", "mariadb", "oracle-ee", "sqlserver-ee"], var.db_engine)
    error_message = "Database engine must be one of: postgres, mysql, mariadb, oracle-ee, sqlserver-ee."
  }
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.4"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Database master password (if not provided, random password will be generated)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_allocated_storage" {
  description = "Allocated storage for database (GB)"
  type        = number
  default     = 20
  
  validation {
    condition     = var.db_allocated_storage >= 20
    error_message = "Database allocated storage must be at least 20 GB."
  }
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for database (GB)"
  type        = number
  default     = 100
}

variable "db_backup_retention_period" {
  description = "Database backup retention period (days)"
  type        = number
  default     = 7
  
  validation {
    condition     = var.db_backup_retention_period >= 1 && var.db_backup_retention_period <= 35
    error_message = "Database backup retention period must be between 1 and 35 days."
  }
}

variable "db_backup_window" {
  description = "Database backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Database maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "db_multi_az" {
  description = "Enable multi-AZ deployment for database"
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Enable deletion protection for database"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when deleting database"
  type        = bool
  default     = false
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
}

variable "node_group_instance_types" {
  description = "Instance types for EKS node groups"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "node_group_capacity_type" {
  description = "Capacity type for EKS node groups (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
  
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_group_capacity_type)
    error_message = "Node group capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "node_group_disk_size" {
  description = "Disk size for EKS node groups (GB)"
  type        = number
  default     = 50
  
  validation {
    condition     = var.node_group_disk_size >= 20
    error_message = "Node group disk size must be at least 20 GB."
  }
}

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = true
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

# =============================================================================
# MONITORING CONFIGURATION
# =============================================================================

variable "enable_monitoring" {
  description = "Enable comprehensive monitoring"
  type        = bool
  default     = true
}

variable "monitoring_retention_days" {
  description = "CloudWatch log retention period (days)"
  type        = number
  default     = 30
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 3653], var.monitoring_retention_days)
    error_message = "Monitoring retention days must be a valid CloudWatch retention period."
  }
}

variable "enable_prometheus" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

variable "enable_grafana" {
  description = "Enable Grafana dashboards"
  type        = bool
  default     = true
}

variable "enable_elk_stack" {
  description = "Enable ELK (Elasticsearch, Logstash, Kibana) stack"
  type        = bool
  default     = false
}

variable "enable_jaeger" {
  description = "Enable Jaeger distributed tracing"
  type        = bool
  default     = false
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

variable "enable_waf" {
  description = "Enable AWS WAF"
  type        = bool
  default     = true
}

variable "enable_shield" {
  description = "Enable AWS Shield"
  type        = bool
  default     = false
}

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable AWS CloudTrail"
  type        = bool
  default     = true
}

variable "enable_secrets_manager" {
  description = "Enable AWS Secrets Manager"
  type        = bool
  default     = true
}

variable "enable_kms" {
  description = "Enable AWS KMS encryption"
  type        = bool
  default     = true
}

# =============================================================================
# CI/CD CONFIGURATION
# =============================================================================

variable "repository_url" {
  description = "Git repository URL for CI/CD pipeline"
  type        = string
  default     = ""
}

variable "enable_codepipeline" {
  description = "Enable AWS CodePipeline"
  type        = bool
  default     = true
}

variable "enable_codebuild" {
  description = "Enable AWS CodeBuild"
  type        = bool
  default     = true
}

variable "enable_codedeploy" {
  description = "Enable AWS CodeDeploy"
  type        = bool
  default     = true
}

variable "build_timeout" {
  description = "CodeBuild timeout in minutes"
  type        = number
  default     = 60
  
  validation {
    condition     = var.build_timeout >= 5 && var.build_timeout <= 480
    error_message = "Build timeout must be between 5 and 480 minutes."
  }
}

# =============================================================================
# BACKUP AND DISASTER RECOVERY
# =============================================================================

variable "enable_backup" {
  description = "Enable AWS Backup"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention period (days)"
  type        = number
  default     = 30
  
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention days must be between 1 and 365 days."
  }
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup"
  type        = bool
  default     = false
}

variable "backup_region" {
  description = "Region for cross-region backup"
  type        = string
  default     = "us-east-1"
}

# =============================================================================
# COST OPTIMIZATION
# =============================================================================

variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = true
}

variable "enable_scheduled_scaling" {
  description = "Enable scheduled scaling for cost optimization"
  type        = bool
  default     = true
}

variable "enable_rightsizing_recommendations" {
  description = "Enable rightsizing recommendations"
  type        = bool
  default     = true
}

# =============================================================================
# FEATURE FLAGS
# =============================================================================

variable "enable_feature_flags" {
  description = "Enable feature flags system"
  type        = bool
  default     = false
}

variable "enable_service_mesh" {
  description = "Enable service mesh (Istio)"
  type        = bool
  default     = false
}

variable "enable_gitops" {
  description = "Enable GitOps workflow"
  type        = bool
  default     = false
}

variable "enable_chaos_engineering" {
  description = "Enable chaos engineering tools"
  type        = bool
  default     = false
}

# =============================================================================
# COMPLIANCE AND GOVERNANCE
# =============================================================================

variable "enable_compliance_reporting" {
  description = "Enable compliance reporting"
  type        = bool
  default     = true
}

variable "enable_resource_tagging_policy" {
  description = "Enable resource tagging policy"
  type        = bool
  default     = true
}

variable "enable_budget_alerts" {
  description = "Enable budget alerts"
  type        = bool
  default     = true
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 1000
  
  validation {
    condition     = var.monthly_budget_limit > 0
    error_message = "Monthly budget limit must be greater than 0."
  }
}
