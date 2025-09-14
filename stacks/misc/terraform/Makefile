# =============================================================================
# TERRAFORM MAKEFILE - ADVANCED INFRASTRUCTURE AUTOMATION
# =============================================================================
# 
# This Makefile provides convenient commands for managing Terraform
# infrastructure across multiple environments.
#
# Usage:
#   make help          - Show available commands
#   make init          - Initialize Terraform
#   make plan-dev      - Plan development environment
#   make apply-dev     - Apply development environment
#   make plan-prod     - Plan production environment
#   make apply-prod     - Apply production environment
#   make destroy-dev    - Destroy development environment
#   make validate      - Validate Terraform configuration
#   make fmt           - Format Terraform files
#   make test          - Run Terraform tests
# =============================================================================

# =============================================================================
# VARIABLES
# =============================================================================

# Default environment
ENV ?= dev

# Terraform variables file
TFVARS_FILE = $(ENV).tfvars

# Terraform workspace
WORKSPACE ?= $(ENV)

# AWS region
AWS_REGION ?= us-west-2

# Project name
PROJECT_NAME ?= advanced-infra

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
PURPLE = \033[0;35m
CYAN = \033[0;36m
WHITE = \033[0;37m
NC = \033[0m # No Color

# =============================================================================
# HELP
# =============================================================================

.PHONY: help
help: ## Show this help message
	@echo "$(CYAN)Advanced Infrastructure as Code - Terraform$(NC)"
	@echo "$(YELLOW)Available commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =============================================================================
# TERRAFORM COMMANDS
# =============================================================================

.PHONY: init
init: ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	terraform init
	@echo "$(GREEN)Terraform initialized successfully!$(NC)"

.PHONY: validate
validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	terraform validate
	@echo "$(GREEN)Terraform configuration is valid!$(NC)"

.PHONY: fmt
fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)Terraform files formatted!$(NC)"

.PHONY: fmt-check
fmt-check: ## Check Terraform formatting
	@echo "$(BLUE)Checking Terraform formatting...$(NC)"
	terraform fmt -check -recursive
	@echo "$(GREEN)Terraform formatting is correct!$(NC)"

.PHONY: plan
plan: ## Plan Terraform changes
	@echo "$(BLUE)Planning Terraform changes for $(ENV) environment...$(NC)"
	terraform plan -var-file="$(TFVARS_FILE)" -out="$(ENV).tfplan"
	@echo "$(GREEN)Terraform plan completed!$(NC)"

.PHONY: apply
apply: ## Apply Terraform changes
	@echo "$(BLUE)Applying Terraform changes for $(ENV) environment...$(NC)"
	terraform apply "$(ENV).tfplan"
	@echo "$(GREEN)Terraform apply completed!$(NC)"

.PHONY: destroy
destroy: ## Destroy Terraform infrastructure
	@echo "$(RED)Destroying Terraform infrastructure for $(ENV) environment...$(NC)"
	terraform destroy -var-file="$(TFVARS_FILE)" -auto-approve
	@echo "$(GREEN)Terraform destroy completed!$(NC)"

.PHONY: refresh
refresh: ## Refresh Terraform state
	@echo "$(BLUE)Refreshing Terraform state...$(NC)"
	terraform refresh -var-file="$(TFVARS_FILE)"
	@echo "$(GREEN)Terraform state refreshed!$(NC)"

.PHONY: output
output: ## Show Terraform outputs
	@echo "$(BLUE)Showing Terraform outputs...$(NC)"
	terraform output

.PHONY: show
show: ## Show Terraform state
	@echo "$(BLUE)Showing Terraform state...$(NC)"
	terraform show

# =============================================================================
# ENVIRONMENT-SPECIFIC COMMANDS
# =============================================================================

.PHONY: plan-dev
plan-dev: ## Plan development environment
	@$(MAKE) plan ENV=dev

.PHONY: apply-dev
apply-dev: ## Apply development environment
	@$(MAKE) apply ENV=dev

.PHONY: destroy-dev
destroy-dev: ## Destroy development environment
	@$(MAKE) destroy ENV=dev

.PHONY: plan-staging
plan-staging: ## Plan staging environment
	@$(MAKE) plan ENV=staging

.PHONY: apply-staging
apply-staging: ## Apply staging environment
	@$(MAKE) apply ENV=staging

.PHONY: destroy-staging
destroy-staging: ## Destroy staging environment
	@$(MAKE) destroy ENV=staging

.PHONY: plan-prod
plan-prod: ## Plan production environment
	@$(MAKE) plan ENV=prod

.PHONY: apply-prod
apply-prod: ## Apply production environment
	@$(MAKE) apply ENV=prod

.PHONY: destroy-prod
destroy-prod: ## Destroy production environment
	@$(MAKE) destroy ENV=prod

# =============================================================================
# WORKSPACE COMMANDS
# =============================================================================

.PHONY: workspace-list
workspace-list: ## List Terraform workspaces
	@echo "$(BLUE)Listing Terraform workspaces...$(NC)"
	terraform workspace list

.PHONY: workspace-new
workspace-new: ## Create new Terraform workspace
	@echo "$(BLUE)Creating new Terraform workspace: $(WORKSPACE)...$(NC)"
	terraform workspace new $(WORKSPACE)
	@echo "$(GREEN)Terraform workspace created!$(NC)"

.PHONY: workspace-select
workspace-select: ## Select Terraform workspace
	@echo "$(BLUE)Selecting Terraform workspace: $(WORKSPACE)...$(NC)"
	terraform workspace select $(WORKSPACE)
	@echo "$(GREEN)Terraform workspace selected!$(NC)"

.PHONY: workspace-delete
workspace-delete: ## Delete Terraform workspace
	@echo "$(RED)Deleting Terraform workspace: $(WORKSPACE)...$(NC)"
	terraform workspace delete $(WORKSPACE)
	@echo "$(GREEN)Terraform workspace deleted!$(NC)"

# =============================================================================
# TESTING COMMANDS
# =============================================================================

.PHONY: test
test: ## Run Terraform tests
	@echo "$(BLUE)Running Terraform tests...$(NC)"
	terraform test
	@echo "$(GREEN)Terraform tests completed!$(NC)"

.PHONY: test-modules
test-modules: ## Test Terraform modules
	@echo "$(BLUE)Testing Terraform modules...$(NC)"
	@for module in modules/*/; do \
		echo "$(YELLOW)Testing module: $$module$(NC)"; \
		cd $$module && terraform init && terraform validate && cd ../..; \
	done
	@echo "$(GREEN)All modules tested successfully!$(NC)"

# =============================================================================
# SECURITY COMMANDS
# =============================================================================

.PHONY: security-scan
security-scan: ## Run security scan on Terraform files
	@echo "$(BLUE)Running security scan...$(NC)"
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec .; \
	else \
		echo "$(YELLOW)tfsec not installed. Install with: brew install tfsec$(NC)"; \
	fi

.PHONY: security-check
security-check: ## Check Terraform security
	@echo "$(BLUE)Checking Terraform security...$(NC)"
	@if command -v checkov >/dev/null 2>&1; then \
		checkov -d .; \
	else \
		echo "$(YELLOW)checkov not installed. Install with: pip install checkov$(NC)"; \
	fi

# =============================================================================
# CLEANUP COMMANDS
# =============================================================================

.PHONY: clean
clean: ## Clean Terraform files
	@echo "$(BLUE)Cleaning Terraform files...$(NC)"
	rm -f *.tfplan
	rm -f .terraform.lock.hcl
	rm -rf .terraform/
	@echo "$(GREEN)Cleanup completed!$(NC)"

.PHONY: clean-all
clean-all: clean ## Clean all Terraform files and state
	@echo "$(RED)Cleaning all Terraform files and state...$(NC)"
	rm -f *.tfstate
	rm -f *.tfstate.backup
	rm -f *.tfplan
	rm -f .terraform.lock.hcl
	rm -rf .terraform/
	@echo "$(GREEN)Complete cleanup completed!$(NC)"

# =============================================================================
# DOCUMENTATION COMMANDS
# =============================================================================

.PHONY: docs
docs: ## Generate Terraform documentation
	@echo "$(BLUE)Generating Terraform documentation...$(NC)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown . > README.md; \
	else \
		echo "$(YELLOW)terraform-docs not installed. Install with: brew install terraform-docs$(NC)"; \
	fi

.PHONY: graph
graph: ## Generate Terraform graph
	@echo "$(BLUE)Generating Terraform graph...$(NC)"
	terraform graph | dot -Tpng > terraform-graph.png
	@echo "$(GREEN)Terraform graph generated!$(NC)"

# =============================================================================
# DEPLOYMENT COMMANDS
# =============================================================================

.PHONY: deploy-dev
deploy-dev: init validate plan-dev apply-dev ## Deploy development environment
	@echo "$(GREEN)Development environment deployed successfully!$(NC)"

.PHONY: deploy-staging
deploy-staging: init validate plan-staging apply-staging ## Deploy staging environment
	@echo "$(GREEN)Staging environment deployed successfully!$(NC)"

.PHONY: deploy-prod
deploy-prod: init validate plan-prod apply-prod ## Deploy production environment
	@echo "$(GREEN)Production environment deployed successfully!$(NC)"

# =============================================================================
# MONITORING COMMANDS
# =============================================================================

.PHONY: status
status: ## Show infrastructure status
	@echo "$(BLUE)Infrastructure Status:$(NC)"
	@echo "$(YELLOW)Environment: $(ENV)$(NC)"
	@echo "$(YELLOW)Region: $(AWS_REGION)$(NC)"
	@echo "$(YELLOW)Project: $(PROJECT_NAME)$(NC)"
	@terraform output

.PHONY: urls
urls: ## Show service URLs
	@echo "$(BLUE)Service URLs:$(NC)"
	@terraform output access_urls

# =============================================================================
# UTILITY COMMANDS
# =============================================================================

.PHONY: version
version: ## Show Terraform version
	@echo "$(BLUE)Terraform Version:$(NC)"
	terraform version

.PHONY: providers
providers: ## Show Terraform providers
	@echo "$(BLUE)Terraform Providers:$(NC)"
	terraform providers

.PHONY: state-list
state-list: ## List Terraform state resources
	@echo "$(BLUE)Terraform State Resources:$(NC)"
	terraform state list

.PHONY: state-show
state-show: ## Show Terraform state resource
	@echo "$(BLUE)Terraform State Resource:$(NC)"
	@if [ -z "$(RESOURCE)" ]; then \
		echo "$(RED)Please specify RESOURCE=resource_name$(NC)"; \
	else \
		terraform state show $(RESOURCE); \
	fi

# =============================================================================
# DEFAULT TARGET
# =============================================================================

.DEFAULT_GOAL := help
