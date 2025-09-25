# Kubernetes development environment — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Kubernetes only (no backend/frontend/AI/analytics).

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  kubectl = pkgs.kubectl;
  kustomize = pkgs.kustomize;
  helm = pkgs.helm;
  kubeseal = pkgs.kubeseal;
  kubeval = pkgs.kubeval;
  kind = pkgs.kind;

in pkgs.mkShell {
  name = "k8s-dev";

  packages = [
    kubectl
    kustomize
    helm
    kubeseal
    kubeval
    kind

    # Helpers
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.yaml2json
  ];

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    echo "[k8s-dev] kubectl $(kubectl version --client --short 2>/dev/null | head -n1), helm $(helm version --short), kustomize $(kustomize version --short), kind $(kind version | head -n1)."
    echo "Available tools: kubectl, helm, kustomize, kubeseal, kubeval, kind."
    echo "Run: kubectl get pods | helm install | kustomize build | kind create cluster"
  '';
}
