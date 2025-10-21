# Rice-Mono Kubernetes Configuration

This directory contains the Kubernetes/Helm configuration for deploying the Rice-Mono application stack across multiple
environments.

## 📁 Directory Structure

```
.dev/kubernetes/
├── Chart.yaml                    # Helm chart metadata and dependencies
├── values.yaml                   # Default configuration values
├── kubeconfig.yaml              # Multi-cluster kubeconfig template
├── setup-kubeconfig.sh          # Helper script for kubeconfig setup
├── .kubeconfig.env.example      # Environment variables template
├── KUBECONFIG.md                # Detailed kubeconfig documentation
├── .gitignore                   # Protect sensitive files
└── templates/                   # Kubernetes resource templates
    ├── _helpers.tpl            # Helm template helpers
    ├── namespace.yaml          # Namespace definitions
    ├── deployment.yaml         # Application deployments
    ├── service.yaml            # Service definitions
    ├── ingress.yaml            # Ingress configuration
    ├── configmap.yaml          # Configuration maps
    ├── secret.yaml             # Secrets management
    ├── hpa.yaml                # Horizontal Pod Autoscaler
    ├── pvc.yaml                # Persistent Volume Claims
    ├── networkpolicy.yaml      # Network policies
    ├── argocd-project.yaml     # ArgoCD project configuration
    ├── argocd-application.yaml # ArgoCD application configuration
    ├── istio-install.yaml      # Istio service mesh
    ├── istio-install.sh        # Istio installation script
    ├── chaos-mesh.yaml         # Chaos engineering
    └── chaos-mesh-install.sh   # Chaos Mesh installation script
```

## 🚀 Quick Start

### Prerequisites

Install required tools:

```bash
# Kubernetes CLI
brew install kubectl

# Helm
brew install helm

# Context/Namespace switcher (optional but recommended)
brew install kubectx

# Kubernetes IDE (optional)
brew install k9s
```

### 1. Configure Kubeconfig

```bash
# Copy the environment template
cp .kubeconfig.env.example .kubeconfig.env

# Edit with your credentials
vim .kubeconfig.env

# Setup for local development
./setup-kubeconfig.sh local minikube

# Or setup for cloud provider
./setup-kubeconfig.sh cloud eks
```

### 2. Deploy to Development

```bash
# Set context
export KUBECONFIG=$(pwd)/kubeconfig.yaml
kubectl config use-context dev

# Install/Update Helm chart
helm upgrade --install rice-mono . \
  --namespace rice-mono-dev \
  --create-namespace \
  --values values.yaml

# Verify deployment
kubectl get pods -n rice-mono-dev
```

### 3. Deploy to Production

```bash
# Switch context
kubectl config use-context prod

# Deploy with production values
helm upgrade --install rice-mono . \
  --namespace rice-mono-prod \
  --create-namespace \
  --values values.yaml \
  --set global.environment=prod \
  --set backend.replicaCount=5
```

## 🏗️ Architecture

The Rice-Mono stack consists of:

- **Backend API** (Go) - REST/GraphQL API server
- **Frontend Web** (Next.js/Flutter) - Web and mobile interfaces
- **Bot Service** (Python) - AI/ML bot service
- **Token Chain** (Cosmos SDK) - Blockchain service
- **PostgreSQL** - Primary database
- **Redis** - Caching layer

### Infrastructure Components

- **ArgoCD** - GitOps continuous delivery
- **Istio** (optional) - Service mesh
- **Nginx Ingress** - Ingress controller
- **Cert Manager** - TLS certificate management
- **Prometheus + Grafana** - Monitoring and alerting
- **Network Policies** - Security and isolation

## 🔧 Configuration

### Helm Values

The `values.yaml` file contains all configuration options. Key sections:

#### Global Settings

```yaml
global:
  environment: dev # dev, staging, prod
  domain: rice-mono.local
  registry: docker.io/rice-mono
```

#### Backend Configuration

```yaml
backend:
  enabled: true
  replicaCount: 3
  image:
    repository: rice-mono/backend
    tag: latest
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
```

### Environment-Specific Overrides

Create environment-specific values files:

```bash
# values.dev.yaml
global:
  environment: dev
backend:
  replicaCount: 1

# values.prod.yaml
global:
  environment: prod
backend:
  replicaCount: 5
  resources:
    requests:
      cpu: 1000m
      memory: 1Gi
```

Deploy with:

```bash
helm upgrade --install rice-mono . -f values.yaml -f values.prod.yaml
```

## 📦 Helm Chart Management

### Install Dependencies

```bash
# Update Helm dependencies
helm dependency update

# List dependencies
helm dependency list
```

### Dry Run

```bash
# See what would be deployed
helm upgrade --install rice-mono . \
  --dry-run \
  --debug \
  --namespace rice-mono-dev
```

### Template Rendering

```bash
# Render templates locally
helm template rice-mono . \
  --values values.yaml \
  --namespace rice-mono-dev > rendered.yaml
```

### Upgrade and Rollback

```bash
# Upgrade
helm upgrade rice-mono . --namespace rice-mono-dev

# Check release history
helm history rice-mono -n rice-mono-dev

# Rollback to previous version
helm rollback rice-mono -n rice-mono-dev

# Rollback to specific revision
helm rollback rice-mono 3 -n rice-mono-dev
```

## 🔐 Secrets Management

### Option 1: Sealed Secrets (Recommended for GitOps)

```bash
# Install Sealed Secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Encrypt a secret
echo -n "mysecret" | kubectl create secret generic my-secret \
  --dry-run=client \
  --from-file=password=/dev/stdin \
  -o yaml | \
  kubeseal -o yaml > my-sealed-secret.yaml

# Apply sealed secret
kubectl apply -f my-sealed-secret.yaml
```

### Option 2: External Secrets Operator

Configure in `values.yaml`:

```yaml
secrets:
  externalSecrets:
    enabled: true
    backend: aws-secrets-manager
```

### Option 3: Vault

```bash
# See .dev/vault/ for Vault setup
```

## 🌐 Ingress Configuration

### Local Development (Minikube)

```bash
# Enable ingress addon
minikube addons enable ingress

# Add hosts entry
echo "$(minikube ip) rice-mono.local api.rice-mono.local" | sudo tee -a /etc/hosts

# Access application
curl http://rice-mono.local
```

### Production (Cloud)

Configure DNS records to point to your LoadBalancer:

```bash
# Get LoadBalancer IP
kubectl get svc -n ingress-nginx

# Configure DNS
# rice-mono.com      A  <LOADBALANCER_IP>
# api.rice-mono.com  A  <LOADBALANCER_IP>
```

## 📊 Monitoring

### Prometheus

Access Prometheus:

```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Open http://localhost:9090
```

### Grafana

Access Grafana:

```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Open http://localhost:3000
# Default: admin / <check secret>
```

Get Grafana password:

```bash
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

## 🔍 Debugging

### View Logs

```bash
# Application logs
kubectl logs -f deployment/rice-backend -n rice-mono-dev

# Multiple containers
kubectl logs -f deployment/rice-backend -c backend -n rice-mono-dev

# Previous container
kubectl logs deployment/rice-backend --previous -n rice-mono-dev

# All pods
kubectl logs -l app=rice-backend -n rice-mono-dev --all-containers=true
```

### Debug Pod

```bash
# Get pod status
kubectl get pods -n rice-mono-dev
kubectl describe pod <pod-name> -n rice-mono-dev

# Execute command in pod
kubectl exec -it <pod-name> -n rice-mono-dev -- /bin/sh

# Debug with ephemeral container
kubectl debug -it <pod-name> -n rice-mono-dev --image=busybox --target=backend
```

### Network Debugging

```bash
# Test service connectivity
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -n rice-mono-dev

# Inside the pod:
curl http://rice-backend:8080/health
nslookup rice-backend
```

## 🧪 Testing

### Smoke Tests

```bash
# Check if all pods are running
kubectl wait --for=condition=ready pod -l app.kubernetes.io/part-of=rice-mono -n rice-mono-dev --timeout=300s

# Test health endpoints
kubectl run curl --rm -i --tty --image=curlimages/curl -n rice-mono-dev -- \
  curl http://rice-backend:8080/health
```

### Load Testing

```bash
# Install k6
brew install k6

# Run load test
k6 run loadtest.js
```

## 🚨 Disaster Recovery

### Backup

```bash
# Backup with Velero (recommended)
velero backup create rice-mono-backup --include-namespaces rice-mono-prod

# Backup PostgreSQL
kubectl exec -n rice-mono-prod deployment/postgres -- \
  pg_dump -U rice_user rice_db > backup.sql
```

### Restore

```bash
# Restore from Velero backup
velero restore create --from-backup rice-mono-backup

# Restore PostgreSQL
kubectl exec -i -n rice-mono-prod deployment/postgres -- \
  psql -U rice_user rice_db < backup.sql
```

## 🎯 ArgoCD GitOps

### Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Deploy Application

```bash
# Apply ArgoCD project
kubectl apply -f templates/argocd-project.yaml

# Apply ArgoCD application
kubectl apply -f templates/argocd-application.yaml
```

## 🌊 Service Mesh (Istio)

### Install Istio

```bash
# Run installation script
./templates/istio-install.sh

# Or manually
istioctl install --set profile=demo -y

# Enable sidecar injection
kubectl label namespace rice-mono-dev istio-injection=enabled
```

### Enable in Helm

```yaml
serviceMesh:
  enabled: true
  mtls:
    enabled: true
```

## 🔥 Chaos Engineering (Chaos Mesh)

### Install Chaos Mesh

```bash
# Run installation script
./templates/chaos-mesh-install.sh

# Or apply manually
kubectl apply -f templates/chaos-mesh.yaml
```

### Run Chaos Experiments

```bash
# Pod kill experiment
kubectl apply -f - <<EOF
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-kill-backend
  namespace: rice-mono-dev
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces:
      - rice-mono-dev
    labelSelectors:
      app: rice-backend
  scheduler:
    cron: '@every 5m'
EOF
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [KUBECONFIG.md](./KUBECONFIG.md) - Detailed kubeconfig guide

## 🤝 Contributing

When adding new Kubernetes resources:

1. Add templates in `templates/` directory
2. Document configuration in `values.yaml`
3. Update this README
4. Test with `helm template` and `helm lint`
5. Test deployment in dev environment

## 📞 Support

For issues or questions:

- Check the [QUICKSTART.md](../QUICKSTART.md)
- See [KUBERNETES.md](../docs/KUBERNETES.md) for more details
- Open an issue in the repository

## 📝 License

See [LICENSE.md](../../.doc/docs/LICENSE.md)
