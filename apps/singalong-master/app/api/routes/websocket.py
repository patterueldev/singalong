"""WebSocket endpoint for Node connections."""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status
from app.websocket import connection_manager
from app.middleware.auth import get_auth_service
import logging
import jwt

logger = logging.getLogger(__name__)

router = APIRouter()


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for Node connections.

    Nodes connect here at startup to listen for Master events:
    - download:progress (streaming download progress)
    - download:complete (download finished, triggers sync)
    - catalog:updated (new videos indexed)
    - system:health (periodic heartbeat, optional)

    Authentication: Node must provide JWT token via query parameter:
      ws://master:5001/ws?token=<jwt_access_token>
    
    Token is generated via POST /api/auth/exchange with API key.
    The connection is persistent and long-lived (hours/days).
    """
    # Extract and validate JWT token from query params
    token = websocket.query_params.get("token")
    if not token:
        logger.warning("WebSocket connection rejected: No token provided")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Missing authentication token")
        return

    # Validate token
    auth_service = get_auth_service()
    try:
        payload = auth_service.validate_token(token)
        logger.info(f"WebSocket connection authenticated for Node API")
    except jwt.ExpiredSignatureError:
        logger.warning("WebSocket connection rejected: Token expired")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Token has expired")
        return
    except jwt.InvalidTokenError as e:
        logger.warning(f"WebSocket connection rejected: Invalid token - {str(e)}")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")
        return
    except Exception as e:
        logger.error(f"WebSocket token validation error: {e}")
        await websocket.close(code=status.WS_1011_SERVER_ERROR, reason="Token validation failed")
        return

    # Token is valid, accept connection
    try:
        await connection_manager.connect(websocket)
        logger.info("Node WebSocket connection accepted")

        # Keep connection alive, wait for disconnect
        while True:
            # Receive data from Node (not used for MVP, just keep connection alive)
            data = await websocket.receive_text()
            logger.debug(f"Received from Node: {data}")

    except WebSocketDisconnect:
        connection_manager.disconnect(websocket)
        logger.info("Node WebSocket disconnected")

    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        connection_manager.disconnect(websocket)
