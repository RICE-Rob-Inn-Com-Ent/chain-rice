#!/bin/bash
# =============================================================================
# HEALTH CHECK SCRIPT - Comprehensive System Health Check
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
VERBOSE=false
FORMAT="text" # text or json

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --verbose | -v)
      VERBOSE=true
      shift
      ;;
    --json)
      FORMAT="json"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Results storage
declare -A CHECKS

# Functions
log_info() { [ "$FORMAT" = "text" ] && echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { [ "$FORMAT" = "text" ] && echo -e "${GREEN}✓${NC} $1"; }
log_warning() { [ "$FORMAT" = "text" ] && echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { [ "$FORMAT" = "text" ] && echo -e "${RED}✗${NC} $1"; }

check_terraform() {
  log_info "Checking Terraform state..."

  cd "$DEV_DIR/terraform"

  if terraform workspace select "$ENVIRONMENT" 2>/dev/null; then
    local state_ok=$(terraform state list | wc -l)
    if [ "$state_ok" -gt 0 ]; then
      CHECKS[terraform]="OK"
      log_success "Terraform: $state_ok resources managed"
    else
      CHECKS[terraform]="WARNING"
      log_warning "Terraform: No resources in state"
    fi
  else
    CHECKS[terraform]="ERROR"
    log_error "Terraform: Workspace $ENVIRONMENT not found"
  fi
}

check_kubernetes() {
  log_info "Checking Kubernetes cluster..."

  local namespace="$ENVIRONMENT"

  # Check cluster connection
  if kubectl cluster-info &>/dev/null; then
    CHECKS[k8s_cluster]="OK"
    log_success "Kubernetes: Cluster accessible"
  else
    CHECKS[k8s_cluster]="ERROR"
    log_error "Kubernetes: Cannot connect to cluster"
    return
  fi

  # Check namespace
  if kubectl get namespace "$namespace" &>/dev/null; then
    CHECKS[k8s_namespace]="OK"
    log_success "Kubernetes: Namespace $namespace exists"
  else
    CHECKS[k8s_namespace]="WARNING"
    log_warning "Kubernetes: Namespace $namespace not found"
    return
  fi

  # Check pods
  local total_pods=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | wc -l)
  local running_pods=$(kubectl get pods -n "$namespace" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
  local failed_pods=$(kubectl get pods -n "$namespace" --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)

  if [ "$total_pods" -eq "$running_pods" ] && [ "$failed_pods" -eq 0 ]; then
    CHECKS[k8s_pods]="OK"
    log_success "Kubernetes: All $total_pods pods running"
  elif [ "$failed_pods" -gt 0 ]; then
    CHECKS[k8s_pods]="ERROR"
    log_error "Kubernetes: $failed_pods pods failed"
  else
    CHECKS[k8s_pods]="WARNING"
    log_warning "Kubernetes: $running_pods/$total_pods pods running"
  fi

  # Check services
  local services=$(kubectl get svc -n "$namespace" --no-headers 2>/dev/null | wc -l)
  if [ "$services" -gt 0 ]; then
    CHECKS[k8s_services]="OK"
    log_success "Kubernetes: $services services deployed"
  else
    CHECKS[k8s_services]="WARNING"
    log_warning "Kubernetes: No services found"
  fi
}

check_endpoints() {
  log_info "Checking service endpoints..."

  local namespace="$ENVIRONMENT"

  # Get all ingresses
  while IFS= read -r line; do
    local name=$(echo "$line" | awk '{print $1}')
    local host=$(echo "$line" | awk '{print $2}')

    if [ -n "$host" ] && [ "$host" != "<none>" ]; then
      if curl -k -s -f -o /dev/null "https://$host/health" 2>/dev/null; then
        CHECKS[endpoint_$name]="OK"
        log_success "Endpoint: https://$host - OK"
      else
        CHECKS[endpoint_$name]="ERROR"
        log_error "Endpoint: https://$host - FAILED"
      fi
    fi
  done < <(kubectl get ingress -n "$namespace" --no-headers 2>/dev/null)
}

check_resources() {
  log_info "Checking resource usage..."

  local namespace="$ENVIRONMENT"

  # Get resource metrics (requires metrics-server)
  if kubectl top nodes &>/dev/null; then
    local node_count=$(kubectl top nodes --no-headers | wc -l)
    CHECKS[resources_nodes]="OK"
    log_success "Resources: $node_count nodes monitored"

    if [ "$VERBOSE" = true ]; then
      kubectl top nodes
    fi
  else
    CHECKS[resources_nodes]="WARNING"
    log_warning "Resources: Metrics not available (install metrics-server)"
  fi

  # Check pod resources
  if kubectl top pods -n "$namespace" &>/dev/null; then
    local pod_count=$(kubectl top pods -n "$namespace" --no-headers | wc -l)
    CHECKS[resources_pods]="OK"
    log_success "Resources: $pod_count pods monitored"

    if [ "$VERBOSE" = true ]; then
      kubectl top pods -n "$namespace"
    fi
  else
    CHECKS[resources_pods]="WARNING"
    log_warning "Resources: Pod metrics not available"
  fi
}

check_storage() {
  log_info "Checking persistent storage..."

  local namespace="$ENVIRONMENT"

  local pvcs=$(kubectl get pvc -n "$namespace" --no-headers 2>/dev/null | wc -l)
  local bound_pvcs=$(kubectl get pvc -n "$namespace" --field-selector=status.phase=Bound --no-headers 2>/dev/null | wc -l)

  if [ "$pvcs" -eq "$bound_pvcs" ]; then
    CHECKS[storage]="OK"
    log_success "Storage: All $pvcs PVCs bound"
  else
    CHECKS[storage]="WARNING"
    log_warning "Storage: $bound_pvcs/$pvcs PVCs bound"
  fi
}

check_networking() {
  log_info "Checking network policies..."

  local namespace="$ENVIRONMENT"

  local netpol_count=$(kubectl get networkpolicy -n "$namespace" --no-headers 2>/dev/null | wc -l)

  if [ "$netpol_count" -gt 0 ]; then
    CHECKS[networking]="OK"
    log_success "Networking: $netpol_count network policies active"
  else
    CHECKS[networking]="WARNING"
    log_warning "Networking: No network policies found"
  fi
}

check_security() {
  log_info "Checking security configuration..."

  local namespace="$ENVIRONMENT"

  # Check RBAC
  local roles=$(kubectl get role -n "$namespace" --no-headers 2>/dev/null | wc -l)
  local rolebindings=$(kubectl get rolebinding -n "$namespace" --no-headers 2>/dev/null | wc -l)

  if [ "$roles" -gt 0 ] && [ "$rolebindings" -gt 0 ]; then
    CHECKS[security_rbac]="OK"
    log_success "Security: RBAC configured ($roles roles, $rolebindings bindings)"
  else
    CHECKS[security_rbac]="WARNING"
    log_warning "Security: RBAC not fully configured"
  fi

  # Check secrets
  local secrets=$(kubectl get secrets -n "$namespace" --no-headers 2>/dev/null | wc -l) # pragma: allowlist secret

  if [ "$secrets" -gt 0 ]; then
    CHECKS[security_secrets]="OK"                       # pragma: allowlist secret
    log_success "Security: $secrets secrets configured" # pragma: allowlist secret
  else
    CHECKS[security_secrets]="WARNING"       # pragma: allowlist secret
    log_warning "Security: No secrets found" # pragma: allowlist secret
  fi
}

generate_report() {
  if [ "$FORMAT" = "json" ]; then
    # JSON output
    echo "{"
    echo "  \"environment\": \"$ENVIRONMENT\","
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"checks\": {"

    local first=true
    for check in "${!CHECKS[@]}"; do
      if [ "$first" = true ]; then
        first=false
      else
        echo ","
      fi
      echo -n "    \"$check\": \"${CHECKS[$check]}\""
    done

    echo ""
    echo "  }"
    echo "}"
  else
    # Text output
    echo -e "\n${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}           Health Check Summary            ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}\n"

    echo -e "${BLUE}Environment:${NC} $ENVIRONMENT"
    echo -e "${BLUE}Timestamp:${NC} $(date)"
    echo ""

    local ok_count=0
    local warning_count=0
    local error_count=0

    for check in "${!CHECKS[@]}"; do
      local status="${CHECKS[$check]}"
      case $status in
        OK)
          echo -e "  ${GREEN}✓${NC} $check: ${GREEN}OK${NC}"
          ((ok_count++))
          ;;
        WARNING)
          echo -e "  ${YELLOW}⚠${NC} $check: ${YELLOW}WARNING${NC}"
          ((warning_count++))
          ;;
        ERROR)
          echo -e "  ${RED}✗${NC} $check: ${RED}ERROR${NC}"
          ((error_count++))
          ;;
      esac
    done

    echo ""
    echo -e "${BLUE}Summary:${NC}"
    echo -e "  ${GREEN}✓${NC} OK: $ok_count"
    echo -e "  ${YELLOW}⚠${NC} Warnings: $warning_count"
    echo -e "  ${RED}✗${NC} Errors: $error_count"
    echo ""

    if [ "$error_count" -gt 0 ]; then
      echo -e "${RED}Status: UNHEALTHY${NC}"
      exit 1
    elif [ "$warning_count" -gt 0 ]; then
      echo -e "${YELLOW}Status: DEGRADED${NC}"
      exit 0
    else
      echo -e "${GREEN}Status: HEALTHY${NC}"
      exit 0
    fi
  fi
}

# Main execution
main() {
  [ "$FORMAT" = "text" ] && echo -e "${BLUE}🏥 Rice-Mono Health Check${NC}\n"

  check_terraform
  check_kubernetes
  check_endpoints
  check_resources
  check_storage
  check_networking
  check_security

  generate_report
}

main "$@"
