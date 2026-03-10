#!/bin/bash
# Stop script for Transformer WAF development servers

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Stopping Transformer WAF services..."

# Stop API server
if [ -f "$PROJECT_ROOT/.api.pid" ]; then
    API_PID=$(cat "$PROJECT_ROOT/.api.pid")
    if ps -p $API_PID > /dev/null 2>&1; then
        echo "Stopping API server (PID: $API_PID)..."
        kill $API_PID
        rm "$PROJECT_ROOT/.api.pid"
        echo "✓ API server stopped"
    else
        echo "API server not running"
        rm "$PROJECT_ROOT/.api.pid"
    fi
else
    echo "No API PID file found"
fi

# Stop frontend server
if [ -f "$PROJECT_ROOT/.frontend.pid" ]; then
    FRONTEND_PID=$(cat "$PROJECT_ROOT/.frontend.pid")
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo "Stopping frontend server (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID
        rm "$PROJECT_ROOT/.frontend.pid"
        echo "✓ Frontend server stopped"
    else
        echo "Frontend server not running"
        rm "$PROJECT_ROOT/.frontend.pid"
    fi
else
    echo "No frontend PID file found"
fi

# Stop Docker services if running
if docker-compose -f "$PROJECT_ROOT/docker/docker-compose.yml" ps -q 2>/dev/null | grep -q .; then
    echo "Stopping Docker services..."
    docker-compose -f "$PROJECT_ROOT/docker/docker-compose.yml" down
    echo "✓ Docker services stopped"
fi

echo -e "\n✓ All services stopped successfully"
