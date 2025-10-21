#!/bin/bash
# =============================================================================
# SETUP SCRIPT - Initial DevOps Environment Setup
# =============================================================================
# This script sets up the complete DevOps environment
#
# Usage: ./setup.sh [options]
# Options:
#   --skip-tools    Skip tool installation
#   --skip-config   Skip configuration
#   --help          Show this help message
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$DEV_DIR")"

# Flags
SKIP_TOOLS=false
SKIP_CONFIG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-tools)
      SKIP_TOOLS=true
      shift
      ;;
    --skip-config)
      SKIP_CONFIG=true
      shift
      ;;
    --help)
      head -20 "$0" | grep "^#" | sed 's/^# //'
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Functions
log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

banner() {
  echo -e "${BLUE}"
  cat <<"EOF"
╔═══════════════════════════════════════════╗
║   Rice-Mono DevOps Environment Setup     ║
║   Professional Infrastructure Automation  ║
╚═══════════════════════════════════════════╝
EOF
  echo -e "${NC}"
}

check_os() {
  log_info "Detecting operating system..."

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      DISTRO=$ID
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    DISTRO="macos"
  else
    log_error "Unsupported OS: $OSTYPE"
    exit 1
  fi

  log_success "Detected: $OS ($DISTRO)"
}

install_tools() {
  if [ "$SKIP_TOOLS" = true ]; then
    log_warning "Skipping tool installation"
    return
  fi

  log_info "Installing required tools..."

  # Docker
  if ! command -v docker &>/dev/null; then
    log_info "Installing Docker..."
    if [ "$OS" = "linux" ]; then
      curl -fsSL https://get.docker.com | sh
      sudo usermod -aG docker $USER
    elif [ "$OS" = "macos" ]; then
      log_warning "Please install Docker Desktop manually: https://www.docker.com/products/docker-desktop"
    fi
  else
    log_success "Docker already installed"
  fi

  # kubectl
  if ! command -v kubectl &>/dev/null; then
    log_info "Installing kubectl..."
    if [ "$OS" = "linux" ]; then
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
      rm kubectl
    elif [ "$OS" = "macos" ]; then
      brew install kubectl
    fi
  else
    log_success "kubectl already installed"
  fi

  # Helm
  if ! command -v helm &>/dev/null; then
    log_info "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  else
    log_success "Helm already installed"
  fi

  # Terraform
  if ! command -v terraform &>/dev/null; then
    log_info "Installing Terraform..."
    TERRAFORM_VERSION="1.10.0"
    if [ "$OS" = "linux" ]; then
      wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
      unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
      sudo mv terraform /usr/local/bin/
      rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    elif [ "$OS" = "macos" ]; then
      brew install terraform
    fi
  else
    log_success "Terraform already installed"
  fi

  # Ansible
  if ! command -v ansible &>/dev/null; then
    log_info "Installing Ansible..."
    if [ "$OS" = "linux" ]; then
      if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
        sudo apt update
        sudo apt install -y ansible
      elif [ "$DISTRO" = "fedora" ] || [ "$DISTRO" = "centos" ] || [ "$DISTRO" = "rhel" ]; then
        sudo dnf install -y ansible
      elif [ "$DISTRO" = "arch" ]; then
        sudo pacman -S --noconfirm ansible
      fi
    elif [ "$OS" = "macos" ]; then
      brew install ansible
    fi
  else
    log_success "Ansible already installed"
  fi

  # ArgoCD CLI
  if ! command -v argocd &>/dev/null; then
    log_info "Installing ArgoCD CLI..."
    if [ "$OS" = "linux" ]; then
      curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
      sudo install -m 555 argocd /usr/local/bin/argocd
      rm argocd
    elif [ "$OS" = "macos" ]; then
      brew install argocd
    fi
  else
    log_success "ArgoCD CLI already installed"
  fi

  log_success "All tools installed successfully"
}

configure_ansible() {
  log_info "Configuring Ansible..."

  cd "$DEV_DIR/ansible"

  # Install Ansible dependencies
  if [ -f requirements.yml ]; then
    log_info "Installing Ansible collections and roles..."
    ansible-galaxy install -r requirements.yml --force
    ansible-galaxy collection install kubernetes.core --force
  fi

  # Create log directory
  mkdir -p logs cache

  log_success "Ansible configured"
}

configure_terraform() {
  log_info "Configuring Terraform..."

  cd "$DEV_DIR/terraform"

  # Initialize Terraform
  log_info "Initializing Terraform..."
  terraform init

  # Create workspaces
  for env in dev staging prod; do
    if ! terraform workspace list | grep -q "$env"; then
      terraform workspace new "$env" || true
    fi
  done

  terraform workspace select dev

  log_success "Terraform configured"
}

configure_kubernetes() {
  log_info "Configuring Kubernetes..."

  cd "$DEV_DIR/k8s"

  # Update Helm dependencies
  if [ -f Chart.yaml ]; then
    log_info "Updating Helm dependencies..."
    helm dependency update
  fi

  log_success "Kubernetes configured"
}

create_directories() {
  log_info "Creating necessary directories..."

  # Ansible
  mkdir -p "$DEV_DIR/ansible/"{logs,cache,roles,playbooks,inventory}

  # Terraform
  mkdir -p "$DEV_DIR/terraform/"{.terraform,environments,backends}

  # Scripts
  mkdir -p "$DEV_DIR/scripts/"{ansible,terraform,k8s}

  # Configs
  mkdir -p "$DEV_DIR/configs/"{environments,secrets,policies}

  log_success "Directories created"
}

display_summary() {
  echo -e "\n${GREEN}╔═══════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   ✓ Setup Completed Successfully!        ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}\n"

  echo -e "${BLUE}Installed Tools:${NC}"
  echo -e "  • Docker:    $(docker --version 2>/dev/null || echo 'Not installed')"
  echo -e "  • kubectl:   $(kubectl version --client --short 2>/dev/null || echo 'Not installed')"
  echo -e "  • Helm:      $(helm version --short 2>/dev/null || echo 'Not installed')"
  echo -e "  • Terraform: $(terraform version -json 2>/dev/null | jq -r '.terraform_version' || echo 'Not installed')"
  echo -e "  • Ansible:   $(ansible --version 2>/dev/null | head -1 || echo 'Not installed')"
  echo -e "  • ArgoCD:    $(argocd version --client --short 2>/dev/null || echo 'Not installed')"

  echo -e "\n${BLUE}Next Steps:${NC}"
  echo -e "  1. Configure cloud credentials (AWS, Azure, GCP)"
  echo -e "  2. Update inventory files in ${YELLOW}ansible/inventory/${NC}"
  echo -e "  3. Update environment configs in ${YELLOW}terraform/environments/${NC}"
  echo -e "  4. Run: ${YELLOW}./scripts/deploy-all.sh --env dev${NC}"

  echo -e "\n${BLUE}Documentation:${NC}"
  echo -e "  • Main README:   ${YELLOW}.dev/README.md${NC}"
  echo -e "  • Ansible Guide: ${YELLOW}.dev/docs/ANSIBLE.md${NC}"
  echo -e "  • K8s Guide:     ${YELLOW}.dev/docs/KUBERNETES.md${NC}"
  echo -e "  • Terraform Guide: ${YELLOW}.dev/docs/TERRAFORM.md${NC}"

  echo ""
}

# Main execution
main() {
  banner
  check_os
  create_directories
  install_tools

  if [ "$SKIP_CONFIG" = false ]; then
    configure_ansible
    configure_terraform
    configure_kubernetes
  fi

  display_summary
}

main "$@"
