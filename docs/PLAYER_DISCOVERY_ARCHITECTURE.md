# Player Discovery & Connection Architecture

This document describes the complete lifecycle of player discovery, connection, reconnection, and disconnection in the Singalong karaoke system.

## State Diagram

```
┌─────────────┐
│   IDLE      │  Player app not connected to any node
└──────┬──────┘
       │ Player discovers node(s) via mDNS/Avahi
       ▼
┌──────────────────┐
│  DISCOVERING     │  Player connects to node's discovery WebSocket
│                  │  - Waits for admin to select
│                  │  - Can disconnect and re-discover
└──────┬───────────┘
       │ Admin clicks "Select Player" in admin UI
       │ Node receives POST /api/sessions/{code}/select-player
       ▼
┌──────────────────┐
│  LOCKED          │  Player locked to session
│                  │  - Node sends lock message to player
│                  │  - Player closes discovery WS
│                  │  - Opens playback/queue connections
│                  │  - Node disables discovery for this player
└──────┬───────────┘
       │ Player successfully transitions to playback
       ▼
┌──────────────────┐
│  PLAYBACK        │  Player in playback/queue mode
│                  │  - Connected via dedicated WS connections
│                  │  - Receiving queue updates
│                  │  - Playing songs
│                  │  - Can disconnect gracefully (admin) or crash
└──────┬───────────┘
       │
       ├─ Admin clicks "Disconnect" (OFFICIAL)
       │  ▼
       │  ┌──────────────────┐
       │  │  DISCONNECTING   │  Admin-initiated disconnect
       │  │                  │  - Node sends disconnect message
       │  │                  │  - Player closes all connections
       │  │                  │  - Player returns to IDLE
       │  │                  │  - Session.player_id cleared
       │  └────────┬─────────┘
       │           ▼
       │  Back to DISCOVERING/IDLE
       │
       └─ Player crashes/closes (UNOFFICIAL)
          ▼
          ┌──────────────────────┐
          │ OFFLINE_BUT_ASSIGNED │  Player disconnected, session still has assignment
          │                      │  - WebSocket died
          │                      │  - Session.player_id still set in DB
          │                      │  - Node waiting for reconnection
          └────────┬─────────────┘
                   │
                   ├─ Player reopens within 60s (RECONNECTION)
                   │  ▼
                   │  ┌──────────────────┐
                   │  │  RECONNECTING    │  Player sends POST /api/players/reconnect
                   │  │                  │  - Validates player_id matches
                   │  │                  │  - Restores WebSocket connections
                   │  │                  │  - Resumes playback
                   │  └────────┬─────────┘
                   │           ▼
                   │  Back to PLAYBACK
                   │
                   └─ 60s timeout elapsed (AUTO-CLEANUP)
                      ▼
                      ┌──────────────────┐
                      │  STALE_TIMEOUT   │  Background job clears assignment
                      │                  │  - Session.player_id → NULL
                      │                  │  - Admin UI shows "No Player"
                      │                  │  - Player can re-discover and re-select
                      └──────────────────┘
```

## Four Key Scenarios

### Scenario 1: Perfect Flow (Happy Path)

**Precondition**: Player app running, node running, admin UI running

**Steps**:
1. **Discovery Phase**
   - Player app starts, searches for nodes via mDNS
   - Player connects to `GET /api/player/ws` (discovery WebSocket)
   - Node: `PlayerDiscoveryManager.register_player(name, platform, ws)` → generates/reuses player_id
   - Admin UI: Shows player in "Available Players" list with player_id
   - Player status: DISCOVERING

2. **Selection Phase**
   - Admin clicks "Select" on player in modal
   - Admin UI: `POST /api/sessions/{code}/select-player` with player_id
   - Node: Validates player exists and status=DISCOVERING
   - Node: `discovery_manager.lock_player(player_id, session_code)` → status=LOCKED
   - Node: Updates `session.player_id`, `session.player_name`, `session.player_platform` in DB
   - Node: Sends lock message to player via discovery WS
   - Player receives lock message → closes discovery WS → opens playback connections
   - Admin UI: Shows player in "Assigned Player" section
   - Player status: LOCKED → PLAYBACK

3. **Playback Phase**
   - Player: Connected to playback/queue WebSockets
   - Queue updates flow: Admin → Node → Player
   - Playback: Player receives song commands
   - Player status: PLAYBACK

4. **Disconnect Phase (Official)**
   - Admin clicks "Disconnect" button
   - Admin UI: `POST /api/sessions/{code}/disconnect-player`
   - Node: Finds player in discovery_manager (or gracefully handles if not found)
   - Node: Sends disconnect message to player (if WebSocket still open)
   - Node: `discovery_manager.unlock_player(player_id)` → status=DISCOVERING
   - Node: Clears `session.player_id`, `session.player_name`, `session.player_platform` from DB
   - Player receives disconnect message → closes all connections → returns to Idle
   - Player can immediately re-discover nodes
   - Admin UI: Shows "Select Player" button again

**Expected Logs**:
```
[DISCOVERY] register | player_id=39d1...58f | new=discovering | name=Pat's MacBook Pro
[DISCOVERY] lock | player_id=39d1...58f | session=3059 | discovering→locked
[DISCOVERY] disconnect_msg_sent | player_id=39d1...58f | session=3059
[DISCOVERY] unlock | player_id=39d1...58f | session=3059 | locked→discovering
```

---

### Scenario 2a: Player Crashes During Playback (Unofficial Disconnect)

**Precondition**: Player is PLAYBACK, connected to node

**What Happens**:
1. Player app crashes or user force-closes it
   - WebSocket connections drop
   - Node detects connection closed
   - Session.player_id STILL SET in DB (source of truth)
   - Player NOT in discovery_manager.players anymore (WS closed)
   - Node status: waiting for reconnection
   - Admin UI: Still shows player as "Assigned" (might add "Offline" badge)

2. **If player reopens within 60 seconds** (Scenario 2b: Reconnection)
   - Player app restarts, sends `POST /api/players/reconnect` with player_id
   - Node: Finds player_id in session assignment (DB), not in memory
   - Node: Re-registers player in discovery_manager with same player_id
   - Node: Returns session code and "continue playback" instruction
   - Player: Opens playback connections again, resumes from where it left off
   - Admin UI: Shows "Connected" again
   - Player status: OFFLINE_BUT_ASSIGNED → RECONNECTING → PLAYBACK

3. **If player never reopens, 60 seconds pass** (Scenario 2c: Timeout Cleanup)
   - Background job runs every 30 seconds
   - Finds session with player_id set but player offline >60s
   - Clears session.player_id from DB
   - Logs: `[DISCOVERY] cleanup_stale | session=3059 | player_id=39d1...58f | offline_duration=65s`
   - Admin UI: Shows "No Player" or "Disconnected (Timeout)"
   - Player (if reopened now): Goes to idle discovery mode, can be re-selected

**Expected Logs**:
```
[DISCOVERY] ws_closed | player_id=39d1...58f | session=3059
[DISCOVERY] waiting_for_reconnection | session=3059 | player_id=39d1...58f
[DISCOVERY] reconnect_attempt | player_id=39d1...58f | name=Pat's MacBook Pro
[DISCOVERY] reconnect_success | player_id=39d1...58f | session=3059 | offline_duration=15s
[DISCOVERY] cleanup_stale | session=3059 | player_id=39d1...58f | offline_duration=65s
```

---

### Scenario 2d: Admin Force-Disconnect While Player is Offline

**Precondition**: Player crashed (Scenario 2a), session.player_id still set, player not in discovery_manager

**Steps**:
1. Admin sees "Assigned Player: Pat's MacBook Pro (Offline)"
2. Admin clicks "Disconnect" button
3. Admin UI: `POST /api/sessions/{code}/disconnect-player`
4. Node endpoint receives request:
   - Gets player_id from session.player_id
   - Calls `discovery_manager.get_player(player_id)` → returns None (player is offline)
   - **Gracefully handles None**: Logs warning but continues
   - Tries to send disconnect message (skipped since player not in memory)
   - Clears session.player_id from DB
   - Returns 200 success (idempotent operation)
5. Admin UI: Shows "No Player" again
6. Later if player reopens:
   - Player sends `POST /api/players/reconnect` with player_id
   - Node checks session assignment → finds None (was cleared)
   - Returns "No active session, enter discovery mode"
   - Player goes to Idle, can be re-discovered and re-selected

**Expected Logs**:
```
[DISCOVERY] disconnect_request | session=3059 | player_id=39d1...58f
[DISCOVERY] player_not_in_memory | player_id=39d1...58f | status=already_offline
[DISCOVERY] disconnect_message_skipped | player_id=39d1...58f
[DISCOVERY] session_cleared | session=3059 | player_id=39d1...58f
```

---

### Scenario 3: Node Crashes/Restarts (Node Reconnection)

**Precondition**: Node and player connected in playback mode, then node crashes

**What Happens**:
1. **Node Crash**:
   - All WebSocket connections die
   - PlayerDiscoveryManager singleton loses all in-memory state
   - Database still has `session.player_id` and `session.player_name`

2. **Node Restart**:
   - Node starts up, FastAPI app initializes
   - Startup code queries DB:
     ```
     SELECT session_code, player_id, player_name 
     FROM sessions 
     WHERE player_id IS NOT NULL AND status='active'
     ```
   - For each session: Create placeholder in discovery_manager marking as "offline_but_assigned"
   - Logs: `[DISCOVERY] node_startup | awaiting_reconnection | session=3059 | player_id=39d1...58f`
   - Admin UI: Player shows as "Offline - Reconnecting..." (waiting for player to reconnect)

3. **Player Detects Node Offline**:
   - Player WebSocket closes
   - Player detects "Node not responding"
   - Player does NOT clear its state immediately
   - Player starts reconnection attempts to node

4. **Player Reconnects to Node**:
   - Player: `POST /api/players/reconnect` with player_id
   - Node: Finds assignment in DB, re-registers in discovery_manager
   - Node: Returns session code and playback state snapshot
   - Player: Resumes playback from snapshot

5. **Success**:
   - Both node and player are back in PLAYBACK state
   - Playback resumes (might skip a few seconds, acceptable)
   - Admin UI: Shows "Connected" again

**Expected Logs**:
```
[DISCOVERY] node_startup | session=3059 | player_id=39d1...58f | status=offline_but_assigned
[DISCOVERY] reconnect_attempt_from_crash | player_id=39d1...58f
[DISCOVERY] node_reconnect_success | player_id=39d1...58f | session=3059 | downtime=12s
```

---

### Scenario 4: Player Switching (Player Crash, Different Player Connects)

**Precondition**: Player A in PLAYBACK, then crashes. Player B (different device) tries to connect

**Steps**:
1. **Player A Crashes**:
   - Session.player_id = "39d1...58f" (still set)
   - Discovery manager: Player A not in memory

2. **Player B Attempts Discovery**:
   - Player B connects to `GET /api/player/ws`
   - Node: Tries to register Player B as new player
   - Player B: Gets new player_id "8f2c...91a"
   - Discovery manager has: {39d1...58f (offline), 8f2c...91a (discovering)}
   - Admin UI: Shows Player B in available list, Player A still in assigned

3. **Admin Sees Problem**:
   - "Assigned: Pat's MacBook Pro (Offline)"
   - "Available: Pat's iPad (iOS)"
   - Admin should first disconnect offline player

4. **Admin Force-Disconnects Player A**:
   - `POST /api/sessions/{code}/disconnect-player`
   - Node: Player A not in memory (gracefully handled)
   - Session.player_id → NULL

5. **Admin Selects Player B**:
   - `POST /api/sessions/{code}/select-player` with player_id=8f2c...91a
   - Node: Finds Player B in discovery, locks to session
   - Session.player_id = "8f2c...91a", player_platform="ipados"
   - Admin UI: Shows "Pat's iPad (iOS)" as assigned player
   - Playback continues with Player B

**Expected Logs**:
```
[DISCOVERY] register | player_id=8f2c...91a | new=discovering | name=Pat's iPad
[DISCOVERY] lock | player_id=8f2c...91a | session=3059 | discovering→locked
[DISCOVERY] disconnect_msg_skipped | player_id=39d1...58f | status=offline
[DISCOVERY] session_cleared | session=3059 | old_player_id=39d1...58f
```

---

## Implementation Details

### Player ID Management

**Generation**:
```python
# In player discovery manager
async def register_player(name, platform, websocket, player_id=None):
    if player_id and player_id in self.players:
        # Reconnection: reuse existing player_id
        player = self.players[player_id]
        player.ws_connection = websocket  # Update connection
        player.status = "discovering"
        return player
    
    if player_id is None:
        # New player: generate UUID
        player_id = str(uuid.uuid4())
    
    # Create new player entry
    player = PlayerInfo(player_id=player_id, name=name, platform=platform, ws_connection=websocket)
    self.players[player_id] = player
    return player
```

### Reconnection Endpoint

**Endpoint**: `POST /api/players/reconnect`

**Request**:
```json
{
  "player_id": "39d16667-b28d-4c27-ac30-ed750e73158f",
  "name": "Pat's MacBook Pro",
  "platform": "macos"
}
```

**Response** (200 OK):
```json
{
  "status": "reconnected",
  "session_code": "3059",
  "player_platform": "macos",
  "message": "Welcome back to session 3059"
}
```

Or (if not assigned):
```json
{
  "status": "not_assigned",
  "message": "No active session. Please wait for admin selection."
}
```

**Logic**:
```python
@router.post("/reconnect", status_code=200)
async def reconnect_player(request: PlayerReconnectRequest):
    # Find or re-register player
    discovery_manager = PlayerDiscoveryManager.get_instance()
    player = discovery_manager.register_player(
        name=request.name,
        platform=request.platform,
        websocket=<new_ws>,
        player_id=request.player_id  # <-- allows reconnection
    )
    
    # Check if still assigned to a session
    session = db.query(Session).filter(Session.player_id == player.player_id).first()
    
    if session:
        return {
            "status": "reconnected",
            "session_code": session.code,
            "message": f"Welcome back to session {session.code}"
        }
    else:
        return {
            "status": "not_assigned",
            "message": "No active session, enter discovery mode"
        }
```

### Cleanup Job

**Runs**: Every 30 seconds via background task

**Logic**:
```python
async def cleanup_stale_assignments():
    """Find and clear player assignments older than 60 seconds"""
    now = datetime.now(timezone.utc)
    threshold = now - timedelta(seconds=60)
    
    # Find sessions with player offline too long
    stale_sessions = db.query(Session).filter(
        Session.player_id.isnot(None),
        Session.player_last_seen < threshold
    ).all()
    
    for session in stale_sessions:
        player_id = session.player_id
        session.player_id = None
        session.player_name = None
        session.player_platform = None
        db.commit()
        logger.info(f"[DISCOVERY] cleanup_stale | session={session.code} | player_id={player_id}")
```

### Graceful Disconnect

**Key Change**: Don't fail if player not in memory

```python
@router.post("/{session_code}/disconnect-player")
async def disconnect_player(session_code: str, db: SQLSession = Depends(get_db), ...):
    session = _validate_session_exists(session_code, db)
    
    if not session.player_id:
        raise HTTPException(status_code=409, detail="No player assigned")
    
    player_id = session.player_id
    discovery_manager = PlayerDiscoveryManager.get_instance()
    player = discovery_manager.get_player(player_id)  # May return None
    
    # Send disconnect message if player is in memory (graceful if not)
    if player and player.ws_connection:
        try:
            await player.ws_connection.send_json({"type": "disconnect", "reason": "admin_requested"})
        except Exception as e:
            logger.warning(f"[DISCOVERY] disconnect_msg_failed | player_id={player_id} | error={e}")
    else:
        logger.warning(f"[DISCOVERY] player_not_in_memory | player_id={player_id} | status=offline")
    
    # Unlock if in memory
    if player:
        discovery_manager.unlock_player(player_id)
    
    # ALWAYS clear from session (DB is source of truth)
    session.player_id = None
    session.player_name = None
    session.player_platform = None
    db.commit()
    
    return {"success": True, "message": "Player disconnected"}  # <-- Always succeeds
```

### Node Startup Logic

**In app startup** (main.py):
```python
async def startup_event():
    # ... other startup code ...
    
    # Restore player assignments from DB
    db = SessionLocal()
    active_sessions = db.query(Session).filter(
        Session.player_id.isnot(None),
        Session.status == "active"
    ).all()
    
    discovery_manager = PlayerDiscoveryManager.get_instance()
    for session in active_sessions:
        # Create placeholder for offline but assigned player
        logger.info(f"[DISCOVERY] node_startup | session={session.code} | "
                   f"player_id={session.player_id} | awaiting_reconnection")
    
    # Don't clear assignments - wait for player reconnection
    db.close()
    
    # Start cleanup job
    asyncio.create_task(cleanup_job())
```

---

## Logging Conventions

All discovery-related logs follow this format:

```
[DISCOVERY] <action> | <key_fields> | <details>
```

**Standard fields**:
- `action`: register, lock, unlock, disconnect_sent, disconnect_failed, reconnect, cleanup, etc.
- `player_id`: 8-char truncated UUID (e.g., 39d16667...158f)
- `session`: session code
- `old→new`: state transition (discovering→locked)
- `duration`: time elapsed (for timeouts, offline duration)

**Examples**:
```
[DISCOVERY] register | player_id=39d1...58f | name=Pat's MacBook | platform=macos | status=discovering
[DISCOVERY] lock | player_id=39d1...58f | session=3059 | discovering→locked
[DISCOVERY] disconnect_sent | player_id=39d1...58f | session=3059
[DISCOVERY] unlock | player_id=39d1...58f | session=3059 | locked→discovering
[DISCOVERY] reconnect | player_id=39d1...58f | offline_duration=45s
[DISCOVERY] cleanup_stale | session=3059 | player_id=39d1...58f | offline_duration=65s | clearing_assignment
```

---

## WebSocket Message Format

### Discovery Phase

**Player → Node** (registration):
```json
{
  "type": "register",
  "player_id": "39d16667-b28d-4c27-ac30-ed750e73158f",  // Optional for reconnection
  "name": "Pat's MacBook Pro",
  "platform": "macos"
}
```

**Node → Player** (lock):
```json
{
  "type": "lock",
  "session_code": "3059",
  "token": "auth-token-for-playback"
}
```

**Node → Player** (disconnect):
```json
{
  "type": "disconnect",
  "reason": "admin_requested|timeout|node_shutdown"
}
```

---

## Timeout Behaviors

| Scenario | Timeout | Action |
|----------|---------|--------|
| Player offline during playback | 60 seconds | Cleanup job clears assignment |
| Player in discovery, idle | Infinite | Player can disconnect/reconnect any time |
| Node waiting for reconnection | 60 seconds | Same as offline—cleanup clears it |
| Admin force disconnect | Immediate | Always succeeds (graceful if player offline) |

---

## Error Cases & Recovery

| Error | Cause | Recovery |
|-------|-------|----------|
| Player not found on disconnect | Player already offline | Gracefully clear assignment (no 500 error) |
| WebSocket send fails | Connection dead | Log warning, continue with cleanup |
| Multiple players same name | Different devices, same name | Show player_id to distinguish |
| Player reconnects with wrong ID | User error or bug | Treat as new player, old session orphaned |
| Node restart while player offline | Player was already offline | Preserved assignment in DB, wait for reconnection |

---

## Future Enhancements

1. **Persistent Player Store**: Move from in-memory to database
   - Track player connection history
   - Store preferred node for faster reconnection
   - Analytics on player uptime/disconnections

2. **Explicit State Machine**: Use enum instead of string states
   - Type-safe state transitions
   - Prevent invalid state combinations

3. **Player Health Metrics**: 
   - Heartbeat messages every 30 seconds
   - Detect stale connections earlier
   - Track reconnection success rate

4. **Graceful Degradation**:
   - If player offline, cache queue locally
   - Resume playback without admin re-selection
   - Show "buffering" instead of "disconnected"

5. **WebSocket Keepalive**:
   - Ping/pong every 30 seconds
   - Auto-cleanup truly dead connections
   - Reduce false "offline" detections
