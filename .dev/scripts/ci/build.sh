#!/bin/bash
# =============================================================================
# BUILD SCRIPT - Docker Image Build for CI/CD
# =============================================================================

set -euo pipefail

# Default values
SERVICE_NAME="${SERVICE_NAME:-}"
VERSION="${VERSION:-latest}"
REGISTRY="${REGISTRY:-rice-mono}"
DOCKER_FILE="${DOCKER_FILE:-Dockerfile}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"
PUSH="${PUSH:-false}"

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

IMAGE_NAME="${REGISTRY}/${SERVICE_NAME}"
IMAGE_TAG="${IMAGE_NAME}:${VERSION}"

log_info "Building Docker image: $IMAGE_TAG"

# Build image
docker build \
  -t "$IMAGE_TAG" \
  -f "$DOCKER_FILE" \
  --build-arg VERSION="$VERSION" \
  --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --build-arg VCS_REF="${GIT_COMMIT:-$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')}" \
  "$BUILD_CONTEXT"

log_success "Image built: $IMAGE_TAG"

# Tag as latest
if [ "$VERSION" != "latest" ]; then
  docker tag "$IMAGE_TAG" "${IMAGE_NAME}:latest"
  log_success "Tagged as latest"
fi

# Push to registry
if [ "$PUSH" = "true" ]; then
  log_info "Pushing to registry..."

  docker push "$IMAGE_TAG"

  if [ "$VERSION" != "latest" ]; then
    docker push "${IMAGE_NAME}:latest"
  fi

  log_success "Pushed to registry"
fi

# Output image details
echo ""
echo "Image: $IMAGE_TAG"
echo "Size: $(docker images "$IMAGE_TAG" --format '{{.Size}}')"
echo "ID: $(docker images "$IMAGE_TAG" --format '{{.ID}}')"
