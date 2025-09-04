# 🛠️ PowerShell Environment Setup Script
# Prepares the development environment for Windows PowerShell

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "🛠️ Setting up Chain Rice development environment for Windows..." -ForegroundColor Blue

# Check if running in WSL
if ($env:WSL_DISTRO_NAME) {
    Write-Host "🐧 Detected WSL: $($env:WSL_DISTRO_NAME)" -ForegroundColor Yellow
    Write-Host "Please run the Linux setup script instead: ./scripts/setup/setup-environment.sh" -ForegroundColor Yellow
    exit 1
}

# Function to check if command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Check Docker installation and status
function Test-Docker {
    Write-Host "🐳 Checking Docker installation..." -ForegroundColor Yellow
    
    if (-not (Test-Command "docker")) {
        Write-Host "❌ Docker is not installed!" -ForegroundColor Red
        Write-Host "📥 Please install Docker Desktop for Windows" -ForegroundColor Yellow
        Write-Host "   Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        return $false
    }
    
    try {
        $dockerVersion = docker --version
        Write-Host "✅ Docker is installed: $dockerVersion" -ForegroundColor Green
        
        # Check if Docker is running
        docker info | Out-Null
        Write-Host "✅ Docker is running" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Docker is not running!" -ForegroundColor Red
        Write-Host "🔧 Please start Docker Desktop" -ForegroundColor Yellow
        return $false
    }
}

# Check Docker Compose
function Test-DockerCompose {
    Write-Host "🐳 Checking Docker Compose..." -ForegroundColor Yellow
    
    try {
        docker compose version | Out-Null
        $composeVersion = docker compose version --short
        Write-Host "✅ Docker Compose is available: $composeVersion" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Docker Compose is not available!" -ForegroundColor Red
        Write-Host "📥 Please update Docker Desktop to the latest version" -ForegroundColor Yellow
        return $false
    }
}

# Check Git
function Test-Git {
    Write-Host "📝 Checking Git..." -ForegroundColor Yellow
    
    if (-not (Test-Command "git")) {
        Write-Host "❌ Git is not installed!" -ForegroundColor Red
        Write-Host "📥 Please install Git for Windows" -ForegroundColor Yellow
        Write-Host "   Download from: https://git-scm.com/download/win" -ForegroundColor Yellow
        return $false
    }
    
    $gitVersion = git --version
    Write-Host "✅ Git is installed: $gitVersion" -ForegroundColor Green
    return $true
}

# Check Go (optional)
function Test-Go {
    Write-Host "🐹 Checking Go..." -ForegroundColor Yellow
    
    if (-not (Test-Command "go")) {
        Write-Host "⚠️  Go is not installed (needed for blockchain development)" -ForegroundColor Yellow
        Write-Host "📥 To install Go: Download from https://golang.org/dl/" -ForegroundColor Yellow
        return $false
    }
    
    $goVersion = go version
    Write-Host "✅ Go is installed: $goVersion" -ForegroundColor Green
    return $true
}

# Setup Docker buildx for multi-platform builds
function Setup-DockerBuildx {
    Write-Host "🔧 Setting up Docker Buildx for multi-platform builds..." -ForegroundColor Yellow
    
    try {
        $buildxList = docker buildx ls
        if ($buildxList -notmatch "multiplatform") {
            Write-Host "📦 Creating multiplatform builder..." -ForegroundColor Yellow
            docker buildx create --name multiplatform --use | Out-Null
            Write-Host "✅ Multiplatform builder created" -ForegroundColor Green
        } else {
            Write-Host "✅ Multiplatform builder already exists" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "⚠️  Could not setup Docker Buildx: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Create necessary directories
function New-Directories {
    Write-Host "📁 Creating necessary directories..." -ForegroundColor Yellow
    
    $directories = @(
        "blockchain-data",
        "meowtopia\backend\logs",
        "meowtopia\frontend\web\logs"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    Write-Host "✅ Directories created" -ForegroundColor Green
}

# Set up environment file if it doesn't exist
function Setup-EnvFile {
    Write-Host "⚙️  Setting up environment configuration..." -ForegroundColor Yellow
    
    if (-not (Test-Path ".env")) {
        if (Test-Path "env.example") {
            Copy-Item "env.example" ".env"
            Write-Host "✅ Created .env file from env.example" -ForegroundColor Green
        } else {
            $envContent = @"
# Chain Rice Development Environment
BUILD_ENV=development
BUILD_NUMBER=1
BUILD_DATE=$(Get-Date -Format "yyyy-MM-dd")
BUILD_VERSION=0.1.0
BUILD_COMMIT=dev

# Database Configuration
POSTGRES_DB=meowtopia
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOST=meowtopia-db

# Blockchain Configuration
BLOCKCHAIN_DATA_DIR=./blockchain-data
"@
            $envContent | Out-File -FilePath ".env" -Encoding UTF8
            Write-Host "✅ Created .env file with default values" -ForegroundColor Green
        }
    } else {
        Write-Host "✅ .env file already exists" -ForegroundColor Green
    }
}

# Main setup function
function Main {
    $errors = 0
    
    Write-Host "🔍 Running system checks..." -ForegroundColor Blue
    
    # Essential checks
    if (-not (Test-Docker)) { $errors++ }
    if (-not (Test-DockerCompose)) { $errors++ }
    if (-not (Test-Git)) { $errors++ }
    
    # Optional checks (warn but don't fail)
    if (-not (Test-Go)) { 
        Write-Host "⚠️  Go check failed (optional for web development)" -ForegroundColor Yellow 
    }
    
    if ($errors -gt 0) {
        Write-Host "❌ Setup failed with $errors error(s)" -ForegroundColor Red
        Write-Host "🔧 Please fix the errors above and run setup again" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✅ All essential checks passed!" -ForegroundColor Green
    
    # Setup tasks
    Write-Host "🔧 Running setup tasks..." -ForegroundColor Blue
    Setup-DockerBuildx
    New-Directories
    Setup-EnvFile
    
    Write-Host "🎉 Environment setup completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 You can now run:" -ForegroundColor Yellow
    Write-Host "  • make dev     - Start complete development environment" -ForegroundColor White
    Write-Host "  • make web     - Start web services only" -ForegroundColor White
    Write-Host "  • make up      - Start all services" -ForegroundColor White
    Write-Host "  • make build-all - Build for all platforms" -ForegroundColor White
    Write-Host ""
    Write-Host "📚 For more commands, run: make help" -ForegroundColor Yellow
}

# Run main function
Main
