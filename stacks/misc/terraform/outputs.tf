# =============================================================================
# TERRAFORM OUTPUTS CONFIGURATION
# =============================================================================
# 
# This file contains all output definitions for the infrastructure
# configuration. Outputs are organized by category and include
# comprehensive descriptions.
# =============================================================================

# =============================================================================
# GENERAL OUTPUTS
# =============================================================================

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

# =============================================================================
# NETWORKING OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = module.networking.vpc_arn
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.networking.database_subnet_ids
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = module.networking.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = module.networking.private_subnet_cidrs
}

output "database_subnet_cidrs" {
  description = "CIDR blocks of the database subnets"
  value       = module.networking.database_subnet_cidrs
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.networking.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.networking.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = module.networking.nat_gateway_public_ips
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.networking.public_route_table_id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = module.networking.private_route_table_ids
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = module.networking.database_route_table_id
}

output "db_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = module.networking.db_subnet_group_name
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = module.networking.availability_zones
}

output "vpc_endpoint_ids" {
  description = "IDs of the VPC endpoints"
  value       = module.networking.vpc_endpoint_ids
}

# =============================================================================
# SECURITY OUTPUTS
# =============================================================================

output "security_group_ids" {
  description = "IDs of the security groups"
  value       = module.security.security_group_ids
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.security.web_security_group_id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = module.security.app_security_group_id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = module.security.db_security_group_id
}

output "monitoring_security_group_id" {
  description = "ID of the monitoring security group"
  value       = module.security.monitoring_security_group_id
}

# =============================================================================
# COMPUTE OUTPUTS
# =============================================================================

output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = module.compute.asg_id
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.compute.asg_arn
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = module.compute.launch_template_id
}

output "launch_template_arn" {
  description = "ARN of the Launch Template"
  value       = module.compute.launch_template_arn
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.compute.load_balancer_arn
}

output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.load_balancer_dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.compute.load_balancer_zone_id
}

output "target_group_arns" {
  description = "ARNs of the target groups"
  value       = module.compute.target_group_arns
}

# =============================================================================
# DATABASE OUTPUTS
# =============================================================================

output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "db_port" {
  description = "RDS instance port"
  value       = module.database.db_port
}

output "db_name" {
  description = "RDS instance database name"
  value       = module.database.db_name
}

output "db_username" {
  description = "RDS instance master username"
  value       = module.database.db_username
  sensitive   = true
}

output "db_arn" {
  description = "RDS instance ARN"
  value       = module.database.db_arn
}

output "db_identifier" {
  description = "RDS instance identifier"
  value       = module.database.db_identifier
}

output "db_instance_class" {
  description = "RDS instance class"
  value       = module.database.db_instance_class
}

output "db_engine" {
  description = "RDS instance engine"
  value       = module.database.db_engine
}

output "db_engine_version" {
  description = "RDS instance engine version"
  value       = module.database.db_engine_version
}

output "db_allocated_storage" {
  description = "RDS instance allocated storage"
  value       = module.database.db_allocated_storage
}

output "db_backup_retention_period" {
  description = "RDS instance backup retention period"
  value       = module.database.db_backup_retention_period
}

output "db_multi_az" {
  description = "RDS instance multi-AZ deployment"
  value       = module.database.db_multi_az
}

output "db_deletion_protection" {
  description = "RDS instance deletion protection"
  value       = module.database.db_deletion_protection
}

# =============================================================================
# KUBERNETES OUTPUTS
# =============================================================================

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.kubernetes.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.kubernetes.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.kubernetes.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.kubernetes.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.kubernetes.cluster_certificate_authority_data
}

output "cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = module.kubernetes.cluster_platform_version
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = module.kubernetes.cluster_status
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = module.kubernetes.cluster_version
}

output "node_group_arns" {
  description = "EKS node group ARNs"
  value       = module.kubernetes.node_group_arns
}

output "node_group_statuses" {
  description = "EKS node group statuses"
  value       = module.kubernetes.node_group_statuses
}

output "kms_key_id" {
  description = "KMS key ID for EKS encryption"
  value       = module.kubernetes.kms_key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for EKS encryption"
  value       = module.kubernetes.kms_key_arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = module.kubernetes.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL"
  value       = module.kubernetes.oidc_provider_url
}

# =============================================================================
# MONITORING OUTPUTS
# =============================================================================

output "prometheus_url" {
  description = "Prometheus server URL"
  value       = module.monitoring.prometheus_url
}

output "grafana_url" {
  description = "Grafana server URL"
  value       = module.monitoring.grafana_url
}

output "grafana_password" {
  description = "Grafana admin password"
  value       = module.monitoring.grafana_password
  sensitive   = true
}

output "kibana_url" {
  description = "Kibana server URL"
  value       = module.monitoring.kibana_url
}

output "jaeger_url" {
  description = "Jaeger UI URL"
  value       = module.monitoring.jaeger_url
}

output "elasticsearch_endpoints" {
  description = "Elasticsearch cluster endpoints"
  value       = module.monitoring.elasticsearch_endpoints
}

output "logstash_endpoint" {
  description = "Logstash endpoint"
  value       = module.monitoring.logstash_endpoint
}

output "dashboard_url" {
  description = "Main monitoring dashboard URL"
  value       = module.monitoring.dashboard_url
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = module.monitoring.cloudwatch_log_group_name
}

# =============================================================================
# CI/CD OUTPUTS
# =============================================================================

output "pipeline_url" {
  description = "URL of the CI/CD pipeline"
  value       = module.cicd.pipeline_url
}

output "pipeline_arn" {
  description = "ARN of the CI/CD pipeline"
  value       = module.cicd.pipeline_arn
}

output "pipeline_name" {
  description = "Name of the CI/CD pipeline"
  value       = module.cicd.pipeline_name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  value       = module.cicd.codebuild_project_arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = module.cicd.codebuild_project_name
}

output "codedeploy_application_arn" {
  description = "ARN of the CodeDeploy application"
  value       = module.cicd.codedeploy_application_arn
}

output "codedeploy_application_name" {
  description = "Name of the CodeDeploy application"
  value       = module.cicd.codedeploy_application_name
}

# =============================================================================
# SUMMARY OUTPUTS
# =============================================================================

output "infrastructure_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    environment = var.environment
    region      = var.aws_region
    vpc_id      = module.networking.vpc_id
    cluster_id  = module.kubernetes.cluster_id
    db_endpoint = module.database.db_endpoint
    monitoring  = module.monitoring.dashboard_url
    cicd        = module.cicd.pipeline_url
  }
}

output "access_urls" {
  description = "URLs for accessing various services"
  value = {
    grafana     = module.monitoring.grafana_url
    kibana      = module.monitoring.kibana_url
    jaeger      = module.monitoring.jaeger_url
    prometheus  = module.monitoring.prometheus_url
    load_balancer = module.compute.load_balancer_dns_name
  }
}

output "connection_info" {
  description = "Information for connecting to the infrastructure"
  value = {
    kubectl_config = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.kubernetes.cluster_id}"
    database_connection = "psql -h ${module.database.db_endpoint} -U ${module.database.db_username} -d ${module.database.db_name}"
    ssh_access = "ssh -i ${var.key_pair_name}.pem ec2-user@<instance-ip>"
  }
  sensitive = true
}
