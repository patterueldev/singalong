#!/bin/bash

# WebSocket Token Expiration Bug Reproduction Script
# Usage: ./test_websocket_token_bug.sh [BASE_URL]
# Example: ./test_websocket_token_bug.sh http://localhost:5002
# Example: ./test_websocket_token_bug.sh https://singalongnode-dev.nicenature.space

set -e

# Configuration
BASE_URL="${1:-http://localhost:5002}"
LOG_FILE="websocket_bug_$(date +%s).log"

echo "========================================"
echo "WebSocket Token Expiration Bug Test"
echo "Base URL: $BASE_URL"
echo "Log File: $LOG_FILE"
echo "========================================"

# Write to both stdout and log file
log() {
  local msg="[$(date '+%H:%M:%S')] $1"
  echo "$msg"
  echo "$msg" >> "$LOG_FILE"
}

log "========== STEP 1: Admin Login =========="
log "Authenticating admin user..."

LOGIN_RESPONSE=$(curl -s --request POST \
  --url "$BASE_URL/api/auth/admin" \
  --header 'content-type: application/json' \
  --data '{"username":"admin","password":"admin123"}')

log "Response received"
echo "=== LOGIN RESPONSE ===" >> "$LOG_FILE"
echo "$LOGIN_RESPONSE" | jq . >> "$LOG_FILE" 2>&1 || echo "$LOGIN_RESPONSE" >> "$LOG_FILE"

ADMIN_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token // empty')

if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" = "null" ]; then
  log "ERROR: Failed to get admin token!"
  exit 1
fi

log "✓ Got admin token: ${ADMIN_TOKEN:0:50}..."

log ""
log "========== STEP 2: GET Sessions (Before WS) =========="
log "Fetching list of all sessions..."

SESSIONS_BEFORE=$(curl -s -w "\nHTTP_CODE:%{http_code}" --request GET \
  --url "$BASE_URL/api/sessions" \
  --header "authorization: Bearer $ADMIN_TOKEN")

HTTP_CODE=$(echo "$SESSIONS_BEFORE" | grep "^HTTP_CODE:" | cut -d: -f2)
SESSIONS_BEFORE=$(echo "$SESSIONS_BEFORE" | grep -v "^HTTP_CODE:")

SESSION_COUNT_BEFORE=$(echo "$SESSIONS_BEFORE" | jq '.sessions | length // 0')
log "✓ HTTP Code: $HTTP_CODE | Session count: $SESSION_COUNT_BEFORE"
echo "=== GET SESSIONS BEFORE WS ===" >> "$LOG_FILE"
echo "$SESSIONS_BEFORE" | jq . >> "$LOG_FILE" 2>&1 || echo "$SESSIONS_BEFORE" >> "$LOG_FILE"

log ""
log "========== STEP 3: Create Session =========="
log "Creating new session..."

CREATE_RESPONSE=$(curl -s --request POST \
  --url "$BASE_URL/api/sessions" \
  --header "authorization: Bearer $ADMIN_TOKEN" \
  --header 'content-type: application/json' \
  --data '{"title":"Test WebSocket","vibes":"debug","max_users":0}')

SESSION_ID=$(echo "$CREATE_RESPONSE" | jq -r '.code // empty')

if [ -z "$SESSION_ID" ] || [ "$SESSION_ID" = "null" ]; then
  log "ERROR: Failed to create session!"
  echo "=== CREATE SESSION ERROR ===" >> "$LOG_FILE"
  echo "$CREATE_RESPONSE" | jq . >> "$LOG_FILE" 2>&1 || echo "$CREATE_RESPONSE" >> "$LOG_FILE"
  exit 1
fi

log "✓ Created session: $SESSION_ID"
echo "=== CREATE SESSION RESPONSE ===" >> "$LOG_FILE"
echo "$CREATE_RESPONSE" | jq . >> "$LOG_FILE" 2>&1 || echo "$CREATE_RESPONSE" >> "$LOG_FILE"

log ""
log "========== STEP 3.5: GET Sessions (Before WS - Verification) =========="
log "Reloading session list to verify token still works..."

SESSIONS_RELOAD=$(curl -s -w "\nHTTP_CODE:%{http_code}" --request GET \
  --url "$BASE_URL/api/sessions" \
  --header "authorization: Bearer $ADMIN_TOKEN")

HTTP_CODE=$(echo "$SESSIONS_RELOAD" | grep "^HTTP_CODE:" | cut -d: -f2)
SESSIONS_RELOAD=$(echo "$SESSIONS_RELOAD" | grep -v "^HTTP_CODE:")

SESSION_COUNT_RELOAD=$(echo "$SESSIONS_RELOAD" | jq '.sessions | length // 0')
log "✓ HTTP Code: $HTTP_CODE | Session count: $SESSION_COUNT_RELOAD (Token works)"
echo "=== GET SESSIONS RELOAD (BEFORE WS) ===" >> "$LOG_FILE"
echo "$SESSIONS_RELOAD" | jq . >> "$LOG_FILE" 2>&1 || echo "$SESSIONS_RELOAD" >> "$LOG_FILE"

log ""
log "========== STEP 4: Connect to WebSocket =========="
log "Connecting to WebSocket with authentication token..."
WS_URL="${BASE_URL/http/ws}/ws/$SESSION_ID"
log "WebSocket URL: $WS_URL"
log "Authorization: Bearer ${ADMIN_TOKEN:0:50}..."

# Connect and listen briefly (3 second timeout)
echo "=== WEBSOCKET CONNECTION ===" >> "$LOG_FILE"
(timeout 3 websocat "$WS_URL" --header "Authorization: Bearer $ADMIN_TOKEN" 2>&1 || true) >> "$LOG_FILE"
log "✓ WebSocket connection completed"

log ""
log "========== STEP 5: GET Sessions (After WS Connection) =========="
log "This is the CRITICAL TEST - token should still work after WebSocket"

SESSIONS_AFTER=$(curl -s -w "\nHTTP_CODE:%{http_code}" --request GET \
  --url "$BASE_URL/api/sessions" \
  --header "authorization: Bearer $ADMIN_TOKEN")

HTTP_CODE=$(echo "$SESSIONS_AFTER" | grep "^HTTP_CODE:" | cut -d: -f2)
SESSIONS_AFTER=$(echo "$SESSIONS_AFTER" | grep -v "^HTTP_CODE:")

log "HTTP Response Code: $HTTP_CODE"

if [ "$HTTP_CODE" = "401" ]; then
  log "❌ BUG CONFIRMED: Got HTTP 401 Unauthorized after WebSocket connection!"
  log "   The same token worked BEFORE WebSocket but fails AFTER"
  BUG_REPRODUCED=1
elif [ -z "$HTTP_CODE" ]; then
  log "⚠️  Could not determine HTTP code"
  HTTP_CODE="UNKNOWN"
  BUG_REPRODUCED=0
else
  log "✓ Token still works after WebSocket (HTTP $HTTP_CODE)"
  BUG_REPRODUCED=0
fi

echo "=== GET SESSIONS AFTER WS ===" >> "$LOG_FILE"
echo "HTTP Code: $HTTP_CODE" >> "$LOG_FILE"
echo "$SESSIONS_AFTER" | jq . >> "$LOG_FILE" 2>&1 || echo "$SESSIONS_AFTER" >> "$LOG_FILE"

SESSION_COUNT_AFTER=$(echo "$SESSIONS_AFTER" | jq '.sessions | length // 0')

# Cleanup
log ""
log "========================================"
log "SUMMARY"
log "========================================"
log "Base URL: $BASE_URL"
log "Admin Token: ${ADMIN_TOKEN:0:50}..."
log "Session ID: $SESSION_ID"
log ""
log "Results:"
log "  Step 2 (Before WS):  HTTP $HTTP_CODE | Sessions: $SESSION_COUNT_BEFORE"
log "  Step 3.5 (Reload):   Sessions: $SESSION_COUNT_RELOAD"
log "  Step 5 (After WS):   HTTP $HTTP_CODE | Sessions: $SESSION_COUNT_AFTER"
log ""

if [ "$BUG_REPRODUCED" = "1" ]; then
  log "🔴 BUG REPRODUCED - Token expired after WebSocket connection"
  log "Full log: $LOG_FILE"
  exit 1
else
  log "✓ Bug not reproduced - Token remains valid"
  log "Full log: $LOG_FILE"
  exit 0
fi
