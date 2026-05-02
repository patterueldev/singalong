"""WebSocket server for Node - manages connections and broadcasts session events"""

import logging
import json
import asyncio
from typing import Dict, List, Optional, Set
from datetime import datetime
from fastapi import WebSocket

logger = logging.getLogger(__name__)


class WebSocketConnectionManager:
    """Manages WebSocket connections per session"""

    def __init__(self):
        # Dict[session_id] -> Set[WebSocket]
        self.sessions: Dict[str, Set[WebSocket]] = {}
        # Dict[session_id] -> Dict[role] -> Set[WebSocket]
        # For role-based filtering in future
        self.sessions_by_role: Dict[str, Dict[str, Set[WebSocket]]] = {}

    async def connect(self, session_id: str, websocket: WebSocket, role: str):
        """
        Register a new WebSocket connection for a session

        Args:
            session_id: Session code (e.g., "0001")
            websocket: FastAPI WebSocket object
            role: User role (admin, controller, player)
        """
        await websocket.accept()

        # Track connection
        if session_id not in self.sessions:
            self.sessions[session_id] = set()
            self.sessions_by_role[session_id] = {}
            logger.info(f"[WS] Created session group: {session_id}")

        self.sessions[session_id].add(websocket)

        # Track by role
        if role not in self.sessions_by_role[session_id]:
            self.sessions_by_role[session_id][role] = set()
        self.sessions_by_role[session_id][role].add(websocket)

        logger.info(
            f"[WS] Client connected to session {session_id} | role={role} | "
            f"total_clients={len(self.sessions[session_id])}"
        )

    async def disconnect(self, session_id: str, websocket: WebSocket):
        """
        Unregister a WebSocket connection
        """
        if session_id not in self.sessions:
            return

        self.sessions[session_id].discard(websocket)

        # Remove from role tracking
        for role, ws_set in self.sessions_by_role.get(session_id, {}).items():
            ws_set.discard(websocket)

        # Cleanup empty session groups
        if not self.sessions[session_id]:
            del self.sessions[session_id]
            del self.sessions_by_role[session_id]
            logger.info(f"[WS] Session group removed: {session_id}")
        else:
            logger.info(
                f"[WS] Client disconnected from session {session_id} | "
                f"remaining_clients={len(self.sessions[session_id])}"
            )

    async def broadcast_to_session(
        self,
        session_id: str,
        event_type: str,
        data: dict,
        roles: Optional[List[str]] = None,
    ):
        """
        Broadcast an event to all clients in a session (optionally filtered by role)

        Args:
            session_id: Session code (e.g., "0001")
            event_type: Event type (e.g., "song:playing")
            data: Event data (dict)
            roles: Optional list of roles to filter (e.g., ["admin", "controller"])
                   If None, broadcasts to all
        """
        if session_id not in self.sessions:
            logger.debug(f"[WS] No clients in session {session_id}, skipping broadcast")
            return

        # Build event message
        message = {
            "type": event_type,
            "data": data,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }
        payload = json.dumps(message)

        # Determine target websockets
        if roles:
            # Broadcast to specific roles only
            target_websockets = set()
            for role in roles:
                target_websockets.update(
                    self.sessions_by_role.get(session_id, {}).get(role, set())
                )
        else:
            # Broadcast to all clients
            target_websockets = self.sessions[session_id]

        # Send to all targets
        disconnected = []
        for websocket in target_websockets:
            try:
                await websocket.send_text(payload)
            except RuntimeError:
                # Connection closed
                disconnected.append(websocket)

        # Cleanup disconnected clients
        for websocket in disconnected:
            await self.disconnect(session_id, websocket)

        logger.debug(
            f"[WS] Broadcast '{event_type}' to session {session_id} | "
            f"targets={len(target_websockets)} | "
            f"roles={roles or 'all'}"
        )

    async def broadcast_all_sessions(
        self,
        event_type: str,
        data: dict,
        roles: Optional[List[str]] = None,
    ):
        """
        Broadcast an event to all connected sessions

        Useful for system-wide events (e.g., server status)
        """
        for session_id in list(self.sessions.keys()):
            await self.broadcast_to_session(session_id, event_type, data, roles)

    def get_session_client_count(self, session_id: str) -> int:
        """Get number of connected clients for a session"""
        return len(self.sessions.get(session_id, set()))

    def get_session_clients_by_role(self, session_id: str) -> Dict[str, int]:
        """Get connected clients grouped by role for a session"""
        result = {}
        for role, ws_set in self.sessions_by_role.get(session_id, {}).items():
            result[role] = len(ws_set)
        return result

    def get_all_sessions(self) -> Dict[str, Dict]:
        """Get info about all active sessions"""
        result = {}
        for session_id, websockets in self.sessions.items():
            result[session_id] = {
                "total_clients": len(websockets),
                "by_role": self.get_session_clients_by_role(session_id),
            }
        return result


# Global singleton instance
_manager: Optional[WebSocketConnectionManager] = None


def get_websocket_manager() -> WebSocketConnectionManager:
    """Get or create the global WebSocket manager"""
    global _manager
    if _manager is None:
        _manager = WebSocketConnectionManager()
        logger.info("[WS] WebSocket manager initialized")
    return _manager
