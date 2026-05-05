#!/bin/bash
set -e

echo "Starting Singalong mDNS Bridge..."

# Set defaults (can be overridden via environment)
export NODE_HOST=${NODE_HOST:-localhost}
export NODE_PORT=${NODE_PORT:-5002}
export MDNS_SERVICE_NAME=${MDNS_SERVICE_NAME:-"Singalong Node"}
export MDNS_SERVICE_TYPE=${MDNS_SERVICE_TYPE:-"_singalong-node._tcp"}

echo "Configuration:"
echo "  Node Host: $NODE_HOST"
echo "  Node Port: $NODE_PORT"
echo "  Service: $MDNS_SERVICE_NAME"
echo "  Type: $MDNS_SERVICE_TYPE"
echo ""

poetry run python app.py
