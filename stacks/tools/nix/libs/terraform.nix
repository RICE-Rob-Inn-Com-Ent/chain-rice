{ pkgs }:

{
  packages = with pkgs; [
    # Terraform core
    terraform
    terraform-ls  # Language server
    
    # Terraform utilities
    terragrunt
    terraform-docs
    tflint
    tfsec  # Security scanner
    terrascan  # Policy as code
    
    # Cloud provider CLIs
    awscli2
    google-cloud-sdk
    azure-cli
    
    # Infrastructure validation
    checkov  # Infrastructure security scanner
    
    # JSON/YAML tools
    jq
    yq
    
    # Version control
    git
    
    # Text processing
    gnused
    gnugrep
    
    # Network tools
    curl
    wget
    
    # File utilities
    tree
    
    # Process monitoring
    htop
  ];
  
  envVars = {
    # Terraform configuration
    TF_LOG = "INFO";
    TF_CLI_ARGS = "-no-color";
    TF_IN_AUTOMATION = "true";
    
    # Plugin cache
    TF_PLUGIN_CACHE_DIR = "$HOME/.terraform.d/plugin-cache";
    
    # ChainRice specific Terraform settings
    CHAINRICE_TERRAFORM_ROOT = "$PWD/infrastructure/terraform";
    TF_VAR_project_name = "chainrice";
    TF_VAR_environment = "development";
    
    # Cloud provider settings (examples)
    # AWS_REGION = "us-west-2";
    # GOOGLE_PROJECT = "chainrice-dev";
    # ARM_SUBSCRIPTION_ID = "";
    
    # Terragrunt settings
    TERRAGRUNT_DOWNLOAD_DIR = "$HOME/.terragrunt-cache";
    TERRAGRUNT_SOURCE_UPDATE = "true";
    
    # Security scanning
    CHECKOV_QUIET = "true";
    
    # Development settings
    TF_WORKSPACE = "development";
  };
  
  shellHook = ''
    echo "🏗️  Terraform ${pkgs.terraform.version} with infrastructure tools"
    echo "   • Terragrunt for DRY configurations"
    echo "   • TFLint for code quality"
    echo "   • TFSec for security scanning"
    echo "   • Cloud provider CLIs available"
    
    # Create Terraform plugin cache directory
    mkdir -p $TF_PLUGIN_CACHE_DIR
    
    # Initialize Terraform if configuration exists
    if [ -f "infrastructure/terraform/main.tf" ]; then
      echo "📁 Terraform configuration found in infrastructure/terraform"
      cd infrastructure/terraform
      if [ ! -d ".terraform" ]; then
        echo "🔧 Initializing Terraform..."
        terraform init
      fi
      cd - > /dev/null
    fi
    
    # Check for Terraform version constraints
    if [ -f "infrastructure/terraform/versions.tf" ]; then
      echo "📋 Terraform version constraints defined"
    fi
    
    # Set up Terragrunt if configuration exists
    if [ -f "infrastructure/terraform/terragrunt.hcl" ]; then
      echo "🏗️  Terragrunt configuration found"
    fi
    
    # Aliases for common Terraform operations
    alias tf='terraform'
    alias tfi='terraform init'
    alias tfp='terraform plan'
    alias tfa='terraform apply'
    alias tfd='terraform destroy'
    alias tfv='terraform validate'
    alias tff='terraform fmt'
    alias tfs='terraform state'
    alias tfo='terraform output'
    alias tfw='terraform workspace'
    
    # Terragrunt aliases
    alias tg='terragrunt'
    alias tgp='terragrunt plan'
    alias tga='terragrunt apply'
    alias tgd='terragrunt destroy'
    alias tgv='terragrunt validate'
    
    # Security scanning aliases
    alias tfscan='tfsec .'
    alias checkov-tf='checkov -d . --framework terraform'
  '';
}
