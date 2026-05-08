"""WebSocket endpoints for session client connections"""

import logging
import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status

from app.middleware.auth import get_auth_service

logger = logging.getLogger(__name__)

router = APIRouter(tags=["WebSocket"])


@router.websocket("/ws/session/{session_id}")
async def websocket_session_endpoint(session_id: str, websocket: WebSocket):
    """
    WebSocket endpoint for session updates

    Clients (Admin UI, Controller UI) connect here to receive real-time events:
    - song:playing - When a song starts
    - player:position - Current playback position (every 2-5s)
    - queue:updated - When the queue changes
    - download:progress - Download progress (admin-only)
    - attendee:list - Connected attendees (admin-only)

    **Authentication**:
    JWT token must be provided in the Authorization header during WebSocket handshake.

    **Header Format**:
    ```
    Authorization: Bearer <access_token>
    ```

    **Example (using curl with websocat)**:
    ```bash
    TOKEN=$(curl -s -X POST http://localhost:5002/api/auth/controller \\
      -H "Content-Type: application/json" \\
      -d '{"nickname":"Test","session_id":"1234"}' | jq -r '.access_token')

    websocat -H "Authorization: Bearer $TOKEN" "ws://localhost:5002/ws/session/1234"
    ```

    **Example (JavaScript/TypeScript)**:
    Note: Browser WebSocket API doesn't support custom headers in constructor.
    Options:
    1. Send token in first message after connect (recommended for browser)
    2. Use a proxy that supports header forwarding
    3. Use library like Socket.IO with header support

    ```typescript
    const sessionId = "1234";
    const token = await getAccessToken(); // from /api/auth/controller

    // Connect without token initially
    const ws = new WebSocket(`ws://localhost:5002/ws/${sessionId}`);

    ws.onopen = () => {
      // Send token in first message (application-level auth)
      ws.send(JSON.stringify({
        type: "auth",
        token: token
      }));
    };

    ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      console.log("Event:", message.type, message.data);
    };

    ws.onerror = (error) => {
      console.error("WebSocket error:", error);
    };
    ```

    **Event Examples**:

    Song Playing:
    ```json
    {
      "type": "song:playing",
      "data": {
        "song_id": "song-456",
        "title": "Never Gonna Give You Up",
        "artist": "Rick Astley",
        "duration_seconds": 252
      },
      "timestamp": "2026-05-02T12:00:00Z"
    }
    ```

    Player Position (sent every 2-5 seconds):
    ```json
    {
      "type": "player:position",
      "data": {
        "elapsed_seconds": 45,
        "remaining_seconds": 207,
        "percentage": 17.86
      },
      "timestamp": "2026-05-02T12:00:05Z"
    }
    ```

    Queue Updated:
    ```json
    {
      "type": "queue:updated",
      "data": {
        "queue": [
          {
            "position": 1,
            "song_id": "song-1",
            "title": "Song 1",
            "artist": "Artist 1",
            "reserved_by": "John"
          }
        ]
      },
      "timestamp": "2026-05-02T12:00:00Z"
    }
    ```
    """
    # Extract token from Authorization header
    auth_header = websocket.headers.get("authorization", "")
    token = None

    if auth_header.startswith("Bearer "):
        token = auth_header[7:]  # Strip "Bearer " prefix

    if not token:
        logger.warning(
            f"[WS] Connection attempt without token | session={session_id} | "
            f"client={websocket.client}"
        )
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Unauthorized")
        return

    # Verify JWT token
    try:
        auth_service = get_auth_service()
        payload = auth_service.validate_token(token)
        user_id = payload.get("sub")
        role = payload.get("role")

        if not user_id or not role:
            raise ValueError("Invalid token payload")

        logger.info(
            f"[WS] Token validated | session={session_id} | user_id={user_id} | role={role}"
        )
    except Exception as e:
        logger.warning(f"[WS] Token validation failed | error={str(e)}")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Unauthorized")
        return

    # Register connection with connection manager
    from app.services.websocket_service_container import get_service_container
    container = get_service_container()
    manager = container.get_connection_manager()
    event_service = container.get_event_service()
    event_bus = container.get_event_bus()
    
    await manager.connect(session_id, websocket, role)
    
    # Emit client connected event (will trigger attendee list broadcast)
    from app.services.event_bus import Event
    await event_bus.emit(Event.CLIENT_CONNECTED, session_id=session_id, user_id=user_id, role=role)
    
    # Note: Initial state is now loaded via REST endpoint GET /api/sessions/{id}/state
    # WebSocket handles real-time updates only (queue:updated, player:position, etc.)

    try:
        # Keep connection alive and listen for client messages
        # (client could send heartbeat, auth refresh, etc in future)
        while True:
            data = await websocket.receive_text()
            try:
                message = json.loads(data)
                msg_type = message.get("type")

                if msg_type == "ping":
                    # Simple heartbeat for keeping connection alive
                    await websocket.send_json({"type": "pong"})
                elif msg_type == "auth":
                    # Client can refresh/resend token
                    client_token = message.get("token")
                    if client_token:
                        try:
                            auth_service = get_auth_service()
                            auth_service.validate_token(client_token)
                            logger.debug(
                                f"[WS] Token refresh received | session={session_id}"
                            )
                        except Exception as e:
                            logger.warning(
                                f"[WS] Token refresh failed | session={session_id} | "
                                f"error={str(e)}"
                            )
                            await websocket.close(
                                code=status.WS_1008_POLICY_VIOLATION,
                                reason="Unauthorized",
                            )
                            return
                else:
                    logger.debug(
                        f"[WS] Unknown message type | session={session_id} | "
                        f"type={msg_type}"
                    )
            except json.JSONDecodeError:
                logger.debug(f"[WS] Invalid JSON from client | session={session_id}")

    except WebSocketDisconnect:
        await manager.disconnect(session_id, websocket)
        # Emit client disconnected event
        from app.services.event_bus import Event
        await event_bus.emit(Event.CLIENT_DISCONNECTED, session_id=session_id, user_id=user_id)
        logger.info(f"[WS] Client disconnected | session={session_id}")
    except Exception as e:
        logger.error(
            f"[WS] WebSocket error | session={session_id} | error={str(e)}",
            exc_info=True,
        )
        await manager.disconnect(session_id, websocket)


@router.websocket("/ws/player/discovery")
async def websocket_player_discovery_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for player discovery.
    
    Players connect here during idle/discovery phase to:
    1. Register their existence with the Node
    2. Receive "lock" messages when admin selects them
    3. Receive playback commands once locked
    
    **Protocol**:
    
    Player connects and sends:
    ```json
    {
      "type": "register",
      "name": "Pat's MacBook",
      "platform": "macos"
    }
    ```
    
    Node responds with:
    ```json
    {
      "type": "registered",
      "player_id": "uuid-here"
    }
    ```
    
    When admin selects player via POST /api/players/select, Node sends:
    ```json
    {
      "type": "lock",
      "session_code": "0001",
      "token": "jwt-token-here"
    }
    ```
    
    Player receives lock, acknowledges with:
    ```json
    {
      "type": "locked",
      "player_id": "uuid-here",
      "session_code": "0001"
    }
    ```
    
    Then player closes this discovery connection and opens playback connection
    to /ws/player/session/{code}
    """
    # Check if discovery is locked (active session has a player assigned)
    # This check persists across node restarts because it reads from DB
    from app.api.dependencies import get_db
    from app.models.db_models import Session as DBSession, SessionStatus
    db = next(get_db())
    try:
        locked_session = db.query(DBSession).filter(
            DBSession.player_id.isnot(None),
            DBSession.status == SessionStatus.ACTIVE,
        ).first()
    finally:
        db.close()

    if locked_session:
        logger.info(
            f"[Discovery] rejecting_connection | reason=discovery_locked | "
            f"session={locked_session.code} | player_id={locked_session.player_id}"
        )
        await websocket.close(
            code=status.WS_1008_POLICY_VIOLATION,
            reason="Discovery locked: node already has an active session player",
        )
        return

    await websocket.accept()
    
    from app.services.player_discovery_manager import PlayerDiscoveryManager
    discovery_manager = PlayerDiscoveryManager.get_instance()
    
    player_info = None
    
    try:
        # Wait for player registration message
        data = await websocket.receive_text()
        try:
            message = json.loads(data)
        except json.JSONDecodeError:
            logger.warning("[Player Discovery] Invalid JSON from player on connect")
            await websocket.close(code=status.WS_1003_UNSUPPORTED_DATA, reason="Invalid JSON")
            return
        
        if message.get("type") != "register":
            logger.warning(
                f"[Player Discovery] First message not register | type={message.get('type')}"
            )
            await websocket.close(code=status.WS_1002_PROTOCOL_ERROR, reason="Expected register")
            return
        
        # Extract player info
        name = message.get("name", "Unknown Player")
        platform = message.get("platform", "unknown")
        player_id = message.get("player_id")  # Optional: for reconnections
        
        # Register player (reuses player_id if provided)
        player_info = await discovery_manager.register_player(
            name=name,
            platform=platform,
            websocket=websocket,
            player_id=player_id,  # None = new player, or existing player_id
        )
        
        # Send registered confirmation
        await websocket.send_json({
            "type": "registered",
            "player_id": player_info.player_id,
        })
        
        is_reconnect = player_id and player_id in discovery_manager.players
        logger.info(
            f"[Discovery] ws_connect | player_id={player_info.player_id[:8]}...{player_info.player_id[-4:]} | "
            f"name={name} | platform={platform} | reconnect={is_reconnect}"
        )
        
        # Keep connection alive and wait for lock message from admin
        while True:
            try:
                data = await websocket.receive_text()
                message = json.loads(data)
                msg_type = message.get("type")
                
                if msg_type == "ping":
                    # Heartbeat response
                    await websocket.send_json({"type": "pong"})
                
                elif msg_type == "locked":
                    # Player acknowledged lock, closing discovery connection
                    logger.info(
                        f"[Player Discovery] Player acknowledged lock | "
                        f"player_id={player_info.player_id} | session={message.get('session_code')}"
                    )
                    # Close discovery connection (player will open playback connection next)
                    await websocket.close(code=1000, reason="Locked, switching to playback connection")
                    logger.info(
                        f"[Player Discovery] Closed discovery connection after lock | "
                        f"player_id={player_info.player_id}"
                    )
                    break
                    
                else:
                    logger.debug(
                        f"[Player Discovery] Unknown message type | "
                        f"player_id={player_info.player_id} | type={msg_type}"
                    )
                    
            except json.JSONDecodeError:
                logger.debug(f"[Discovery] invalid_json_from_player")
    
    except WebSocketDisconnect:
        if player_info:
            await discovery_manager.unregister_player(player_info.player_id)
            logger.info(
                f"[Discovery] ws_disconnect | player_id={player_info.player_id[:8]}...{player_info.player_id[-4:]} | "
                f"name={player_info.name}"
            )
    
    except Exception as e:
        if player_info:
            await discovery_manager.unregister_player(player_info.player_id)
        logger.error(
            f"[Discovery] ws_error | player_id={player_info.player_id[:8] if player_info and len(player_info.player_id) >= 8 else 'unknown'} | "
            f"error={str(e)}",
            exc_info=True,
        )


@router.websocket("/ws/player/session/{session_code}")
async def websocket_player_session_endpoint(session_code: str, websocket: WebSocket):
    """
    WebSocket endpoint for player session connection.
    
    After player is locked to a session, player opens this connection to:
    1. Receive player control commands (play, pause, seek, volume, disconnect, etc.)
    2. Send player state updates (progress, ended, etc.)
    
    **Authentication**: Player must send token from lock message in first message
    
    **Protocol**:
    
    Player sends:
    ```json
    {
      "type": "auth",
      "token": "jwt-token-from-lock-message"
    }
    ```
    
    Node responds:
    ```json
    {
      "type": "authenticated"
    }
    ```
    
    Then bidirectional communication:
    
    Node → Player (player control commands):
    ```json
    {
      "type": "play",
      "song_id": "song-id",
      "url": "file:///path/to/video.mp4"
    }
    ```
    
    Or:
    ```json
    {
      "type": "disconnect",
      "reason": "admin_requested"
    }
    ```
    
    Player → Node (player state updates):
    ```json
    {
      "type": "progress",
      "elapsed_seconds": 45,
      "total_seconds": 180
    }
    ```
    """
    await websocket.accept()
    
    from app.services.player_discovery_manager import PlayerDiscoveryManager
    discovery_manager = PlayerDiscoveryManager.get_instance()
    
    player_info = discovery_manager.get_session_player(session_code)
    
    if not player_info:
        # Player not in memory — check DB (handles node restart scenario)
        from app.api.dependencies import get_db
        from app.models.db_models import Session as DBSession, SessionStatus
        db = next(get_db())
        try:
            db_session = db.query(DBSession).filter(
                DBSession.code == session_code,
                DBSession.status == SessionStatus.ACTIVE,
                DBSession.player_id.isnot(None),
            ).first()
        finally:
            db.close()

        if db_session:
            logger.info(
                f"[Player Playback] Restoring player from DB after node restart | "
                f"session={session_code} | player_id={db_session.player_id}"
            )
            player_info = await discovery_manager.register_player(
                name=db_session.player_name or "Unknown Player",
                platform=db_session.player_platform or "unknown",
                websocket=websocket,
                player_id=db_session.player_id,
            )
            discovery_manager.lock_player(db_session.player_id, session_code)
        else:
            logger.warning(
                f"[Player Playback] No locked player for session | session={session_code}"
            )
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="No player locked")
            return

    # Update player connection to this new WS
    player_info.ws_connection = websocket
    
    logger.info(
        f"[Player Playback] Playback connection established | "
        f"player_id={player_info.player_id} | session={session_code}"
    )
    
    try:
        # Wait for authentication
        data = await websocket.receive_text()
        try:
            message = json.loads(data)
        except json.JSONDecodeError:
            logger.warning(f"[Player Playback] Invalid JSON on auth | session={session_code}")
            await websocket.close(code=status.WS_1003_UNSUPPORTED_DATA, reason="Invalid JSON")
            return
        
        if message.get("type") != "auth":
            logger.warning(
                f"[Player Playback] First message not auth | session={session_code} | "
                f"type={message.get('type')}"
            )
            await websocket.close(code=status.WS_1002_PROTOCOL_ERROR, reason="Expected auth")
            return
        
        # TODO: Validate token from auth message
        # For now, just accept it
        
        # Send authenticated confirmation
        await websocket.send_json({
            "type": "authenticated",
            "session_code": session_code,
        })
        
        logger.info(
            f"[Player Playback] Player authenticated | "
            f"player_id={player_info.player_id} | session={session_code}"
        )
        
        # Listen for player messages
        while True:
            data = await websocket.receive_text()
            try:
                message = json.loads(data)
                msg_type = message.get("type")
                
                if msg_type == "ping":
                    await websocket.send_json({"type": "pong"})
                
                elif msg_type == "status":
                    # Player reporting playback status
                    state = message.get("state")  # playing, paused, stopped
                    elapsed = message.get("elapsed_seconds")
                    total = message.get("total_seconds")
                    
                    logger.debug(
                        f"[Player Playback] Status update | player_id={player_info.player_id} | "
                        f"state={state} | elapsed={elapsed}/{total}"
                    )
                    # TODO: Broadcast this status to session clients
                    
                else:
                    logger.debug(
                        f"[Player Playback] Unknown message type | "
                        f"player_id={player_info.player_id} | type={msg_type}"
                    )
                    
            except json.JSONDecodeError:
                logger.debug(f"[Player Playback] Invalid JSON from player | session={session_code}")
    
    except WebSocketDisconnect:
        logger.info(
            f"[Player Playback] Player disconnected | "
            f"player_id={player_info.player_id} | session={session_code}"
        )
        # TODO: Unlock player and update session
        # TODO: Notify admin that player disconnected
    
    except Exception as e:
        logger.error(
            f"[Player Playback] WebSocket error | "
            f"player_id={player_info.player_id} | error={str(e)}",
            exc_info=True,
        )

