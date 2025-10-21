#!/bin/bash

# Rice-Mono Kubernetes Deployment Script
# Deploys all services using Helm charts

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  Deploying Rice-Mono to Kubernetes${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo

NAMESPACE="${1:-rice-mono}"
CLUSTER_NAME="rice-mono"
VERSION="${2:-latest}"

cd "$(dirname "$0")"

# Check if cluster exists
if ! kubectl cluster-info &>/dev/null; then
  echo -e "${RED}✗${NC} Kubernetes cluster not accessible"
  echo -e "${YELLOW}Run: ./setup-cluster.sh${NC}"
  exit 1
fi

# Check if Helm is installed
if ! command -v helm &>/dev/null; then
  echo -e "${RED}✗${NC} Helm not found"
  echo -e "${YELLOW}Install: brew install helm  OR  sudo pacman -S helm${NC}"
  exit 1
fi

echo -e "${BLUE}Deploying to namespace: ${NAMESPACE}${NC}"
echo -e "${BLUE}Image version: ${VERSION}${NC}"
echo

# Deploy Backend
echo -e "${BLUE}[1/3] Deploying Backend...${NC}"
helm upgrade --install rice-backend ./charts/backend \
  --namespace ${NAMESPACE} \
  --create-namespace \
  --set image.tag=${VERSION} \
  --wait \
  --timeout 5m

echo -e "${GREEN}✓${NC} Backend deployed"
echo

# Deploy Bot
echo -e "${BLUE}[2/3] Deploying Bot...${NC}"
if [ -d "./charts/bot" ]; then
  helm upgrade --install rice-bot ./charts/bot \
    --namespace ${NAMESPACE} \
    --set image.tag=${VERSION} \
    --wait \
    --timeout 5m
  echo -e "${GREEN}✓${NC} Bot deployed"
else
  echo -e "${YELLOW}!${NC} Bot chart not found, skipping..."
fi
echo

# Deploy Frontend
echo -e "${BLUE}[3/3] Deploying Frontend...${NC}"
if [ -d "./charts/frontend" ]; then
  helm upgrade --install rice-frontend ./charts/frontend \
    --namespace ${NAMESPACE} \
    --set image.tag=${VERSION} \
    --wait \
    --timeout 5m
  echo -e "${GREEN}✓${NC} Frontend deployed"
else
  echo -e "${YELLOW}!${NC} Frontend chart not found, skipping..."
fi
echo

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          🎉  Deployment Complete!  🎉                     ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${CYAN}Deployment Status:${NC}"
kubectl get pods -n ${NAMESPACE}
echo

echo -e "${CYAN}Services:${NC}"
kubectl get svc -n ${NAMESPACE}
echo

echo -e "${CYAN}Ingresses:${NC}"
kubectl get ingress -n ${NAMESPACE}
echo

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Access Your Services:${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "  ${CYAN}Backend API:${NC}"
echo -e "    ${BLUE}kubectl port-forward svc/rice-backend 8080:8080 -n ${NAMESPACE}${NC}"
echo -e "    ${BLUE}curl http://localhost:8080/health${NC}"
echo
echo -e "  ${CYAN}Bot Service:${NC}"
echo -e "    ${BLUE}kubectl port-forward svc/rice-bot 8000:8000 -n ${NAMESPACE}${NC}"
echo
echo -e "  ${CYAN}View Logs:${NC}"
echo -e "    ${BLUE}kubectl logs -f deployment/rice-backend -n ${NAMESPACE}${NC}"
echo
echo -e "  ${CYAN}Get Pod Status:${NC}"
echo -e "    ${BLUE}kubectl describe pod <pod-name> -n ${NAMESPACE}${NC}"
echo
echo -e "${GREEN}Happy deploying! 🚀${NC}"
echo
