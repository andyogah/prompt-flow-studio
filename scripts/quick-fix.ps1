# =================================
# PROMPT FLOW QUICK FIX SCRIPT
# =================================

Write-Host "[*] Applying quick fixes..." -ForegroundColor Cyan

# Navigate to project root
Push-Location ".."

# Fix 1: Add JWT_SECRET if missing
Write-Host "Fixing environment configuration..." -ForegroundColor Blue
if (Test-Path "backend\.env") {
    $envContent = Get-Content "backend\.env" -Raw
    if (-not ($envContent -match "JWT_SECRET=")) {
        Write-Host "[!] Adding missing JWT_SECRET" -ForegroundColor Yellow
        Add-Content "backend\.env" "`nJWT_SECRET=prompt-flow-development-secret-key-change-in-production"
        Write-Host "[OK] JWT_SECRET added" -ForegroundColor Green
    } else {
        Write-Host "[OK] JWT_SECRET already exists" -ForegroundColor Green
    }
}

# Fix 2: Create main.py if missing
Write-Host "Checking backend entry point..." -ForegroundColor Blue
if (-not (Test-Path "backend\main.py")) {
    Write-Host "[!] Creating missing main.py" -ForegroundColor Yellow
    @"
"""
Prompt Flow Backend - Main Entry Point
"""

import uvicorn
from app.core.config import settings

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="info"
    )
"@ | Out-File -FilePath "backend\main.py" -Encoding UTF8
    Write-Host "[OK] main.py created" -ForegroundColor Green
} else {
    Write-Host "[OK] main.py already exists" -ForegroundColor Green
}

# Fix 3: Remove obsolete version from docker-compose.yml
Write-Host "Fixing docker-compose.yml..." -ForegroundColor Blue
if (Test-Path "docker-compose.yml") {
    $composeContent = Get-Content "docker-compose.yml"
    if ($composeContent -match "version:") {
        Write-Host "[!] Removing obsolete version attribute" -ForegroundColor Yellow
        # Create backup
        Copy-Item "docker-compose.yml" "docker-compose.yml.backup"
        # Remove version line
        ($composeContent | Where-Object { $_ -notmatch "^version:" }) | Set-Content "docker-compose.yml"
        Write-Host "[OK] Removed version attribute" -ForegroundColor Green
    } else {
        Write-Host "[OK] docker-compose.yml is already fixed" -ForegroundColor Green
    }
}

# Fix 4: Stop and rebuild containers
Write-Host "Rebuilding containers..." -ForegroundColor Blue
docker-compose down
docker-compose build --no-cache backend frontend
docker-compose up -d

Write-Host "Waiting for services to start..." -ForegroundColor Blue
Start-Sleep -Seconds 15

# Check if services are now running
Write-Host "Checking service status..." -ForegroundColor Blue
$backendRunning = docker-compose ps -q backend
$frontendRunning = docker-compose ps -q frontend

if ($backendRunning) {
    Write-Host "[OK] Backend container is running" -ForegroundColor Green
} else {
    Write-Host "[!] Backend container failed to start" -ForegroundColor Yellow
    Write-Host "Check logs: docker-compose logs backend" -ForegroundColor Gray
}

if ($frontendRunning) {
    Write-Host "[OK] Frontend container is running" -ForegroundColor Green
} else {
    Write-Host "[!] Frontend container failed to start" -ForegroundColor Yellow
    Write-Host "Check logs: docker-compose logs frontend" -ForegroundColor Gray
}

# Health check
Write-Host "Performing health checks..." -ForegroundColor Blue
Start-Sleep -Seconds 5

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "[OK] Backend health check passed!" -ForegroundColor Green
    }
} catch {
    Write-Host "[!] Backend health check failed" -ForegroundColor Yellow
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "[OK] Frontend is accessible!" -ForegroundColor Green
    }
} catch {
    Write-Host "[!] Frontend health check failed" -ForegroundColor Yellow
}

Pop-Location

Write-Host ""
Write-Host "=== QUICK FIX COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "If services are still not running:" -ForegroundColor White
Write-Host "1. Check build logs: docker-compose logs backend" -ForegroundColor Gray
Write-Host "2. Check frontend logs: docker-compose logs frontend" -ForegroundColor Gray
Write-Host "3. Run diagnose script again: .\diagnose.ps1" -ForegroundColor Gray
