## Multi-Cloud Kubernetes Lab

This directory is intended for manifests that work on any Kubernetes cluster
(minikube, kind, EKS, AKS, GKE, etc.).

Typical contents:

- `deployment.yaml` – sample app (Go HTTP service from backend labs)
- `service.yaml` – ClusterIP / LoadBalancer
- `ingress.yaml` – optional, based on cluster ingress controller
- `configmap.yaml`, `secret.yaml` – configuration of cloud credentials when needed

You can use the same manifests with:

```bash
kubectl apply -f .
```

and then specialize in:

- `../aws`   – EKS-specific settings (IRSA, load balancers, etc.)
- `../azure` – AKS-specific settings (managed identities, ingress)
- `../gcp`   – GKE-specific settings (Workload Identity, load balancers)

