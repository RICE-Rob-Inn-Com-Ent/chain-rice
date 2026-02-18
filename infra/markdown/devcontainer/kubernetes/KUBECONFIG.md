# Kubernetes Configuration Guide

This directory contains the kubeconfig file for managing access to Rice-Mono Kubernetes clusters across different
environments.

## Overview

The `kubeconfig.yaml` file contains configurations for multiple Kubernetes clusters and authentication methods,
supporting development, staging, and production environments.

## Setup

### 1. Environment Variables

Export the kubeconfig file location:

```bash
export KUBECONFIG=/home/mrDinkelman/rice-mono/.dev/kubernetes/kubeconfig.yaml
```

Or merge it with your existing kubeconfig:

```bash
export KUBECONFIG=~/.kube/config:/home/mrDinkelman/rice-mono/.dev/kubernetes/kubeconfig.yaml
```

### 2. Replace Placeholders

Before using the kubeconfig, replace the following placeholders with actual values:

- `<BASE64_ENCODED_CA_CERT>` - Cluster CA certificate (base64 encoded)
- `<BASE64_ENCODED_CLIENT_CERT>` - Client certificate (base64 encoded)
- `<BASE64_ENCODED_CLIENT_KEY>` - Client key (base64 encoded)
- `<SERVICE_ACCOUNT_TOKEN>` - Kubernetes service account token
- `<OIDC_CLIENT_SECRET>` - OIDC client secret for authentication
- `<REFRESH_TOKEN>` - OIDC refresh token
- `<ID_TOKEN>` - OIDC ID token
- `<AZURE_SERVER_ID>` - Azure server ID for AKS
- `<AZURE_CLIENT_ID>` - Azure client ID
- `<AZURE_TENANT_ID>` - Azure tenant ID

### 3. Obtain Certificates and Tokens

#### For Certificate-Based Authentication:

```bash
# Get CA certificate (from cluster)
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'

# Generate client certificate and key (if needed)
openssl req -new -key client.key -out client.csr
# Have it signed by the cluster CA

# Base64 encode certificates
cat ca.crt | base64 -w 0
cat client.crt | base64 -w 0
cat client.key | base64 -w 0
```

#### For Service Account Token:

```bash
# Create service account
kubectl create serviceaccount rice-mono-sa -n rice-mono-dev

# Create ClusterRoleBinding
kubectl create clusterrolebinding rice-mono-sa-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=rice-mono-dev:rice-mono-sa

# Get the token
kubectl create token rice-mono-sa -n rice-mono-dev --duration=87600h
```

## Available Contexts

### Development

- `dev` - Main development cluster (admin access)
- `dev-backend` - Backend namespace in dev
- `dev-frontend` - Frontend namespace in dev
- `local` - Local cluster (minikube/kind/k3s)
- `eks-dev` - AWS EKS development cluster

### Staging

- `staging` - Main staging cluster (admin access)
- `staging-backend` - Backend namespace in staging
- `aks-staging` - Azure AKS staging cluster

### Production

- `prod` - Main production cluster (OIDC auth)
- `prod-backend` - Backend namespace in prod
- `prod-frontend` - Frontend namespace in prod
- `gke-prod` - GCP GKE production cluster

## Usage Examples

### Switch Contexts

```bash
# List all contexts
kubectl config get-contexts

# Switch to development
kubectl config use-context dev

# Switch to production
kubectl config use-context prod

# Switch to specific namespace
kubectl config use-context dev-backend
```

### View Current Context

```bash
kubectl config current-context
```

### Test Connection

```bash
# Test cluster connectivity
kubectl cluster-info

# Verify permissions
kubectl auth can-i get pods --namespace=rice-mono-dev

# List resources
kubectl get nodes
kubectl get namespaces
kubectl get pods --all-namespaces
```

### Quick Context Switching

Create aliases in your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
alias k='kubectl'
alias kdev='kubectl config use-context dev'
alias kstaging='kubectl config use-context staging'
alias kprod='kubectl config use-context prod'
alias klocal='kubectl config use-context local'

# Namespace-specific
alias kdevbe='kubectl config use-context dev-backend'
alias kdevfe='kubectl config use-context dev-frontend'
```

## Cloud Provider Setup

### AWS EKS

1. Install AWS CLI and configure credentials:

```bash
aws configure --profile rice-mono
```

2. Update kubeconfig for EKS:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name rice-mono-cluster \
  --profile rice-mono
```

### Google GKE

1. Install gcloud CLI and authenticate:

```bash
gcloud auth login
gcloud config set project rice-mono
```

2. Get cluster credentials:

```bash
gcloud container clusters get-credentials rice-mono-cluster \
  --region us-central1 \
  --project rice-mono
```

### Azure AKS

1. Install Azure CLI and login:

```bash
az login
az account set --subscription <subscription-id>
```

2. Install kubelogin:

```bash
az aks install-cli
```

3. Get cluster credentials:

```bash
az aks get-credentials \
  --resource-group rice-mono-rg \
  --name rice-mono-cluster
```

## Security Best Practices

1. **Never commit secrets**: Keep this kubeconfig file out of version control if it contains real credentials
2. **Use RBAC**: Apply principle of least privilege for service accounts
3. **Rotate credentials**: Regularly rotate tokens and certificates
4. **Use namespace isolation**: Separate environments and services into different namespaces
5. **Enable audit logging**: Track all API server access
6. **Use sealed secrets**: For storing secrets in Git (see values.yaml)
7. **Enable network policies**: Restrict pod-to-pod communication

## Troubleshooting

### Connection Issues

```bash
# Check cluster endpoint
kubectl config view --minify --output 'jsonpath={.clusters[0].cluster.server}'

# Verify certificates
kubectl config view --raw

# Test with verbose output
kubectl get pods -v=8
```

### Authentication Issues

```bash
# Check current user
kubectl config view --minify --output 'jsonpath={.contexts[0].context.user}'

# Test authentication
kubectl auth whoami

# Verify token expiration
kubectl get --raw /api/v1/namespaces
```

### Permission Issues

```bash
# Check your permissions
kubectl auth can-i --list

# Check specific resource
kubectl auth can-i create deployments --namespace=rice-mono-dev
```

## Multi-Cluster Management Tools

Consider using these tools for easier multi-cluster management:

- **kubectx/kubens**: Quick context and namespace switching
- **k9s**: Terminal UI for Kubernetes
- **Lens**: Desktop application for Kubernetes
- **kubectl plugins**: Extend kubectl functionality

```bash
# Install kubectx/kubens
brew install kubectx

# Use kubectx for quick switching
kubectx dev
kubectx staging
kubectx prod

# Use kubens for namespace switching
kubens rice-mono-backend
```

## Integration with Helm

When deploying with Helm, specify the context:

```bash
# Deploy to development
kubectl config use-context dev
helm upgrade --install rice-mono . -f values.yaml

# Deploy to production
kubectl config use-context prod
helm upgrade --install rice-mono . -f values.yaml \
  --set global.environment=prod
```

## Related Files

- `Chart.yaml` - Helm chart metadata
- `values.yaml` - Configuration values for all environments
- `templates/` - Kubernetes resource templates

## Resources

- [Kubernetes Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)
- [Organizing Cluster Access Using kubeconfig Files](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)
- [Configure Access to Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
