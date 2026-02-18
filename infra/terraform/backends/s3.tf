# S3 Backend Configuration for Terraform State
# This configuration stores Terraform state in S3 with DynamoDB locking

terraform {
  backend "s3" {
    # S3 Bucket for state storage
    bucket = "rice-mono-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "us-west-2"

    # DynamoDB table for state locking
    dynamodb_table = "rice-mono-terraform-locks"

    # Encryption
    encrypt = true

    # Versioning (managed by S3 bucket)
    # Server-side encryption
    kms_key_id = "alias/terraform-state"

    # Workspace prefix
    workspace_key_prefix = "workspaces"
  }
}

# S3 Bucket for Terraform State (create separately or via bootstrap)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "rice-mono-terraform-state"

  tags = {
    Name        = "Terraform State"
    Environment = "Global"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "rice-mono-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Locks"
    Environment = "Global"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# KMS Key for State Encryption
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "Terraform State Encryption"
    Environment = "Global"
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}
