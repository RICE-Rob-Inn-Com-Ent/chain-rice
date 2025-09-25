# Julia numerical & FinTech modeling environment (2025)
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Advanced calculations, simulations, optimization, and quantitative finance.
# Includes Julia 1.9+ with major scientific, optimization, finance, and visualization packages.
# Provides optional GPU support via CUDA.jl if NVIDIA drivers/toolkit are available.
# Python interop via PyCall is configured to use the shell's Python 3.11.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  isLinux = pkgs.stdenv.isLinux;

  # Julia runtime (prefer binary distribution for faster startup)
  julia = pkgs.julia-bin or pkgs.julia;
  juliaPkgs = pkgs.juliaPackages;

  # Python for PyCall interop
  python = pkgs.python311;

  # Assemble Julia with required packages pre-installed
  juliaWithPkgs = juliaPkgs.withPackages julia (
    ps: with ps; [
      # Data & stats
      DataFrames
      CSV
      Distributions
      StatsBase
      StatsModels

      # Time series & market data
      TimeSeries
      MarketData

      # Differential equations & modeling
      DifferentialEquations
      ModelingToolkit

      # Optimization / operations research
      JuMP

      # Visualization
      Plots
      Makie

      # ML / hybrid modeling
      Flux
      DiffEqFlux

      # Finance / numerical tools
      # Prefer FinancialToolbox if present; fall back to FinEtools if available
      # (one or both may not exist in nixpkgs on some channels)
    ] ++ pkgs.lib.optional (ps ? FinancialToolbox) ps.FinancialToolbox
      ++ pkgs.lib.optional (ps ? FinEtools) ps.FinEtools
      ++ [
        # GPU support
        CUDA

        # Interop
        PyCall
      ]
  );

  # CUDA toolchain (for CUDA.jl to discover system libs at runtime)
  cudaPkgs = pkgs.cudaPackages;

in pkgs.mkShell {
  name = "julia-modeling-dev";

  packages = [
    juliaWithPkgs
    python

    # Native build tools for Julia packages that need compilation
    pkgs.git
    pkgs.gcc
    pkgs.cmake
    pkgs.pkg-config
    pkgs.openssl
    pkgs.zlib
    pkgs.openblas
    pkgs.fftw
  ] ++ (if isLinux then [
    cudaPkgs.cudatoolkit
    cudaPkgs.cudnn
    pkgs.nvidia-settings
    pkgs.nvidia-x11
  ] else []);

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Ensure PyCall uses the shell Python (3.11)
    export PYTHON=$(which python)

    # CUDA discovery for CUDA.jl (Linux)
    ${pkgs.lib.optionalString isLinux ''
      export CUDA_PATH=${cudaPkgs.cudatoolkit}
      export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [ cudaPkgs.cudatoolkit cudaPkgs.cudnn ]}:$LD_LIBRARY_PATH
    ''}

    echo "[julia-modeling-dev] Julia $(${julia}/bin/julia -e 'print(VERSION)') with PyCall (Python $(python --version | cut -d' ' -f2)) ready."
  '';
}
