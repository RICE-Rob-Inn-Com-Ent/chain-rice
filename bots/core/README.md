# AI Bot Core

Core AI Bot Application with CUDA support for machine learning model operations.

## Features

- **CUDA-accelerated deep learning** with PyTorch
- **Hugging Face model integration** for transformers and diffusion models
- **Computer vision and audio processing** capabilities
- **RESTful API endpoints** for model interaction
- **Real-time model serving** with FastAPI
- **Docker containerization** with multi-stage builds
- **Bazel build system integration**

## Quick Start

### Using Nix (Recommended)

```bash
# Enter the development environment
nix develop

# Run the application
python app.py
```

### Using Docker

```bash
# Build the image
docker build -t ai-bot-core .

# Run the container
docker run -p 8000:8000 --gpus all ai-bot-core
```

### Using Bazel

```bash
# Build the application
bazel build //bots/core:app

# Run the application
bazel run //bots/core:app

# Build Docker image
bazel build //bots/core:ai-bot-core-image
```

## API Endpoints

### Health Check
- `GET /health` - Check application health

### Model Management
- `GET /models` - List loaded models
- `POST /models/load` - Load a model into memory

### Text Generation
- `POST /generate/text` - Generate text using language models

### Image Generation
- `POST /generate/image` - Generate images using diffusion models

## Configuration

### Environment Variables

- `PYTHONUNBUFFERED=1` - Enable unbuffered Python output
- `CUDA_HOME` - CUDA installation path
- `LD_LIBRARY_PATH` - Library search path for CUDA

### Command Line Arguments

- `--host` - Host to bind to (default: 0.0.0.0)
- `--port` - Port to bind to (default: 8000)
- `--workers` - Number of worker processes (default: 1)
- `--reload` - Enable auto-reload for development

## Development

### Running Tests

```bash
# Using pytest directly
pytest test_core.py

# Using Bazel
bazel test //bots/core:core_test
```

### Code Formatting

```bash
# Format Python code
black app.py test_core.py

# Check code style
flake8 app.py test_core.py
```

## Architecture

The application consists of:

1. **AIBotCore** - Main class for model management and operations
2. **FastAPI Application** - REST API server with endpoints
3. **Model Loading System** - Dynamic model loading and management
4. **CUDA Integration** - GPU acceleration support
5. **Docker Containerization** - Multi-stage builds for different environments

## Dependencies

### Core ML Libraries
- PyTorch with CUDA support
- Transformers (Hugging Face)
- Diffusers (Hugging Face)
- NumPy, SciPy, Pandas

### Web Framework
- FastAPI
- Uvicorn
- CORS middleware

### Development Tools
- Pytest for testing
- Black for code formatting
- Flake8 for linting

## License

This project is part of the rice-dev monorepo and follows the same licensing terms.
