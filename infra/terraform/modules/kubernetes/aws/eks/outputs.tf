# =============================================================================
# EKS MODULE OUTPUTS
# =============================================================================

output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_oidc_provider_arn" {
  description = "ARN of the OIDC Provider if EKS was created with OIDC support"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_security_group.node.id
}

output "node_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = aws_iam_role.node.arn
}

output "kms_key_id" {
  description = "KMS key ID used for encryption"
  value       = var.kms_key_id != "" ? var.kms_key_id : aws_kms_key.eks[0].arn
}

output "kubeconfig" {
  description = "Kubeconfig file content"
  value = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = aws_eks_cluster.main.name
      cluster = {
        certificate-authority-data = aws_eks_cluster.main.certificate_authority[0].data
        server                     = aws_eks_cluster.main.endpoint
      }
    }]
    contexts = [{
      name = aws_eks_cluster.main.name
      context = {
        cluster = aws_eks_cluster.main.name
        user    = aws_eks_cluster.main.name
      }
    }]
    "current-context" = aws_eks_cluster.main.name
    users = [{
      name = aws_eks_cluster.main.name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            aws_eks_cluster.main.name
          ]
        }
      }
    }]
  })
  sensitive = true
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler (IRSA)"
  value       = aws_iam_role.cluster_autoscaler.arn
}

