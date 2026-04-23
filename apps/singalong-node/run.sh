#!/bin/bash
# Development server startup script for singalong-node

set -e

echo "Starting Singalong Node development server..."
echo ""

# Load environment variables from .env if it exists
if [ -f .env ]; then
    echo "Loading environment from .env"
    export $(cat .env | grep -v '^#' | xargs)
fi

# Display configuration
echo "Configuration:"
echo "  Host: ${HOST:-0.0.0.0}"
echo "  Port: ${PORT:-5002}"
echo "  Master URL: ${MASTER_URL:-http://localhost:5000}"
echo "  Debug: ${DEBUG:-False}"
echo ""

# Start the development server with hot-reload
poetry run uvicorn app.main:app \
    --reload \
    --host "${HOST:-0.0.0.0}" \
    --port "${PORT:-5002}"
