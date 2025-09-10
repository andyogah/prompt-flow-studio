# =================================
# PROMPT FLOW POETRY DEBUG SCRIPT
# =================================

Write-Host "[*] Debugging Poetry configuration..." -ForegroundColor Cyan

# Navigate to the backend directory
$backendPath = "../backend"
if (-Not (Test-Path -Path $backendPath)) {
    Write-Host "[!] Backend path not found: $backendPath" -ForegroundColor Red
    exit 1
}
Set-Location -Path $backendPath

# Check if Poetry is installed
if (-Not (Get-Command poetry -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Poetry is not installed or not in PATH. Please install Poetry and try again." -ForegroundColor Red
    exit 1
}

# Check if poetry.lock exists
if (-Not (Test-Path -Path "poetry.lock")) {
    Write-Host "[!] poetry.lock is missing. Generating it..."
    poetry lock
}

# Validate pyproject.toml and poetry.lock
Write-Host "[*] Validating pyproject.toml and poetry.lock..."
poetry check
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Validation failed. Please fix issues in pyproject.toml or poetry.lock." -ForegroundColor Red
    exit 1
}

Write-Host "[*] Poetry configuration is valid."
Set-Location -Path "../scripts"

# Build the backend
Write-Host "Building backend container..." -ForegroundColor Blue
docker-compose build backend

# Run each diagnostic command separately
Write-Host "=== Poetry Environment Info ===" -ForegroundColor Yellow
docker-compose run --rm backend poetry env info

Write-Host "=== Poetry Show Packages ===" -ForegroundColor Yellow
docker-compose run --rm backend poetry show

Write-Host "=== Check if uvicorn is installed ===" -ForegroundColor Yellow
docker-compose run --rm backend bash -c "poetry run which uvicorn || echo 'uvicorn not found'"

Write-Host "=== Try running uvicorn directly ===" -ForegroundColor Yellow
docker-compose run --rm backend bash -c "poetry run uvicorn --version || echo 'uvicorn version failed'"

Write-Host "=== Check virtual environment ===" -ForegroundColor Yellow
docker-compose run --rm backend bash -c "ls -la .venv/ || echo 'No .venv directory'"

Write-Host "=== Python path ===" -ForegroundColor Yellow
docker-compose run --rm backend poetry run python -c "import sys; print(sys.path)"

Write-Host "=== Try importing app ===" -ForegroundColor Yellow
docker-compose run --rm backend poetry run python -c "import app.main; print('App import successful')"

Pop-Location

Write-Host ""
Write-Host "=== POETRY DEBUG COMPLETE ===" -ForegroundColor Green
