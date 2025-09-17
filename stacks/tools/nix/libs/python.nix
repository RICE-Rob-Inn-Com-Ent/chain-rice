{ pkgs }:

{
  packages = with pkgs; [
    # Python runtime and development tools
    python3
    python3Packages.pip
    python3Packages.setuptools
    python3Packages.wheel
    python3Packages.virtualenv
    python3Packages.pipenv
    uv  # ultra-fast Python package manager
    
    # Package management
    python3Packages.poetry
    python3Packages.pip-tools
    python3Packages.hatch
    python3Packages.build  # PEP 517 build backend
    python3Packages.twine
    
    # Development tools
    python3Packages.black
    python3Packages.flake8
    python3Packages.mypy
    python3Packages.pylint
    python3Packages.autopep8
    python3Packages.isort
    python3Packages.ruff
    python3Packages.bandit
    python3Packages.safety
    python3Packages.pre-commit
    python3Packages.nbqa
    
    # Testing frameworks
    python3Packages.pytest
    python3Packages.pytest-cov
    python3Packages.pytest-xdist
    python3Packages.tox
    python3Packages.pytest-asyncio
    python3Packages.pytest-mock
    python3Packages.hypothesis
    python3Packages.coverage
    
    # Web frameworks (for backend services)
    python3Packages.fastapi
    python3Packages.uvicorn
    python3Packages.flask
    python3Packages.django
    python3Packages.requests
    python3Packages.httpx
    python3Packages.starlette
    python3Packages.uvloop
    python3Packages.watchfiles
    
    # Database connectivity
    python3Packages.sqlalchemy
    python3Packages.psycopg2
    python3Packages.pymongo
    python3Packages.redis
    
    # Data science and analysis
    python3Packages.numpy
    python3Packages.pandas
    python3Packages.matplotlib
    python3Packages.seaborn
    python3Packages.jupyter
    python3Packages.ipython
    python3Packages.scipy
    python3Packages.scikit-learn
    python3Packages.polars
    
    # Async and concurrency
    python3Packages.asyncio
    python3Packages.aiohttp
    python3Packages.celery
    
    # Configuration and environment
    python3Packages.python-dotenv
    python3Packages.pydantic
    python3Packages.click
    python3Packages.typer
    
    # Blockchain and crypto related
    python3Packages.cryptography
    python3Packages.pynacl
    python3Packages.ecdsa
    
    # JSON and data parsing
    python3Packages.orjson
    python3Packages.pyyaml
    python3Packages.toml
    
    # Date and time
    python3Packages.python-dateutil
    python3Packages.pytz
    
    # Logging and monitoring
    python3Packages.structlog
    python3Packages.prometheus-client

    # Protocol Buffers / gRPC (for Python codegen)
    python3Packages.grpcio
    python3Packages.grpcio-tools
    python3Packages.protobuf
    python3Packages.mypy-protobuf

    # Language server / static type checker
    pyright

    # Interop with Rust for extension modules
    maturin
  ];
  
  envVars = {
    # Python configuration
    PYTHONPATH = "$PWD/backend/python:$PYTHONPATH";
    PYTHON_ENV = "development";
    
    # pip configuration
    PIP_DISABLE_PIP_VERSION_CHECK = "1";
    PIP_NO_CACHE_DIR = "1";
    PIP_DEFAULT_TIMEOUT = "120";
    
    # Virtual environment
    VIRTUAL_ENV_DISABLE_PROMPT = "1";
    PIPENV_VENV_IN_PROJECT = "1";
    
    # Development settings
    PYTHONDONTWRITEBYTECODE = "1";
    PYTHONUNBUFFERED = "1";
    
    # ChainRice specific Python settings
    CHAINRICE_PYTHON_ROOT = "$PWD/backend/python";

    # Optional setup toggles
    PYTHON_SETUP_FULL = "0";  # if 1, install heavy ML stacks via pip (torch, jax, etc.)
    
    # FastAPI configuration
    FASTAPI_ENV = "development";
    FASTAPI_DEBUG = "true";
    
    # Database URLs (for SQLAlchemy)
    DATABASE_URL = "sqlite:///$PWD/backend/go/accounting.db";
    
    # Logging
    LOG_LEVEL = "DEBUG";
    PYTHONPATH = "$PWD:$PYTHONPATH";
  };
  
  shellHook = ''
    echo "🐍 Python ${pkgs.python3.version} with comprehensive development stack"
    echo "   • FastAPI, Flask, Django for web development"
    echo "   • SQLAlchemy for database ORM"
    echo "   • Pandas/Polars, NumPy/SciPy for data analysis"
    echo "   • Pytest for testing"
    echo "   • Black, Ruff, Flake8, MyPy, Pyright for code quality"
    
    # Set up Python virtual environment
    if [ ! -d ".venv" ] && [ -f "backend/python/pyproject.toml" ]; then
      echo "📦 Setting up Python environment in backend/python..."
      cd backend/python
      if command -v uv >/dev/null 2>&1; then
        uv venv .venv || true
        source .venv/bin/activate
        uv pip install --upgrade pip setuptools wheel
        uv pip install -e . || true
      else
        python -m venv .venv
        source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -e . || true
      fi
      cd - > /dev/null
    fi
    
    # Activate virtual environment if it exists
    if [ -d "backend/python/.venv" ]; then
      source backend/python/.venv/bin/activate
    fi
    
    # Install development dependencies
    if [ -f "backend/python/requirements-dev.txt" ]; then
      if command -v uv >/dev/null 2>&1; then
        uv pip install -r backend/python/requirements-dev.txt || true
      else
        pip install -r backend/python/requirements-dev.txt || true
      fi
    fi

    # Optional: install heavy ML stacks when requested (CPU wheels)
    if [ "$PYTHON_SETUP_FULL" = "1" ]; then
      echo "🧪 Installing extended ML packages (optional)"
      pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu || true
      pip install xgboost lightgbm || true
    fi

    # Pre-commit hooks
    if [ -f ".pre-commit-config.yaml" ] && command -v pre-commit >/dev/null 2>&1; then
      pre-commit install || true
    fi
    
    # Set up Jupyter kernel
    if command -v jupyter &> /dev/null; then
      python -m ipykernel install --user --name chainrice-python --display-name "ChainRice Python"
    fi

    # Helpful aliases
    alias pt='pytest -q'
    alias pto='pytest -q -k'
    alias cov='coverage run -m pytest && coverage html && echo "open htmlcov/index.html"'
    alias fmt='black . && isort . && ruff check . --fix'
    alias lint='ruff check . && flake8 . && pylint $(git ls-files "**/*.py" | tr '\n' ' ') || true'
    alias typecheck='pyright || mypy'
    alias serve='uvicorn app.main:app --reload --host 0.0.0.0 --port 8003'
  '';
}
