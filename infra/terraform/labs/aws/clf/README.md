## AWS Cloud Practitioner (CLF) – Terraform Lab

Minimal lab to explore:

- global AWS concepts (regions, accounts, IAM identities)
- simple storage and compute primitives
- basic logging/monitoring hooks

### Topology

This lab is intentionally small and reuses shared modules from `../../modules`:

- VPC/networking
- IAM roles/policies
- S3 bucket for static content or logs
- optional compute (EC2 or Fargate)

### Commands

```bash
cd .devcontainer/auto/terraform/labs/aws/clf
terraform init
terraform apply -auto-approve
```

Then, inside the devcontainer:

```bash
cd .devcontainer/backend
go run ./cmd/cloudlabs/aws-lab
```

### Exam Mapping (examples)

- **Account structure & IAM basics** – see IAM roles/policies in the module composition.
- **Core services (S3, compute, databases)** – resources created by this lab.
- **Shared responsibility model & security** – IAM and logging configuration.

