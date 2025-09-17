{ pkgs }:

{
  packages = with pkgs; [
    # Julia runtime and development tools
    julia-bin
    
    # Additional tools for Julia development
    julia-lts
    
    # Package management
    git  # Required for Julia package manager
    
    # Development tools
    gnumake
    gcc
    gfortran
    cmake
    pkg-config
    
    # Scientific computing dependencies
    openblas
    lapack
    fftw
    suitesparse
    arpack
    
    # Plotting and visualization dependencies
    cairo
    pango
    glib
    gdk-pixbuf
    libpng
    freetype
    fontconfig
    graphviz
    ffmpeg
    glfw
    libGL
    
    # HDF5 for data storage
    hdf5
    
    # Additional libraries commonly used in Julia
    openssl
    curl
    zlib
    zstd
    libxml2
    libzip
    
    # Python integration (PyCall.jl)
    python3
    python3Packages.numpy
    python3Packages.matplotlib
    
    # R integration (RCall.jl)
    R
    
    # Jupyter notebook support
    python3Packages.jupyter
    python3Packages.ipykernel

    # Parallel/MPI (optional; used by MPI.jl)
    openmpi
  ];
  
  envVars = {
    # Julia configuration
    JULIA_NUM_THREADS = "auto";
    JULIA_PROJECT = "@.";
    
    # Package compilation optimization
    JULIA_CPU_TARGET = "generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)";
    
    # Development settings
    JULIA_EDITOR = "code";  # VS Code integration
    
    # Package server
    JULIA_PKG_SERVER = "https://pkg.julialang.org";
    
    # ChainRice specific Julia environment
    JULIA_CHAINRICE_ROOT = "$PWD/functions/julia";
    
    # Scientific computing optimizations
    OMP_NUM_THREADS = "4";
    OPENBLAS_NUM_THREADS = "4";
    
    # Memory settings
    JULIA_HEAP_SIZE_HINT = "2G";

    # Optional setup flags
    JULIA_SETUP_CORE = "1";      # install core dev pkgs (Revise, DataFrames, Plots, etc.)
    JULIA_SETUP_FULL = "0";      # if 1, also install heavy ML/visualization stacks
    JULIA_ENABLE_GPU = "0";      # if 1 and CUDA detected, install CUDA.jl
  };
  
  shellHook = ''
    echo "🔬 Julia ${pkgs.julia-bin.version} (LTS: ${pkgs.julia-lts.version}) with scientific stack"
    echo "   • OpenBLAS for linear algebra"
    echo "   • FFTW for Fourier transforms"
    echo "   • HDF5 for data storage"
    echo "   • Python & R integration ready"
    
    # Set up Julia project environment
    if [ -f "functions/julia/Project.toml" ]; then
      echo "📦 Julia project detected in functions/julia"
      export JULIA_PROJECT="functions/julia"
      cd functions/julia
      julia --project=. -e "using Pkg; Pkg.instantiate()"
      cd - > /dev/null
    fi
    
    # Precompile commonly used packages
    if [ -f "$JULIA_PROJECT/Project.toml" ]; then
      echo "🚀 Precompiling Julia packages..."
      julia --project=$JULIA_PROJECT -e "using Pkg; Pkg.precompile()"
    fi
    
    # Set up Jupyter kernel for Julia
    if command -v jupyter &> /dev/null; then
      julia -e 'using Pkg; Pkg.add("IJulia"); using IJulia; installkernel("Julia")'
    fi

    # Point PyCall at system Python (for stable linking)
    if command -v python3 >/dev/null 2>&1; then
      export PYTHON=$(which python3)
    fi

    # Install a curated set of Julia packages (idempotent)
    if [ "${JULIA_SETUP_CORE}" = "1" ]; then
      echo "🧰 Ensuring core Julia dev packages are installed"
      julia -e '
        import Pkg
        core = [
          "Revise", "OhMyREPL", "JuliaFormatter",
          "DataFrames", "CSV", "Arrow", "Parquet", "Tables",
          "JSON3", "YAML", "HTTP", "URIs", "MbedTLS",
          "StatsBase", "Distributions",
          "Plots", "GR",
          "IJulia"
        ]
        for p in core
          try Pkg.add(p); catch err; @warn("Pkg.add failed", pkg=p, err=err); end
        end
      '
    fi

    # Optional heavy stacks (visualization/ML)
    if [ "${JULIA_SETUP_FULL}" = "1" ]; then
      echo "🧪 Installing extended visualization/ML toolkits"
      julia -e '
        import Pkg
        extra = [
          "Pluto", "PlotlyJS", "Makie", "CairoMakie",
          "Flux", "MLJ", "CUDA", "Optim", "JuMP",
          "DifferentialEquations"
        ]
        for p in extra
          try Pkg.add(p); catch err; @warn("Pkg.add failed", pkg=p, err=err); end
        end
      '
    fi

    # GPU support (only if enabled and NVIDIA GPU detected)
    if [ "${JULIA_ENABLE_GPU}" = "1" ] && command -v nvidia-smi >/dev/null 2>&1; then
      echo "🎛️ Installing CUDA.jl for GPU support"
      julia -e 'import Pkg; try Pkg.add("CUDA"); catch err; @warn("CUDA add failed", err=err); end'
    fi

    # Helpful aliases
    alias jrepl='julia -e "using Revise; using InteractiveUtils; println(\"Revise loaded.\")"'
    alias jfmt='julia -e "using JuliaFormatter; format('.', verbose=false)"'
    alias pluto='julia -e "import Pluto; Pluto.run()"'
    alias jtest='julia --project=. -e "using Pkg; Pkg.test()"'
  '';
}
