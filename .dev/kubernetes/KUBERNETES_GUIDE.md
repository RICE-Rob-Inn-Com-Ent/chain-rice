# 🚀 Rice-Mono Kubernetes Deployment Guide

Complete guide for deploying Rice-Mono to Kubernetes (local and production).

## 📋 Prerequisites

### Required Tools

```bash
# Install all required tools
cd /home/mrDinkelman/rice-mono
./.dev/scripts/setup-all.sh
```

This installs:

- ✅ kubectl (Kubernetes CLI)
- ✅ helm (Package manager)
- ✅ kind (Kubernetes in Docker)
- ✅ Docker (Container runtime)

### Verify Installation

```bash
kubectl version --client
helm version
kind --version
docker --version
```

---

## 🏗️ Quick Start (Local Development)

### Step 1: Create Kubernetes Cluster

```bash
cd .dev/kubernetes
./setup-cluster.sh
```

This creates a 3-node kind cluster with:

- NGINX Ingress Controller
- Metrics Server
- Development namespaces
- Development secrets

### Step 2: Build Docker Images

```bash
./build-images.sh
```

Builds and loads images for:

- Backend (Go)
- Bot (Python AI)
- Frontend (Next.js)

### Step 3: Deploy All Services

```bash
./deploy-all.sh
```

Deploys all services using Helm charts.

### Step 4: Verify Deployment

```bash
# Check pods
kubectl get pods -n rice-mono

# Check services
kubectl get svc -n rice-mono

# Check ingress
kubectl get ingress -n rice-mono
```

---

## 📊 Project Structure

```
.dev/kubernetes/
├── setup-cluster.sh           # Creates kind cluster
├── build-images.sh            # Builds Docker images
├── deploy-all.sh              # Deploys all services
├── setup-kubeconfig.sh        # Configures kubeconfig
│
├── charts/                    # Helm charts
│   ├── backend/               # Backend (Go) chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── ingress.yaml
│   │       ├── hpa.yaml
│   │       └── configmap.yaml
│   │
│   ├── bot/                   # Bot (Python) chart
│   ├── frontend/              # Frontend (Next.js) chart
│   └── database/              # PostgreSQL chart
│
├── templates/                 # Kubernetes manifests
│   ├── namespace.yaml
│   ├── networkpolicy.yaml
│   ├── argocd-application.yaml
│   └── ...
│
├── values.yaml                # Global values
└── Chart.yaml                 # Meta chart
```

---

## 🎯 Available Services

### Backend API (Go)

- **Port:** 8080
- **Endpoint:** `http://api.rice-mono.local`
- **Health:** `/health`
- **Metrics:** `/metrics`

**Access:**

```bash
kubectl port-forward svc/rice-backend 8080:8080 -n rice-mono
curl http://localhost:8080/health
```

### Bot Service (Python AI)

- **Port:** 8000
- **Internal:** `rice-bot.rice-mono.svc.cluster.local:8000`

**Access:**

```bash
kubectl port-forward svc/rice-bot 8000:8000 -n rice-mono
curl http://localhost:8000/health
```

### Frontend (Next.js)

- **Port:** 3000
- **Endpoint:** `http://rice-mono.local`

**Access:**

```bash
kubectl port-forward svc/rice-frontend 3000:3000 -n rice-mono
```

---

## 🔧 Common Operations

### View Logs

```bash
# Backend logs
kubectl logs -f deployment/rice-backend -n rice-mono

# Bot logs
kubectl logs -f deployment/rice-bot -n rice-mono

# All pods in namespace
kubectl logs -f -l app.kubernetes.io/part-of=rice-mono -n rice-mono
```

### Scale Services

```bash
# Scale backend manually
kubectl scale deployment rice-backend --replicas=5 -n rice-mono

# View autoscaler status
kubectl get hpa -n rice-mono
```

### Update Deployment

```bash
# Rebuild images
./build-images.sh v1.0.1

# Redeploy
./deploy-all.sh rice-mono v1.0.1

# Or update specific service
helm upgrade rice-backend ./charts/backend \
  --namespace rice-mono \
  --set image.tag=v1.0.1
```

### Rollback Deployment

```bash
# View revision history
kubectl rollout history deployment/rice-backend -n rice-mono

# Rollback to previous version
kubectl rollout undo deployment/rice-backend -n rice-mono

# Rollback to specific revision
kubectl rollout undo deployment/rice-backend --to-revision=2 -n rice-mono
```

### Debug Pods

```bash
# Describe pod
kubectl describe pod <pod-name> -n rice-mono

# Get pod events
kubectl get events -n rice-mono --sort-by='.lastTimestamp'

# Execute command in pod
kubectl exec -it <pod-name> -n rice-mono -- /bin/sh

# Copy files from pod
kubectl cp rice-mono/<pod-name>:/app/logs.txt ./logs.txt
```

---

## 📈 Monitoring & Observability

### Metrics

```bash
# Top pods
kubectl top pods -n rice-mono

# Top nodes
kubectl top nodes

# Resource usage
kubectl describe pod <pod-name> -n rice-mono | grep -A 5 Resources
```

### Health Checks

```bash
# Test liveness probe
kubectl exec <pod-name> -n rice-mono -- wget -qO- http://localhost:8080/health

# Test readiness probe
kubectl exec <pod-name> -n rice-mono -- wget -qO- http://localhost:8080/ready
```

---

## 🔐 Security

### Secrets Management

```bash
# Create secret
kubectl create secret generic my-secret \
  --from-literal=key=value \
  --namespace rice-mono

# View secrets (base64 encoded)
kubectl get secret my-secret -n rice-mono -o yaml

# Decode secret
kubectl get secret my-secret -n rice-mono -o jsonpath='{.data.key}' | base64 -d
```

### Network Policies

Network policies are enabled by default. Check:

```bash
kubectl get networkpolicies -n rice-mono
kubectl describe networkpolicy <policy-name> -n rice-mono
```

---

## 🚀 Production Deployment

### Cloud Providers

#### AWS EKS

```bash
# Configure kubeconfig
aws eks update-kubeconfig --region us-west-2 --name rice-mono-cluster

# Deploy
./deploy-all.sh rice-mono-prod v1.0.0
```

#### Google GKE

```bash
# Configure kubeconfig
gcloud container clusters get-credentials rice-mono-cluster --region us-central1

# Deploy
./deploy-all.sh rice-mono-prod v1.0.0
```

#### Azure AKS

```bash
# Configure kubeconfig
az aks get-credentials --resource-group rice-mono --name rice-mono-cluster

# Deploy
./deploy-all.sh rice-mono-prod v1.0.0
```

### Production Checklist

- [ ] Update image tags (no `latest`)
- [ ] Configure production secrets
- [ ] Set resource limits
- [ ] Enable autoscaling
- [ ] Configure ingress with TLS
- [ ] Setup monitoring (Prometheus/Grafana)
- [ ] Configure backup strategy
- [ ] Test health checks
- [ ] Configure network policies
- [ ] Setup logging aggregation
- [ ] Configure alerts

---

## 🐛 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n rice-mono

# Describe pod
kubectl describe pod <pod-name> -n rice-mono

# Check events
kubectl get events -n rice-mono --sort-by='.lastTimestamp'
```

**Common issues:**

- ImagePullBackOff → Check image exists in kind cluster
- CrashLoopBackOff → Check logs and health checks
- Pending → Check resource availability

### Service Not Accessible

```bash
# Check service
kubectl get svc -n rice-mono

# Check endpoints
kubectl get endpoints -n rice-mono

# Test from inside cluster
kubectl run test --rm -it --image=busybox -n rice-mono -- /bin/sh
wget -O- http://rice-backend:8080/health
```

### Ingress Not Working

```bash
# Check ingress
kubectl get ingress -n rice-mono
kubectl describe ingress <ingress-name> -n rice-mono

# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [kind Documentation](https://kind.sigs.k8s.io/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

## 🤝 Contributing

See main [CONTRIBUTING.md](../../.doc/docs/CONTRIBUTING.md) for contribution guidelines.

---

**Built with ❤️ by the Rice-Mono DevOps Team**
