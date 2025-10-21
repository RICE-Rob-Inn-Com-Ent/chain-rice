#!/bin/bash

# Rice-Mono Kubeconfig Setup Script
# This script helps configure kubeconfig with proper credentials

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECONFIG_FILE="${SCRIPT_DIR}/kubeconfig.yaml"
KUBECONFIG_TEMPLATE="${SCRIPT_DIR}/kubeconfig.yaml"
ENV_FILE="${SCRIPT_DIR}/.kubeconfig.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required commands exist
check_dependencies() {
  local missing_deps=()

  for cmd in kubectl openssl base64; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_deps+=("$cmd")
    fi
  done

  if [ ${#missing_deps[@]} -ne 0 ]; then
    log_error "Missing required dependencies: ${missing_deps[*]}"
    log_info "Please install them and try again."
    exit 1
  fi
}

# Load environment variables from .kubeconfig.env
load_env() {
  if [ -f "$ENV_FILE" ]; then
    log_info "Loading credentials from $ENV_FILE"
    # shellcheck disable=SC1090
    source "$ENV_FILE"
  else
    log_warning "Environment file not found: $ENV_FILE"
    log_info "You can create it from .kubeconfig.env.example"
  fi
}

# Base64 encode a file
encode_file() {
  local file="$1"
  if [ -f "$file" ]; then
    base64 -w 0 <"$file"
  else
    log_error "File not found: $file"
    return 1
  fi
}

# Generate self-signed certificates for local development
generate_local_certs() {
  log_info "Generating self-signed certificates for local development..."

  local certs_dir="${SCRIPT_DIR}/certs"
  mkdir -p "$certs_dir"

  # Generate CA
  if [ ! -f "${certs_dir}/ca.key" ]; then
    openssl genrsa -out "${certs_dir}/ca.key" 4096
    openssl req -new -x509 -days 3650 -key "${certs_dir}/ca.key" \
      -out "${certs_dir}/ca.crt" \
      -subj "/CN=rice-mono-ca/O=rice-mono"
    log_success "Generated CA certificate"
  fi

  # Generate client certificate
  if [ ! -f "${certs_dir}/client.key" ]; then
    openssl genrsa -out "${certs_dir}/client.key" 4096
    openssl req -new -key "${certs_dir}/client.key" \
      -out "${certs_dir}/client.csr" \
      -subj "/CN=rice-mono-admin/O=system:masters"
    openssl x509 -req -days 3650 -in "${certs_dir}/client.csr" \
      -CA "${certs_dir}/ca.crt" -CAkey "${certs_dir}/ca.key" \
      -CAcreateserial -out "${certs_dir}/client.crt"
    log_success "Generated client certificate"
  fi

  log_success "Certificates generated in ${certs_dir}"
  log_info "You can now use these for local development"
}

# Setup kubeconfig for local development (minikube/kind/k3s)
setup_local() {
  log_info "Setting up kubeconfig for local development..."

  local cluster_type="$1"

  case "$cluster_type" in
    minikube)
      log_info "Configuring for Minikube..."
      if command -v minikube &>/dev/null; then
        minikube update-context
        log_success "Minikube context updated"
      else
        log_error "Minikube not found"
        exit 1
      fi
      ;;
    kind)
      log_info "Configuring for Kind..."
      if command -v kind &>/dev/null; then
        kind get kubeconfig --name rice-mono >/tmp/kind-kubeconfig
        log_success "Kind kubeconfig exported"
      else
        log_error "Kind not found"
        exit 1
      fi
      ;;
    k3s)
      log_info "Configuring for K3s..."
      if [ -f /etc/rancher/k3s/k3s.yaml ]; then
        sudo cat /etc/rancher/k3s/k3s.yaml >/tmp/k3s-kubeconfig
        log_success "K3s kubeconfig exported"
      else
        log_error "K3s not found"
        exit 1
      fi
      ;;
    *)
      log_error "Unknown cluster type: $cluster_type"
      log_info "Supported types: minikube, kind, k3s"
      exit 1
      ;;
  esac
}

# Setup kubeconfig for cloud providers
setup_cloud() {
  local provider="$1"

  case "$provider" in
    eks)
      log_info "Setting up AWS EKS..."
      if [ -z "$AWS_CLUSTER_NAME" ] || [ -z "$AWS_REGION" ]; then
        log_error "AWS_CLUSTER_NAME and AWS_REGION must be set"
        exit 1
      fi

      aws eks update-kubeconfig \
        --region "$AWS_REGION" \
        --name "$AWS_CLUSTER_NAME" \
        --alias rice-mono-eks
      log_success "EKS kubeconfig updated"
      ;;
    gke)
      log_info "Setting up Google GKE..."
      if [ -z "$GCP_CLUSTER_NAME" ] || [ -z "$GCP_REGION" ] || [ -z "$GCP_PROJECT" ]; then
        log_error "GCP_CLUSTER_NAME, GCP_REGION, and GCP_PROJECT must be set"
        exit 1
      fi

      gcloud container clusters get-credentials "$GCP_CLUSTER_NAME" \
        --region "$GCP_REGION" \
        --project "$GCP_PROJECT"
      log_success "GKE kubeconfig updated"
      ;;
    aks)
      log_info "Setting up Azure AKS..."
      if [ -z "$AZURE_CLUSTER_NAME" ] || [ -z "$AZURE_RESOURCE_GROUP" ]; then
        log_error "AZURE_CLUSTER_NAME and AZURE_RESOURCE_GROUP must be set"
        exit 1
      fi

      az aks get-credentials \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --name "$AZURE_CLUSTER_NAME" \
        --overwrite-existing
      log_success "AKS kubeconfig updated"
      ;;
    *)
      log_error "Unknown cloud provider: $provider"
      log_info "Supported providers: eks, gke, aks"
      exit 1
      ;;
  esac
}

# Create service account and get token
create_service_account() {
  local namespace="${1:-default}"
  local sa_name="${2:-rice-mono-sa}"

  log_info "Creating service account: $sa_name in namespace: $namespace"

  # Create namespace if it doesn't exist
  kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

  # Create service account
  kubectl create serviceaccount "$sa_name" -n "$namespace" --dry-run=client -o yaml | kubectl apply -f -

  # Create cluster role binding
  kubectl create clusterrolebinding "${sa_name}-binding" \
    --clusterrole=cluster-admin \
    --serviceaccount="${namespace}:${sa_name}" \
    --dry-run=client -o yaml | kubectl apply -f -

  # Get token
  local token
  token=$(kubectl create token "$sa_name" -n "$namespace" --duration=87600h)

  log_success "Service account created"
  log_info "Token: $token"
  echo "$token"
}

# Validate kubeconfig
validate_kubeconfig() {
  log_info "Validating kubeconfig..."

  if kubectl config view --minify &>/dev/null; then
    log_success "Kubeconfig is valid"

    log_info "Testing cluster connection..."
    if kubectl cluster-info &>/dev/null; then
      log_success "Successfully connected to cluster"
    else
      log_warning "Could not connect to cluster"
    fi
  else
    log_error "Kubeconfig is invalid"
    exit 1
  fi
}

# Merge kubeconfig files
merge_kubeconfig() {
  log_info "Merging kubeconfig files..."

  local source_kubeconfig="$1"
  local target_kubeconfig="${KUBECONFIG:-$HOME/.kube/config}"

  if [ ! -f "$source_kubeconfig" ]; then
    log_error "Source kubeconfig not found: $source_kubeconfig"
    exit 1
  fi

  # Backup existing kubeconfig
  if [ -f "$target_kubeconfig" ]; then
    cp "$target_kubeconfig" "${target_kubeconfig}.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backed up existing kubeconfig"
  fi

  # Merge configs
  KUBECONFIG="${target_kubeconfig}:${source_kubeconfig}" kubectl config view --flatten >/tmp/merged-kubeconfig
  mv /tmp/merged-kubeconfig "$target_kubeconfig"
  chmod 600 "$target_kubeconfig"

  log_success "Kubeconfig merged successfully"
}

# Display usage
usage() {
  cat <<EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    local [minikube|kind|k3s]   Setup kubeconfig for local development
    cloud [eks|gke|aks]         Setup kubeconfig for cloud provider
    generate-certs              Generate self-signed certificates
    create-sa [namespace] [name] Create service account and get token
    validate                    Validate kubeconfig
    merge [source]              Merge kubeconfig files
    help                        Display this help message

Examples:
    $0 local minikube           Setup for Minikube
    $0 cloud eks                Setup for AWS EKS
    $0 generate-certs           Generate local certificates
    $0 create-sa rice-mono-dev  Create service account
    $0 validate                 Validate current kubeconfig
    $0 merge ./other-config.yaml Merge kubeconfig files

Environment Variables:
    AWS_CLUSTER_NAME            AWS EKS cluster name
    AWS_REGION                  AWS region
    GCP_CLUSTER_NAME            GCP GKE cluster name
    GCP_REGION                  GCP region
    GCP_PROJECT                 GCP project ID
    AZURE_CLUSTER_NAME          Azure AKS cluster name
    AZURE_RESOURCE_GROUP        Azure resource group

For more information, see KUBECONFIG.md
EOF
}

# Main function
main() {
  check_dependencies
  load_env

  case "${1:-help}" in
    local)
      setup_local "${2:-minikube}"
      validate_kubeconfig
      ;;
    cloud)
      setup_cloud "${2:-eks}"
      validate_kubeconfig
      ;;
    generate-certs)
      generate_local_certs
      ;;
    create-sa)
      create_service_account "${2:-default}" "${3:-rice-mono-sa}"
      ;;
    validate)
      validate_kubeconfig
      ;;
    merge)
      merge_kubeconfig "${2:-$KUBECONFIG_FILE}"
      ;;
    help | --help | -h)
      usage
      ;;
    *)
      log_error "Unknown command: $1"
      usage
      exit 1
      ;;
  esac
}

# Run main function
main "$@"
