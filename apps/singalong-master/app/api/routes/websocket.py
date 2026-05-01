"""WebSocket endpoint for Node connections."""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.websocket import connection_manager
import logging

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

    The connection is persistent and long-lived (hours/days).
    """
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
