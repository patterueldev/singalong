"""WebSocket module for Master service."""

from app.websocket.manager import ConnectionManager

# Global connection manager instance
connection_manager = ConnectionManager()

__all__ = ["connection_manager", "ConnectionManager"]
