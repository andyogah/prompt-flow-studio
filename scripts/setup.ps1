# =================================
# PROMPT FLOW SETUP SCRIPT (Windows PowerShell)
# =================================

Write-Host "[*] Setting up Prompt Flow development environment..." -ForegroundColor Cyan

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Blue

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "[X] Docker is not installed. Please install Docker Desktop first." -ForegroundColor Red
    exit 1
}

if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "[X] Docker Compose is not installed. Please install Docker Compose first." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Prerequisites check passed!" -ForegroundColor Green

# Check if Poetry is installed
Write-Host "Checking Poetry installation..." -ForegroundColor Blue
if (-Not (Get-Command poetry -ErrorAction SilentlyContinue)) {
    Write-Host "[X] Poetry is not installed or not in PATH. Please install Poetry and try again." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Poetry is installed." -ForegroundColor Green

# Create environment file
Write-Host "Setting up environment configuration..." -ForegroundColor Blue
if (-not (Test-Path "..\backend\.env")) {
    if (Test-Path "..\backend\.env.example") {
        Copy-Item "..\backend\.env.example" "..\backend\.env"
        Write-Host "[OK] Created backend\.env from template" -ForegroundColor Green
        Write-Host "[!] Please edit backend\.env with your API keys and configuration" -ForegroundColor Yellow
    } else {
        Write-Host "[!] .env.example not found, creating minimal .env file" -ForegroundColor Yellow
        # Create a minimal .env file
        @"
# API Keys
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Database URLs
MONGODB_URL=mongodb://mongodb:27017/promptflow
REDIS_URL=redis://redis:6379
QDRANT_URL=http://qdrant:6333

# JWT Secret
JWT_SECRET=your_jwt_secret_here

# Environment
ENVIRONMENT=development
"@ | Out-File -FilePath "..\backend\.env" -Encoding UTF8
        Write-Host "[OK] Created minimal backend\.env file" -ForegroundColor Green
    }
} else {
    Write-Host "[!] backend\.env already exists, skipping copy" -ForegroundColor Yellow
}

# Enable PowerShell execution policy if needed
Write-Host "Checking PowerShell execution policy..." -ForegroundColor Blue
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted") {
    Write-Host "[!] PowerShell execution policy is restricted. Enabling scripts..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Host "[OK] PowerShell execution policy updated" -ForegroundColor Green
}

# Fix Poetry package-mode compatibility issue
Write-Host "Checking Poetry configuration..." -ForegroundColor Blue
if (Test-Path "..\backend\pyproject.toml") {
    if (Select-String -Path "..\backend\pyproject.toml" -Pattern "package-mode = false" -Quiet) {
        Write-Host "[!] Found 'package-mode = false' in pyproject.toml" -ForegroundColor Yellow
        Write-Host "Removing unsupported package-mode line..." -ForegroundColor Blue
        
        # Create backup
        Copy-Item "..\backend\pyproject.toml" "..\backend\pyproject.toml.backup"
        
        # Remove the problematic line
        (Get-Content "..\backend\pyproject.toml") | Where-Object { $_ -notmatch "package-mode = false" } | Set-Content "..\backend\pyproject.toml"
        
        Write-Host "[OK] Removed package-mode line from pyproject.toml" -ForegroundColor Green
    } else {
        Write-Host "[OK] pyproject.toml is already compatible" -ForegroundColor Green
    }
} else {
    Write-Host "[!] pyproject.toml not found, skipping Poetry configuration check" -ForegroundColor Yellow
}

# Check and generate poetry.lock for backend
Write-Host "Checking backend dependencies..." -ForegroundColor Blue
$backendPath = "..\backend"
if (Test-Path "$backendPath\pyproject.toml") {
    if (-Not (Test-Path "$backendPath\poetry.lock")) {
        Write-Host "[!] backend\poetry.lock is missing. Generating it..." -ForegroundColor Yellow
        Push-Location $backendPath
        poetry lock
        Pop-Location
        Write-Host "[OK] Generated backend\poetry.lock" -ForegroundColor Green
    } else {
        Write-Host "[OK] backend\poetry.lock already exists" -ForegroundColor Green
    }
    Write-Host "Validating backend dependencies..." -ForegroundColor Blue
    Push-Location $backendPath
    poetry check
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] Validation failed for backend dependencies. Please fix issues in pyproject.toml or poetry.lock." -ForegroundColor Red
        exit 1
    }
    Pop-Location
    Write-Host "[OK] Backend dependencies are valid" -ForegroundColor Green
} else {
    Write-Host "[!] backend\pyproject.toml not found. Skipping backend dependency setup." -ForegroundColor Yellow
}

# Check and generate poetry.lock for frontend
Write-Host "Checking frontend dependencies..." -ForegroundColor Blue
$frontendPath = "..\frontend"
if (Test-Path "$frontendPath\pyproject.toml") {
    if (-Not (Test-Path "$frontendPath\poetry.lock")) {
        Write-Host "[!] frontend\poetry.lock is missing. Generating it..." -ForegroundColor Yellow
        Push-Location $frontendPath
        poetry lock
        Pop-Location
        Write-Host "[OK] Generated frontend\poetry.lock" -ForegroundColor Green
    } else {
        Write-Host "[OK] frontend\poetry.lock already exists" -ForegroundColor Green
    }
    Write-Host "Validating frontend dependencies..." -ForegroundColor Blue
    Push-Location $frontendPath
    poetry check
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] Validation failed for frontend dependencies. Please fix issues in pyproject.toml or poetry.lock." -ForegroundColor Red
        exit 1
    }
    Pop-Location
    Write-Host "[OK] Frontend dependencies are valid" -ForegroundColor Green
} else {
    Write-Host "[!] frontend\pyproject.toml not found. Skipping frontend dependency setup." -ForegroundColor Yellow
}

# Navigate to project root for docker-compose commands
Push-Location ".."

# Stop any existing containers and clean cache
Write-Host "Stopping existing containers and cleaning cache..." -ForegroundColor Blue
docker-compose down 2>$null
docker system prune -f 2>$null

# Build and start services
Write-Host "Building and starting services..." -ForegroundColor Blue
docker-compose build --no-cache
docker-compose up -d

Write-Host "Waiting for services to be ready..." -ForegroundColor Blue
Start-Sleep -Seconds 10

# Health checks
Write-Host "Performing health checks..." -ForegroundColor Blue
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "[OK] Backend is healthy!" -ForegroundColor Green
    }
} catch {
    Write-Host "[!] Backend health check failed, check logs with: docker-compose logs backend" -ForegroundColor Yellow
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "[OK] Frontend is accessible!" -ForegroundColor Green
    }
} catch {
    Write-Host "[!] Frontend not accessible, check logs with: docker-compose logs frontend" -ForegroundColor Yellow
}

# Return to scripts directory
Pop-Location

Write-Host ""
Write-Host "=== SETUP COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "1. Edit backend\.env with your API keys" -ForegroundColor Gray
Write-Host "2. Access the application:" -ForegroundColor Gray
Write-Host "   - Frontend: http://localhost:3000" -ForegroundColor Gray
Write-Host "   - Backend API: http://localhost:8000" -ForegroundColor Gray
Write-Host "   - API Docs: http://localhost:8000/docs" -ForegroundColor Gray
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor White
Write-Host "  - View logs: docker-compose logs -f [service]" -ForegroundColor Gray
Write-Host "  - Debug Poetry: .\debug-poetry.ps1" -ForegroundColor Gray
Write-Host "  - Stop services: docker-compose down" -ForegroundColor Gray
Write-Host ""
Write-Host "Happy coding!" -ForegroundColor Green
