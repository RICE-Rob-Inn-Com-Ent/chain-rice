# ☸️ Rice-Mono Kubernetes Setup

> **Quick Start:** Get Rice-Mono running on Kubernetes in 3 commands!

## 🚀 TL;DR - Quick Deploy

```bash
cd /home/mrDinkelman/rice-mono/.dev/kubernetes

# 1. Create cluster (one-time setup)
./setup-cluster.sh

# 2. Build images
./build-images.sh

# 3. Deploy everything
./deploy-all.sh
```

Done! Your services are now running! 🎉

---

## 📦 What's Included

This Kubernetes setup provides:

✅ **Complete Infrastructure**

- 3-node kind cluster (1 control-plane + 2 workers)
- NGINX Ingress Controller
- Metrics Server for autoscaling
- Development namespaces & secrets

✅ **All Services Deployed**

- Backend API (Go) - 3 replicas with HPA
- Bot Service (Python AI) - GPU-ready
- Frontend (Next.js) - Static + SSR
- PostgreSQL Database
- Redis Cache

✅ **Production Features**

- Health checks (liveness/readiness/startup)
- Horizontal Pod Autoscaler (HPA)
- Resource limits & requests
- Network policies
- ConfigMaps & Secrets
- Service mesh ready

---

## 📁 Project Structure

```
.dev/kubernetes/
│
├── 🚀 Quick Start Scripts
│   ├── setup-cluster.sh       # Create kind cluster
│   ├── build-images.sh        # Build all Docker images
│   └── deploy-all.sh          # Deploy all services
│
├── 📊 Helm Charts
│   └── charts/
│       ├── backend/           # Go API service
│       ├── bot/               # Python AI service
│       ├── frontend/          # Next.js app
│       └── database/          # PostgreSQL
│
├── 📝 Documentation
│   ├── KUBERNETES_GUIDE.md    # Complete guide
│   └── README-KUBERNETES.md   # This file
│
└── 🛠️ Templates & Config
    ├── templates/             # K8s manifests
    ├── values.yaml            # Global values
    └── Chart.yaml             # Meta chart
```

---

## 🎯 Access Your Services

### Option 1: Port Forwarding (Recommended for Dev)

```bash
# Backend API
kubectl port-forward svc/rice-backend 8080:8080 -n rice-mono
curl http://localhost:8080/health

# Bot Service
kubectl port-forward svc/rice-bot 8000:8000 -n rice-mono

# Frontend
kubectl port-forward svc/rice-frontend 3000:3000 -n rice-mono
```

### Option 2: Ingress (Production-like)

Add to `/etc/hosts`:

```
127.0.0.1 api.rice-mono.local
127.0.0.1 rice-mono.local
```

Then access:

- Backend: `http://api.rice-mono.local`
- Frontend: `http://rice-mono.local`

---

## 🔍 Monitor Your Deployment

```bash
# Watch pods start
kubectl get pods -n rice-mono --watch

# Check all resources
kubectl get all -n rice-mono

# View logs
kubectl logs -f deployment/rice-backend -n rice-mono

# Pod resource usage
kubectl top pods -n rice-mono
```

---

## 🔧 Useful Commands

### View Everything

```bash
# Status overview
kubectl get pods,svc,ingress -n rice-mono

# Detailed pod info
kubectl describe pod <pod-name> -n rice-mono

# Events (troubleshooting)
kubectl get events -n rice-mono --sort-by='.lastTimestamp'
```

### Update Deployment

```bash
# Rebuild with new version
./build-images.sh v1.0.1

# Redeploy
./deploy-all.sh rice-mono v1.0.1

# Or update single service
helm upgrade rice-backend ./charts/backend \
  -n rice-mono \
  --set image.tag=v1.0.1
```

### Scale Services

```bash
# Manual scaling
kubectl scale deployment rice-backend --replicas=5 -n rice-mono

# View autoscaler
kubectl get hpa -n rice-mono

# Autoscaler details
kubectl describe hpa rice-backend -n rice-mono
```

### Debug Issues

```bash
# Shell into pod
kubectl exec -it <pod-name> -n rice-mono -- /bin/sh

# Test service connectivity
kubectl run test --rm -it --image=busybox -n rice-mono -- /bin/sh
wget -O- http://rice-backend:8080/health

# Copy logs from pod
kubectl cp rice-mono/<pod-name>:/app/logs ./logs
```

---

## 🐛 Common Issues

### Pods Stuck in Pending

**Cause:** Not enough resources

**Fix:**

```bash
# Check node resources
kubectl describe nodes

# Lower resource requests in values.yaml
helm upgrade rice-backend ./charts/backend \
  -n rice-mono \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=128Mi
```

### ImagePullBackOff

**Cause:** Image not loaded into kind

**Fix:**

```bash
# Check images in kind
docker exec -it rice-mono-control-plane crictl images

# Rebuild and load
./build-images.sh
```

### CrashLoopBackOff

**Cause:** Application crash

**Fix:**

```bash
# Check logs
kubectl logs <pod-name> -n rice-mono

# Check previous crash
kubectl logs <pod-name> -n rice-mono --previous

# Describe pod for events
kubectl describe pod <pod-name> -n rice-mono
```

---

## 🧹 Cleanup

### Delete Deployment (Keep Cluster)

```bash
# Delete all releases
helm uninstall rice-backend rice-bot rice-frontend -n rice-mono

# Delete namespace
kubectl delete namespace rice-mono
```

### Delete Everything

```bash
# Delete cluster
kind delete cluster --name rice-mono

# Clean Docker images
docker images | grep rice-mono | awk '{print $3}' | xargs docker rmi
```

---

## 📈 Next Steps

### For Development

1. **Setup hot-reload:**

   - Use `skaffold` for automatic rebuild/redeploy
   - Or `tilt` for live development

2. **Add debugging:**

   - Install `kubectl-debug` plugin
   - Use `telepresence` for local debugging

3. **Add observability:**
   - Install Prometheus & Grafana
   - Setup logging with ELK stack

### For Production

1. **Setup CI/CD:**

   - GitHub Actions for builds
   - ArgoCD for GitOps
   - See: `.dev/kubernetes/templates/argocd-*.yaml`

2. **Configure monitoring:**

   - Prometheus for metrics
   - Grafana for dashboards
   - AlertManager for alerts

3. **Harden security:**
   - Enable Pod Security Policies
   - Configure RBAC
   - Use Sealed Secrets

---

## 📚 Documentation

- [Complete Kubernetes Guide](./KUBERNETES_GUIDE.md) - In-depth documentation
- [Helm Chart Values](./charts/backend/values.yaml) - Configuration options
- [Project README](../../README.md) - Main project documentation

---

## 💡 Tips

- **Save time:** Use aliases

  ```bash
  alias k='kubectl'
  alias kgp='kubectl get pods'
  alias kgpa='kubectl get pods --all-namespaces'
  alias kl='kubectl logs -f'
  ```

- **Quick context switch:**

  ```bash
  kubectl config use-context kind-rice-mono
  ```

- **Monitor everything:**
  ```bash
  watch 'kubectl get pods -n rice-mono'
  ```

---

## 🆘 Need Help?

1. Check logs: `kubectl logs -f deployment/<name> -n rice-mono`
2. Check events: `kubectl get events -n rice-mono`
3. Describe resource: `kubectl describe <resource> <name> -n rice-mono`
4. Read the [Complete Guide](./KUBERNETES_GUIDE.md)
5. Check [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

**🎉 Happy Kubernetes-ing! 🚀**
