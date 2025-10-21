#!/bin/bash
# =============================================================================
# DEPLOY ALL SCRIPT - Complete Infrastructure Deployment
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
ENVIRONMENT="dev"
SKIP_TERRAFORM=false
SKIP_ANSIBLE=false
SKIP_KUBERNETES=false
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --skip-terraform)
      SKIP_TERRAFORM=true
      shift
      ;;
    --skip-ansible)
      SKIP_ANSIBLE=true
      shift
      ;;
    --skip-kubernetes)
      SKIP_KUBERNETES=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --env ENV           Environment (dev/staging/prod)"
      echo "  --skip-terraform    Skip Terraform deployment"
      echo "  --skip-ansible      Skip Ansible deployment"
      echo "  --skip-kubernetes   Skip Kubernetes deployment"
      echo "  --dry-run          Show what would be done"
      echo "  --help             Show this help"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Functions
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

banner() {
  echo -e "${BLUE}"
  cat <<"EOF"
╔════════════════════════════════════════════╗
║   Complete Infrastructure Deployment      ║
║   Terraform → Ansible → Kubernetes        ║
╚════════════════════════════════════════════╝
EOF
  echo -e "${NC}"
}

check_prerequisites() {
  log_info "Checking prerequisites..."

  local missing=()

  command -v terraform >/dev/null 2>&1 || missing+=("terraform")
  command -v ansible >/dev/null 2>&1 || missing+=("ansible")
  command -v kubectl >/dev/null 2>&1 || missing+=("kubectl")
  command -v helm >/dev/null 2>&1 || missing+=("helm")

  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Missing tools: ${missing[*]}"
    log_info "Run: ./scripts/setup.sh"
    exit 1
  fi

  log_success "All prerequisites met"
}

deploy_terraform() {
  if [ "$SKIP_TERRAFORM" = true ]; then
    log_warning "Skipping Terraform deployment"
    return
  fi

  log_info "Deploying Terraform infrastructure..."

  cd "$DEV_DIR/terraform"

  # Select workspace
  terraform workspace select "$ENVIRONMENT" || terraform workspace new "$ENVIRONMENT"

  # Initialize
  terraform init

  if [ "$DRY_RUN" = true ]; then
    terraform plan -var-file="environments/${ENVIRONMENT}.tfvars"
  else
    terraform apply -var-file="environments/${ENVIRONMENT}.tfvars" -auto-approve
  fi

  log_success "Terraform deployment completed"
}

deploy_ansible() {
  if [ "$SKIP_ANSIBLE" = true ]; then
    log_warning "Skipping Ansible deployment"
    return
  fi

  log_info "Deploying with Ansible..."

  cd "$DEV_DIR/ansible"

  local inventory="inventory/${ENVIRONMENT}/"

  if [ ! -d "$inventory" ]; then
    log_error "Inventory not found: $inventory"
    exit 1
  fi

  if [ "$DRY_RUN" = true ]; then
    ansible-playbook playbooks/site.yml -i "$inventory" --check
  else
    ansible-playbook playbooks/site.yml -i "$inventory"
  fi

  log_success "Ansible deployment completed"
}

deploy_kubernetes() {
  if [ "$SKIP_KUBERNETES" = true ]; then
    log_warning "Skipping Kubernetes deployment"
    return
  fi

  log_info "Deploying to Kubernetes..."

  cd "$DEV_DIR/k8s"

  local namespace="${ENVIRONMENT}"
  local values_file="values-${ENVIRONMENT}.yaml"

  # Create namespace if not exists
  kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

  if [ "$DRY_RUN" = true ]; then
    helm upgrade --install rice-mono . \
      --namespace "$namespace" \
      --values values.yaml \
      ${values_file:+--values "$values_file"} \
      --dry-run --debug
  else
    helm upgrade --install rice-mono . \
      --namespace "$namespace" \
      --values values.yaml \
      ${values_file:+--values "$values_file"} \
      --wait --timeout 10m
  fi

  log_success "Kubernetes deployment completed"
}

verify_deployment() {
  log_info "Verifying deployment..."

  # Check Kubernetes pods
  local namespace="${ENVIRONMENT}"

  echo -e "\n${BLUE}Pod Status:${NC}"
  kubectl get pods -n "$namespace"

  echo -e "\n${BLUE}Service Status:${NC}"
  kubectl get svc -n "$namespace"

  echo -e "\n${BLUE}Ingress Status:${NC}"
  kubectl get ingress -n "$namespace"

  # Run health checks
  if [ -f "$DEV_DIR/ansible/playbooks/health-check.yml" ]; then
    log_info "Running health checks..."
    cd "$DEV_DIR/ansible"
    ansible-playbook playbooks/health-check.yml -i "inventory/${ENVIRONMENT}/"
  fi

  log_success "Verification completed"
}

display_summary() {
  echo -e "\n${GREEN}╔════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   ✓ Deployment Completed Successfully!    ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}\n"

  echo -e "${BLUE}Environment:${NC} ${YELLOW}${ENVIRONMENT}${NC}"
  echo -e "${BLUE}Namespace:${NC} ${YELLOW}${ENVIRONMENT}${NC}"

  echo -e "\n${BLUE}Access URLs:${NC}"
  kubectl get ingress -n "$ENVIRONMENT" -o custom-columns=NAME:.metadata.name,HOSTS:.spec.rules[*].host --no-headers | while read name hosts; do
    echo -e "  • ${name}: ${YELLOW}https://${hosts}${NC}"
  done

  echo -e "\n${BLUE}Useful Commands:${NC}"
  echo -e "  • View pods:      ${YELLOW}kubectl get pods -n ${ENVIRONMENT}${NC}"
  echo -e "  • View logs:      ${YELLOW}kubectl logs -f <pod-name> -n ${ENVIRONMENT}${NC}"
  echo -e "  • Port forward:   ${YELLOW}kubectl port-forward svc/<service> 8080:80 -n ${ENVIRONMENT}${NC}"
  echo ""
}

# Main execution
main() {
  banner

  log_info "Deploying to environment: $ENVIRONMENT"

  if [ "$DRY_RUN" = true ]; then
    log_warning "DRY RUN MODE - No actual changes will be made"
  fi

  echo ""

  check_prerequisites
  deploy_terraform
  deploy_ansible
  deploy_kubernetes

  if [ "$DRY_RUN" = false ]; then
    verify_deployment
    display_summary
  fi
}

main "$@"
