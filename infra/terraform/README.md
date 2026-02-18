# Terraform Configuration

## Usage

Terraform variables are loaded from environment variables. Set these before running:

```bash
export PROJECT_SLUG=code-rice
export TF_VAR_project_name=${PROJECT_SLUG}
export TF_VAR_environment=dev
export TF_VAR_aws_region=${AWS_DEFAULT_REGION:-us-east-1}
```

Or use `terraform.tfvars`:

```hcl
project_name = "code-rice"
environment = "dev"
aws_region = "us-east-1"
```

## Required Environment Variables

- `PROJECT_SLUG` - Project identifier (used as default for project_name)
- `TF_VAR_project_name` - Terraform project name (defaults to PROJECT_SLUG)
- `TF_VAR_environment` - Environment (dev/staging/prod)
- `AWS_DEFAULT_REGION` - AWS region
- `AWS_PROFILE` or `AWS_ACCESS_KEY_ID` - AWS credentials

