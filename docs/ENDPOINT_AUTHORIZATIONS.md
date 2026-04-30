# Endpoint Authorization Matrix

This document defines which roles have access to which endpoints in the Singalong Node API.

## Role Definitions

- **Admin** - Administrative user with full system access (session management, all song operations)
- **Controller** - User-facing interface for song selection and reservations
- **Player** - Player device interface for playback and status tracking

---

## Authentication Endpoints

All endpoints require Bearer token authentication except `/health` and `/api/auth/*` login endpoints.

| Endpoint | Method | Admin | Controller | Player | Description |
|----------|--------|-------|------------|--------|-------------|
| `/health` | GET | ✅ | ✅ | ✅ | Health check (no auth required) |
| `/api/auth/player` | POST | ❌ | ❌ | ✅ | Authenticate as player |
| `/api/auth/admin` | POST | ✅ | ❌ | ❌ | Authenticate as admin |
| `/api/auth/controller` | POST | ❌ | ✅ | ❌ | Authenticate as controller |
| `/api/auth/refresh` | POST | ✅ | ✅ | ✅ | Refresh expired token |

---

## Song Management Endpoints

All song endpoints are accessible to **all authenticated roles** (Admin, Controller, Player).

### Song Discovery & Search

| Endpoint | Method | Admin | Controller | Player | Description |
|----------|--------|-------|------------|--------|-------------|
| `/api/songs/songbook` | GET | ✅ | ✅ | ❌ | List available songs (synced from master) |
| `/api/songs` | GET | ✅ | ✅ | ❌ | List songs with filters & search |
| `/api/songs/{song_id}` | GET | ✅ | ✅ | ❌ | Get song details by ID |
| `/api/songs/{song_id}/status` | GET | ✅ | ✅ | ❌ | Check song metadata/status |

### Song Identification & Enhancement

| Endpoint | Method | Admin | Controller | Player | Description |
|----------|--------|-------|------------|--------|-------------|
| `/api/songs/identify` | POST | ✅ | ✅ | ❌ | Identify song from YouTube URL using yt-dlp |
| `/api/songs/enhance` | POST | ✅ | ✅ | ❌ | Enhance/correct song metadata (AI-assisted) |

### Song Download Management

| Endpoint | Method | Admin | Controller | Player | Description |
|----------|--------|-------|------------|--------|-------------|
| `/api/songs/download` | POST | ✅ | ✅ | ❌ | Download song from YouTube (creates download queue entry) |
| `/api/songs/{song_id}/download-status` | GET | ✅ | ✅ | ❌ | Check download progress for a song |
| `/api/songs/downloads` | GET | ✅ | ✅ | ❌ | List all active downloads with status |
| `/api/songs/downloads/{download_id}/retry` | POST | ✅ | ✅ | ❌ | Retry failed download |
| `/api/songs/downloads/{download_id}` | DELETE | ✅ | ✅ | ❌ | Cancel/remove download |
| `/api/songs/downloads/cleanup` | POST | ✅ | ✅ | ❌ | Clean up old failed downloads |
| `/api/songs/downloads/clear-pending` | POST | ✅ | ✅ | ❌ | Clear all pending/in-progress downloads |

### Song Streaming & Sync

| Endpoint | Method | Admin | Controller | Player | Description |
|----------|--------|-------|------------|--------|-------------|
| `/api/songs/video/{video_id}` | GET | ✅ | ✅ | ✅ | Stream/download video file |
| `/api/songs/sync` | POST | ✅ | ✅ | ✅ | Sync song catalog from Master |

---

## Session Management Endpoints

**⚠️ ADMIN ONLY**: All session endpoints are restricted to users with `admin` role.

### Session CRUD Operations

| Endpoint | Method | Admin | Controller | Player | Description |
|----------|--------|-------|------------|--------|-------------|
| `/api/sessions` | GET | ✅ | ❌ | ❌ | List all sessions (paginated) |
| `/api/sessions` | POST | ✅ | ❌ | ❌ | Create new session |
| `/api/sessions/{session_id}` | GET | ✅ | ❌ | ❌ | Get session details |
| `/api/sessions/{session_id}` | PUT | ✅ | ❌ | ❌ | Update session (title, vibes, status) |
| `/api/sessions/{session_id}` | DELETE | ✅ | ❌ | ❌ | End/archive session |

### Session Attendee Management

| Endpoint | Method | Admin | Controller | Player | Description |
|----------|--------|-------|------------|--------|-------------|
| `/api/sessions/{session_id}/attendees` | GET | ✅ | ❌ | ❌ | List users in session |

### Session Queue & Reservations

| Endpoint | Method | Admin | Controller | Player | Description |
|----------|--------|-------|------------|--------|-------------|
| `/api/sessions/{session_id}/queue` | GET | ✅ | ✅ | ❌ | Get song queue/reservations for session |
| `/api/sessions/{session_id}/queue` | POST | ✅ | ✅ | ❌ | Add song to queue (reserve) |
| `/api/sessions/{session_id}/queue/{queue_id}` | DELETE | ✅ | ❌ | ❌ | Remove song from queue |
| `/api/sessions/{session_id}/queue/{queue_id}/change-order` | PATCH | ✅ | ❌ | ❌ | Reorder song in queue |

### Session Playback Control

| Endpoint | Method | Admin | Controller | Player | Description |
|----------|--------|-------|------------|--------|-------------|
| `/api/sessions/{session_id}/playback` | GET | ✅ | ❌ | ✅ | Get current playback status |

---

## Player Management Endpoints

Player-related endpoints for tracking which devices are playing songs.

| Endpoint | Method | Admin | Controller | Player | Description |
|----------|--------|-------|------------|--------|-------------|
| `/api/players/register` | POST | ❌ | ❌ | ✅ | Register new player device |
| `/api/players/admin/list` | GET | ✅ | ❌ | ❌ | List all registered players (admin only) |
| `/api/players/admin/{player_id}/activate` | POST | ✅ | ❌ | ❌ | Activate/deactivate player (admin only) |
| `/api/players/{player_id}/status` | GET | ✅ | ❌ | ❌ | Get player status |
| `/api/players/{player_id}/queue` | GET | ✅ | ❌ | ❌ | Get player's queue |
| `/api/players/{player_id}/now-playing/{song_id}` | POST | ✅ | ❌ | ❌ | Mark song as now playing |
| `/api/players/{player_id}/completed/{song_id}` | POST | ✅ | ❌ | ❌ | Mark song as completed |

---

## Summary Table by Role

### Admin
✅ Can access:
- All `/api/songs/*` endpoints
- All `/api/sessions/*` endpoints
- All `/api/players/*` endpoints
- Endpoint-specific admin operations

### Controller
✅ Can access:
- All `/api/songs/*` endpoints
- All `/api/players/*` endpoints (except admin-specific endpoints)
- ❌ Cannot access `/api/sessions/*` endpoints

### Player
✅ Can access:
- All `/api/songs/*` endpoints
- `/api/players/register` (to register as a player)
- Player status and queue endpoints
- ❌ Cannot access `/api/sessions/*` endpoints
- ❌ Cannot access admin-specific player endpoints

---

## Authentication Requirements

### Public Endpoints (No Authentication Required)
- `GET /health`
- `POST /api/auth/player` - Authenticate as player
- `POST /api/auth/admin` - Authenticate as admin
- `POST /api/auth/controller` - Authenticate as controller

### Protected Endpoints (Bearer Token Required)
- All other endpoints require valid JWT Bearer token in `Authorization` header
- Token must have valid signature and not be expired
- Token must contain `role` claim (admin, controller, or player)

**Header Example:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Error Responses:**
- `401 Unauthorized` - Missing or invalid token
- `403 Forbidden` - Token valid but insufficient permissions (role check failed)

---

## Configuration Notes

- Token validation happens at middleware layer (`app/middleware/auth.py`)
- Role-based access control enforced via `verify_admin_role()` dependency for admin endpoints
- All authenticated endpoints check Bearer token via `verify_bearer_token()` dependency
- Session endpoints use `verify_admin_role()` for exclusive admin access
- Song endpoints accessible to all authenticated roles