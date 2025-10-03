#!/bin/bash

# Rice Development Kubernetes Helm Chart - Mock Installation Script
# This script demonstrates the installation process without requiring a real cluster

set -e

CHART_DIR="/home/mrDinkelman/rice-dev/tools/k8s"
RELEASE_NAME="rice-dev-k8s"
NAMESPACE="rice-dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🚀 Rice Development Kubernetes Helm Chart Installation"
echo "======================================================"
echo ""

print_status "Checking prerequisites..."

# Check if kubectl is available in nix shell
if command -v kubectl &> /dev/null; then
    print_success "kubectl is available"
    kubectl version --client --short 2>/dev/null || echo "kubectl version check failed"
else
    print_error "kubectl is not available. Please run: nix develop .#k8s"
    exit 1
fi

# Check if helm is available in nix shell
if command -v helm &> /dev/null; then
    print_success "helm is available"
    helm version --short 2>/dev/null || echo "helm version check failed"
else
    print_error "helm is not available. Please run: nix develop .#k8s"
    exit 1
fi

print_status "Adding Helm repositories..."
echo "Would run: helm repo add argo https://argoproj.github.io/argo-helm"
echo "Would run: helm repo add bitnami https://charts.bitnami.com/bitnami"
echo "Would run: helm repo update"

print_status "Installing chart dependencies..."
echo "Would run: helm dependency update"

print_status "Installing Rice Development Kubernetes chart..."
echo "Would run: helm install $RELEASE_NAME . -n $NAMESPACE --create-namespace"

echo ""
print_warning "⚠️  MOCK INSTALLATION COMPLETE"
echo ""
print_status "To run this for real, you need:"
echo "1. A Kubernetes cluster (Docker Desktop, minikube, kind, or cloud cluster)"
echo "2. Docker installed (for kind/minikube)"
echo "3. Run: nix develop .#k8s"
echo "4. Run: ./manage.sh install"
echo ""
print_status "Cluster setup options:"
echo ""
echo "Option 1 - Docker Desktop:"
echo "  - Install Docker Desktop"
echo "  - Enable Kubernetes in Docker Desktop settings"
echo "  - Run: ./manage.sh install"
echo ""
echo "Option 2 - minikube:"
echo "  - Install Docker"
echo "  - Run: minikube start"
echo "  - Run: ./manage.sh install"
echo ""
echo "Option 3 - kind (Kubernetes in Docker):"
echo "  - Install Docker"
echo "  - Run: kind create cluster --name rice-dev-cluster"
echo "  - Run: ./manage.sh install"
echo ""
echo "Option 4 - Cloud cluster:"
echo "  - Set up kubeconfig for your cloud provider"
echo "  - Run: ./manage.sh install"
echo ""
print_success "ArgoCD Helm chart is ready to deploy!"
print_status "Chart location: $CHART_DIR"
print_status "Values file: $CHART_DIR/values.yaml"
print_status "Templates: $CHART_DIR/templates/"
print_status "Management script: $CHART_DIR/manage.sh"
