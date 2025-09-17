{ pkgs }:

{
  packages = with pkgs; [
    # Docker runtime and tools
    docker
    docker-compose
    docker-buildx
    
    # Container management
    podman
    buildah
    skopeo
    
    # Docker development tools
    dive  # Docker image analysis
    hadolint  # Dockerfile linting
    
    # Container registry tools
    crane  # Container registry client
    
    # Kubernetes tools (for container orchestration)
    kubectl
    kubernetes-helm
    k9s  # Kubernetes CLI UI
    
    # Docker utilities
    ctop  # Container monitoring
    lazydocker  # Docker TUI
    
    # Build tools
    gnumake
    
    # Networking tools for containers
    netcat
    curl
    
    # File system tools
    rsync
    
    # Process monitoring
    htop
    lsof
  ];
  
  envVars = {
    # Docker configuration
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
    
    # Docker registry
    DOCKER_REGISTRY = "docker.io";
    
    # ChainRice specific Docker settings
    CHAINRICE_DOCKER_CONTEXT = "$PWD/infrastructure/docker";
    COMPOSE_PROJECT_NAME = "chainrice";
    
    # Build optimization
    DOCKER_CLI_EXPERIMENTAL = "enabled";
    
    # Container runtime preferences
    CONTAINER_RUNTIME = "docker";
    
    # Development settings
    DOCKER_SCAN_SUGGEST = "false";
    
    # Multi-platform builds
    DOCKER_DEFAULT_PLATFORM = "linux/amd64";
  };
  
  shellHook = ''
    echo "🐳 Docker ${pkgs.docker.version} with container development tools"
    echo "   • Docker Compose for multi-container apps"
    echo "   • Buildx for multi-platform builds"
    echo "   • Hadolint for Dockerfile linting"
    echo "   • Dive for image analysis"
    echo "   • Kubernetes tools available"
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
      echo "⚠️  Docker daemon not running. Start it with: sudo systemctl start docker"
    else
      echo "✅ Docker daemon is running"
    fi
    
    # Set up Docker Compose environment
    if [ -f "docker-compose.yml" ]; then
      echo "🐙 Docker Compose configuration found"
    fi
    
    # Create Docker network for ChainRice if it doesn't exist
    if docker info &> /dev/null; then
      if ! docker network ls | grep -q chainrice-network; then
        echo "🌐 Creating ChainRice Docker network..."
        docker network create chainrice-network 2>/dev/null || true
      fi
    fi
    
    # Enable BuildKit
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    
    # Aliases for common Docker operations
    alias dps='docker ps'
    alias dpa='docker ps -a'
    alias di='docker images'
    alias dcu='docker-compose up'
    alias dcd='docker-compose down'
    alias dcb='docker-compose build'
    alias dcl='docker-compose logs'
  '';
}
