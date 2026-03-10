#!/bin/bash
# Deployment script for Transformer WAF
# For ISRO / Department of Space Academic Evaluation
# Usage: ./deploy.sh [development|production|test]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT="${1:-development}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Transformer WAF Deployment Script${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}========================================${NC}\n"

# ==================== Helper Functions ====================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

# ==================== Pre-flight Checks ====================

log_info "Running pre-flight checks..."

check_command docker
check_command docker-compose
check_command python3
check_command node

log_info "✓ All required commands are available"

# Check if model exists
if [ ! -d "$PROJECT_ROOT/models/waf_transformer" ]; then
    log_warn "Model not found at models/waf_transformer"
    log_info "Please download the pre-trained model or train from scratch"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ==================== Environment Setup ====================

log_info "Setting up environment..."

if [ ! -f "$PROJECT_ROOT/.env" ]; then
    log_info "Creating .env file from template..."
    cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
    log_warn "Please review and customize .env file"
fi

# Create necessary directories
mkdir -p "$PROJECT_ROOT/logs"
mkdir -p "$PROJECT_ROOT/data"
mkdir -p "$PROJECT_ROOT/reports"

log_info "✓ Environment setup complete"

# ==================== Deployment by Environment ====================

case "$ENVIRONMENT" in
    development)
        log_info "Starting development deployment..."
        
        # Start backend
        log_info "Starting backend API..."
        cd "$PROJECT_ROOT"
        if [ ! -d "venv" ]; then
            log_info "Creating virtual environment..."
            python3 -m venv venv
        fi
        source venv/bin/activate
        pip install -q --upgrade pip
        pip install -q -r requirements.txt
        
        # Start API in background
        nohup python -m api.waf_api --host 127.0.0.1 --port 8000 > logs/api.log 2>&1 &
        API_PID=$!
        echo $API_PID > .api.pid
        log_info "✓ Backend started (PID: $API_PID)"
        
        # Start frontend
        log_info "Starting frontend dashboard..."
        cd "$PROJECT_ROOT/frontend"
        if [ ! -d "node_modules" ]; then
            log_info "Installing frontend dependencies..."
            npm install
        fi
        
        # Start frontend in background
        nohup npm run dev > ../logs/frontend.log 2>&1 &
        FRONTEND_PID=$!
        echo $FRONTEND_PID > ../.frontend.pid
        log_info "✓ Frontend started (PID: $FRONTEND_PID)"
        
        sleep 5
        
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN}Development deployment successful!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "Backend API:    ${BLUE}http://localhost:8000${NC}"
        echo -e "Frontend:       ${BLUE}http://localhost:3000${NC}"
        echo -e "API Docs:       ${BLUE}http://localhost:8000/docs${NC}"
        echo -e "\nLogs:"
        echo -e "  Backend:  tail -f logs/api.log"
        echo -e "  Frontend: tail -f logs/frontend.log"
        echo -e "\nTo stop: ./scripts/stop.sh"
        ;;
        
    production)
        log_info "Starting production deployment with Docker..."
        
        # Build Docker images
        log_info "Building Docker images..."
        cd "$PROJECT_ROOT"
        docker-compose -f docker/docker-compose.yml build
        
        # Run security scan on images
        if command -v trivy &> /dev/null; then
            log_info "Running security scan on Docker images..."
            trivy image transformer-waf:latest
        else
            log_warn "Trivy not found, skipping image security scan"
        fi
        
        # Start services
        log_info "Starting Docker services..."
        docker-compose -f docker/docker-compose.yml up -d
        
        # Wait for health checks
        log_info "Waiting for services to be healthy..."
        sleep 10
        
        # Check service status
        docker-compose -f docker/docker-compose.yml ps
        
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN}Production deployment successful!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "Backend API:    ${BLUE}http://localhost:8000${NC}"
        echo -e "Frontend:       ${BLUE}http://localhost:3000${NC}"
        echo -e "Redis:          ${BLUE}localhost:6379${NC}"
        echo -e "\nManagement commands:"
        echo -e "  Logs:    docker-compose -f docker/docker-compose.yml logs -f"
        echo -e "  Stop:    docker-compose -f docker/docker-compose.yml down"
        echo -e "  Restart: docker-compose -f docker/docker-compose.yml restart"
        ;;
        
    test)
        log_info "Running test suite..."
        
        cd "$PROJECT_ROOT"
        
        # Activate virtual environment
        if [ ! -d "venv" ]; then
            log_error "Virtual environment not found. Run deployment first."
            exit 1
        fi
        source venv/bin/activate
        
        # Run unit tests
        log_info "Running unit tests..."
        pytest --cov=. --cov-report=html --cov-report=term
        
        # Run security scans
        log_info "Running security scans..."
        
        # SAST
        if [ -f "devsecops/bandit_scan.sh" ]; then
            bash devsecops/bandit_scan.sh
        fi
        
        # Dependency scan
        safety check --json > reports/safety_report.json || true
        
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN}Test suite complete!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "Coverage report: ${BLUE}file://$(pwd)/htmlcov/index.html${NC}"
        echo -e "Bandit report:   ${BLUE}file://$(pwd)/reports/bandit_report.html${NC}"
        ;;
        
    *)
        log_error "Unknown environment: $ENVIRONMENT"
        echo "Usage: $0 [development|production|test]"
        exit 1
        ;;
esac

echo -e "\n${GREEN}Deployment complete! 🚀${NC}\n"
