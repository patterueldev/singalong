"""WebSocket connection manager for broadcasting events to connected Nodes."""

from typing import Set
from fastapi import WebSocket
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages WebSocket connections and broadcasts events to all connected Nodes."""

    def __init__(self):
        """Initialize connection manager with empty active connections set."""
        self.active_connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket) -> None:
        """
        Accept a WebSocket connection and add it to active connections.

        Args:
            websocket: The WebSocket connection to accept
        """
        await websocket.accept()
        self.active_connections.add(websocket)
        logger.info(f"Node connected. Active connections: {len(self.active_connections)}")

    def disconnect(self, websocket: WebSocket) -> None:
        """
        Remove a WebSocket connection from active connections.

        Args:
            websocket: The WebSocket connection to remove
        """
        self.active_connections.discard(websocket)
        logger.info(f"Node disconnected. Active connections: {len(self.active_connections)}")

    async def broadcast(self, event_type: str, data: dict) -> None:
        """
        Broadcast an event to all connected Nodes.

        Args:
            event_type: Type of event (e.g., "download:progress", "download:complete")
            data: Event data payload
        """
        message = {
            "type": event_type,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "data": data,
        }

        # Log with actual data details
        if event_type == "download:progress":
            progress = data.get("progress_percent", 0)
            video_id = data.get("video_id", "unknown")
            status = data.get("status", "unknown")
            logger.info(f"[BROADCAST] download:progress | {video_id} | {progress}% | status={status}")
        elif event_type == "download:complete":
            video_id = data.get("video_id", "unknown")
            title = data.get("title", "unknown")
            logger.info(f"[BROADCAST] download:complete | {video_id} | {title}")
        elif event_type == "download:error":
            video_id = data.get("video_id", "unknown")
            error = data.get("error_message", "unknown")
            logger.info(f"[BROADCAST] download:error | {video_id} | {error}")
        else:
            logger.debug(f"[BROADCAST] {event_type} | connections={len(self.active_connections)}")

        # Track disconnected connections to clean up
        disconnected = set()

        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception as e:
                logger.warning(f"Failed to send message to connection: {e}")
                disconnected.add(connection)

        # Clean up dead connections
        for conn in disconnected:
            self.disconnect(conn)

    def get_connection_count(self) -> int:
        """Return the number of active WebSocket connections."""
        return len(self.active_connections)
