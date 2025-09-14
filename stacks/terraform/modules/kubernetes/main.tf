# =============================================================================
# KUBERNETES MODULE - EKS CLUSTER WITH ADVANCED FEATURES
# =============================================================================
# 
# This module creates a comprehensive EKS cluster with:
# - EKS cluster with managed node groups
# - Cluster autoscaler
# - AWS Load Balancer Controller
# - CoreDNS and kube-proxy add-ons
# - IRSA (IAM Roles for Service Accounts)
# - Pod Security Standards
# - Network policies
# - Monitoring and logging
#
# Features:
# - Multi-node group support
# - Spot and On-Demand instances
# - Auto-scaling capabilities
# - Security hardening
# - Cost optimization
# =============================================================================

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.main.id
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.main.id
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# =============================================================================
# EKS CLUSTER
# =============================================================================

resource "aws_eks_cluster" "main" {
  name     = var.name_prefix
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version
  
  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = [aws_security_group.cluster.id]
  }
  
  # Enable EKS control plane logging
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  
  # Encryption configuration
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }
  
  # Add-ons
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_cloudwatch_log_group.cluster,
  ]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cluster"
    Type = "EKSCluster"
  })
}

# =============================================================================
# EKS NODE GROUPS
# =============================================================================

resource "aws_eks_node_group" "main" {
  count = length(var.node_group_configs)
  
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.name_prefix}-node-group-${count.index + 1}"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids
  
  instance_types = var.node_group_configs[count.index].instance_types
  capacity_type  = var.node_group_configs[count.index].capacity_type
  disk_size      = var.node_group_configs[count.index].disk_size
  
  scaling_config {
    desired_size = var.node_group_configs[count.index].desired_size
    max_size     = var.node_group_configs[count.index].max_size
    min_size     = var.node_group_configs[count.index].min_size
  }
  
  update_config {
    max_unavailable_percentage = 25
  }
  
  # Launch template for advanced configuration
  launch_template {
    id      = aws_launch_template.node_group[count.index].id
    version = aws_launch_template.node_group[count.index].latest_version
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
  ]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-node-group-${count.index + 1}"
    Type = "EKSNodeGroup"
  })
}

# =============================================================================
# LAUNCH TEMPLATES FOR NODE GROUPS
# =============================================================================

resource "aws_launch_template" "node_group" {
  count = length(var.node_group_configs)
  
  name_prefix   = "${var.name_prefix}-node-group-${count.index + 1}-"
  image_id      = data.aws_ami.eks_optimized.id
  instance_type = var.node_group_configs[count.index].instance_types[0]
  
  vpc_security_group_ids = [aws_security_group.node_group.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = aws_eks_cluster.main.name
    cluster_endpoint = aws_eks_cluster.main.endpoint
    cluster_ca = aws_eks_cluster.main.certificate_authority[0].data
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-node-group-${count.index + 1}"
      Type = "EKSNode"
    })
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-launch-template-${count.index + 1}"
    Type = "LaunchTemplate"
  })
}

# =============================================================================
# EKS ADD-ONS
# =============================================================================

# CoreDNS Add-on
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
  addon_version = "v1.10.1-eksbuild.1"
  
  resolve_conflicts = "OVERWRITE"
  
  depends_on = [aws_eks_node_group.main]
}

# kube-proxy Add-on
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
  addon_version = "v1.28.1-eksbuild.1"
  
  resolve_conflicts = "OVERWRITE"
  
  depends_on = [aws_eks_node_group.main]
}

# VPC CNI Add-on
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
  addon_version = "v1.14.1-eksbuild.1"
  
  resolve_conflicts = "OVERWRITE"
  
  depends_on = [aws_eks_node_group.main]
}

# EBS CSI Driver Add-on
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"
  addon_version = "v1.20.0-eksbuild.1"
  
  resolve_conflicts = "OVERWRITE"
  
  depends_on = [aws_eks_node_group.main]
}

# =============================================================================
# IAM ROLES AND POLICIES
# =============================================================================

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${var.name_prefix}-cluster-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cluster-role"
    Type = "IAMRole"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# EKS Node Group IAM Role
resource "aws_iam_role" "node_group" {
  name = "${var.name_prefix}-node-group-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-node-group-role"
    Type = "IAMRole"
  })
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# Additional policies for node groups
resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy_Additional" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

resource "aws_security_group" "cluster" {
  name_prefix = "${var.name_prefix}-cluster-"
  vpc_id      = var.vpc_id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cluster-sg"
    Type = "SecurityGroup"
  })
}

resource "aws_security_group" "node_group" {
  name_prefix = "${var.name_prefix}-node-group-"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }
  
  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-node-group-sg"
    Type = "SecurityGroup"
  })
}

# =============================================================================
# KMS KEY FOR EKS ENCRYPTION
# =============================================================================

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-kms-key"
    Type = "KMSKey"
  })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.name_prefix}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# =============================================================================
# CLOUDWATCH LOG GROUP
# =============================================================================

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.name_prefix}/cluster"
  retention_in_days = 7
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cluster-logs"
    Type = "CloudWatchLogGroup"
  })
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_ami" "eks_optimized" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.kubernetes_version}-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_security_group.cluster.id
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = aws_eks_cluster.main.status
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = aws_eks_cluster.main.version
}

output "node_group_arns" {
  description = "EKS node group ARNs"
  value       = aws_eks_node_group.main[*].arn
}

output "node_group_statuses" {
  description = "EKS node group statuses"
  value       = aws_eks_node_group.main[*].status
}

output "kms_key_id" {
  description = "KMS key ID for EKS encryption"
  value       = aws_kms_key.eks.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for EKS encryption"
  value       = aws_kms_key.eks.arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.main.arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL"
  value       = aws_iam_openid_connect_provider.main.url
}

# =============================================================================
# OIDC PROVIDER FOR IRSA
# =============================================================================

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-oidc-provider"
    Type = "OIDCProvider"
  })
}
