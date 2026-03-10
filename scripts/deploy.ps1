# Deployment script for Transformer WAF (Windows PowerShell)
# For ISRO / Department of Space Academic Evaluation
# Usage: .\deploy.ps1 -Environment [development|production|test]

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('development', 'production', 'test')]
    [string]$Environment = 'development'
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

Write-Host "========================================" -ForegroundColor Blue
Write-Host "Transformer WAF Deployment Script" -ForegroundColor Blue
Write-Host "Environment: $Environment" -ForegroundColor Blue
Write-Host "========================================`n" -ForegroundColor Blue

# Get project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# ==================== Pre-flight Checks ====================

Write-Info "Running pre-flight checks..."

# Check for required commands
$RequiredCommands = @('docker', 'docker-compose', 'python', 'node', 'npm')
foreach ($cmd in $RequiredCommands) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "$cmd is not installed. Please install it first."
        exit 1
    }
}

Write-Info "✓ All required commands are available"

# Check if model exists
if (-not (Test-Path "$ProjectRoot\models\waf_transformer")) {
    Write-Warn "Model not found at models\waf_transformer"
    Write-Info "Please download the pre-trained model or train from scratch"
    $response = Read-Host "Continue anyway? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        exit 1
    }
}

# ==================== Environment Setup ====================

Write-Info "Setting up environment..."

if (-not (Test-Path "$ProjectRoot\.env")) {
    Write-Info "Creating .env file from template..."
    Copy-Item "$ProjectRoot\.env.example" "$ProjectRoot\.env"
    Write-Warn "Please review and customize .env file"
}

# Create necessary directories
@('logs', 'data', 'reports') | ForEach-Object {
    $dir = Join-Path $ProjectRoot $_
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-Info "✓ Environment setup complete"

# ==================== Deployment by Environment ====================

switch ($Environment) {
    'development' {
        Write-Info "Starting development deployment..."
        
        # Start backend
        Write-Info "Starting backend API..."
        Set-Location $ProjectRoot
        
        if (-not (Test-Path "venv")) {
            Write-Info "Creating virtual environment..."
            python -m venv venv
        }
        
        & ".\venv\Scripts\Activate.ps1"
        pip install --upgrade pip -q
        pip install -r requirements.txt -q
        
        # Start API in background
        Write-Info "Starting API server..."
        $ApiProcess = Start-Process -FilePath "python" -ArgumentList "-m api.waf_api --host 127.0.0.1 --port 8000" -PassThru -RedirectStandardOutput "logs\api.log" -RedirectStandardError "logs\api_error.log"
        $ApiProcess.Id | Out-File ".api.pid"
        Write-Info "✓ Backend started (PID: $($ApiProcess.Id))"
        
        # Start frontend
        Write-Info "Starting frontend dashboard..."
        Set-Location "$ProjectRoot\frontend"
        
        if (-not (Test-Path "node_modules")) {
            Write-Info "Installing frontend dependencies..."
            npm install
        }
        
        # Start frontend in background
        $FrontendProcess = Start-Process -FilePath "npm" -ArgumentList "run dev" -PassThru -RedirectStandardOutput "..\logs\frontend.log" -RedirectStandardError "..\logs\frontend_error.log"
        $FrontendProcess.Id | Out-File "..\.frontend.pid"
        Write-Info "✓ Frontend started (PID: $($FrontendProcess.Id))"
        
        Start-Sleep -Seconds 5
        
        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "Development deployment successful!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Backend API:    http://localhost:8000" -ForegroundColor Blue
        Write-Host "Frontend:       http://localhost:3000" -ForegroundColor Blue
        Write-Host "API Docs:       http://localhost:8000/docs" -ForegroundColor Blue
        Write-Host "`nLogs:"
        Write-Host "  Backend:  Get-Content logs\api.log -Wait"
        Write-Host "  Frontend: Get-Content logs\frontend.log -Wait"
        Write-Host "`nTo stop: .\scripts\stop.ps1"
    }
    
    'production' {
        Write-Info "Starting production deployment with Docker..."
        
        Set-Location $ProjectRoot
        
        # Build Docker images
        Write-Info "Building Docker images..."
        docker-compose -f docker\docker-compose.yml build
        
        # Run security scan if Trivy is available
        if (Get-Command trivy -ErrorAction SilentlyContinue) {
            Write-Info "Running security scan on Docker images..."
            trivy image transformer-waf:latest
        } else {
            Write-Warn "Trivy not found, skipping image security scan"
        }
        
        # Start services
        Write-Info "Starting Docker services..."
        docker-compose -f docker\docker-compose.yml up -d
        
        # Wait for health checks
        Write-Info "Waiting for services to be healthy..."
        Start-Sleep -Seconds 10
        
        # Check service status
        docker-compose -f docker\docker-compose.yml ps
        
        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "Production deployment successful!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Backend API:    http://localhost:8000" -ForegroundColor Blue
        Write-Host "Frontend:       http://localhost:3000" -ForegroundColor Blue
        Write-Host "Redis:          localhost:6379" -ForegroundColor Blue
        Write-Host "`nManagement commands:"
        Write-Host "  Logs:    docker-compose -f docker\docker-compose.yml logs -f"
        Write-Host "  Stop:    docker-compose -f docker\docker-compose.yml down"
        Write-Host "  Restart: docker-compose -f docker\docker-compose.yml restart"
    }
    
    'test' {
        Write-Info "Running test suite..."
        
        Set-Location $ProjectRoot
        
        # Activate virtual environment
        if (-not (Test-Path "venv")) {
            Write-Error "Virtual environment not found. Run deployment first."
            exit 1
        }
        
        & ".\venv\Scripts\Activate.ps1"
        
        # Run unit tests
        Write-Info "Running unit tests..."
        pytest --cov=. --cov-report=html --cov-report=term
        
        # Run security scans
        Write-Info "Running security scans..."
        
        # SAST
        if (Test-Path "devsecops\bandit_scan.sh") {
            bash devsecops\bandit_scan.sh
        }
        
        # Dependency scan
        safety check --json | Out-File reports\safety_report.json
        
        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "Test suite complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Coverage report: file://$(Get-Location)\htmlcov\index.html" -ForegroundColor Blue
        Write-Host "Bandit report:   file://$(Get-Location)\reports\bandit_report.html" -ForegroundColor Blue
    }
}

Write-Host "`nDeployment complete! 🚀`n" -ForegroundColor Green
