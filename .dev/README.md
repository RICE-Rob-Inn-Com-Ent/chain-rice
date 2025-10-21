# 🚀 DevOps Infrastructure & Automation Suite

> **Professional-grade infrastructure automation for the Rice-Mono project**
> Automated deployment, configuration, and orchestration across all environments

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Prerequisites](#prerequisites)
- [Ansible Automation](#ansible-automation)
- [Kubernetes Orchestration](#kubernetes-orchestration)
- [Terraform Infrastructure](#terraform-infrastructure)
- [Automation Scripts](#automation-scripts)
- [Adding New Projects](#adding-new-projects)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This directory contains the complete DevOps infrastructure stack for Rice-Mono, providing:

- **Infrastructure as Code (IaC)** with Terraform
- **Configuration Management** with Ansible
- **Container Orchestration** with Kubernetes/Helm
- **Full Automation** for project onboarding
- **Multi-Cloud Support** (AWS, Azure, GCP)
- **GitOps Integration** with ArgoCD

### Key Features

✅ **One-Command Deployment** - Deploy entire infrastructure with a single command
✅ **Multi-Environment Support** - Dev, Staging, Production configurations
✅ **Auto-Scaling** - Automatic resource scaling based on demand
✅ **Security Hardened** - Best practices for secrets, RBAC, and network policies
✅ **Monitoring Built-in** - Prometheus, Grafana, ELK stack integration
✅ **CI/CD Ready** - GitHub Actions, ArgoCD pipelines

---

## 🚀 Quick Start

### 1. Setup Environment

```bash
# Initialize all components
make dev-init

# Or manually:
cd .dev
./scripts/setup.sh
```

### 2. Deploy Infrastructure

```bash
# Deploy everything
make dev-deploy

# Or step by step:
cd .dev
./scripts/deploy-all.sh --env dev
```

### 3. Add New Project

```bash
# Automated project onboarding
./scripts/add-project.sh --name my-service --type backend

# Interactive mode
./scripts/add-project.sh --interactive
```

---

## 📁 Directory Structure

```
.dev/
├── ansible/                    # Configuration Management
│   ├── playbooks/             # Ansible playbooks
│   ├── roles/                 # Reusable roles
│   ├── inventory/             # Environment inventories
│   ├── group_vars/            # Group variables
│   ├── host_vars/             # Host-specific variables
│   └── requirements.yml       # Ansible dependencies
│
├── k8s/                       # Kubernetes Manifests
│   ├── base/                  # Base configurations
│   ├── overlays/              # Environment overlays
│   ├── charts/                # Custom Helm charts
│   ├── operators/             # Kubernetes operators
│   └── templates/             # Helm templates
│
├── terraform/                 # Infrastructure as Code
│   ├── modules/               # Terraform modules
│   ├── environments/          # Environment configs
│   ├── backends/              # State backends
│   └── *.tf                   # Root configuration
│
├── scripts/                   # Automation Scripts
│   ├── setup.sh              # Initial setup
│   ├── deploy-all.sh         # Full deployment
│   ├── add-project.sh        # Add new project
│   ├── update-project.sh     # Update project
│   └── destroy.sh            # Cleanup resources
│
├── configs/                   # Configuration Files
│   ├── environments/          # Environment configs
│   ├── secrets/              # Secret templates
│   └── policies/             # Security policies
│
├── docs/                      # Documentation
│   ├── ANSIBLE.md            # Ansible guide
│   ├── KUBERNETES.md         # K8s guide
│   ├── TERRAFORM.md          # Terraform guide
│   └── WORKFLOWS.md          # Common workflows
│
└── README.md                 # This file
```

---

## 📦 Prerequisites

### Automated Installation (Recommended)

We provide automated setup scripts for all required tools:

```bash
# Install everything (Java, Node.js, kind, kubectl, helm)
./.dev/scripts/setup-all.sh

# Or install components individually:
./.dev/scripts/setup-java.sh     # Java JDK 17 for Android/Kotlin/Gradle
./.dev/scripts/setup-nodejs.sh   # Node.js 20.x LTS for frontend/SonarQube
./.dev/scripts/setup-bazel.sh    # Bazel/Bazelisk for monorepo builds
./.dev/scripts/setup-flutter.sh  # Flutter SDK for mobile development (optional)
```

### Manual Installation

If you prefer manual installation:

```bash
# Arch Linux
sudo pacman -S jdk17-openjdk nodejs npm kubectl helm terraform ansible docker
yay -S bazelisk  # From AUR

# Ubuntu/Debian
sudo apt install openjdk-17-jdk nodejs npm kubectl helm terraform ansible docker.io
# Install Bazelisk manually (see setup-bazel.sh)

# Or using Homebrew (macOS/Linux)
brew install --cask docker      # Docker Desktop
brew install kubectl            # Kubernetes CLI
brew install helm               # Helm 3
brew install terraform          # Terraform
brew install ansible            # Ansible
brew install kind               # Kubernetes in Docker
```

### Versions

| Tool      | Min Version | Recommended |
| --------- | ----------- | ----------- |
| Docker    | 24.0+       | 25.0+       |
| Kubectl   | 1.28+       | 1.30+       |
| Helm      | 3.12+       | 3.14+       |
| Terraform | 1.9+        | 1.10+       |
| Ansible   | 2.15+       | 2.17+       |

### Cloud CLI Tools (Optional)

```bash
# AWS
brew install awscli
aws configure

# Azure
brew install azure-cli
az login

# Google Cloud
brew install google-cloud-sdk
gcloud auth login
```

---

## 🔧 Ansible Automation

Ansible handles configuration management, server provisioning, and application deployment.

### Quick Commands

```bash
# Run all playbooks
cd ansible
ansible-playbook playbooks/site.yml -i inventory/dev/

# Deploy specific service
ansible-playbook playbooks/deploy-backend.yml --tags api

# Configure servers
ansible-playbook playbooks/configure-servers.yml --limit web

# Run health checks
ansible-playbook playbooks/health-check.yml
```

### Project Structure

- **playbooks/** - Main automation playbooks
- **roles/** - Reusable Ansible roles
- **inventory/** - Environment-specific inventories
- **group_vars/** - Variables for groups
- **host_vars/** - Variables for specific hosts

### Adding New Playbook

```bash
# Create from template
./scripts/ansible/create-playbook.sh --name my-playbook

# Or manually
cp ansible/playbooks/_template.yml ansible/playbooks/my-playbook.yml
```

📖 **[Full Ansible Documentation →](docs/ANSIBLE.md)**

---

## ☸️ Kubernetes Orchestration

Kubernetes configuration using Helm charts and Kustomize overlays with ArgoCD GitOps.

### Quick Commands

```bash
# Deploy to cluster
cd k8s
helm upgrade --install rice-app ./charts/rice-app -n production

# Use Kustomize overlays
kubectl apply -k overlays/dev/

# ArgoCD sync
argocd app sync rice-app --prune

# Port forward for local access
kubectl port-forward svc/rice-api 8080:80 -n dev
```

### Features

- **Helm Charts** - Templated Kubernetes manifests
- **Kustomize Overlays** - Environment-specific patches
- **ArgoCD Integration** - GitOps continuous deployment
- **Operators** - Custom resource management
- **Auto-scaling** - HPA and VPA configured
- **Monitoring** - Prometheus, Grafana dashboards

### Adding New Service

```bash
# Automated chart creation
./scripts/k8s/create-service.sh --name my-service --type deployment

# Deploy with Helm
helm upgrade --install my-service k8s/charts/my-service
```

📖 **[Full Kubernetes Documentation →](docs/KUBERNETES.md)**

---

## 🏗️ Terraform Infrastructure

Multi-cloud infrastructure provisioning with modular Terraform configuration.

### Quick Commands

```bash
# Initialize Terraform
cd terraform
terraform init

# Plan infrastructure changes
terraform plan -var-file="environments/dev.tfvars"

# Apply infrastructure
terraform apply -var-file="environments/dev.tfvars" -auto-approve

# Destroy infrastructure
terraform destroy -var-file="environments/dev.tfvars"
```

### Modules

| Module     | Description             | Status |
| ---------- | ----------------------- | ------ |
| calc       | Compute resources       | ✅     |
| db         | Database infrastructure | ✅     |
| ci         | CI/CD pipeline          | ✅     |
| job        | Batch job processing    | ✅     |
| secrets    | Secret management       | ✅     |
| trigger    | Event triggers          | ✅     |
| network    | VPC, subnets, routing   | ✅     |
| monitoring | Observability stack     | ✅     |
| security   | IAM, security groups    | ✅     |

### Environment Management

```bash
# Switch environments
./scripts/terraform/switch-env.sh dev

# Import existing resources
terraform import module.db.aws_db_instance.main db-instance-id

# State management
terraform state list
terraform state show module.calc.aws_instance.app
```

📖 **[Full Terraform Documentation →](docs/TERRAFORM.md)**

---

## 🤖 Automation Scripts

Powerful automation scripts for common operations.

### Available Scripts

#### Setup & Initialization

```bash
./scripts/setup.sh                    # Complete environment setup
./scripts/install-tools.sh            # Install required tools
./scripts/configure-cloud.sh          # Configure cloud providers
```

#### Deployment

```bash
./scripts/deploy-all.sh --env dev     # Deploy everything
./scripts/deploy-app.sh --app backend # Deploy specific app
./scripts/rollback.sh --app backend   # Rollback deployment
```

#### Project Management

```bash
./scripts/add-project.sh              # Add new project (interactive)
./scripts/update-project.sh           # Update project config
./scripts/remove-project.sh           # Remove project safely
```

#### Utilities

```bash
./scripts/health-check.sh             # System health check
./scripts/backup.sh                   # Backup configurations
./scripts/restore.sh                  # Restore from backup
./scripts/logs.sh --follow            # Stream logs
```

---

## ➕ Adding New Projects

### Automated Method (Recommended)

```bash
# Interactive wizard
./scripts/add-project.sh --interactive

# Or with parameters
./scripts/add-project.sh \
  --name my-service \
  --type backend \
  --language go \
  --port 8080 \
  --env dev,staging,prod
```

### What Gets Created

1. **Terraform Module** - Infrastructure definition
2. **Kubernetes Manifests** - Deployment, Service, Ingress
3. **Helm Chart** - Templated configuration
4. **Ansible Role** - Configuration management
5. **ArgoCD Application** - GitOps deployment
6. **CI/CD Pipeline** - Automated builds & deploys
7. **Monitoring** - Dashboards & alerts

### Manual Method

If you prefer manual configuration:

1. **Create Terraform Module**

   ```bash
   cd terraform/modules
   cp -r _template my-service
   # Edit variables, outputs, main.tf
   ```

2. **Create Helm Chart**

   ```bash
   cd k8s/charts
   helm create my-service
   # Customize templates
   ```

3. **Create Ansible Role**

   ```bash
   cd ansible/roles
   ansible-galaxy init my-service
   # Implement tasks
   ```

4. **Register in ArgoCD**
   ```bash
   kubectl apply -f k8s/argocd/my-service-app.yaml
   ```

---

## 💡 Best Practices

### Infrastructure as Code

- ✅ **Version everything** - All configs in Git
- ✅ **Use modules** - DRY principle
- ✅ **Separate environments** - Dev/Staging/Prod isolation
- ✅ **State management** - Remote state with locking
- ✅ **Secrets handling** - Never commit secrets

### Kubernetes

- ✅ **Use namespaces** - Logical separation
- ✅ **Resource limits** - Always set requests/limits
- ✅ **Health checks** - Liveness & readiness probes
- ✅ **Security context** - Run as non-root
- ✅ **Network policies** - Restrict traffic

### Ansible

- ✅ **Idempotent playbooks** - Safe to re-run
- ✅ **Use roles** - Reusable components
- ✅ **Variable precedence** - Understand order
- ✅ **Testing** - Validate with --check
- ✅ **Documentation** - Comment complex tasks

### CI/CD

- ✅ **Automated testing** - Unit, integration, e2e
- ✅ **Gradual rollout** - Canary/blue-green
- ✅ **Rollback ready** - Easy revert mechanism
- ✅ **Monitoring** - Observe deployments
- ✅ **Notifications** - Alert on failures

---

## 🔍 Troubleshooting

### Common Issues

#### Terraform State Lock

```bash
# Remove stale lock
terraform force-unlock <lock-id>

# Alternative: Use new workspace
terraform workspace new temp
```

#### Kubernetes Pod CrashLoop

```bash
# Check logs
kubectl logs <pod-name> --previous

# Describe pod
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

#### Ansible Connection Issues

```bash
# Test connectivity
ansible all -m ping -i inventory/dev/

# Debug connection
ansible-playbook playbook.yml -vvv

# Check SSH
ssh -i ~/.ssh/key.pem user@host
```

### Getting Help

1. **Check Logs**

   ```bash
   ./scripts/logs.sh --component terraform
   ./scripts/logs.sh --component ansible
   ./scripts/logs.sh --component kubernetes
   ```

2. **Run Diagnostics**

   ```bash
   ./scripts/diagnose.sh
   ```

3. **Consult Documentation**
   - [Ansible Guide](docs/ANSIBLE.md)
   - [Kubernetes Guide](docs/KUBERNETES.md)
   - [Terraform Guide](docs/TERRAFORM.md)
   - [Workflows](docs/WORKFLOWS.md)

---

## 📚 Additional Resources

### Documentation

- [Architecture Overview](../.doc/docs/ARCHITECTURE.md)
- [Contributing Guidelines](../.doc/docs/CONTRIBUTING.md)
- [Security Policies](../.doc/docs/SECURITY.md)
- [Changelog](../.doc/docs/CHANGELOG.md)

### External Links

- [Terraform Registry](https://registry.terraform.io/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Helm Charts](https://artifacthub.io/)
- [Kubernetes Docs](https://kubernetes.io/docs/)

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](../.doc/docs/CONTRIBUTING.md).

### Development Workflow

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Submit PR
5. Pass CI/CD checks
6. Code review
7. Merge & deploy

---

## 📄 License

See [LICENSE.md](../.doc/docs/LICENSE.md) for details.

---

## 👥 Support

- **Issues**: [GitHub Issues](https://github.com/rice-mono/issues)
- **Discussions**: [GitHub Discussions](https://github.com/rice-mono/discussions)
- **Email**: devops@rice-mono.com

---

**Built with ❤️ by the Rice-Mono DevOps Team**
