"""
WebSocket broadcast service - handles sending data to clients.

Single Responsibility: Only broadcasts, no data fetching or business logic.
Depends on IWebSocketConnectionRepository for decoupling.
"""

import logging
import json
from typing import Dict, Optional, List
from datetime import datetime
from fastapi import WebSocket

from app.services.websocket_repository import IWebSocketConnectionRepository

logger = logging.getLogger(__name__)


class WebSocketBroadcastService:
    """
    Broadcasts WebSocket events to clients.
    
    Single Responsibility: Send JSON payloads to WebSocket clients.
    Depends on abstract repository, enabling test mocks.
    """
    
    def __init__(self, connection_repo: IWebSocketConnectionRepository):
        """
        Initialize broadcast service.
        
        Args:
            connection_repo: Repository for WebSocket connections (can be mocked)
        """
        self._repo = connection_repo
        self._logger = logger
    
    async def broadcast_to_session(
        self,
        session_id: str,
        event_type: str,
        data: Dict,
        roles: Optional[List[str]] = None,
    ) -> int:
        """
        Broadcast an event to all clients in a session.
        
        Args:
            session_id: Session code
            event_type: Event type (e.g., "queue:updated")
            data: Event payload
            roles: Optional role filter (admin, controller, player)
                   If None, broadcasts to all roles
                   
        Returns:
            Number of clients message was sent to
        """
        # Get target websockets
        if roles:
            target_websockets = self._repo.get_session_clients_by_role(session_id, roles)
        else:
            target_websockets = self._repo.get_session_clients(session_id)
        
        if not target_websockets:
            self._logger.debug(
                f"[Broadcast] No clients in session {session_id} for {event_type}"
            )
            return 0
        
        # Build message
        message = {
            "type": event_type,
            "data": data,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }
        payload = json.dumps(message)
        
        # Send to all targets
        sent_count = 0
        disconnected = []
        
        for websocket in target_websockets:
            try:
                await websocket.send_text(payload)
                sent_count += 1
            except RuntimeError as e:
                # Connection closed, mark for cleanup
                disconnected.append(websocket)
                self._logger.debug(
                    f"[Broadcast] Failed to send to client: {str(e)}"
                )
        
        # Cleanup disconnected
        for websocket in disconnected:
            await self._repo.disconnect(session_id, websocket)
        
        self._logger.info(
            f"[Broadcast] {event_type} | session={session_id} | "
            f"sent_to={sent_count} | roles={roles or 'all'} | "
            f"disconnected={len(disconnected)}"
        )
        
        return sent_count
    
    async def broadcast_to_user(
        self,
        user_id: str,
        session_id: str,
        event_type: str,
        data: Dict,
    ) -> int:
        """
        Broadcast an event to a specific user in a session.
        
        Args:
            user_id: User ID (for filtering)
            session_id: Session code
            event_type: Event type
            data: Event payload
            
        Returns:
            Number of clients message was sent to
        """
        # TODO: Implement user-specific filtering when user context is added to WebSocket
        # For now, broadcast to session (filtering will happen client-side)
        return await self.broadcast_to_session(session_id, event_type, data)
    
    async def broadcast_to_all_sessions(
        self,
        event_type: str,
        data: Dict,
        roles: Optional[List[str]] = None,
    ) -> int:
        """
        Broadcast an event to all sessions.
        
        Args:
            event_type: Event type
            data: Event payload
            roles: Optional role filter
            
        Returns:
            Total number of clients message was sent to
        """
        total_sent = 0
        active_sessions = self._repo.get_active_sessions()
        
        for session_id in active_sessions:
            sent = await self.broadcast_to_session(session_id, event_type, data, roles)
            total_sent += sent
        
        self._logger.info(
            f"[Broadcast] System-wide {event_type} | "
            f"sessions={len(active_sessions)} | total_sent={total_sent}"
        )
        
        return total_sent
    
    def get_session_client_count(self, session_id: str) -> int:
        """Get number of connected clients in a session"""
        return self._repo.get_session_client_count(session_id)
    
    def get_active_sessions(self) -> List[str]:
        """Get all sessions with active connections"""
        return self._repo.get_active_sessions()
