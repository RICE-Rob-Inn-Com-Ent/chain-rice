{ pkgs }:

{
  packages = with pkgs; [
    # Compiler and build tools
    ocaml
    dune_3
    opam

    # Language server and tooling
    ocamlPackages.ocaml-lsp
    ocamlPackages.ocamlformat
    ocamlPackages.merlin
    ocamlPackages.utop

    # Linters / additional tools
    ocamlPackages.ounit
    ocamlPackages.alcotest

    # Popular libraries
    ocamlPackages.core
    ocamlPackages.core_kernel
    ocamlPackages.async
    ocamlPackages.lwt
    ocamlPackages.cohttp
    ocamlPackages.yojson
    ocamlPackages.cmdliner

    # System utilities
    git
    gnumake
    pkg-config
    ripgrep
    fd
  ];
  
  envVars = {
    # OPAM configuration (local switch inside project if used)
    OPAMROOT = "$HOME/.opam";
    OPAMYES = "1";

    # Dune
    DUNE_BUILD_DIR = "_build";

    # Project root hint
    CHAINRICE_OCAML_ROOT = "$PWD/stacks/langs/ocaml";
  };
  
  shellHook = ''
    echo "🟧 OCaml $(ocamlc -version) with dune and opam"
    echo "   • ocaml-lsp / merlin / ocamlformat / utop"

    # Initialize opam switch if desired (commented by default)
    # if ! opam switch show >/dev/null 2>&1; then
    #   echo "📦 Initializing opam switch"
    #   opam init -y --bare --disable-sandboxing || true
    #   opam switch create . ocaml-base-compiler.$(ocamlc -version) || true
    #   eval $(opam env)
    # fi

    # Format on entry (non-blocking)
    if command -v ocamlformat >/dev/null 2>&1; then
      (git ls-files "**/*.ml" "**/*.mli" | xargs -r ocamlformat -i >/dev/null 2>&1 || true) &
    fi

    # Build if dune project exists
    if [ -f "dune" ] || [ -d "dune-project" ] || [ -f "dune-project" ]; then
      echo "🏗️  Dune project detected"
      dune build || true
    fi

    # Helpful aliases
    alias db='dune build'
    alias dr='dune exec ./main.exe'
    alias dt='dune runtest'
    alias utop='utop -d s'
    alias ofmt='git ls-files "**/*.ml" "**/*.mli" | xargs -r ocamlformat -i'

    # Sample project hint
    if [ -f "${CHAINRICE_OCAML_ROOT}/main.ml" ]; then
      echo "📘 Sample available at ${CHAINRICE_OCAML_ROOT}"
      echo "   (cd ${CHAINRICE_OCAML_ROOT} && dune build && dune exec ./main.exe)"
    fi
  '';
}
