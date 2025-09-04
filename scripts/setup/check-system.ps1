# 🔍 PowerShell System Check Script
# Checks if the system is ready for Chain Rice development

$ErrorActionPreference = "Stop"

Write-Host "🔍 Checking Chain Rice development environment for Windows..." -ForegroundColor Blue

# Check if running in WSL
if ($env:WSL_DISTRO_NAME) {
    Write-Host "🐧 Detected WSL: $($env:WSL_DISTRO_NAME)" -ForegroundColor Yellow
    Write-Host "Please run the Linux check script instead: ./scripts/setup/check-system.sh" -ForegroundColor Yellow
    exit 1
}

$errors = 0
$warnings = 0

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

# Check Docker
Write-Host "🐳 Checking Docker..." -ForegroundColor Yellow
if (-not (Test-Command "docker")) {
    Write-Host "❌ Docker is not installed" -ForegroundColor Red
    $errors++
} else {
    Write-Host "✅ Docker is installed" -ForegroundColor Green
    try {
        docker info | Out-Null
        Write-Host "✅ Docker is running" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Docker is not running" -ForegroundColor Red
        $errors++
    }
}

# Check Docker Compose
Write-Host "🐳 Checking Docker Compose..." -ForegroundColor Yellow
try {
    docker compose version | Out-Null
    Write-Host "✅ Docker Compose is available" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker Compose is not available" -ForegroundColor Red
    $errors++
}

# Check Git
Write-Host "📝 Checking Git..." -ForegroundColor Yellow
if (-not (Test-Command "git")) {
    Write-Host "❌ Git is not installed" -ForegroundColor Red
    $errors++
} else {
    Write-Host "✅ Git is installed" -ForegroundColor Green
}

# Check Go (optional)
Write-Host "🐹 Checking Go..." -ForegroundColor Yellow
if (-not (Test-Command "go")) {
    Write-Host "⚠️  Go is not installed (optional for web development)" -ForegroundColor Yellow
    $warnings++
} else {
    Write-Host "✅ Go is installed" -ForegroundColor Green
}

# Check Node.js (optional)
Write-Host "📦 Checking Node.js..." -ForegroundColor Yellow
if (-not (Test-Command "node")) {
    Write-Host "⚠️  Node.js is not installed (needed for frontend development)" -ForegroundColor Yellow
    $warnings++
} else {
    Write-Host "✅ Node.js is installed" -ForegroundColor Green
}

# Check required files
Write-Host "📁 Checking required files..." -ForegroundColor Yellow
$requiredFiles = @(
    "docker-compose.yml",
    "Dockerfile.blockchain",
    "meowtopia\backend\Dockerfile.backend",
    "meowtopia\frontend\web\Dockerfile.web.npm"
)

$missingFiles = 0
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "❌ Missing: $file" -ForegroundColor Red
        $missingFiles++
    }
}

if ($missingFiles -gt 0) {
    $errors += $missingFiles
} else {
    Write-Host "✅ All required files present" -ForegroundColor Green
}

# Check environment file
Write-Host "⚙️  Checking environment configuration..." -ForegroundColor Yellow
if (-not (Test-Path ".env")) {
    Write-Host "⚠️  .env file not found (will be created automatically)" -ForegroundColor Yellow
    $warnings++
} else {
    Write-Host "✅ .env file exists" -ForegroundColor Green
}

# Check Docker buildx
Write-Host "🔧 Checking Docker Buildx..." -ForegroundColor Yellow
try {
    $buildxList = docker buildx ls
    if ($buildxList -match "multiplatform") {
        Write-Host "✅ Multiplatform builder available" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Multiplatform builder not found (will be created automatically)" -ForegroundColor Yellow
        $warnings++
    }
}
catch {
    Write-Host "⚠️  Could not check Docker Buildx" -ForegroundColor Yellow
    $warnings++
}

Write-Host ""
Write-Host "📊 System Check Summary:" -ForegroundColor Blue

if ($errors -eq 0) {
    Write-Host "✅ System is ready for development!" -ForegroundColor Green
    if ($warnings -gt 0) {
        Write-Host "⚠️  $warnings warning(s) - some features may not be available" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "🚀 You can now run:" -ForegroundColor Yellow
    Write-Host "  • make dev     - Start complete development environment" -ForegroundColor White
    Write-Host "  • make web     - Start web services only" -ForegroundColor White
    Write-Host "  • make up      - Start all services" -ForegroundColor White
} else {
    Write-Host "❌ System check failed with $errors error(s)" -ForegroundColor Red
    if ($warnings -gt 0) {
        Write-Host "⚠️  $warnings warning(s)" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "🔧 To fix issues, run:" -ForegroundColor Yellow
    Write-Host "  • make setup   - Run automatic setup" -ForegroundColor White
    Write-Host "  • make prepare - Prepare environment" -ForegroundColor White
    exit 1
}
