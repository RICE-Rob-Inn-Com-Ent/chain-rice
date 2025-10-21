#!/bin/bash
# =============================================================================
# ADD PROJECT SCRIPT - Automated Project Onboarding
# =============================================================================
# This script automates the complete setup for a new project/service
#
# Usage: ./add-project.sh [options]
# Options:
#   --name NAME         Project name (required)
#   --type TYPE         Project type: backend|frontend|bot|service
#   --language LANG     Programming language
#   --port PORT         Service port
#   --database yes|no   Needs database
#   --cache yes|no      Needs cache
#   --env ENV           Environments (comma-separated)
#   --interactive       Interactive mode
#   --help              Show help
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
PROJECT_NAME=""
PROJECT_TYPE=""
LANGUAGE=""
PORT=""
NEEDS_DATABASE="no"
NEEDS_CACHE="no"
ENVIRONMENTS="dev"
INTERACTIVE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --name)
      PROJECT_NAME="$2"
      shift 2
      ;;
    --type)
      PROJECT_TYPE="$2"
      shift 2
      ;;
    --language)
      LANGUAGE="$2"
      shift 2
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --database)
      NEEDS_DATABASE="$2"
      shift 2
      ;;
    --cache)
      NEEDS_CACHE="$2"
      shift 2
      ;;
    --env)
      ENVIRONMENTS="$2"
      shift 2
      ;;
    --interactive)
      INTERACTIVE=true
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
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

banner() {
  echo -e "${BLUE}"
  cat <<"EOF"
╔════════════════════════════════════════════╗
║   Add New Project to Infrastructure       ║
║   Automated Service Onboarding            ║
╚════════════════════════════════════════════╝
EOF
  echo -e "${NC}"
}

prompt() {
  local prompt_text="$1"
  local default_value="${2:-}"
  local user_input

  if [ -n "$default_value" ]; then
    read -p "$(echo -e ${BLUE}${prompt_text}${NC} [${default_value}]:)" user_input
    echo "${user_input:-$default_value}"
  else
    read -p "$(echo -e ${BLUE}${prompt_text}${NC}:)" user_input
    echo "$user_input"
  fi
}

interactive_mode() {
  banner
  log_info "Starting interactive project setup..."
  echo ""

  PROJECT_NAME=$(prompt "Project name (e.g., my-api)")

  echo -e "\n${BLUE}Project types:${NC}"
  echo "  1) backend   - Backend API service"
  echo "  2) frontend  - Frontend web application"
  echo "  3) bot       - Bot/Worker service"
  echo "  4) service   - Generic microservice"

  type_choice=$(prompt "Select type (1-4)" "1")
  case $type_choice in
    1) PROJECT_TYPE="backend" ;;
    2) PROJECT_TYPE="frontend" ;;
    3) PROJECT_TYPE="bot" ;;
    4) PROJECT_TYPE="service" ;;
  esac

  echo -e "\n${BLUE}Programming languages:${NC}"
  echo "  1) go        - Golang"
  echo "  2) python    - Python"
  echo "  3) node      - Node.js"
  echo "  4) rust      - Rust"
  echo "  5) java      - Java"

  lang_choice=$(prompt "Select language (1-5)" "1")
  case $lang_choice in
    1) LANGUAGE="go" ;;
    2) LANGUAGE="python" ;;
    3) LANGUAGE="node" ;;
    4) LANGUAGE="rust" ;;
    5) LANGUAGE="java" ;;
  esac

  PORT=$(prompt "Service port" "8080")
  NEEDS_DATABASE=$(prompt "Needs database? (yes/no)" "no")
  NEEDS_CACHE=$(prompt "Needs cache? (yes/no)" "no")
  ENVIRONMENTS=$(prompt "Environments (comma-separated)" "dev,staging,prod")

  echo ""
}

validate_inputs() {
  if [ -z "$PROJECT_NAME" ]; then
    log_error "Project name is required"
    exit 1
  fi

  if [ -z "$PROJECT_TYPE" ]; then
    log_error "Project type is required"
    exit 1
  fi

  if [[ ! "$PROJECT_TYPE" =~ ^(backend|frontend|bot|service)$ ]]; then
    log_error "Invalid project type: $PROJECT_TYPE"
    exit 1
  fi
}

create_terraform_module() {
  log_info "Creating Terraform module..."

  local module_dir="$DEV_DIR/terraform/modules/$PROJECT_NAME"
  mkdir -p "$module_dir"

  # main.tf
  cat >"$module_dir/main.tf" <<EOF
# Terraform module for $PROJECT_NAME

resource "aws_ecs_task_definition" "$PROJECT_NAME" {
  family                   = "\${var.name_prefix}-$PROJECT_NAME"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory

  container_definitions = jsonencode([
    {
      name      = "$PROJECT_NAME"
      image     = "\${var.image_repository}:\${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = $PORT
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "PORT"
          value = "$PORT"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/$PROJECT_NAME"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "$PROJECT_NAME" {
  name            = "$PROJECT_NAME"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.$PROJECT_NAME.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.$PROJECT_NAME.arn
    container_name   = "$PROJECT_NAME"
    container_port   = $PORT
  }

  tags = var.tags
}

resource "aws_lb_target_group" "$PROJECT_NAME" {
  name     = "$PROJECT_NAME"
  port     = $PORT
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = var.tags
}
EOF

  # variables.tf
  cat >"$module_dir/variables.tf" <<'EOF'
variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "image_repository" {
  description = "Docker image repository"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "cpu" {
  description = "CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired task count"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
EOF

  # outputs.tf
  cat >"$module_dir/outputs.tf" <<EOF
output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.$PROJECT_NAME.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.$PROJECT_NAME.name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.$PROJECT_NAME.arn
}
EOF

  log_success "Terraform module created at $module_dir"
}

create_kubernetes_manifests() {
  log_info "Creating Kubernetes manifests..."

  local k8s_dir="$DEV_DIR/k8s/charts/$PROJECT_NAME"
  mkdir -p "$k8s_dir/templates"

  # Chart.yaml
  cat >"$k8s_dir/Chart.yaml" <<EOF
apiVersion: v2
name: $PROJECT_NAME
description: Helm chart for $PROJECT_NAME service
type: application
version: 1.0.0
appVersion: "1.0.0"
EOF

  # values.yaml
  cat >"$k8s_dir/values.yaml" <<EOF
replicaCount: 2

image:
  repository: rice-mono/$PROJECT_NAME
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  targetPort: $PORT

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: $PROJECT_NAME.rice-mono.local
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: $PROJECT_NAME-tls
      hosts:
        - $PROJECT_NAME.rice-mono.local

resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

env:
  - name: ENVIRONMENT
    value: "dev"
  - name: PORT
    value: "$PORT"
EOF

  # deployment.yaml template
  cat >"$k8s_dir/templates/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "chart.fullname" . }}
  labels:
    {{- include "chart.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "chart.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
          protocol: TCP
        env:
          {{- toYaml .Values.env | nindent 10 }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
EOF

  log_success "Kubernetes manifests created at $k8s_dir"
}

create_ansible_role() {
  log_info "Creating Ansible role..."

  local role_dir="$DEV_DIR/ansible/roles/$PROJECT_NAME"

  # Initialize role
  cd "$DEV_DIR/ansible/roles"
  ansible-galaxy init "$PROJECT_NAME" --force

  # Update tasks/main.yml
  cat >"$role_dir/tasks/main.yml" <<EOF
---
# Tasks for $PROJECT_NAME

- name: Create application directory
  file:
    path: "/opt/$PROJECT_NAME"
    state: directory
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0755'

- name: Deploy application configuration
  template:
    src: config.yml.j2
    dest: "/opt/$PROJECT_NAME/config.yml"
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0644'
  notify: Restart $PROJECT_NAME

- name: Deploy systemd service
  template:
    src: $PROJECT_NAME.service.j2
    dest: "/etc/systemd/system/$PROJECT_NAME.service"
    mode: '0644'
  notify:
    - Reload systemd
    - Restart $PROJECT_NAME

- name: Enable and start $PROJECT_NAME service
  systemd:
    name: $PROJECT_NAME
    enabled: true
    state: started
    daemon_reload: true
EOF

  # Create handler
  cat >"$role_dir/handlers/main.yml" <<EOF
---
- name: Reload systemd
  systemd:
    daemon_reload: true

- name: Restart $PROJECT_NAME
  systemd:
    name: $PROJECT_NAME
    state: restarted
EOF

  log_success "Ansible role created at $role_dir"
}

create_argocd_application() {
  log_info "Creating ArgoCD application..."

  local argocd_file="$DEV_DIR/k8s/argocd/$PROJECT_NAME-app.yaml"
  mkdir -p "$(dirname "$argocd_file")"

  cat >"$argocd_file" <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $PROJECT_NAME
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: rice-mono

  source:
    repoURL: https://github.com/rice-mono/rice-mono.git
    targetRevision: HEAD
    path: .dev/k8s/charts/$PROJECT_NAME
    helm:
      valueFiles:
        - values.yaml

  destination:
    server: https://kubernetes.default.svc
    namespace: dev

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

  log_success "ArgoCD application created at $argocd_file"
}

create_ci_cd_pipeline() {
  log_info "Creating CI/CD pipeline..."

  local pipeline_file="$DEV_DIR/../.github/workflows/$PROJECT_NAME.yml"
  mkdir -p "$(dirname "$pipeline_file")"

  cat >"$pipeline_file" <<EOF
name: $PROJECT_NAME CI/CD

on:
  push:
    branches: [ main, develop ]
    paths:
      - '$PROJECT_NAME/**'
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Build Docker image
      run: |
        docker build -t rice-mono/$PROJECT_NAME:\${{ github.sha }} ./$PROJECT_NAME

    - name: Run tests
      run: |
        docker run rice-mono/$PROJECT_NAME:\${{ github.sha }} test

    - name: Push to registry
      if: github.ref == 'refs/heads/main'
      run: |
        echo "\${{ secrets.DOCKER_PASSWORD }}" | docker login -u "\${{ secrets.DOCKER_USERNAME }}" --password-stdin
        docker push rice-mono/$PROJECT_NAME:\${{ github.sha }}
        docker tag rice-mono/$PROJECT_NAME:\${{ github.sha }} rice-mono/$PROJECT_NAME:latest
        docker push rice-mono/$PROJECT_NAME:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/$PROJECT_NAME $PROJECT_NAME=rice-mono/$PROJECT_NAME:\${{ github.sha }} -n dev
EOF

  log_success "CI/CD pipeline created at $pipeline_file"
}

display_summary() {
  echo -e "\n${GREEN}╔════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   ✓ Project Added Successfully!           ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}\n"

  echo -e "${BLUE}Project Details:${NC}"
  echo -e "  • Name:       ${YELLOW}$PROJECT_NAME${NC}"
  echo -e "  • Type:       ${YELLOW}$PROJECT_TYPE${NC}"
  echo -e "  • Language:   ${YELLOW}$LANGUAGE${NC}"
  echo -e "  • Port:       ${YELLOW}$PORT${NC}"
  echo -e "  • Database:   ${YELLOW}$NEEDS_DATABASE${NC}"
  echo -e "  • Cache:      ${YELLOW}$NEEDS_CACHE${NC}"

  echo -e "\n${BLUE}Created Resources:${NC}"
  echo -e "  ✓ Terraform module: ${YELLOW}.dev/terraform/modules/$PROJECT_NAME${NC}"
  echo -e "  ✓ Helm chart: ${YELLOW}.dev/k8s/charts/$PROJECT_NAME${NC}"
  echo -e "  ✓ Ansible role: ${YELLOW}.dev/ansible/roles/$PROJECT_NAME${NC}"
  echo -e "  ✓ ArgoCD app: ${YELLOW}.dev/k8s/argocd/$PROJECT_NAME-app.yaml${NC}"
  echo -e "  ✓ CI/CD pipeline: ${YELLOW}.github/workflows/$PROJECT_NAME.yml${NC}"

  echo -e "\n${BLUE}Next Steps:${NC}"
  echo -e "  1. Review and customize generated files"
  echo -e "  2. Update Terraform main.tf to include the new module"
  echo -e "  3. Update ArgoCD project to include the new application"
  echo -e "  4. Deploy: ${YELLOW}helm install $PROJECT_NAME .dev/k8s/charts/$PROJECT_NAME${NC}"
  echo ""
}

# Main execution
main() {
  if [ "$INTERACTIVE" = true ]; then
    interactive_mode
  fi

  validate_inputs
  banner

  log_info "Adding project: $PROJECT_NAME ($PROJECT_TYPE)"
  echo ""

  create_terraform_module
  create_kubernetes_manifests
  create_ansible_role
  create_argocd_application
  create_ci_cd_pipeline

  display_summary
}

main "$@"
