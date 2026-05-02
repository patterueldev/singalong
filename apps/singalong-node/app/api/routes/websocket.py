"""WebSocket endpoints for session client connections"""

import logging
import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status

from app.middleware.auth import get_auth_service
from app.services.node_websocket_server import get_websocket_manager

logger = logging.getLogger(__name__)

router = APIRouter(tags=["WebSocket"])


@router.websocket("/ws/{session_id}")
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

    websocat -H "Authorization: Bearer $TOKEN" "ws://localhost:5002/ws/1234"
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

    # Register connection
    manager = get_websocket_manager()
    await manager.connect(session_id, websocket, role)

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
        logger.info(f"[WS] Client disconnected | session={session_id}")
    except Exception as e:
        logger.error(
            f"[WS] WebSocket error | session={session_id} | error={str(e)}",
            exc_info=True,
        )
        await manager.disconnect(session_id, websocket)
