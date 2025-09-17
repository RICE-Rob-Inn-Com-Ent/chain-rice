{ pkgs }:

{
  packages = with pkgs; [
    # Octave with GUI and many features
    octaveFull

    # Plotting/printing and visualization
    gnuplot
    ghostscript
    graphviz
    texlive.combined.scheme-small

    # BLAS/LAPACK and numerics
    openblas
    lapack
    fftw
    suitesparse
    arpack
    gsl
    glpk

    # IO and data formats
    hdf5
    netcdf
    zlib
    zstd
    libxml2
    libzip

    # Graphics stack (for image/plots backends)
    cairo
    pango
    glib
    gdk-pixbuf
    libpng
    freetype
    fontconfig
    graphicsmagick
    imagemagick
    ffmpeg
    glfw
    libGL

    # Audio and realtime (optional)
    portaudio
    libsndfile

    # Build toolchain for oct-files and packages
    gcc
    gfortran
    gnumake
    cmake
    pkg-config

    # Jupyter + Octave kernel
    python3
    python3Packages.jupyter
    python3Packages.ipykernel
    python3Packages.metakernel
    python3Packages.octave_kernel

    # MATLAB/Octave language server (for editors)
    nodejs_22
    nodePackages.matlab-language-server

    # Utilities
    git
    curl
    ripgrep
    fd
  ];
  
  envVars = {
    # Paths for project-local functions and scripts
    CHAINRICE_OCTAVE_ROOT = "$PWD/stacks/langs/octave";
    OCTAVE_PATH = "$PWD/stacks/langs/octave/functions:$PWD/stacks/langs/octave/scripts:$OCTAVE_PATH";

    # Threading
    OMP_NUM_THREADS = "4";

    # Avoid pagers
    PAGER = "cat";
  };
  
  shellHook = ''
    echo "🟨 Octave $(octave --quiet --eval \"printf('%s', version());\") with scientific stack"
    echo "   • BLAS/LAPACK/FFTW, HDF5/NetCDF"
    echo "   • Gnuplot/GraphicsMagick/ImageMagick, TeX (small)"
    echo "   • Jupyter Octave kernel and MATLAB language server"

    # Ensure project paths are included
    export OCTAVE_PATH="$CHAINRICE_OCTAVE_ROOT/functions:$CHAINRICE_OCTAVE_ROOT/scripts:$OCTAVE_PATH"

    # Install Jupyter Octave kernel (idempotent)
    if command -v jupyter >/dev/null 2>&1; then
      python3 -m octave_kernel.install --user >/dev/null 2>&1 || true
    fi

    # Helpful aliases
    alias oct='octave --quiet'
    alias octi='octave'
    alias octrun='octave --quiet ${CHAINRICE_OCTAVE_ROOT}/main.m'
    alias octpath='octave --quiet --eval "disp(path())"'

    # Quick package status
    alias octpkg='octave --quiet --eval "pkg list"'

    # Sample project hint
    if [ -f "${CHAINRICE_OCTAVE_ROOT}/index.m" ]; then
      echo "📘 Sample available at ${CHAINRICE_OCTAVE_ROOT}"
      echo "   oct ${CHAINRICE_OCTAVE_ROOT}/index.m"
      echo "   oct ${CHAINRICE_OCTAVE_ROOT}/main.m"
    fi
  '';
}


