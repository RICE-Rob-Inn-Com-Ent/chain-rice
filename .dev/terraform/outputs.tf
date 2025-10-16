# =============================================================================
# TERRAFORM OUTPUTS CONFIGURATION
# =============================================================================
#
# This file defines all output values for the Terraform configuration.
# Outputs are organized by category for better maintainability.
#
# Author: Infrastructure Team
# Version: 2.0.0
# Last Updated: 2024-01-15
# =============================================================================

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

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.networking.nat_gateway_ids
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

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = module.security.database_security_group_id
}

# =============================================================================
# COMPUTE OUTPUTS
# =============================================================================

output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = module.compute.asg_id
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = module.compute.launch_template_id
}

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = module.compute.instance_ids
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = module.compute.load_balancer_dns
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
  description = "RDS database name"
  value       = module.database.db_name
}

output "db_username" {
  description = "RDS master username"
  value       = module.database.db_username
  sensitive   = true
}

# =============================================================================
# KUBERNETES OUTPUTS
# =============================================================================

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

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.kubernetes.cluster_arn
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = module.kubernetes.cluster_version
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = module.kubernetes.node_group_arn
}

# =============================================================================
# MONITORING OUTPUTS
# =============================================================================

output "monitoring_dashboard_url" {
  description = "URL of the monitoring dashboard"
  value       = module.monitoring.dashboard_url
}

output "prometheus_endpoint" {
  description = "Prometheus endpoint URL"
  value       = module.monitoring.prometheus_endpoint
}

output "grafana_endpoint" {
  description = "Grafana endpoint URL"
  value       = module.monitoring.grafana_endpoint
}

# =============================================================================
# CI/CD OUTPUTS
# =============================================================================

output "pipeline_url" {
  description = "URL of the CI/CD pipeline"
  value       = module.cicd.pipeline_url
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = module.cicd.codebuild_project_name
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.cicd.codepipeline_name
}

# =============================================================================
# GENERAL OUTPUTS
# =============================================================================

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

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.availability_zones
}

output "name_prefix" {
  description = "Common name prefix used for resources"
  value       = local.name_prefix
}

# =============================================================================
# CONNECTION INFORMATION
# =============================================================================

output "ssh_connection_command" {
  description = "SSH command to connect to instances"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@<instance-ip>"
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.kubernetes.cluster_id}"
}

# =============================================================================
# COST AND BILLING
# =============================================================================

output "estimated_monthly_cost" {
  description = "Estimated monthly cost for the infrastructure"
  value       = "See AWS Cost Explorer for detailed breakdown"
}

output "cost_center" {
  description = "Cost center for billing"
  value       = var.cost_center
}
