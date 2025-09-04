@echo off
REM 🔍 Windows System Check Script
REM Checks if the system is ready for Chain Rice development

setlocal enabledelayedexpansion

echo 🔍 Checking Chain Rice development environment for Windows...

REM Check if running in WSL
if defined WSL_DISTRO_NAME (
    echo 🐧 Detected WSL: %WSL_DISTRO_NAME%
    echo Please run the Linux check script instead: ./scripts/setup/check-system.sh
    exit /b 1
)

set errors=0
set warnings=0

REM Check Docker
echo 🐳 Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed
    set /a errors+=1
) else (
    echo ✅ Docker is installed
    docker info >nul 2>&1
    if errorlevel 1 (
        echo ❌ Docker is not running
        set /a errors+=1
    ) else (
        echo ✅ Docker is running
    )
)

REM Check Docker Compose
echo 🐳 Checking Docker Compose...
docker compose version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose is not available
    set /a errors+=1
) else (
    echo ✅ Docker Compose is available
)

REM Check Git
echo 📝 Checking Git...
git --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Git is not installed
    set /a errors+=1
) else (
    echo ✅ Git is installed
)

REM Check Go (optional)
echo 🐹 Checking Go...
go version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Go is not installed (optional for web development)
    set /a warnings+=1
) else (
    echo ✅ Go is installed
)

REM Check Node.js (optional)
echo 📦 Checking Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Node.js is not installed (needed for frontend development)
    set /a warnings+=1
) else (
    echo ✅ Node.js is installed
)

REM Check required files
echo 📁 Checking required files...
set missing_files=0

if not exist "docker-compose.yml" (
    echo ❌ Missing: docker-compose.yml
    set /a missing_files+=1
)

if not exist "Dockerfile.blockchain" (
    echo ❌ Missing: Dockerfile.blockchain
    set /a missing_files+=1
)

if not exist "meowtopia\backend\Dockerfile.backend" (
    echo ❌ Missing: meowtopia\backend\Dockerfile.backend
    set /a missing_files+=1
)

if not exist "meowtopia\frontend\web\Dockerfile.web.npm" (
    echo ❌ Missing: meowtopia\frontend\web\Dockerfile.web.npm
    set /a missing_files+=1
)

if %missing_files% gtr 0 (
    set /a errors+=%missing_files%
) else (
    echo ✅ All required files present
)

REM Check environment file
echo ⚙️  Checking environment configuration...
if not exist ".env" (
    echo ⚠️  .env file not found (will be created automatically)
    set /a warnings+=1
) else (
    echo ✅ .env file exists
)

REM Check Docker buildx
echo 🔧 Checking Docker Buildx...
docker buildx ls | findstr "multiplatform" >nul
if errorlevel 1 (
    echo ⚠️  Multiplatform builder not found (will be created automatically)
    set /a warnings+=1
) else (
    echo ✅ Multiplatform builder available
)

echo.
echo 📊 System Check Summary:

if %errors% equ 0 (
    echo ✅ System is ready for development!
    if %warnings% gtr 0 (
        echo ⚠️  %warnings% warning(s) - some features may not be available
    )
    echo.
    echo 🚀 You can now run:
    echo   • make dev     - Start complete development environment
    echo   • make web     - Start web services only
    echo   • make up      - Start all services
) else (
    echo ❌ System check failed with %errors% error(s)
    if %warnings% gtr 0 (
        echo ⚠️  %warnings% warning(s)
    )
    echo.
    echo 🔧 To fix issues, run:
    echo   • make setup   - Run automatic setup
    echo   • make prepare - Prepare environment
    exit /b 1
)

endlocal
