# ☸️ Kubernetes Orchestration Guide

Complete guide for Kubernetes deployment and management in the Rice-Mono project.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Helm Charts](#helm-charts)
- [ArgoCD GitOps](#argocd-gitops)
- [Operators & CRDs](#operators--crds)
- [Networking](#networking)
- [Storage](#storage)
- [Monitoring](#monitoring)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

Our Kubernetes setup provides:

- **Multi-Service Orchestration** - Backend, Frontend, Bot, Token services
- **Auto-Scaling** - HPA and VPA for dynamic scaling
- **High Availability** - Multi-replica deployments
- **GitOps** - ArgoCD for continuous deployment
- **Service Mesh** - Optional Istio integration
- **Monitoring** - Prometheus, Grafana dashboards

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│              Ingress (NGINX)                    │
│         SSL/TLS + Rate Limiting                 │
└────────────────┬────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
   ┌────▼────┐      ┌────▼────┐
   │Frontend │      │Backend  │
   │ (React) │      │  (Go)   │
   │   x2    │      │   x3    │
   └─────────┘      └────┬────┘
                          │
        ┌─────────────────┼─────────────┐
        │                 │             │
   ┌────▼────┐      ┌────▼────┐   ┌───▼───┐
   │Database │      │  Redis  │   │ Bot   │
   │(Postgres)      │ (Cache) │   │(Python)
   │   x2    │      │   x2    │   │  x1   │
   └─────────┘      └─────────┘   └───────┘
```

### Components

| Component | Replicas   | Resources  | Purpose         |
| --------- | ---------- | ---------- | --------------- |
| Frontend  | 2-6 (HPA)  | 250m/256Mi | React Web App   |
| Backend   | 3-10 (HPA) | 500m/512Mi | Go API Server   |
| Bot       | 1          | 250m/512Mi | Python AI Bot   |
| Token     | 1          | 500m/1Gi   | Blockchain Node |
| Database  | 2          | 500m/1Gi   | PostgreSQL      |
| Redis     | 2          | 250m/256Mi | Cache Layer     |

---

## 🚀 Quick Start

### 1. Install Prerequisites

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installations
kubectl version --client
helm version
```

### 2. Configure Cluster Access

```bash
# For EKS
aws eks update-kubeconfig --region us-west-2 --name rice-mono-cluster

# For GKE
gcloud container clusters get-credentials rice-mono-cluster --region us-west2

# For local (minikube/kind)
kubectl config use-context minikube
```

### 3. Deploy with Helm

```bash
cd .dev/k8s

# Install dependencies
helm dependency update

# Deploy to dev
helm upgrade --install rice-mono . \
  --namespace dev \
  --create-namespace \
  --values values.yaml \
  --values values-dev.yaml

# Deploy to production
helm upgrade --install rice-mono . \
  --namespace production \
  --create-namespace \
  --values values.yaml \
  --values values-prod.yaml
```

---

## 📦 Helm Charts

### Chart Structure

```
k8s/
├── Chart.yaml              # Chart metadata
├── values.yaml            # Default values
├── values-dev.yaml        # Dev overrides
├── values-prod.yaml       # Prod overrides
└── templates/             # K8s manifests
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── hpa.yaml
    ├── configmap.yaml
    ├── secret.yaml
    ├── pvc.yaml
    └── _helpers.tpl
```

### Using Values

**Override values:**

```bash
# From file
helm upgrade rice-mono . -f custom-values.yaml

# From command line
helm upgrade rice-mono . \
  --set backend.replicaCount=5 \
  --set global.domain=myapp.com
```

**Common overrides:**

```yaml
# custom-values.yaml
global:
  domain: myapp.com
  environment: production

backend:
  replicaCount: 5
  image:
    tag: v1.2.3
  resources:
    requests:
      cpu: 1000m
      memory: 1Gi

monitoring:
  enabled: true
```

### Managing Releases

```bash
# List releases
helm list -A

# Get release status
helm status rice-mono -n dev

# Get release values
helm get values rice-mono -n dev

# Rollback release
helm rollback rice-mono 1 -n dev

# Uninstall release
helm uninstall rice-mono -n dev
```

---

## 🔄 ArgoCD GitOps

### Setup ArgoCD

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Create ArgoCD Application

```bash
# Apply ArgoCD project and apps
kubectl apply -f k8s/templates/argocd-project.yaml
kubectl apply -f k8s/templates/argocd-application.yaml
```

### ArgoCD CLI

```bash
# Login
argocd login localhost:8080

# List apps
argocd app list

# Sync app
argocd app sync rice-backend

# Get app status
argocd app get rice-backend

# Enable auto-sync
argocd app set rice-backend --sync-policy automated
```

### GitOps Workflow

1. **Push to Git** - Commit changes to `.dev/k8s/`
2. **ArgoCD Detects** - Monitors repo for changes
3. **Auto-Sync** - Applies changes to cluster
4. **Health Check** - Verifies deployment status
5. **Rollback if Failed** - Auto-rollback on errors

---

## 🔧 Operators & CRDs

### Cert-Manager

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml

# Create ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@rice-mono.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### External Secrets Operator

```bash
# Install ESO
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n kube-system

# Create SecretStore (AWS Secrets Manager)
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsmanager
  namespace: dev
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
EOF

# Create ExternalSecret
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: backend-secrets
  namespace: dev
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: backend-secrets
    creationPolicy: Owner
  data:
  - secretKey: DATABASE_PASSWORD
    remoteRef:
      key: prod/database
      property: password
EOF
```

### Sealed Secrets

```bash
# Install Sealed Secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Install kubeseal CLI
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar xfz kubeseal-0.24.0-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal

# Seal a secret
kubectl create secret generic mysecret --dry-run=client --from-literal=password=mypass -o yaml | \
  kubeseal -o yaml > mysealedsecret.yaml

# Apply sealed secret
kubectl apply -f mysealedsecret.yaml
```

---

## 🌐 Networking

### Ingress Configuration

```yaml
# Basic ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rice-backend
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.rice-mono.com
      secretName: backend-tls
  rules:
    - host: api.rice-mono.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: rice-backend
                port:
                  number: 8080
```

### Network Policies

Already configured in `templates/networkpolicy.yaml`:

- **Default Deny** - Block all ingress by default
- **Allow Frontend→Backend** - Specific service communication
- **Allow Backend→Database** - Database access
- **Allow Ingress→Services** - External traffic
- **Allow Prometheus** - Monitoring access

### Service Mesh (Istio)

```bash
# Install Istio
istioctl install --set profile=production -y

# Enable sidecar injection
kubectl label namespace dev istio-injection=enabled

# Create Virtual Service
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend
spec:
  hosts:
  - api.rice-mono.com
  gateways:
  - rice-gateway
  http:
  - match:
    - uri:
        prefix: /api
    route:
    - destination:
        host: rice-backend
        port:
          number: 8080
      weight: 90
    - destination:
        host: rice-backend-canary
        port:
          number: 8080
      weight: 10
EOF
```

---

## 💾 Storage

### StorageClasses

```bash
# List storage classes
kubectl get storageclass

# Create custom storage class (AWS EBS)
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF
```

### Persistent Volumes

```yaml
# PVC for database
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 50Gi
```

### Backup & Restore

```bash
# Using Velero
velero install \
  --provider aws \
  --bucket rice-mono-backups \
  --backup-location-config region=us-west-2 \
  --snapshot-location-config region=us-west-2

# Create backup
velero backup create dev-backup --include-namespaces dev

# Restore backup
velero restore create --from-backup dev-backup
```

---

## 📊 Monitoring

### Prometheus Stack

```bash
# Install Prometheus Operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

### Custom Metrics

```yaml
# ServiceMonitor for app metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: backend-metrics
spec:
  selector:
    matchLabels:
      app: rice-backend
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
```

### Alerting

```yaml
# PrometheusRule for alerts
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: backend-alerts
spec:
  groups:
    - name: backend
      interval: 30s
      rules:
        - alert: HighErrorRate
          expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
          for: 5m
          annotations:
            summary: "High error rate detected"
```

---

## 🔒 Security

### RBAC

```yaml
# ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-sa
  namespace: dev

---
# Role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: backend-role
  namespace: dev
rules:
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    verbs: ["get", "list"]

---
# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: backend-binding
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: backend-role
subjects:
  - kind: ServiceAccount
    name: backend-sa
    namespace: dev
```

### Pod Security

```yaml
# PodSecurityContext
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

# SecurityContext
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
```

### Image Security

```bash
# Scan images with Trivy
trivy image rice-mono/backend:latest

# Use signed images (Cosign)
cosign verify --key cosign.pub rice-mono/backend:latest
```

---

## 🔍 Troubleshooting

### Debug Pods

```bash
# Get pod status
kubectl get pods -n dev

# Describe pod
kubectl describe pod <pod-name> -n dev

# View logs
kubectl logs <pod-name> -n dev

# Follow logs
kubectl logs -f <pod-name> -n dev

# Previous container logs
kubectl logs <pod-name> -n dev --previous

# Exec into pod
kubectl exec -it <pod-name> -n dev -- /bin/sh
```

### Debug Services

```bash
# Test service connectivity
kubectl run test --rm -it --image=busybox -- /bin/sh
wget -O- http://rice-backend:8080/health

# Check endpoints
kubectl get endpoints -n dev

# Port forward for testing
kubectl port-forward svc/rice-backend 8080:8080 -n dev
```

### Debug Networking

```bash
# Test DNS
kubectl run test --rm -it --image=busybox -- nslookup rice-backend

# Check network policies
kubectl get networkpolicies -n dev

# Describe network policy
kubectl describe networkpolicy <policy-name> -n dev
```

### Common Issues

**Pod CrashLoopBackOff:**

```bash
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>
```

**ImagePullBackOff:**

```bash
kubectl describe pod <pod-name>
# Check imagePullSecrets
```

**Service not accessible:**

```bash
kubectl get svc,ep
kubectl describe svc <service-name>
```

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Main DevOps Guide](../README.md)

---

**For support, contact the DevOps team or check the [main README](../README.md).**
