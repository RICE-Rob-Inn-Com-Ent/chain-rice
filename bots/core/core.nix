# Core AI development environment (CPU + NVIDIA CUDA)
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# CUDA binary caches (speed up builds) — add to your flake:
#   nixConfig.substituters = [
#     "https://cache.nixos.org/"
#     "https://cuda-maintainers.cachix.org"
#     "https://flox.cachix.org"
#   ];
#   nixConfig.trusted-public-keys = [
#     "cuda-maintainers.cachix.org-1:4PqVMKc68gHPXT1CRO2FQh9KQh4Zq8CkA9aZ8N2V3Gk="
#     "flox.cachix.org-1:2Vj6E0mX0Jr4Lw5v+M2y2P8s0m4nIw1qQFfHjz9g9Uk="
#   ];

{ pkgs ? let
    # Default to latest available nixpkgs flake on this system unless provided
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  # Aliases
  python = pkgs.python311;
  py = pkgs.python311Packages;
  isLinux = pkgs.stdenv.isLinux;

  # CUDA toolchain (Linux)
  cudaPkgs = pkgs.cudaPackages;

  # CUDA-enabled deep learning frameworks (using CUDA variants when available)
  torchCuda = py.pytorchWithCuda or py.pytorch or py.torch or pkgs.pytorch;
  torchvisionCuda = py.torchvisionWithCuda or py.torchvision or pkgs.torchvision;
  torchaudioCuda = py.torchaudioWithCuda or py.torchaudio or pkgs.torchaudio;
  tensorflowCuda = py.tensorflowWithCuda or py.tensorflow or pkgs.tensorflow;
  jax = py.jax or pkgs.jax;
  jaxlibCuda = py.jaxlibWithCuda or py.jaxlib or pkgs.jaxlib;

  # Python environment (3.11+)
  pythonEnv = python.withPackages (ps: with ps; [
    # Numerical / ML core
    numpy
    scipy
    scikitlearn
    pandas

    # Visualization
    matplotlib
    seaborn

    # Hugging Face
    transformers
    diffusers
    datasets

    # Computer vision + audio (виключаємо OpenCV через проблеми збірки)
    # (py.opencv4 or py.opencv)
    (ps.whisper or ps.openai-whisper)

    # Core frameworks (CUDA-enabled variants)
    torchCuda
    torchvisionCuda
    torchaudioCuda
    tensorflowCuda
    jax
    jaxlibCuda
  ]);

  # CUDA libs for runtime
  cudaLibs = [
    cudaPkgs.cudatoolkit
    cudaPkgs.cudnn
  ];

in pkgs.mkShell {
  name = "ai-core-dev";

  packages = [
    pythonEnv

    # Native build tools for many Python wheels
    pkgs.git
    pkgs.gcc
    pkgs.cmake
    pkgs.pkg-config
    pkgs.openssl
    pkgs.zlib
    pkgs.ffmpeg
    pkgs.libsndfile
    pkgs.ncurses
    pkgs.openblas
  ] ++ (if isLinux then [
    cudaPkgs.cudatoolkit
    cudaPkgs.cudnn
  ] else []);

  # Environment for CUDA-enabled frameworks
  shellHook = ''
    export PYTHONNOUSERSITE=1

    # Prefer UTF-8
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    ${pkgs.lib.optionalString isLinux ''
      export CUDA_PATH=${cudaPkgs.cudatoolkit}
      export XLA_FLAGS=--xla_gpu_cuda_data_dir=${cudaPkgs.cudatoolkit}
      export TF_CUDA_PATHS=${cudaPkgs.cudatoolkit}:${cudaPkgs.cudnn}
      export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath cudaLibs}:$LD_LIBRARY_PATH
    ''}

    echo "[ai-core-dev] Python $(python --version) ready. CUDA: ${if isLinux then "enabled (toolchain available)" else "not enabled (non-Linux)"}."
    echo "Tip: enable CUDA binary caches (cuda-maintainers, flox) in flake.nix for faster builds."
  '';
}
