# WebSocket Events Documentation

**Note**: WebSocket endpoints are **not** covered by Swagger/OpenAPI (OpenAPI v3.1 only recently added basic WebSocket support). This document serves as the comprehensive reference for all WebSocket events in Singalong.

---

## Architecture Overview

```
┌─────────────────┐                          ┌──────────────────┐
│ singalong-node  │                          │ singalong-master │
│   (Client)      │ ◄──── WebSocket ────► │  (Server)        │
│                 │   /ws (JSON events)   │                  │
└─────────────────┘                          └──────────────────┘
        │
        │ (Future - W2.4)
        │ /ws/{sessionId} (local clients)
        │
        ▼
┌──────────────────────────────────┐
│  Frontend Clients                │
├──────────────────────────────────┤
│ • singalong-admin                │ (Admin UI)
│ • singalong-controller           │ (User UI)
└──────────────────────────────────┘
```

**Current Status**:
- ✅ Master → Node WebSocket (W2.1-W2.3 complete)
- ⏳ Node → Frontends WebSocket (W2.4 pending)

---

## 1. Master WebSocket Server

**Endpoint**: `ws://singalong-master:5001/ws` (or secure `wss://` in production)

**Purpose**: Broadcast real-time events to connected Nodes

### Authentication

Node must authenticate before connecting:

```python
# 1. Exchange API key for JWT token
POST /api/auth/exchange
{
  "api_key": "test-node-api-key"
}

# Response:
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 3600
}

# 2. Connect WebSocket with token
WebSocket: ws://singalong-master:5001/ws?token={access_token}
```

**Token Format**: JWT with payload:
```json
{
  "sub": "singalong-node",
  "service_name": "singalong-node",
  "iat": 1234567890,
  "exp": 1234571490,
  "token_type": "access"
}
```

**Secret**: `master-secret-key` (defined in Master `.env`)

**Validation**: 
- Token must be valid (not expired)
- Token must have `token_type: "access"`
- Service can be any value (not validated for MVP)

### Connection States

```
┌─────────────────────────────────────────────────────────────┐
│                   WebSocket Lifecycle                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Node calls POST /api/auth/exchange                      │
│     ├─ Success: Get access_token                            │
│     └─ Failure: Return 401 Unauthorized                     │
│                                                              │
│  2. Node connects: ws://master:5001/ws?token={token}        │
│     ├─ Token valid: Accept, enter listen loop               │
│     └─ Token invalid: Reject, close with code 1008          │
│                                                              │
│  3. Listen for events (while connected)                     │
│     ├─ Receive JSON: { "type": "...", "data": {...} }       │
│     └─ Dispatch to registered handlers                      │
│                                                              │
│  4. Disconnect                                              │
│     ├─ Network error: Reconnect with exponential backoff    │
│     └─ Server close: Close connection gracefully            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Events Broadcast by Master

Master broadcasts events to all connected Nodes in real-time.

### Event Format

All events follow this structure:

```json
{
  "type": "event:name",
  "data": {
    "field1": "value1",
    "field2": "value2"
  }
}
```

### Event Types

#### 2.1 `download:progress`

**Purpose**: Stream download progress updates during video download

**Broadcast When**: yt-dlp reports progress while downloading

**Data Payload**:
```json
{
  "type": "download:progress",
  "data": {
    "video_id": "abc123xyz",
    "status": "downloading",
    "progress_percent": 35,
    "downloaded_bytes": 10485760,
    "total_bytes": 29360128,
    "speed_mbps": 2.5,
    "eta_seconds": 6240
  }
}
```

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `video_id` | string | YouTube video ID |
| `status` | string | Current status: `downloading`, `completed`, `failed` |
| `progress_percent` | int | 0-100 completion percentage |
| `downloaded_bytes` | int | Bytes downloaded so far |
| `total_bytes` | int | Total file size in bytes |
| `speed_mbps` | float | Download speed in MB/s (2 decimal places) |
| `eta_seconds` | int | Estimated seconds remaining (or -1 if unknown) |

**Node Handling**:
- Log progress to console/dashboards
- Update UI with progress bar (future)
- Store in memory cache for admin dashboard (future)
- **Do NOT trigger sync** - that happens on completion

**Frequency**: Every progress update from yt-dlp (~1-2 per second)

---

#### 2.2 `download:complete`

**Purpose**: Notify that a video download finished successfully on Master

**Broadcast When**: yt-dlp finishes downloading, file saved to disk

**Data Payload**:
```json
{
  "type": "download:complete",
  "data": {
    "video_id": "abc123xyz",
    "title": "Wonderful Rush",
    "artist": "μ's",
    "duration": 312,
    "filesize_mb": 28.5
  }
}
```

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `video_id` | string | YouTube video ID |
| `title` | string | Song title (may be raw, not enhanced) |
| `artist` | string | Artist name (may be raw, not enhanced) |
| `duration` | int | Song duration in seconds |
| `filesize_mb` | float | Downloaded file size in MB (optional) |

**Node Handling** (W2.3):
1. Log completion: `[DOWNLOAD COMPLETE] video_id={id} | {artist} - {title}`
2. **Trigger auto-sync**: Spawn background thread
3. Call `NodeSyncService.sync_songs_from_master()`
4. Download video file to Node's local cache
5. Update Node's database with song metadata
6. Log progress: `[SYNC PROGRESS] X% (N/TOTAL) | Title`
7. On completion: `[SYNC COMPLETE] | synced=X updated=X failed=X`

**Critical**: This is the event that triggers W2.3 auto-sync!

---

#### 2.3 `catalog:updated`

**Purpose**: Notify that Master's song catalog was updated (new videos indexed)

**Broadcast When**: Admin adds songs, database sync completes, etc.

**Data Payload**:
```json
{
  "type": "catalog:updated",
  "data": {
    "new_count": 5,
    "updated_count": 2,
    "total_count": 342,
    "timestamp": "2026-05-01T06:47:16Z"
  }
}
```

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `new_count` | int | Number of new songs |
| `updated_count` | int | Number of updated songs |
| `total_count` | int | Total songs in Master catalog |
| `timestamp` | string | ISO 8601 timestamp |

**Node Handling** (Future):
- May trigger full catalog sync
- Update local cache if needed
- Currently not implemented (deferred to future phase)

---

#### 2.4 `system:health`

**Purpose**: Periodic heartbeat to keep connection alive and verify Master health

**Broadcast When**: Configurable interval (currently not implemented, reserved for future)

**Data Payload**:
```json
{
  "type": "system:health",
  "data": {
    "status": "healthy",
    "uptime_seconds": 3600,
    "active_nodes": 1,
    "connected_at": "2026-05-01T06:00:00Z"
  }
}
```

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `status` | string | `healthy`, `degraded`, `error` |
| `uptime_seconds` | int | Master uptime in seconds |
| `active_nodes` | int | Number of connected Nodes |
| `connected_at` | string | ISO 8601 timestamp of connection |

**Node Handling**:
- Acknowledge receipt (keep alive)
- Currently not implemented (no handler registered)

---

## 3. Node WebSocket Client

**Implementation**: `apps/singalong-node/app/services/master_websocket_client.py`

**Class**: `MasterWebSocketClient`

### Client Lifecycle

```python
# 1. Get global singleton instance
from app.services.master_websocket_client import get_master_websocket_client

client = get_master_websocket_client()

# 2. Register event handlers
from app.services.master_event_handlers import MasterEventHandlers

client.register_handler("download:progress", MasterEventHandlers.handle_download_progress)
client.register_handler("download:complete", MasterEventHandlers.handle_download_complete)
client.register_handler("catalog:updated", MasterEventHandlers.handle_catalog_updated)

# 3. Connect and listen (background task)
asyncio.create_task(client.connect_and_listen())

# 4. Later: disconnect gracefully
await client.disconnect()
```

### Registered Handlers

Handlers are registered in `app/main.py` lifespan context:

```python
async def lifespan(app: FastAPI):
    # Startup
    ws_client = get_master_websocket_client()
    
    ws_client.register_handler("download:progress", MasterEventHandlers.handle_download_progress)
    ws_client.register_handler("download:complete", MasterEventHandlers.handle_download_complete)
    ws_client.register_handler("catalog:updated", MasterEventHandlers.handle_catalog_updated)
    
    ws_listen_task = asyncio.create_task(ws_client.listen())
    
    yield
    
    # Shutdown
    await ws_client.disconnect()
    ws_listen_task.cancel()
```

### Reconnection Logic

Node automatically reconnects on disconnect with exponential backoff:

```
Connection lost
    ↓
Wait 1 second
    ↓
Try connect
    ├─ Success: Reset delay to 1 second, resume listening
    └─ Failure: Wait 2 seconds, try again
                    ↓
                Try connect
                    ├─ Success: Reset delay to 1 second
                    └─ Failure: Wait 4 seconds, try again
                                    ↓
                                [continues until max 30 seconds]
```

**Code**:
```python
self.reconnect_delay = 1  # Start at 1 second
self.max_reconnect_delay = 30  # Cap at 30 seconds

# On reconnect failure:
self.reconnect_delay = min(self.reconnect_delay * 2, self.max_reconnect_delay)
```

---

## 4. Event Handlers

**Implementation**: `apps/singalong-node/app/services/master_event_handlers.py`

**Class**: `MasterEventHandlers` (static methods)

### Handler: `handle_download_progress`

```python
@staticmethod
async def handle_download_progress(data: dict[str, Any]) -> None:
    """Handle download progress event from Master."""
    video_id = data.get("video_id", "unknown")
    progress = data.get("progress_percent", 0)
    speed = data.get("speed_mbps", 0)
    eta = data.get("eta_seconds", 0)
    
    # Format ETA
    if eta > 0:
        minutes = eta // 60
        seconds = eta % 60
        eta_str = f"{minutes:02d}:{seconds:02d}"
    else:
        eta_str = "N/A"
    
    # Log structured progress
    logger.info(
        f"[DOWNLOAD PROGRESS] video_id={video_id} | {progress}% | "
        f"{speed:.2f}MB/s | ETA {eta_str}"
    )
```

**Example Output**:
```
2026-05-01 06:47:10,123 - app.services.master_event_handlers - INFO - [DOWNLOAD PROGRESS] video_id=abc123 | 0% | 0.00MB/s | ETA N/A
2026-05-01 06:47:12,456 - app.services.master_event_handlers - INFO - [DOWNLOAD PROGRESS] video_id=abc123 | 25% | 2.45MB/s | ETA 00:05
2026-05-01 06:47:14,789 - app.services.master_event_handlers - INFO - [DOWNLOAD PROGRESS] video_id=abc123 | 50% | 2.50MB/s | ETA 00:04
2026-05-01 06:47:17,012 - app.services.master_event_handlers - INFO - [DOWNLOAD PROGRESS] video_id=abc123 | 100% | 0.00MB/s | ETA N/A
```

---

### Handler: `handle_download_complete`

```python
@staticmethod
async def handle_download_complete(data: dict[str, Any]) -> None:
    """Handle download completion event from Master."""
    video_id = data.get("video_id", "unknown")
    title = data.get("title", "Unknown")
    artist = data.get("artist", "Unknown")
    
    logger.info(f"[DOWNLOAD COMPLETE] video_id={video_id} | {artist} - {title}")
    
    # Spawn background thread to sync video
    logger.info(f"[AUTO-SYNC] Syncing newly downloaded video: {video_id}")
    
    thread = threading.Thread(
        target=MasterEventHandlers._sync_video_in_background,
        args=(video_id,),
        daemon=True
    )
    thread.start()
```

**Example Output**:
```
2026-05-01 06:47:16,618 - app.services.master_event_handlers - INFO - [DOWNLOAD COMPLETE] video_id=y8o7Wk6_Xm8 | μ's - Wonderful Rush
2026-05-01 06:47:16,618 - app.services.master_event_handlers - INFO - [AUTO-SYNC] Syncing newly downloaded video: y8o7Wk6_Xm8
2026-05-01 06:47:16,627 - app.services.master_event_handlers - INFO - [AUTO-SYNC] Starting sync for video: y8o7Wk6_Xm8
2026-05-01 06:47:16,700 - app.services.node_sync_service - INFO - [SYNC PROGRESS] 25.0% (1/4) | First Song
2026-05-01 06:47:16,750 - app.services.node_sync_service - INFO - [SYNC PROGRESS] 50.0% (2/4) | Second Song
2026-05-01 06:47:16,800 - app.services.node_sync_service - INFO - [SYNC COMPLETE] 100% | 2 new, 0 updated, 0 failed
```

---

### Handler: `handle_catalog_updated`

```python
@staticmethod
async def handle_catalog_updated(data: dict[str, Any]) -> None:
    """Handle catalog update event from Master."""
    try:
        logger.info(f"[CATALOG UPDATED] Master has new videos")
        # TODO: Trigger sync to fetch updated catalog
    except Exception as e:
        logger.error(f"Error handling catalog update: {e}")
```

**Status**: Implemented but deferred (no sync triggered yet)

---

## 5. Future: Node WebSocket Server (W2.4)

**Planned Endpoint**: `ws://singalong-node:5002/ws/{sessionId}`

**Purpose**: Broadcast real-time session events to connected frontend clients (Admin UI, Controller UI)

### Planned Events (W2.4)

```json
{
  "type": "session:ready",
  "data": {
    "session_id": "sess-abc123",
    "admin_name": "Admin Name"
  }
}
```

```json
{
  "type": "attendee:joined",
  "data": {
    "user_id": "user-xyz",
    "nickname": "John"
  }
}
```

```json
{
  "type": "song:queued",
  "data": {
    "reservation_id": "res-123",
    "song_id": "song-456",
    "title": "Song Name",
    "queued_by": "user-xyz",
    "position": 3
  }
}
```

```json
{
  "type": "song:playing",
  "data": {
    "song_id": "song-456",
    "title": "Song Name",
    "elapsed_seconds": 15,
    "duration_seconds": 300
  }
}
```

```json
{
  "type": "download:progress",
  "data": {
    "video_id": "abc123",
    "progress_percent": 75
  }
}
```

**Status**: Not yet implemented (W2.4 phase)

---

## 6. Testing WebSocket Connections

### Test Master WebSocket

```bash
# 1. Get auth token
TOKEN=$(curl -s -X POST http://localhost:5001/api/auth/exchange \
  -H "Content-Type: application/json" \
  -d '{"api_key":"test-node-api-key"}' | jq -r '.access_token')

# 2. Connect to WebSocket (requires websocat or similar)
websocat "ws://localhost:5001/ws?token=$TOKEN"

# Connection should succeed and wait for events
# (will receive events when Master broadcasts them)
```

### Test Node WebSocket Client (in code)

```python
# Check that Node is connected
import asyncio
from app.services.master_websocket_client import get_master_websocket_client

client = get_master_websocket_client()
print(f"Connected: {client.is_connected}")
print(f"Access token: {client.access_token is not None}")
```

### Trigger a Test Download

```bash
# Master-side (simulate download to test WebSocket broadcast)
curl -X POST http://localhost:5001/graphql/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "query": "mutation { downloadVideo(...) { ... } }"
  }'

# Watch Node logs for:
# [DOWNLOAD PROGRESS] video_id=... | X% | ...
# [DOWNLOAD COMPLETE] video_id=... | Artist - Title
# [AUTO-SYNC] Starting sync for video: ...
# [SYNC PROGRESS] X% (N/TOTAL) | Title
# [SYNC COMPLETE] 100% | counts
```

---

## 7. Debugging WebSocket Issues

### Node not connecting to Master

**Symptom**: Node logs show "✗ WebSocket connection failed"

**Possible Causes**:
1. Master not running on the network
2. Incorrect `MASTER_URL` environment variable
3. API key or JWT token invalid
4. Firewall blocking port 5001

**Debugging**:
```bash
# Check Master is running
curl http://master:5001/health

# Check Node can reach Master
docker exec singalong-node curl http://master:5001/health

# Check Node's MASTER_URL
docker exec singalong-node printenv MASTER_URL

# Check Node logs
docker-compose logs node | grep -i websocket
```

---

### No events received

**Symptom**: Node connects but no `[DOWNLOAD PROGRESS]` logs appear during Master download

**Possible Causes**:
1. Download not happening (check Master logs)
2. Event handler not registered (check main.py lifespan)
3. JSON parsing error in event handler

**Debugging**:
```bash
# Check Node event handler registration
docker exec singalong-node grep -r "register_handler" app/

# Check Master is broadcasting
docker-compose logs master | grep broadcast

# Enable debug logging in Node
docker exec singalong-node python3 -c "
import logging
logging.basicConfig(level=logging.DEBUG)
"
```

---

## 8. Summary Table

| Component | Endpoint | Direction | Events | Status |
|-----------|----------|-----------|--------|--------|
| Master WebSocket Server | `ws://master:5001/ws` | Server (broadcast) | `download:progress`, `download:complete`, `catalog:updated`, `system:health` | ✅ Complete (W2.1) |
| Node WebSocket Client | Connects to Master | Client (listen) | All of above | ✅ Complete (W2.1-W2.3) |
| Node Event Handlers | Internal | Internal | Process events, trigger sync | ✅ Complete (W2.3) |
| Node WebSocket Server | `ws://node:5002/ws/{sessionId}` | Server (broadcast) | `session:*`, `attendee:*`, `song:*`, `download:*` | ⏳ Planned (W2.4) |
| Frontend WebSocket Clients | Connect to Node | Client (listen) | Session/attendee/song/download updates | ⏳ Planned (W2.4) |

---

## 9. References

- **Master Implementation**: `apps/singalong-master/app/api/routes/websocket.py`
- **Master Event Broadcasting**: `apps/singalong-master/app/websocket/manager.py`
- **Node Client**: `apps/singalong-node/app/services/master_websocket_client.py`
- **Node Event Handlers**: `apps/singalong-node/app/services/master_event_handlers.py`
- **Node Initialization**: `apps/singalong-node/app/main.py` (lifespan context)

---

**Document Version**: 1.0  
**Created**: 2026-05-01  
**Status**: Active (W2.1-W2.3 complete, W2.4 planned)
