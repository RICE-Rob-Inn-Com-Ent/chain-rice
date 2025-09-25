# Finance analytics, reporting, and visualization environment (2025)
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Fast exploratory analysis, dashboards, and beautiful reports (no AI training libs).

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  python = pkgs.python311;

  pythonEnv = python.withPackages (ps: [
    # Core analytics stack
    ps.pandas
    ps.numpy
    ps.scipy

    # Visualization
    ps.matplotlib
    ps.seaborn
    ps.plotly
    ps.bokeh
    ps.altair

    # Excel report generation
    ps.openpyxl
    ps.xlsxwriter

    # Notebooks and interactivity
    ps.jupyterlab
    ps.ipywidgets

    # Dashboards
    ps.dash
    ps.streamlit

    # Geospatial / maps
    ps.pygmt
    ps.cartopy

    # API data fetching
    ps.requests
    ps.httpx
    ps.aiohttp

    # Databases
    ps.sqlalchemy
    ps.psycopg2

    # Validation & utilities
    ps.pydantic
    ps.faker

    # Notebook export and formatting
    ps.nbconvert
    ps.jupyter
  ]);

in pkgs.mkShell {
  name = "analytics-reporting-dev";

  packages = [
    pythonEnv

    # System tools and libs for mapping, export, and plotting backends
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.gdal
    pkgs.proj
    pkgs.geos
    pkgs.gmt
    pkgs.ghostscript
    pkgs.graphviz

    # For PDF/HTML report export
    pkgs.pandoc
    (pkgs.texlive.combine { inherit (pkgs.texlive) scheme-small latexmk xetex; })
    pkgs.wkhtmltopdf

    # Database headers for psycopg2 build and runtime
    pkgs.postgresql
  ];

  shellHook = ''
    export PYTHONNOUSERSITE=1
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Ensure psycopg2 finds pg_config
    export PG_CONFIG=$(which pg_config)

    echo "[analytics-reporting-dev] Python $(python --version) ready for analysis, dashboards, and reporting."
    echo "Notebook export: HTML via nbconvert/pandoc; PDF via TeX Live and wkhtmltopdf."
  '';
}
