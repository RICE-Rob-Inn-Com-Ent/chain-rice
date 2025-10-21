output "security_group_ids" {
  description = "Map of security group IDs"
  value = {
    web        = aws_security_group.web.id
    database   = aws_security_group.database.id
    kubernetes = aws_security_group.kubernetes.id
  }
}

output "web_security_group_id" {
  description = "ID of web security group"
  value       = aws_security_group.web.id
}

output "database_security_group_id" {
  description = "ID of database security group"
  value       = aws_security_group.database.id
}

output "kubernetes_security_group_id" {
  description = "ID of Kubernetes security group"
  value       = aws_security_group.kubernetes.id
}

output "kms_key_id" {
  description = "ID of KMS key"
  value       = var.enable_encryption ? aws_kms_key.main[0].id : null
}

output "kms_key_arn" {
  description = "ARN of KMS key"
  value       = var.enable_encryption ? aws_kms_key.main[0].arn : null
}

output "ec2_iam_role_arn" {
  description = "ARN of EC2 IAM role"
  value       = aws_iam_role.ec2.arn
}

output "ec2_instance_profile_name" {
  description = "Name of EC2 instance profile"
  value       = aws_iam_instance_profile.ec2.name
}

output "waf_web_acl_id" {
  description = "ID of WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].id : null
}

output "waf_web_acl_arn" {
  description = "ARN of WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null
}
