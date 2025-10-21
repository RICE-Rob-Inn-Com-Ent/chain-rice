#!/bin/bash
# =============================================================================
# ROLLBACK SCRIPT - Rollback Kubernetes Deployment
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Required variables
SERVICE_NAME="${SERVICE_NAME:-}"
NAMESPACE="${NAMESPACE:-dev}"
REVISION="${REVISION:-0}" # 0 means previous revision

if [ -z "$SERVICE_NAME" ]; then
  log_error "SERVICE_NAME is required"
  exit 1
fi

# Show rollout history
log_info "Rollout history for $SERVICE_NAME:"
kubectl rollout history deployment/"$SERVICE_NAME" -n "$NAMESPACE"

# Determine target revision
if [ "$REVISION" = "0" ]; then
  log_info "Rolling back to previous revision..."
  kubectl rollout undo deployment/"$SERVICE_NAME" -n "$NAMESPACE"
else
  log_info "Rolling back to revision $REVISION..."
  kubectl rollout undo deployment/"$SERVICE_NAME" -n "$NAMESPACE" --to-revision="$REVISION"
fi

# Wait for rollback
kubectl rollout status deployment/"$SERVICE_NAME" -n "$NAMESPACE" --timeout=5m

log_success "Rollback completed successfully"

# Verify
CURRENT_REVISION=$(kubectl rollout history deployment/"$SERVICE_NAME" -n "$NAMESPACE" | tail -1 | awk '{print $1}')
READY_REPLICAS=$(kubectl get deployment "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')

echo ""
echo "Current revision: $CURRENT_REVISION"
echo "Ready replicas: $READY_REPLICAS"
