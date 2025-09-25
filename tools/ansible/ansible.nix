# Ansible development environment — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Ansible only (no backend/frontend/AI/analytics).

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  ansible = pkgs.ansible;
  ansibleLint = pkgs.ansible-lint or pkgs.python311Packages.ansible-lint;
  yamllint = pkgs.yamllint;
  molecule = pkgs.molecule;
  docker = pkgs.docker;

in pkgs.mkShell {
  name = "ansible-dev";

  packages = [
    ansible
    ansibleLint
    yamllint
    molecule
    docker

    # Helpers
    pkgs.git
    pkgs.curl
    pkgs.jq
  ];

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    echo "[ansible-dev] ansible $(ansible --version | head -n1), ansible-lint $(ansible-lint --version | head -n1), molecule $(molecule --version | head -n1)."
    echo "Docker available for local role tests (molecule)."
    echo "Run: ansible-playbook -i inventory site.yml | ansible-lint | molecule test"
  '';
}
