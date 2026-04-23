#!/bin/bash
# Development server startup script for singalong-master

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables from .env if it exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Default values
PORT=${PORT:-5001}
HOST=${HOST:-0.0.0.0}
DEBUG=${DEBUG:-True}

echo "🚀 Starting Singalong Master Service"
echo "   Host: $HOST"
echo "   Port: $PORT"
echo "   Debug: $DEBUG"
echo "   API Docs: http://$HOST:$PORT/docs"
echo ""

poetry run uvicorn app.main:app --host "$HOST" --port "$PORT" --reload
