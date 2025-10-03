# Rice Development Kubernetes Helm Chart

This Helm chart provides a complete Kubernetes setup for the Rice Development project, including ArgoCD for GitOps and Nginx for ingress.

## Features

- **ArgoCD**: GitOps continuous delivery tool
- **Nginx**: Ingress controller and reverse proxy
- **Custom Applications**: Pre-configured ArgoCD applications
- **Projects**: Organized ArgoCD projects with RBAC

## Prerequisites

- Kubernetes cluster (1.20+)
- Helm 3.x
- kubectl configured to access your cluster

## Installation

### 1. Add Helm Repositories

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. Install Dependencies

```bash
cd /home/mrDinkelman/rice-dev/tools/k8s
helm dependency update
```

### 3. Install the Chart

```bash
# Install with default values
helm install rice-dev-k8s . -n rice-dev --create-namespace

# Or install with custom values
helm install rice-dev-k8s . -n rice-dev --create-namespace -f values.yaml
```

### 4. Access ArgoCD

After installation, you can access ArgoCD:

- **URL**: https://argocd.rice-dev.local
- **Username**: admin
- **Password**: admin123 (default, change in production)

To get the admin password:

```bash
kubectl -n rice-dev get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Configuration

### Values.yaml

The `values.yaml` file contains configuration for:

- **ArgoCD**: Server, controller, and application settings
- **Nginx**: Ingress controller configuration
- **Global**: Namespace and common settings

### Key Configuration Options

#### ArgoCD Server

```yaml
argo-cd:
  server:
    service:
      type: LoadBalancer # or ClusterIP for internal access
    ingress:
      enabled: true
      hosts:
        - argocd.rice-dev.local
```

#### ArgoCD Applications

The chart includes a sample ArgoCD application (`argocd-application.yaml`) that deploys the guestbook example app.

#### ArgoCD Projects

A custom project (`rice-dev-project`) is created with:

- Repository access controls
- Namespace permissions
- RBAC roles for admins and developers

## Customization

### Adding New Applications

1. Create a new Application manifest in `templates/`
2. Update the ArgoCD project to include new repositories
3. Redeploy the chart

### Adding New Repositories

Update the `values.yaml` file:

```yaml
argo-cd:
  configs:
    cm:
      repositories: |
        - type: git
          url: https://github.com/your-org/your-repo
          name: your-repo
```

### RBAC Configuration

Modify the project roles in `templates/argocd-project.yaml`:

```yaml
roles:
  - name: custom-role
    description: "Custom role description"
    policies:
      - p, proj:rice-dev-project:custom-role, applications, get, rice-dev-project/*, allow
    groups:
      - your-custom-group
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n rice-dev
```

### Check ArgoCD Server Logs

```bash
kubectl logs -n rice-dev -l app.kubernetes.io/name=argocd-server
```

### Check Application Status

```bash
kubectl get applications -n rice-dev
```

### Port Forward for Local Access

```bash
kubectl port-forward -n rice-dev svc/rice-dev-k8s-argo-cd-server 8080:80
```

## Uninstallation

```bash
helm uninstall rice-dev-k8s -n rice-dev
```

## Security Considerations

- Change default admin password in production
- Enable TLS/SSL for ArgoCD server
- Configure proper RBAC policies
- Use external identity providers (OIDC/SAML)
- Enable audit logging

## Support

For issues and questions:

- Check ArgoCD documentation: https://argo-cd.readthedocs.io/
- Check Helm chart documentation: https://github.com/argoproj/argo-helm
- Review Kubernetes logs and events
