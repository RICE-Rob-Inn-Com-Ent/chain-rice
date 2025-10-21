# ⚡ Quick Start Guide

Get up and running with the Rice-Mono DevOps infrastructure in minutes!

## 🎯 Prerequisites

- Linux or macOS
- Bash shell
- Internet connection
- Cloud account (AWS/Azure/GCP) - optional

## 🚀 5-Minute Setup

### Step 1: Initial Setup (2 minutes)

```bash
# Clone the repository (if not already done)
cd /home/mrDinkelman/rice-mono

# Run complete setup script (installs everything)
./.dev/scripts/setup-all.sh
```

This will install:

- **Java JDK 17** (for Android/Kotlin/Gradle development)
- **Node.js 20.x LTS** (for frontend and SonarQube)
- **kind** (Kubernetes in Docker)
- **kubectl** (Kubernetes CLI)
- **helm** (Kubernetes package manager)
- **Docker** (if not installed)

**Individual component installation:**

```bash
# Just Java
./.dev/scripts/setup-java.sh

# Just Node.js
./.dev/scripts/setup-nodejs.sh
```

### Step 2: Configure Cloud (1 minute)

Choose your cloud provider:

**AWS:**

```bash
aws configure
# Enter: Access Key, Secret Key, Region (us-west-2), Output (json)
```

**Azure:**

```bash
az login
```

**Google Cloud:**

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### Step 3: Deploy Infrastructure (2 minutes)

```bash
# Deploy to dev environment
./.dev/scripts/deploy-all.sh --env dev
```

## ✅ Verify Deployment

```bash
# Check health
./.dev/scripts/health-check.sh --env dev

# View Kubernetes resources
kubectl get all -n dev

# Access services
kubectl get ingress -n dev
```

## 🎨 What's Next?

### Add Your First Service

```bash
# Interactive mode
./.dev/scripts/add-project.sh --interactive

# Or specify parameters
./.dev/scripts/add-project.sh \
  --name my-api \
  --type backend \
  --language go \
  --port 8080
```

### Common Commands

```bash
# View all pods
kubectl get pods -n dev

# Follow logs
kubectl logs -f deployment/rice-backend -n dev

# Port forward for local access
kubectl port-forward svc/rice-backend 8080:80 -n dev

# Update deployment
kubectl set image deployment/rice-backend \
  rice-backend=rice-mono/backend:v1.2.3 -n dev

# Rollback deployment
./.dev/scripts/ci/rollback.sh
```

## 📊 Access Dashboards

```bash
# Kubernetes Dashboard
kubectl proxy
# Visit: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

# Grafana (if deployed)
kubectl port-forward svc/grafana 3000:80 -n monitoring
# Visit: http://localhost:3000

# ArgoCD
kubectl port-forward svc/argocd-server 8080:443 -n argocd
# Visit: https://localhost:8080
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## 🔧 Troubleshooting

### Pods Not Starting?

```bash
# Check pod status
kubectl describe pod POD_NAME -n dev

# View logs
kubectl logs POD_NAME -n dev

# Check events
kubectl get events -n dev --sort-by='.lastTimestamp'
```

### Service Not Accessible?

```bash
# Test from inside cluster
kubectl run test --rm -it --image=busybox -- /bin/sh
wget -O- http://service-name:80/health
```

### Need to Reset?

```bash
# Destroy everything
./.dev/scripts/destroy.sh --env dev --confirm

# Start fresh
./.dev/scripts/setup.sh
./.dev/scripts/deploy-all.sh --env dev
```

## 📚 Learn More

- [Complete Documentation](.dev/README.md)
- [Ansible Guide](.dev/docs/ANSIBLE.md)
- [Kubernetes Guide](.dev/docs/KUBERNETES.md)
- [Terraform Guide](.dev/docs/TERRAFORM.md)
- [Workflows](.dev/docs/WORKFLOWS.md)

## 🆘 Getting Help

1. Check documentation in `.dev/docs/`
2. Run health check: `./scripts/health-check.sh --verbose`
3. View logs: `kubectl logs -f deployment/NAME -n dev`
4. Contact DevOps team

---

**Happy Deploying! 🚀**
