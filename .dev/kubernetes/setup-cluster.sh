#!/bin/bash

# Rice-Mono Kubernetes Cluster Setup
# Complete setup script for local development cluster

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}"
cat <<"EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     ██████╗ ██╗ ██████╗███████╗    ██╗  ██╗ █████╗ ███████╗ ║
║     ██╔══██╗██║██╔════╝██╔════╝    ██║ ██╔╝██╔══██╗██╔════╝ ║
║     ██████╔╝██║██║     █████╗      █████╔╝ ╚█████╔╝███████╗ ║
║     ██╔══██╗██║██║     ██╔══╝      ██╔═██╗ ██╔══██╗╚════██║ ║
║     ██║  ██║██║╚██████╗███████╗    ██║  ██╗╚█████╔╝███████║ ║
║     ╚═╝  ╚═╝╚═╝ ╚═════╝╚══════╝    ╚═╝  ╚═╝ ╚════╝ ╚══════╝ ║
║                                                               ║
║             Kubernetes Cluster Setup                          ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

CLUSTER_NAME="rice-mono"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if kubectl and kind are installed
if ! command -v kubectl &>/dev/null; then
  echo -e "${RED}✗${NC} kubectl not found"
  echo -e "${YELLOW}Run: ./.dev/scripts/setup-all.sh${NC}"
  exit 1
fi

if ! command -v kind &>/dev/null; then
  echo -e "${RED}✗${NC} kind not found"
  echo -e "${YELLOW}Run: ./.dev/scripts/setup-all.sh${NC}"
  exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 1/5: Creating kind cluster${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo -e "${YELLOW}!${NC} Cluster '${CLUSTER_NAME}' already exists"
  read -p "Do you want to recreate it? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Deleting existing cluster...${NC}"
    kind delete cluster --name ${CLUSTER_NAME}
  else
    echo -e "${GREEN}✓${NC} Using existing cluster"
    kubectl cluster-info --context kind-${CLUSTER_NAME}
    exit 0
  fi
fi

# Create kind cluster with custom configuration
cat <<EOF | kind create cluster --name ${CLUSTER_NAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
  - role: worker
  - role: worker
networking:
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/16"
EOF

echo -e "${GREEN}✓${NC} Cluster created successfully"
echo

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 2/5: Installing NGINX Ingress Controller${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo -e "${BLUE}Waiting for ingress controller to be ready...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo -e "${GREEN}✓${NC} NGINX Ingress Controller installed"
echo

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 3/5: Installing Metrics Server${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch metrics server for kind
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'

echo -e "${GREEN}✓${NC} Metrics Server installed"
echo

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 4/5: Creating namespaces${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

kubectl create namespace rice-mono --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace rice-mono-dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace rice-mono-staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

kubectl label namespace rice-mono name=rice-mono --overwrite
kubectl label namespace rice-mono-dev name=rice-mono-dev --overwrite

echo -e "${GREEN}✓${NC} Namespaces created"
echo

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 5/5: Setting up development secrets${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Create dummy secrets for development
kubectl create secret generic backend-secrets \
  --from-literal=DATABASE_PASSWORD=dev_password \
  --from-literal=REDIS_PASSWORD=redis_dev \
  --from-literal=JWT_SECRET=dev_jwt_secret \
  --namespace=rice-mono \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic bot-secrets \
  --from-literal=OPENAI_API_KEY=sk-dev-key \
  --from-literal=HUGGINGFACE_TOKEN=hf_dev_token \
  --namespace=rice-mono \
  --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✓${NC} Development secrets created"
echo

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║          🎉  Cluster Setup Complete!  🎉                  ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${CYAN}Cluster Information:${NC}"
kubectl cluster-info --context kind-${CLUSTER_NAME}
echo

echo -e "${CYAN}Nodes:${NC}"
kubectl get nodes
echo

echo -e "${CYAN}Namespaces:${NC}"
kubectl get namespaces
echo

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Next Steps:${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "  ${CYAN}1.${NC} Build Docker images:"
echo -e "     ${BLUE}./dev/kubernetes/build-images.sh${NC}"
echo
echo -e "  ${CYAN}2.${NC} Deploy applications:"
echo -e "     ${BLUE}./dev/kubernetes/deploy-all.sh${NC}"
echo
echo -e "  ${CYAN}3.${NC} Check deployment status:"
echo -e "     ${BLUE}kubectl get pods -n rice-mono${NC}"
echo
echo -e "  ${CYAN}4.${NC} Access services:"
echo -e "     ${BLUE}kubectl port-forward svc/rice-backend 8080:8080 -n rice-mono${NC}"
echo
echo -e "${GREEN}Happy deploying! 🚀${NC}"
echo
