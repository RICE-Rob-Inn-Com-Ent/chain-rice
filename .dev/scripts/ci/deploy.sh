#!/bin/bash
# =============================================================================
# DEPLOY SCRIPT - Deploy to Kubernetes from CI/CD
# =============================================================================

set -euo pipefail

# Required environment variables
SERVICE_NAME="${SERVICE_NAME:-}"
VERSION="${VERSION:-latest}"
NAMESPACE="${NAMESPACE:-dev}"
CLUSTER="${CLUSTER:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

if [ -z "$SERVICE_NAME" ]; then
  log_error "SERVICE_NAME is required"
  exit 1
fi

# Configure kubectl context
if [ -n "$CLUSTER" ]; then
  log_info "Configuring kubectl for cluster: $CLUSTER"

  if [[ "$CLUSTER" == eks://* ]]; then
    # AWS EKS
    CLUSTER_NAME=${CLUSTER#eks://}
    aws eks update-kubeconfig --name "$CLUSTER_NAME"
  elif [[ "$CLUSTER" == gke://* ]]; then
    # Google GKE
    CLUSTER_NAME=${CLUSTER#gke://}
    gcloud container clusters get-credentials "$CLUSTER_NAME"
  elif [[ "$CLUSTER" == aks://* ]]; then
    # Azure AKS
    CLUSTER_NAME=${CLUSTER#aks://}
    az aks get-credentials --name "$CLUSTER_NAME"
  fi
fi

# Deployment strategy
STRATEGY="${DEPLOYMENT_STRATEGY:-rolling}"

deploy_rolling() {
  log_info "Deploying with rolling update strategy..."

  kubectl set image deployment/"$SERVICE_NAME" \
    "$SERVICE_NAME=rice-mono/$SERVICE_NAME:$VERSION" \
    -n "$NAMESPACE"

  kubectl rollout status deployment/"$SERVICE_NAME" \
    -n "$NAMESPACE" \
    --timeout=5m

  log_success "Rolling deployment completed"
}

deploy_blue_green() {
  log_info "Deploying with blue-green strategy..."

  # Create new deployment (green)
  kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${SERVICE_NAME}-green
  namespace: ${NAMESPACE}
spec:
  replicas: $(kubectl get deployment "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
  selector:
    matchLabels:
      app: ${SERVICE_NAME}
      version: green
  template:
    metadata:
      labels:
        app: ${SERVICE_NAME}
        version: green
    spec:
      containers:
      - name: ${SERVICE_NAME}
        image: rice-mono/${SERVICE_NAME}:${VERSION}
EOF

  # Wait for green deployment
  kubectl rollout status deployment/"${SERVICE_NAME}-green" -n "$NAMESPACE" --timeout=5m

  # Switch traffic
  kubectl patch service "$SERVICE_NAME" -n "$NAMESPACE" -p '{"spec":{"selector":{"version":"green"}}}'

  log_success "Blue-green deployment completed"

  # Cleanup old deployment
  log_info "Cleaning up old deployment..."
  kubectl delete deployment "$SERVICE_NAME" -n "$NAMESPACE" --ignore-not-found
  kubectl get deployment "${SERVICE_NAME}-green" -n "$NAMESPACE" -o yaml |
    sed "s/${SERVICE_NAME}-green/${SERVICE_NAME}/" |
    kubectl apply -f -
  kubectl delete deployment "${SERVICE_NAME}-green" -n "$NAMESPACE"
}

deploy_canary() {
  log_info "Deploying with canary strategy..."

  CANARY_PERCENTAGE="${CANARY_PERCENTAGE:-10}"

  # Create canary deployment
  kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${SERVICE_NAME}-canary
  namespace: ${NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${SERVICE_NAME}
      version: canary
  template:
    metadata:
      labels:
        app: ${SERVICE_NAME}
        version: canary
    spec:
      containers:
      - name: ${SERVICE_NAME}
        image: rice-mono/${SERVICE_NAME}:${VERSION}
EOF

  kubectl rollout status deployment/"${SERVICE_NAME}-canary" -n "$NAMESPACE" --timeout=5m

  log_success "Canary deployment completed at ${CANARY_PERCENTAGE}%"
  log_info "Monitor metrics before promoting canary"
}

# Execute deployment
case "$STRATEGY" in
  rolling)
    deploy_rolling
    ;;
  blue-green)
    deploy_blue_green
    ;;
  canary)
    deploy_canary
    ;;
  *)
    log_error "Unknown deployment strategy: $STRATEGY"
    exit 1
    ;;
esac

# Verify deployment
log_info "Verifying deployment..."

READY_REPLICAS=$(kubectl get deployment "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
DESIRED_REPLICAS=$(kubectl get deployment "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

if [ "$READY_REPLICAS" = "$DESIRED_REPLICAS" ]; then
  log_success "Deployment verified: $READY_REPLICAS/$DESIRED_REPLICAS replicas ready"
else
  log_error "Deployment verification failed: $READY_REPLICAS/$DESIRED_REPLICAS replicas ready"
  exit 1
fi

# Display deployment info
echo ""
echo "Service: $SERVICE_NAME"
echo "Version: $VERSION"
echo "Namespace: $NAMESPACE"
echo "Replicas: $READY_REPLICAS/$DESIRED_REPLICAS"
echo "Strategy: $STRATEGY"
