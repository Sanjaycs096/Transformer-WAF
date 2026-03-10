# Stop script for Transformer WAF (Windows PowerShell)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host "Stopping Transformer WAF services..." -ForegroundColor Yellow

# Stop API server
if (Test-Path "$ProjectRoot\.api.pid") {
    $ApiPid = Get-Content "$ProjectRoot\.api.pid"
    try {
        $process = Get-Process -Id $ApiPid -ErrorAction SilentlyContinue
        if ($process) {
            Write-Host "Stopping API server (PID: $ApiPid)..." -ForegroundColor Yellow
            Stop-Process -Id $ApiPid -Force
            Remove-Item "$ProjectRoot\.api.pid"
            Write-Host "✓ API server stopped" -ForegroundColor Green
        } else {
            Write-Host "API server not running" -ForegroundColor Gray
            Remove-Item "$ProjectRoot\.api.pid"
        }
    } catch {
        Write-Host "Error stopping API server: $_" -ForegroundColor Red
    }
} else {
    Write-Host "No API PID file found" -ForegroundColor Gray
}

# Stop frontend server
if (Test-Path "$ProjectRoot\.frontend.pid") {
    $FrontendPid = Get-Content "$ProjectRoot\.frontend.pid"
    try {
        $process = Get-Process -Id $FrontendPid -ErrorAction SilentlyContinue
        if ($process) {
            Write-Host "Stopping frontend server (PID: $FrontendPid)..." -ForegroundColor Yellow
            Stop-Process -Id $FrontendPid -Force
            Remove-Item "$ProjectRoot\.frontend.pid"
            Write-Host "✓ Frontend server stopped" -ForegroundColor Green
        } else {
            Write-Host "Frontend server not running" -ForegroundColor Gray
            Remove-Item "$ProjectRoot\.frontend.pid"
        }
    } catch {
        Write-Host "Error stopping frontend server: $_" -ForegroundColor Red
    }
} else {
    Write-Host "No frontend PID file found" -ForegroundColor Gray
}

# Stop Docker services if running
try {
    $dockerServices = docker-compose -f "$ProjectRoot\docker\docker-compose.yml" ps -q 2>$null
    if ($dockerServices) {
        Write-Host "Stopping Docker services..." -ForegroundColor Yellow
        docker-compose -f "$ProjectRoot\docker\docker-compose.yml" down
        Write-Host "✓ Docker services stopped" -ForegroundColor Green
    }
} catch {
    Write-Host "No Docker services running" -ForegroundColor Gray
}

Write-Host "`n✓ All services stopped successfully" -ForegroundColor Green
