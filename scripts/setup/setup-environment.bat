@echo off
REM 🛠️ Windows Environment Setup Script
REM Prepares the development environment for Windows

setlocal enabledelayedexpansion

echo 🛠️ Setting up Chain Rice development environment for Windows...

REM Check if running in WSL
if defined WSL_DISTRO_NAME (
    echo 🐧 Detected WSL: %WSL_DISTRO_NAME%
    echo Please run the Linux setup script instead: ./scripts/setup/setup-environment.sh
    exit /b 1
)

REM Check Docker installation
echo 🐳 Checking Docker installation...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed!
    echo 📥 Please install Docker Desktop for Windows
    echo    Download from: https://www.docker.com/products/docker-desktop
    exit /b 1
)

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not running!
    echo 🔧 Please start Docker Desktop
    exit /b 1
)

echo ✅ Docker is installed and running

REM Check Docker Compose
echo 🐳 Checking Docker Compose...
docker compose version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose is not available!
    echo 📥 Please update Docker Desktop to the latest version
    exit /b 1
)

echo ✅ Docker Compose is available

REM Check Git
echo 📝 Checking Git...
git --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Git is not installed!
    echo 📥 Please install Git for Windows
    echo    Download from: https://git-scm.com/download/win
    exit /b 1
)

echo ✅ Git is installed

REM Check Go (optional)
echo 🐹 Checking Go...
go version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Go is not installed (needed for blockchain development)
    echo 📥 To install Go: Download from https://golang.org/dl/
) else (
    echo ✅ Go is installed
)

echo ✅ All essential checks passed!

REM Setup Docker buildx
echo 🔧 Setting up Docker Buildx for multi-platform builds...
docker buildx ls | findstr "multiplatform" >nul
if errorlevel 1 (
    echo 📦 Creating multiplatform builder...
    docker buildx create --name multiplatform --use
) else (
    echo ✅ Multiplatform builder already exists
)

REM Create necessary directories
echo 📁 Creating necessary directories...
if not exist "blockchain-data" mkdir blockchain-data
if not exist "meowtopia\backend\logs" mkdir meowtopia\backend\logs
if not exist "meowtopia\frontend\web\logs" mkdir meowtopia\frontend\web\logs

echo ✅ Directories created

REM Set up environment file
echo ⚙️  Setting up environment configuration...
if not exist ".env" (
    if exist "env.example" (
        copy env.example .env >nul
        echo ✅ Created .env file from env.example
    ) else (
        echo # Chain Rice Development Environment > .env
        echo BUILD_ENV=development >> .env
        echo BUILD_NUMBER=1 >> .env
        echo BUILD_DATE=%date% >> .env
        echo BUILD_VERSION=0.1.0 >> .env
        echo BUILD_COMMIT=dev >> .env
        echo. >> .env
        echo # Database Configuration >> .env
        echo POSTGRES_DB=meowtopia >> .env
        echo POSTGRES_USER=postgres >> .env
        echo POSTGRES_PASSWORD=postgres >> .env
        echo POSTGRES_HOST=meowtopia-db >> .env
        echo. >> .env
        echo # Blockchain Configuration >> .env
        echo BLOCKCHAIN_DATA_DIR=./blockchain-data >> .env
        echo ✅ Created .env file with default values
    )
) else (
    echo ✅ .env file already exists
)

echo 🎉 Environment setup completed successfully!
echo.
echo 🚀 You can now run:
echo   • make dev     - Start complete development environment
echo   • make web     - Start web services only
echo   • make up      - Start all services
echo   • make build-all - Build for all platforms
echo.
echo 📚 For more commands, run: make help

endlocal
