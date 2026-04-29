# Singalong MVP Backend API Documentation

**Status**: MVP Complete ✓  
**Last Updated**: 2026-04-29  
**Node Service**: http://localhost:5002  
**Master Service**: https://singalongmaster-dev.nicenature.space

---

## Table of Contents

1. [Authentication](#authentication)
2. [Songs](#songs)
3. [Sessions](#sessions)
4. [Reservations](#reservations)
5. [Players](#players)
6. [Status Codes](#status-codes)
7. [Testing Guide](#testing-guide)

---

## Authentication

All endpoints except health checks require authentication. Three types of tokens are supported.

### Admin Authentication

**Endpoint**: `POST /api/auth/admin`

**Request**:
```json
{
  "username": "admin",
  "password": "your_secure_password"
}
```

**Response** (200):
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_expires_in": 604800,
  "role": "admin"
}
```

**Use Cases**: Session creation, user management, download approval

---

### Controller (Attendee) Authentication

**Endpoint**: `POST /api/auth/controller`

**Request**:
```json
{
  "nickname": "Alice",
  "session_id": "ABC123"
}
```

**Response** (200):
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_expires_in": 604800,
  "role": "controller",
  "user_id": "uuid"
}
```

**Use Cases**: Song identification, downloading, reservations, queue browsing

---

### Player Authentication

**Endpoint**: `POST /api/auth/player`

**Request**:
```json
{
  "session_id": "ABC123",
  "api_key": "your-player-api-key"
}
```

**Response** (200):
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_expires_in": 604800,
  "role": "player",
  "player_id": "uuid",
  "status": "active"
}
```

**Use Cases**: Karaoke player app connecting to a session

---

## Songs

### 1. Identify Song from YouTube URL

**Endpoint**: `POST /api/songs/identify`

**Authentication**: Optional (token if available, for rate limiting)

**Request**:
```json
{
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

**Response** (200):
```json
{
  "video_id": "dQw4w9WgXcQ",
  "title": "Never Gonna Give You Up",
  "artist": "Rick Astley",
  "duration": 212,
  "thumbnail": "https://i.ytimg.com/...",
  "year": 1987,
  "channel": "Rick Astley Official",
  "language": "en",
  "description": "The official music video...",
  "view_count": 1234567890,
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

**Errors**:
- `400`: Invalid YouTube URL format
- `404`: Video not found or removed
- `403`: Video is private or age-restricted
- `429`: Request throttled (too many requests)
- `500`: Extraction failed (YouTube API error)

---

### 2. Enhance Song Metadata

**Endpoint**: `PUT /api/songs/enhance`

**Authentication**: Optional

**Request**:
```json
{
  "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "Never Gonna Give You Up (Remaster)",
  "artist": "Rick Astley",
  "year": 1987,
  "language": "en",
  "genre": "Pop",
  "duration_seconds": 212,
  "additional_notes": "Remastered audio, official upload"
}
```

**Response** (200):
```json
{
  "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "Never Gonna Give You Up (Remaster)",
  "artist": "Rick Astley",
  "year": 1987,
  "language": "en",
  "genre": "Pop",
  "duration_seconds": 212,
  "additional_notes": "Remastered audio, official upload",
  "enhanced_at": "2026-04-29T10:30:00Z",
  "ready_to_download": true
}
```

**Validation Rules**:
- `youtube_url`: Required, must contain youtube.com or youtu.be
- `title`: 1-255 characters
- `artist`: 1-255 characters
- `year`: 1900-2100
- `language`: ISO 639-1 codes (e.g., 'en', 'es', 'fr')
- `genre`: Matched against standard list
- `duration_seconds`: 1-86400 seconds
- `additional_notes`: Max 1000 characters

**Errors**:
- `400`: Validation failed (see detail message)
- `422`: Unprocessable entity

---

### 3. Request Song Download

**Endpoint**: `POST /api/songs/download-request`

**Authentication**: Bearer token (Admin or Controller)

**Request**:
```json
{
  "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "Never Gonna Give You Up",
  "artist": "Rick Astley",
  "year": 1987,
  "language": "en",
  "genre": "Pop",
  "duration_seconds": 212
}
```

**Response** (202 Accepted):
```json
{
  "status": "downloading",
  "song_id": "uuid",
  "download_id": "uuid",
  "message": "Download queued. Check status with GET /api/songs/{song_id}/download-status",
  "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

**Notes**:
- Returns 202 (Accepted) because download is asynchronous
- Poll `/api/songs/{song_id}/download-status` to track progress
- Download happens on Master service, Node syncs after completion

**Errors**:
- `400`: Invalid request
- `401`: Unauthorized
- `502`: Master service unavailable

---

### 4. Check Download Status

**Endpoint**: `GET /api/songs/{song_id}/download-status`

**Authentication**: Optional

**Query Parameters**: None

**Response** (200):
```json
{
  "song_id": "uuid",
  "status": "downloading",
  "progress_percent": 45,
  "duration_seconds": 212,
  "file_size_mb": 150,
  "estimated_time_remaining_seconds": 60,
  "error_message": null,
  "created_at": "2026-04-29T10:30:00Z",
  "started_at": "2026-04-29T10:30:05Z",
  "completed_at": null,
  "file_path": null
}
```

**Status Values**:
- `pending`: Waiting to start
- `downloading`: In progress
- `completed`: Successfully downloaded
- `failed`: Download failed (check error_message)
- `cancelled`: User cancelled

**Errors**:
- `404`: Song not found

---

### 5. List Available Songs

**Endpoint**: `GET /api/songs`

**Authentication**: Optional

**Query Parameters**:
- `limit`: Max results (default 100, max 1000)
- `offset`: Pagination offset (default 0)
- `status`: Filter by status (completed, downloading, failed)
- `search`: Free-text search in title/artist
- `genre`: Filter by genre
- `language`: Filter by language code

**Response** (200):
```json
{
  "songs": [
    {
      "id": "uuid",
      "title": "Never Gonna Give You Up",
      "artist": "Rick Astley",
      "duration": 212,
      "status": "completed",
      "genre": "Pop",
      "language": "en",
      "year": 1987,
      "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "created_at": "2026-04-29T10:30:00Z"
    }
  ],
  "total": 42,
  "limit": 100,
  "offset": 0
}
```

---

## Sessions

### 1. Create Session

**Endpoint**: `POST /api/sessions`

**Authentication**: Bearer token (Admin) or optional

**Request**:
```json
{
  "title": "My Karaoke Party",
  "vibes": "party",
  "max_users": 50,
  "session_code": "ABC123"
}
```

**Response** (201 Created):
```json
{
  "id": "uuid",
  "session_code": "ABC123",
  "title": "My Karaoke Party",
  "vibes": "party",
  "max_users": 50,
  "created_at": "2026-04-29T10:30:00Z",
  "created_by": "admin-uuid"
}
```

**Notes**:
- `session_code`: 6-char unique code, auto-generated if not provided
- `vibes`: Optional, used for song recommendations
- `max_users`: Optional, enforce maximum users per session

**Errors**:
- `400`: Invalid request
- `409`: Session code already exists

---

### 2. Get Session by ID or Code

**Endpoint**: `GET /api/sessions/{session_id_or_code}`

**Authentication**: Optional

**Response** (200):
```json
{
  "id": "uuid",
  "session_code": "ABC123",
  "title": "My Karaoke Party",
  "vibes": "party",
  "max_users": 50,
  "user_count": 5,
  "created_at": "2026-04-29T10:30:00Z"
}
```

**Errors**:
- `404`: Session not found

---

### 3. Add User to Session

**Endpoint**: `POST /api/sessions/{session_id}/users`

**Authentication**: Bearer token (Admin or Controller)

**Request**:
```json
{
  "nickname": "Alice"
}
```

**Response** (201 Created):
```json
{
  "user_id": "uuid",
  "nickname": "Alice",
  "session_id": "uuid",
  "joined_at": "2026-04-29T10:30:00Z",
  "role": "attendee"
}
```

**Errors**:
- `400`: Invalid nickname
- `404`: Session not found
- `409`: User already in session

---

### 4. Remove User from Session

**Endpoint**: `DELETE /api/sessions/{session_id}/users/{user_id}`

**Authentication**: Bearer token (Admin)

**Response** (204 No Content)

**Errors**:
- `404`: Session or user not found

---

## Reservations

### 1. Create Reservation

**Endpoint**: `POST /api/sessions/{session_id}/reservations`

**Authentication**: Bearer token (Admin or Controller)

**Request**:
```json
{
  "song_id": "uuid",
  "user_id": "uuid"
}
```

**Response** (201 Created):
```json
{
  "reservation_id": "uuid",
  "session_id": "uuid",
  "song_id": "uuid",
  "user_id": "uuid",
  "position": 1,
  "status": "pending",
  "reserved_at": "2026-04-29T10:30:00Z",
  "started_at": null,
  "completed_at": null
}
```

**Errors**:
- `400`: Invalid request
- `404`: Song, session, or user not found
- `409`: Song already reserved in this session

---

### 2. List Session Reservations

**Endpoint**: `GET /api/sessions/{session_id}/reservations`

**Authentication**: Optional

**Query Parameters**:
- `status`: Filter by status (pending, playing, completed, cancelled)

**Response** (200):
```json
{
  "session_id": "uuid",
  "reservations": [
    {
      "reservation_id": "uuid",
      "song_id": "uuid",
      "song_title": "Never Gonna Give You Up",
      "song_artist": "Rick Astley",
      "reserved_by": "Alice",
      "position": 1,
      "status": "pending",
      "reserved_at": "2026-04-29T10:30:00Z"
    }
  ],
  "total": 5
}
```

---

### 3. Update Reservation Status

**Endpoint**: `PUT /api/reservations/{reservation_id}/status`

**Authentication**: Bearer token (Admin)

**Request**:
```json
{
  "status": "playing"
}
```

**Response** (200):
```json
{
  "reservation_id": "uuid",
  "status": "playing",
  "started_at": "2026-04-29T10:30:15Z",
  "updated_at": "2026-04-29T10:30:15Z"
}
```

**Valid Transitions**:
- `pending` → `playing` (song starts)
- `pending` → `cancelled` (skip song)
- `playing` → `completed` (song finished)
- `playing` → `cancelled` (abort playback)

**Errors**:
- `400`: Invalid status or invalid transition
- `404`: Reservation not found

---

### 4. Cancel Reservation

**Endpoint**: `DELETE /api/sessions/{session_id}/reservations/{reservation_id}`

**Authentication**: Bearer token (Admin or Controller)

**Response** (204 No Content)

**Side Effects**:
- Reservation marked as cancelled
- Positions of following songs recalculated
- Queue automatically reorganized

**Errors**:
- `404`: Reservation not found

---

### 5. Get Session Queue (For Player)

**Endpoint**: `GET /api/sessions/{session_id}/queue`

**Authentication**: Optional

**Response** (200):
```json
{
  "session_id": "uuid",
  "queue": [
    {
      "position": 1,
      "reservation_id": "uuid",
      "song_id": "uuid",
      "title": "Never Gonna Give You Up",
      "artist": "Rick Astley",
      "reserved_by": "Alice",
      "status": "playing",
      "duration_seconds": 212
    },
    {
      "position": 2,
      "reservation_id": "uuid",
      "song_id": "uuid",
      "title": "Another Song",
      "artist": "Another Artist",
      "reserved_by": "Bob",
      "status": "pending",
      "duration_seconds": 180
    }
  ],
  "current_position": 1,
  "total": 2
}
```

---

## Players

### 1. Register Player

**Endpoint**: `POST /api/auth/player`

**Request**:
```json
{
  "session_id": "ABC123",
  "api_key": "your-valid-api-key"
}
```

**Response** (200):
```json
{
  "access_token": "eyJhbGc...",
  "player_id": "uuid",
  "status": "pending",
  "message": "Player registered. Awaiting admin approval."
}
```

**Notes**:
- Player starts in "pending" status
- Admin must approve before player can access

---

### 2. Activate Player (Admin)

**Endpoint**: `POST /api/auth/player/{player_id}/approve`

**Authentication**: Bearer token (Admin)

**Response** (200):
```json
{
  "player_id": "uuid",
  "status": "active",
  "message": "Player activated"
}
```

---

## Status Codes

### Success Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 200 | OK | Successful GET, PUT, DELETE |
| 201 | Created | Successful POST creating resource |
| 202 | Accepted | Async operation started (downloads) |
| 204 | No Content | Successful DELETE |

### Client Error Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 400 | Bad Request | Invalid parameters, validation failed |
| 401 | Unauthorized | Missing or invalid token |
| 403 | Forbidden | Valid token but no permission |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate resource or constraint violation |
| 422 | Unprocessable Entity | Request body invalid |
| 429 | Too Many Requests | Rate limited (YouTube throttling) |

### Server Error Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 500 | Internal Error | Server error |
| 502 | Bad Gateway | Master service unavailable |
| 504 | Timeout | Request timed out |

---

## Testing Guide

See [MVP_BACKEND_TESTING.md](./MVP_BACKEND_TESTING.md) for complete end-to-end test scenarios.

### Quick Test

```bash
# 1. Health check
curl http://localhost:5002/health

# 2. Admin auth
curl -X POST http://localhost:5002/api/auth/admin \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"singalong123"}'

# 3. Create session
curl -X POST http://localhost:5002/api/sessions \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","max_users":50}'

# 4. Identify song
curl -X POST http://localhost:5002/api/songs/identify \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.youtube.com/watch?v=dQw4w9WgXcQ"}'
```

---

## Error Response Format

All errors follow this format:

```json
{
  "detail": "Error message"
}
```

Or for validation errors:

```json
{
  "detail": [
    {
      "type": "string_too_short",
      "loc": ["body", "title"],
      "msg": "String should have at least 1 character",
      "input": ""
    }
  ]
}
```

---

## Rate Limiting

- Song identification: 10 per minute (YouTube rate limit)
- Song enhancement: No limit
- Downloads: 5 concurrent per Node
- Reservations: No limit

---

## Future API Additions

These are planned but not yet implemented:

- **B10**: Queue reordering, skip, voting
- **B11**: Real-time queue updates via WebSocket
- **B12**: Session settings (playback modes)
- **B13**: Offline availability sync
- **B4**: Song search (YouTube blocking issue)

