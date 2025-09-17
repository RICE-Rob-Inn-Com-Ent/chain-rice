{ pkgs }:

{
  packages = with pkgs; [
    # Core tooling
    ansible
    ansible-lint
    docker
    docker-compose
    docker-buildx
    terraform
    terragrunt
    terraform-ls

    # Cloud CLIs
    awscli2
    azure-cli
    google-cloud-sdk

    # IaC helpers
    tfsec
    checkov
    infracost
    terrascan
    tflint
    terraform-docs

    # Kubernetes (commonly used with Docker/Terraform)
    kubectl
    helm
    k9s

    # Utilities
    jq
    yq
    curl
    wget
    git
    gnupg
    unzip
  ];

  envVars = {
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
    TF_IN_AUTOMATION = "true";
    TF_INPUT = "0";
    TF_CLI_ARGS_init = "-upgrade";
  };

  shellHook = ''
    echo "🛠️ Infra tools: Ansible/Docker/Terraform + AWS/Azure/GCP + K8s"

    # Docker info (if daemon present)
    if command -v docker >/dev/null 2>&1; then
      docker version || true
      docker buildx version || true
    fi

    # Terraform helpers
    alias tf='terraform'
    alias tfi='terraform init'
    alias tfp='terraform plan'
    alias tfa='terraform apply'
    alias tfd='terraform destroy'
    alias tff='terraform fmt'
    alias tfl='tflint'
    alias tfs='tfsec .'
    alias tfdc='terraform-docs markdown . | bat -l md'

    # Ansible helpers
    alias ans='ansible'
    alias ansp='ansible-playbook'
    alias ansl='ansible-lint'

    # Docker helpers
    alias d='docker'
    alias dc='docker compose'
    alias dbx='docker buildx build'

    # Kubernetes
    alias k='kubectl'
    alias h='helm'
    alias k9='k9s'

    echo "💡 Examples: tfp, tfa, ansl, dc up, k get pods"
  '';
}
