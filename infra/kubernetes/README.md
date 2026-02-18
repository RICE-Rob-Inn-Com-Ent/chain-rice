# Kubernetes Deployment Guide for Ceramix

This directory contains Helm charts and Kubernetes configurations for deploying Ceramix to AWS EKS.

## Prerequisites

- AWS CLI configured
- kubectl installed (v1.28+)
- Helm 3.x installed
- eksctl installed (for cluster creation)
- Docker for building images

## Quick Start

### 1. Create EKS Cluster

```bash
eksctl create cluster -f eks-nodegroups.yaml
```

### 2. Build and Push Images

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and push
./scripts/build-and-push.sh
```

### 3. Deploy with Helm

```bash
helm upgrade --install ceramix . \
  --namespace ceramix \
  --create-namespace \
  --set global.registry=ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

## Directory Structure

```
kubernetes/
├── templates/          # Helm templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── pvc.yaml
│   └── ...
├── values.yaml        # Default values
├── eks-nodegroups.yaml # EKS node group configuration
├── iam-roles.yaml     # IAM roles for service accounts
└── README.md          # This file
```

## Services

### ceramix-web
- Frontend Next.js application
- Port: 3000
- Replicas: 2-6 (autoscaling)

### ceramix-bot
- CerAI FastAPI backend
- Port: 8000
- Replicas: 1

### cerai-lora
- LoRA fine-tuning and inference service
- Port: 8007
- GPU required (NVIDIA T4)
- Replicas: 1

## Configuration

### Environment Variables

Set in `values.yaml` or via Helm:

```bash
helm upgrade --install ceramix . \
  --set frontend.env[0].name=NEXT_PUBLIC_CERAI_API_URL \
  --set frontend.env[0].value=http://ceramix-bot:8000
```

### Secrets

Create secrets in Kubernetes:

```bash
kubectl create secret generic ceramix-secrets \
  --from-literal=cerai-api-key=your-key \
  --from-literal=wandb-api-key=your-key \
  -n ceramix
```

### Storage

Persistent volumes are created automatically for:
- ceramix-bot: 10Gi
- cerai-lora: 50Gi (models, adapters, data)

## GPU Configuration

### Node Labels and Taints

GPU nodes are labeled with `accelerator=nvidia-tesla-t4` and tainted with `nvidia.com/gpu=true:NoSchedule`.

### NVIDIA Device Plugin

Install the NVIDIA device plugin:

```bash
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.1/nvidia-device-plugin.yml
```

### GPU Resource Requests

cerai-lora requests 1 GPU:

```yaml
resources:
  limits:
    nvidia.com/gpu: 1
  requests:
    nvidia.com/gpu: 1
```

## CI/CD

GitHub Actions workflow is configured in `.github/workflows/deploy-eks.yml`.

Required secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Monitoring

### Health Checks

```bash
# Check all services
kubectl get pods -n ceramix

# Check service health
curl http://ceramix.ltd/api/health
```

### Logs

```bash
# Follow logs
kubectl logs -f deployment/ceramix-web -n ceramix
kubectl logs -f deployment/ceramix-bot -n ceramix
kubectl logs -f deployment/cerai-lora -n ceramix
```

## Troubleshooting

See [PRODUCTION.md](../../.project/ceramix/PRODUCTION.md) for detailed troubleshooting guide.

## Useful Commands

```bash
# List all resources
kubectl get all -n ceramix

# Describe deployment
kubectl describe deployment ceramix-web -n ceramix

# Port forward for local access
kubectl port-forward -n ceramix deployment/ceramix-web 3000:3000

# Execute command in pod
kubectl exec -it deployment/ceramix-bot -n ceramix -- /bin/bash

# Check events
kubectl get events -n ceramix --sort-by='.lastTimestamp'
```
