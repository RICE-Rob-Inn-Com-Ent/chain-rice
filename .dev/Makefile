# Rice-Mono DevOps Makefile
# Professional automation for infrastructure management

.PHONY: help setup deploy test clean health rollback

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

# Default environment
ENV ?= dev

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "$(BLUE)Rice-Mono DevOps Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Environment Variables:$(NC)"
	@echo "  ENV=$(ENV)     (dev/staging/prod)"
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "  make setup                    # Initial setup"
	@echo "  make deploy ENV=dev          # Deploy to dev"
	@echo "  make health ENV=prod         # Check prod health"
	@echo "  make add-service NAME=my-api # Add new service"

setup: ## Setup DevOps environment
	@echo "$(BLUE)Setting up DevOps environment...$(NC)"
	@./scripts/setup.sh
	@echo "$(GREEN)✓ Setup completed$(NC)"

deploy: ## Deploy infrastructure (ENV=dev|staging|prod)
	@echo "$(BLUE)Deploying to $(ENV)...$(NC)"
	@./scripts/deploy-all.sh --env $(ENV)
	@echo "$(GREEN)✓ Deployment completed$(NC)"

deploy-dry-run: ## Dry run deployment (ENV=dev|staging|prod)
	@echo "$(BLUE)Dry run deployment to $(ENV)...$(NC)"
	@./scripts/deploy-all.sh --env $(ENV) --dry-run

terraform-init: ## Initialize Terraform
	@cd terraform && terraform init

terraform-plan: ## Plan Terraform changes (ENV=dev|staging|prod)
	@cd terraform && \
		terraform workspace select $(ENV) && \
		terraform plan -var-file="environments/$(ENV).tfvars"

terraform-apply: ## Apply Terraform changes (ENV=dev|staging|prod)
	@cd terraform && \
		terraform workspace select $(ENV) && \
		terraform apply -var-file="environments/$(ENV).tfvars"

terraform-destroy: ## Destroy Terraform resources (ENV=dev|staging|prod)
	@cd terraform && \
		terraform workspace select $(ENV) && \
		terraform destroy -var-file="environments/$(ENV).tfvars"

ansible-ping: ## Ping all hosts (ENV=dev|staging|prod)
	@cd ansible && \
		ansible all -i inventory/$(ENV)/ -m ping

ansible-deploy: ## Run Ansible playbooks (ENV=dev|staging|prod)
	@cd ansible && \
		ansible-playbook playbooks/site.yml -i inventory/$(ENV)/

k8s-deploy: ## Deploy Kubernetes resources (ENV=dev|staging|prod)
	@cd k8s && \
		helm upgrade --install rice-mono . \
		--namespace $(ENV) \
		--create-namespace \
		--values values.yaml \
		--values values-$(ENV).yaml

k8s-status: ## Check Kubernetes status (ENV=dev|staging|prod)
	@kubectl get all -n $(ENV)

k8s-pods: ## List pods (ENV=dev|staging|prod)
	@kubectl get pods -n $(ENV)

k8s-logs: ## View logs for SERVICE (ENV=dev|staging|prod SERVICE=name)
	@kubectl logs -f deployment/$(SERVICE) -n $(ENV)

health: ## Run health checks (ENV=dev|staging|prod)
	@echo "$(BLUE)Running health checks for $(ENV)...$(NC)"
	@./scripts/health-check.sh --env $(ENV)

health-verbose: ## Run verbose health checks (ENV=dev|staging|prod)
	@./scripts/health-check.sh --env $(ENV) --verbose

health-json: ## Run health checks with JSON output (ENV=dev|staging|prod)
	@./scripts/health-check.sh --env $(ENV) --json

add-service: ## Add new service (NAME=service-name)
	@echo "$(BLUE)Adding new service: $(NAME)$(NC)"
	@./scripts/add-project.sh --name $(NAME) --interactive

rollback: ## Rollback deployment (ENV=dev|staging|prod SERVICE=name)
	@echo "$(YELLOW)Rolling back $(SERVICE) in $(ENV)...$(NC)"
	@SERVICE_NAME=$(SERVICE) NAMESPACE=$(ENV) ./scripts/ci/rollback.sh
	@echo "$(GREEN)✓ Rollback completed$(NC)"

test: ## Run all tests
	@echo "$(BLUE)Running tests...$(NC)"
	@./scripts/ci/test.sh
	@echo "$(GREEN)✓ Tests passed$(NC)"

test-unit: ## Run unit tests
	@TEST_TYPE=unit ./scripts/ci/test.sh

test-integration: ## Run integration tests
	@TEST_TYPE=integration ./scripts/ci/test.sh

test-e2e: ## Run E2E tests
	@TEST_TYPE=e2e ./scripts/ci/test.sh

build: ## Build Docker images (SERVICE=name VERSION=tag)
	@echo "$(BLUE)Building $(SERVICE):$(VERSION)...$(NC)"
	@SERVICE_NAME=$(SERVICE) VERSION=$(VERSION) ./scripts/ci/build.sh

build-push: ## Build and push Docker images (SERVICE=name VERSION=tag)
	@SERVICE_NAME=$(SERVICE) VERSION=$(VERSION) PUSH=true ./scripts/ci/build.sh

logs: ## Stream logs (ENV=dev|staging|prod)
	@kubectl logs -f --all-containers --tail=100 -n $(ENV)

shell: ## Open shell in pod (ENV=dev|staging|prod POD=name)
	@kubectl exec -it $(POD) -n $(ENV) -- /bin/sh

port-forward: ## Port forward service (ENV=dev|staging|prod SERVICE=name LOCAL=8080 REMOTE=80)
	@kubectl port-forward svc/$(SERVICE) $(LOCAL):$(REMOTE) -n $(ENV)

clean: ## Clean temporary files
	@echo "$(BLUE)Cleaning temporary files...$(NC)"
	@find . -type f -name '*.pyc' -delete
	@find . -type d -name '__pycache__' -delete
	@find . -type d -name '.terraform' -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name 'terraform.tfstate.backup' -delete
	@echo "$(GREEN)✓ Cleaned$(NC)"

format: ## Format all code
	@echo "$(BLUE)Formatting code...$(NC)"
	@cd terraform && terraform fmt -recursive
	@cd ansible && ansible-lint playbooks/ || true
	@echo "$(GREEN)✓ Formatted$(NC)"

validate: ## Validate all configurations
	@echo "$(BLUE)Validating configurations...$(NC)"
	@cd terraform && terraform validate
	@cd ansible && ansible-playbook playbooks/site.yml --syntax-check
	@cd k8s && helm lint .
	@echo "$(GREEN)✓ Validation passed$(NC)"

docs: ## Generate documentation
	@echo "$(BLUE)Documentation available at:$(NC)"
	@echo "  - Main:       $(GREEN).dev/README.md$(NC)"
	@echo "  - Quick Start: $(GREEN).dev/QUICKSTART.md$(NC)"
	@echo "  - Ansible:    $(GREEN).dev/docs/ANSIBLE.md$(NC)"
	@echo "  - Kubernetes: $(GREEN).dev/docs/KUBERNETES.md$(NC)"
	@echo "  - Terraform:  $(GREEN).dev/docs/TERRAFORM.md$(NC)"
	@echo "  - Workflows:  $(GREEN).dev/docs/WORKFLOWS.md$(NC)"

info: ## Display infrastructure info
	@echo "$(BLUE)Infrastructure Information$(NC)"
	@echo ""
	@echo "$(BLUE)Terraform:$(NC)"
	@cd terraform && terraform workspace list
	@echo ""
	@echo "$(BLUE)Kubernetes:$(NC)"
	@kubectl config current-context
	@echo ""
	@echo "$(BLUE)Namespaces:$(NC)"
	@kubectl get namespaces
	@echo ""
	@echo "$(BLUE)Services in $(ENV):$(NC)"
	@kubectl get svc -n $(ENV)

watch: ## Watch pods (ENV=dev|staging|prod)
	@watch -n 2 kubectl get pods -n $(ENV)

dashboard: ## Open Kubernetes dashboard
	@echo "$(BLUE)Opening Kubernetes dashboard...$(NC)"
	@kubectl proxy &
	@sleep 2
	@echo "$(GREEN)Dashboard available at: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/$(NC)"

grafana: ## Open Grafana dashboard
	@echo "$(BLUE)Opening Grafana...$(NC)"
	@kubectl port-forward svc/grafana 3000:80 -n monitoring &
	@sleep 2
	@echo "$(GREEN)Grafana available at: http://localhost:3000$(NC)"

argocd: ## Open ArgoCD dashboard
	@echo "$(BLUE)Opening ArgoCD...$(NC)"
	@kubectl port-forward svc/argocd-server 8080:443 -n argocd &
	@sleep 2
	@echo "$(GREEN)ArgoCD available at: https://localhost:8080$(NC)"
	@echo "$(YELLOW)Password:$(NC) $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"

all: clean format validate test deploy health ## Run complete CI/CD pipeline

dev: ENV=dev deploy health ## Quick deploy to dev

staging: ENV=staging deploy health ## Quick deploy to staging

prod: ENV=prod deploy health ## Quick deploy to production
