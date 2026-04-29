# Singalong API - Endpoint Usage Guide

**Quick Reference for Testing & Integration**

This guide shows you exactly how to use every endpoint with copy-paste examples. All examples use `curl` for simplicity—you can paste these into Postman, a terminal, or your application code.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Authentication](#authentication)
3. [Songs Workflow](#songs-workflow)
4. [Sessions & Queue](#sessions--queue)
5. [Reservations](#reservations)
6. [Player Registration](#player-registration)
7. [Quick Testing Checklist](#quick-testing-checklist)

---

## Prerequisites

### Setup
```bash
# Make sure services are running
docker-compose up -d

# Check Node health
curl http://localhost:5002/health
```

### Environment Variables
Replace these in your examples:
- `{{NODE_URL}}` → `http://localhost:5002`
- `{{ADMIN_TOKEN}}` → JWT token from admin login
- `{{CONTROLLER_TOKEN}}` → JWT token from controller login
- `{{SESSION_ID}}` → UUID from created session
- `{{SONG_ID}}` → UUID from identified song

---

## Authentication

### 1. Admin Login
```bash
curl -X POST http://localhost:5002/api/auth/admin \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "singalong123"
  }'
```

**Response:**
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "token_type": "bearer",
  "user_id": "uuid-here"
}
```

**Save the token:**
```bash
export ADMIN_TOKEN="<paste-access_token-here>"
```

### 2. Controller Login (Attendee)
```bash
curl -X POST http://localhost:5002/api/auth/controller \
  -H "Content-Type: application/json" \
  -d '{
    "username": "attendee1",
    "password": "password123"
  }'
```

**Save the token:**
```bash
export CONTROLLER_TOKEN="<paste-access_token-here>"
```

### 3. Player Login
```bash
curl -X POST http://localhost:5002/api/auth/player \
  -H "Content-Type: application/json" \
  -d '{
    "username": "player1",
    "password": "playerpass123"
  }'
```

---

## Songs Workflow

### Step 1: Identify a Song (Get YouTube Metadata)

Takes a YouTube URL and extracts metadata (title, artist, duration, etc).

```bash
curl -X POST http://localhost:5002/api/songs/identify \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  }'
```

**Expected Response:**
```json
{
  "youtube_id": "dQw4w9WgXcQ",
  "title": "Rick Astley - Never Gonna Give You Up",
  "artist": "Rick Astley",
  "duration": 212,
  "thumbnail_url": "...",
  "view_count": 1000000
}
```

**Save for next step:**
```bash
export SONG_TITLE="Rick Astley - Never Gonna Give You Up"
export SONG_URL="https://www.youtube.com/watch?v=dQw4w9WgXcQ"
```

### Step 2: Enhance Song Metadata (Optional)

Edit the song details before downloading (fix title, artist, year, etc).

```bash
curl -X PUT http://localhost:5002/api/songs/enhance \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "title": "Never Gonna Give You Up",
    "artist": "Rick Astley",
    "year": 1987,
    "genre": "pop",
    "language": "en",
    "duration": 212,
    "additional_notes": "Original music video version"
  }'
```

**Validation Rules:**
- **title**: 1-255 characters
- **artist**: 1-255 characters
- **year**: 1900-2100
- **genre**: Must be from [pop, rock, hip-hop, jazz, classical, country, r&b, electronic, latin, k-pop, etc.]
- **language**: ISO 639-1 code [en, es, fr, de, ja, zh, ko, etc.]
- **duration**: 1-86400 seconds
- **additional_notes**: Max 1000 characters

**Response:**
```json
{
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "Never Gonna Give You Up",
  "artist": "Rick Astley",
  "year": 1987,
  "genre": "pop",
  "language": "en",
  "duration": 212,
  "additional_notes": "Original music video version"
}
```

### Step 3: Request Download

Tell the Master server to download the song.

```bash
curl -X POST http://localhost:5002/api/songs/download-request \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "title": "Never Gonna Give You Up",
    "artist": "Rick Astley",
    "year": 1987,
    "genre": "pop",
    "language": "en",
    "duration": 212,
    "additional_notes": "Original music video version"
  }'
```

**Response:**
```json
{
  "song_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "pending",
  "created_at": "2024-01-01T12:00:00Z",
  "message": "Download request queued"
}
```

**Save the song ID:**
```bash
export SONG_ID="550e8400-e29b-41d4-a716-446655440000"
```

### Step 4: Check Download Status

Poll this to see download progress.

```bash
curl http://localhost:5002/api/songs/download-status/$SONG_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**Response (while downloading):**
```json
{
  "song_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "downloading",
  "progress_percent": 45,
  "file_size_mb": 25.5,
  "estimated_time_remaining_seconds": 120,
  "created_at": "2024-01-01T12:00:00Z",
  "started_at": "2024-01-01T12:00:10Z",
  "completed_at": null
}
```

**Response (completed):**
```json
{
  "song_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "progress_percent": 100,
  "file_size_mb": 25.5,
  "estimated_time_remaining_seconds": 0,
  "created_at": "2024-01-01T12:00:00Z",
  "started_at": "2024-01-01T12:00:10Z",
  "completed_at": "2024-01-01T12:02:00Z"
}
```

### Step 5: List Available Songs

Get all songs in the system (after downloading).

```bash
curl http://localhost:5002/api/songs \
  -H "Authorization: Bearer $CONTROLLER_TOKEN"
```

**Query Parameters:**
- `limit` - Results per page (default: 50)
- `offset` - Pagination offset (default: 0)
- `sort_by` - Field to sort [title, artist, year, duration] (default: title)
- `order` - Sort order [asc, desc] (default: asc)

**Example with pagination:**
```bash
curl "http://localhost:5002/api/songs?limit=10&offset=0&sort_by=title&order=asc" \
  -H "Authorization: Bearer $CONTROLLER_TOKEN"
```

**Response:**
```json
{
  "songs": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Never Gonna Give You Up",
      "artist": "Rick Astley",
      "year": 1987,
      "genre": "pop",
      "language": "en",
      "duration": 212,
      "status": "completed",
      "file_size_mb": 25.5
    }
  ],
  "total": 150,
  "limit": 10,
  "offset": 0
}
```

---

## Sessions & Queue

### Create a Session

Setup a karaoke event (generates 6-character code).

```bash
curl -X POST http://localhost:5002/api/sessions \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Friday Night Karaoke",
    "max_users": 50
  }'
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "code": "ABC123",
  "title": "Friday Night Karaoke",
  "created_by": "admin-uuid",
  "max_users": 50,
  "status": "active",
  "created_at": "2024-01-01T12:00:00Z"
}
```

**Save the session ID and code:**
```bash
export SESSION_ID="550e8400-e29b-41d4-a716-446655440000"
export SESSION_CODE="ABC123"
```

### Join a Session (as Attendee)

```bash
curl -X POST http://localhost:5002/api/sessions/$SESSION_ID/users \
  -H "Authorization: Bearer $CONTROLLER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nickname": "John Doe"
  }'
```

**Response:**
```json
{
  "user_id": "user-uuid",
  "nickname": "John Doe",
  "role": "attendee",
  "joined_at": "2024-01-01T12:01:00Z"
}
```

### Get Queue (for Player App)

Show songs in playback order.

```bash
curl http://localhost:5002/api/sessions/$SESSION_ID/queue
```

**Response:**
```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "queue": [
    {
      "position": 1,
      "song_id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Never Gonna Give You Up",
      "artist": "Rick Astley",
      "duration": 212,
      "status": "pending"
    },
    {
      "position": 2,
      "song_id": "550e8400-e29b-41d4-a716-446655440001",
      "title": "Bohemian Rhapsody",
      "artist": "Queen",
      "duration": 354,
      "status": "pending"
    }
  ],
  "total_queue_duration_seconds": 566
}
```

---

## Reservations

### Reserve a Song

Add a song to the session queue.

```bash
curl -X POST http://localhost:5002/api/sessions/$SESSION_ID/reservations \
  -H "Authorization: Bearer $CONTROLLER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "song_id": "550e8400-e29b-41d4-a716-446655440000"
  }'
```

**Response:**
```json
{
  "reservation_id": "550e8400-e29b-41d4-a716-446655440002",
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "song_id": "550e8400-e29b-41d4-a716-446655440000",
  "song_title": "Never Gonna Give You Up",
  "position": 1,
  "status": "pending",
  "created_at": "2024-01-01T12:02:00Z"
}
```

### List My Reservations

See all songs you've reserved in this session.

```bash
curl "http://localhost:5002/api/sessions/$SESSION_ID/reservations?user_id=your-user-id" \
  -H "Authorization: Bearer $CONTROLLER_TOKEN"
```

**Response:**
```json
{
  "reservations": [
    {
      "reservation_id": "550e8400-e29b-41d4-a716-446655440002",
      "song_id": "550e8400-e29b-41d4-a716-446655440000",
      "song_title": "Never Gonna Give You Up",
      "artist": "Rick Astley",
      "position": 1,
      "status": "pending",
      "created_at": "2024-01-01T12:02:00Z"
    }
  ]
}
```

### Update Reservation Status (Admin Only)

Change status from `pending` → `playing` → `completed` (or `cancelled` at any stage).

```bash
curl -X PUT http://localhost:5002/api/sessions/$SESSION_ID/reservations/$RESERVATION_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "playing"
  }'
```

**Valid Status Transitions:**
```
pending → playing → completed
pending → cancelled
playing → completed
playing → cancelled
completed (final state)
```

**Response:**
```json
{
  "reservation_id": "550e8400-e29b-41d4-a716-446655440002",
  "status": "playing",
  "updated_at": "2024-01-01T12:05:00Z"
}
```

### Cancel Reservation

Remove a song from the queue.

```bash
curl -X DELETE http://localhost:5002/api/sessions/$SESSION_ID/reservations/$RESERVATION_ID \
  -H "Authorization: Bearer $CONTROLLER_TOKEN"
```

**Response:**
```json
{
  "message": "Reservation cancelled",
  "reservation_id": "550e8400-e29b-41d4-a716-446655440002"
}
```

**Note:** Positions of remaining reservations are automatically recalculated.

---

## Player Registration

### Register a Player Device

```bash
curl -X POST http://localhost:5002/api/players/register \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "device_name": "Living Room TV",
    "device_type": "hdmi"
  }'
```

**Response:**
```json
{
  "player_id": "550e8400-e29b-41d4-a716-446655440003",
  "api_key": "pk_live_AbC1234567890XyZ",
  "device_name": "Living Room TV",
  "device_type": "hdmi",
  "status": "inactive",
  "created_at": "2024-01-01T12:00:00Z"
}
```

**Save the API key:**
```bash
export PLAYER_API_KEY="pk_live_AbC1234567890XyZ"
```

### Assign Player to Session

Link a registered player to a session.

```bash
curl -X POST http://localhost:5002/api/players/$PLAYER_ID/assign \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "550e8400-e29b-41d4-a716-446655440000"
  }'
```

**Response:**
```json
{
  "player_id": "550e8400-e29b-41d4-a716-446655440003",
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "active",
  "assigned_at": "2024-01-01T12:10:00Z"
}
```

### Player Gets Queue (using API Key)

```bash
curl "http://localhost:5002/api/sessions/$SESSION_ID/queue" \
  -H "X-Player-API-Key: $PLAYER_API_KEY"
```

---

## Health Check

### Check Node Status

```bash
curl http://localhost:5002/health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "singalong-node",
  "version": "1.0.0",
  "master_url": "http://singalong-master:5001",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

---

## Quick Testing Checklist

Copy-paste this entire workflow to test everything:

```bash
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}1. Health Check${NC}"
curl http://localhost:5002/health | jq .

echo -e "${YELLOW}2. Admin Login${NC}"
ADMIN_RESPONSE=$(curl -s -X POST http://localhost:5002/api/auth/admin \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"singalong123"}')
export ADMIN_TOKEN=$(echo $ADMIN_RESPONSE | jq -r '.access_token')
echo "Admin token: $ADMIN_TOKEN"

echo -e "${YELLOW}3. Controller Login${NC}"
CONTROLLER_RESPONSE=$(curl -s -X POST http://localhost:5002/api/auth/controller \
  -H "Content-Type: application/json" \
  -d '{"username":"attendee1","password":"password123"}')
export CONTROLLER_TOKEN=$(echo $CONTROLLER_RESPONSE | jq -r '.access_token')
echo "Controller token: $CONTROLLER_TOKEN"

echo -e "${YELLOW}4. Identify Song${NC}"
SONG_RESPONSE=$(curl -s -X POST http://localhost:5002/api/songs/identify \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.youtube.com/watch?v=dQw4w9WgXcQ"}')
echo $SONG_RESPONSE | jq .

echo -e "${YELLOW}5. Request Download${NC}"
DOWNLOAD_RESPONSE=$(curl -s -X POST http://localhost:5002/api/songs/download-request \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url":"https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "title":"Never Gonna Give You Up",
    "artist":"Rick Astley",
    "year":1987,
    "genre":"pop",
    "language":"en",
    "duration":212,
    "additional_notes":""
  }')
export SONG_ID=$(echo $DOWNLOAD_RESPONSE | jq -r '.song_id')
echo "Song ID: $SONG_ID"

echo -e "${YELLOW}6. Check Download Status${NC}"
curl -s http://localhost:5002/api/songs/download-status/$SONG_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq .

echo -e "${YELLOW}7. Create Session${NC}"
SESSION_RESPONSE=$(curl -s -X POST http://localhost:5002/api/sessions \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Session","max_users":50}')
export SESSION_ID=$(echo $SESSION_RESPONSE | jq -r '.id')
echo "Session ID: $SESSION_ID"

echo -e "${YELLOW}8. Join Session${NC}"
curl -s -X POST http://localhost:5002/api/sessions/$SESSION_ID/users \
  -H "Authorization: Bearer $CONTROLLER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nickname":"Test User"}' | jq .

echo -e "${YELLOW}9. Reserve Song${NC}"
RESERVATION=$(curl -s -X POST http://localhost:5002/api/sessions/$SESSION_ID/reservations \
  -H "Authorization: Bearer $CONTROLLER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"song_id\":\"$SONG_ID\"}")
export RESERVATION_ID=$(echo $RESERVATION | jq -r '.reservation_id')
echo $RESERVATION | jq .

echo -e "${YELLOW}10. Get Queue${NC}"
curl -s http://localhost:5002/api/sessions/$SESSION_ID/queue | jq .

echo -e "${GREEN}✓ All tests completed!${NC}"
```

Save this as `test.sh`, then run:
```bash
chmod +x test.sh
./test.sh
```

---

## Error Handling

All endpoints return standard error responses:

```json
{
  "status": "error",
  "code": "SONG_NOT_FOUND",
  "message": "Song with id '123' does not exist",
  "details": {
    "song_id": "123"
  }
}
```

**Common Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad request (validation error)
- `401` - Unauthorized (missing/invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not found
- `409` - Conflict (duplicate reservation, etc.)
- `500` - Server error

---

## Tips & Tricks

### Saving Variables in Postman

Instead of copying tokens manually, use Postman's environment variables:

1. Go to **Environments** → **New**
2. Add variables:
   ```
   NODE_URL: http://localhost:5002
   ADMIN_TOKEN: (empty, will be filled by auth endpoint)
   SESSION_ID: (empty)
   SONG_ID: (empty)
   ```
3. In auth endpoint, add test:
   ```javascript
   pm.environment.set("ADMIN_TOKEN", pm.response.json().access_token);
   ```
4. Use `{{ADMIN_TOKEN}}` in all subsequent requests

### Rate Limiting

Currently no rate limiting, but future endpoints will implement:
- 100 requests per minute per IP
- 1000 requests per hour per API key

### Pagination

All list endpoints support pagination:
```bash
curl "http://localhost:5002/api/songs?limit=10&offset=20"
```

### Sorting

Most list endpoints support sorting:
```bash
curl "http://localhost:5002/api/songs?sort_by=artist&order=desc"
```

---

## Next Steps

- **Frontend Integration**: Connect your React/web app to these endpoints
- **Player App**: Use queue endpoint to display current songs
- **Advanced Features**: Implement WebSocket for real-time updates (coming soon)

For complete API reference, see [`MVP_BACKEND_API.md`](./MVP_BACKEND_API.md)

For testing procedures, see [`MVP_BACKEND_TESTING.md`](./MVP_BACKEND_TESTING.md)
