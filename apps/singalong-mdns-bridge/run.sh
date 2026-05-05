#!/bin/bash
set -e

echo "Starting Singalong mDNS Bridge..."

# Set defaults (can be overridden via environment)
export NODE_HOST=${NODE_HOST:-localhost}
export GATEWAY_PORT=${GATEWAY_PORT:-80}  # Nginx gateway port
export HEALTH_POLL_INTERVAL=${HEALTH_POLL_INTERVAL:-5}  # Seconds between health checks
export MDNS_SERVICE_NAME=${MDNS_SERVICE_NAME:-"Singalong Node"}
export MDNS_SERVICE_TYPE=${MDNS_SERVICE_TYPE:-"_singalong-node._tcp"}

echo "Configuration:"
echo "  Node Host: $NODE_HOST"
echo "  Gateway Port: $GATEWAY_PORT (Nginx)"
echo "  Health Poll Interval: ${HEALTH_POLL_INTERVAL}s"
echo "  Service: $MDNS_SERVICE_NAME"
echo "  Type: $MDNS_SERVICE_TYPE"
echo ""
echo "Bridge will continuously monitor Node health and:"
echo "  - Advertise service when Node is healthy"
echo "  - Stop advertising when Node is down"
echo ""

poetry run python app.py
