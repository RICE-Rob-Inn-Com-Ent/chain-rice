# Terraform development environment — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Terraform only (no backend/frontend/AI/analytics).

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  terraform = pkgs.terraform;
  terraformLs = pkgs.terraform-ls;
  tflint = pkgs.tflint;
  terragrunt = pkgs.terragrunt;
  awscli = pkgs.awscli2;
  gcloud = pkgs.google-cloud-sdk;
  azureCli = pkgs.azure-cli;

in pkgs.mkShell {
  name = "terraform-dev";

  packages = [
    terraform
    terraformLs
    tflint
    terragrunt
    awscli
    gcloud
    azureCli

    # Helpers
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.openssl
  ];

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    echo "[terraform-dev] terraform $(terraform version | head -n1), tflint $(tflint --version | head -n1), terragrunt $(terragrunt --version | head -n1)."
    echo "Cloud CLIs: aws $(aws --version | head -n1), gcloud $(gcloud --version | head -n1), az $(az version | head -n1)."
    echo "Run: terraform init | terraform plan | terraform apply | tflint | terragrunt run-all plan"
  '';
}
