#!/bin/bash

# Rice Development Kubernetes Helm Chart Management Script

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

# Function to print colored output
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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed. Please install helm first."
        exit 1
    fi
    
    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to add Helm repositories
add_repositories() {
    print_status "Adding Helm repositories..."
    
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    
    print_success "Helm repositories added and updated"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing chart dependencies..."
    
    cd "$CHART_DIR"
    helm dependency update
    
    print_success "Chart dependencies installed"
}

# Function to install the chart
install_chart() {
    print_status "Installing Rice Development Kubernetes chart..."
    
    cd "$CHART_DIR"
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Install the chart
    helm install "$RELEASE_NAME" . -n "$NAMESPACE" --create-namespace
    
    print_success "Chart installed successfully"
}

# Function to upgrade the chart
upgrade_chart() {
    print_status "Upgrading Rice Development Kubernetes chart..."
    
    cd "$CHART_DIR"
    helm upgrade "$RELEASE_NAME" . -n "$NAMESPACE"
    
    print_success "Chart upgraded successfully"
}

# Function to uninstall the chart
uninstall_chart() {
    print_warning "This will uninstall the Rice Development Kubernetes chart and all its resources."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Uninstalling chart..."
        helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
        print_success "Chart uninstalled successfully"
    else
        print_status "Uninstall cancelled"
    fi
}

# Function to get ArgoCD admin password
get_argocd_password() {
    print_status "Getting ArgoCD admin password..."
    
    PASSWORD=$(kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
    
    if [ -n "$PASSWORD" ]; then
        print_success "ArgoCD admin password: $PASSWORD"
        print_status "ArgoCD URL: https://argocd.rice-dev.local"
        print_status "Username: admin"
    else
        print_warning "Could not retrieve ArgoCD admin password. The secret might not exist yet."
    fi
}

# Function to show status
show_status() {
    print_status "Showing chart status..."
    
    echo
    echo "=== Helm Release Status ==="
    helm list -n "$NAMESPACE"
    
    echo
    echo "=== Pod Status ==="
    kubectl get pods -n "$NAMESPACE"
    
    echo
    echo "=== Services ==="
    kubectl get services -n "$NAMESPACE"
    
    echo
    echo "=== Ingress ==="
    kubectl get ingress -n "$NAMESPACE"
    
    echo
    echo "=== ArgoCD Applications ==="
    kubectl get applications -n "$NAMESPACE" 2>/dev/null || echo "No ArgoCD applications found"
}

# Function to port forward ArgoCD
port_forward_argocd() {
    print_status "Starting port forward for ArgoCD server..."
    print_status "ArgoCD will be available at: http://localhost:8080"
    print_status "Press Ctrl+C to stop"
    
    kubectl port-forward -n "$NAMESPACE" svc/"$RELEASE_NAME"-argo-cd-server 8080:80
}

# Function to show help
show_help() {
    echo "Rice Development Kubernetes Helm Chart Management Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  install     Install the chart"
    echo "  upgrade     Upgrade the chart"
    echo "  uninstall   Uninstall the chart"
    echo "  status      Show chart status"
    echo "  password    Get ArgoCD admin password"
    echo "  port-forward Start port forward for ArgoCD"
    echo "  help        Show this help message"
    echo
    echo "Examples:"
    echo "  $0 install"
    echo "  $0 status"
    echo "  $0 password"
}

# Main script logic
case "${1:-help}" in
    install)
        check_prerequisites
        add_repositories
        install_dependencies
        install_chart
        get_argocd_password
        ;;
    upgrade)
        check_prerequisites
        add_repositories
        install_dependencies
        upgrade_chart
        ;;
    uninstall)
        uninstall_chart
        ;;
    status)
        show_status
        ;;
    password)
        get_argocd_password
        ;;
    port-forward)
        port_forward_argocd
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
