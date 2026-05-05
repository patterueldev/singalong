"""
WebSocket event service - orchestrates events without mixing concerns.

Business logic for WHEN to broadcast and WHAT to send.
Uses data services to fetch data and broadcast service to send.
Depends on abstractions, enabling complete testability.
"""

import logging
from fastapi import WebSocket

from app.services.websocket_broadcast_service import WebSocketBroadcastService
from app.services.websocket_data_service import (
    QueueDataService,
    PlayerDataService,
    AttendeeDataService,
    SessionDataService,
)

logger = logging.getLogger(__name__)


class WebSocketEventService:
    """
    Orchestrates WebSocket events - decides WHAT to broadcast and WHEN.
    
    Single Responsibility: Business logic for event orchestration.
    - Receives events from event bus
    - Uses data services to fetch formatted data
    - Uses broadcast service to send to clients
    - No data access, no WebSocket send logic
    """
    
    def __init__(self, broadcast_service: WebSocketBroadcastService):
        """
        Initialize event service.
        
        Args:
            broadcast_service: Service for sending to WebSocket clients
        """
        self._broadcast = broadcast_service
        self._logger = logger
    
    async def send_initial_state(
        self,
        session_id: str,
        user_id: str,
        websocket: WebSocket,
    ) -> None:
        """
        Send initial state when client connects.
        
        Client receives current queue, player position, and session info immediately.
        
        Args:
            session_id: Session code
            user_id: Connected user ID
            websocket: WebSocket connection
        """
        try:
            # Fetch all initial data
            session_data = SessionDataService.get_session_for_broadcast(session_id)
            queue_data = QueueDataService.get_queue_for_broadcast(session_id)
            player_data = PlayerDataService.get_player_position_for_broadcast(session_id)
            
            # Build initial state payload
            initial_state = {
                "type": "init",
                "data": {
                    **session_data,  # session_id, title, vibes, etc.
                    "queue": queue_data.get("queue", []),
                    "queue_total": queue_data.get("total", 0),
                    "player": player_data,
                }
            }
            
            # Send to client directly
            await websocket.send_json(initial_state)
            
            self._logger.info(
                f"[EventService] Initial state sent | session={session_id} | "
                f"user={user_id} | queue_size={queue_data.get('total', 0)}"
            )
        
        except Exception as e:
            self._logger.error(
                f"[EventService] Error sending initial state: {str(e)}",
                exc_info=True
            )
    
    async def on_client_connected(self, session_id: str, user_id: str, role: str) -> None:
        """
        Handle client connection event.
        
        Args:
            session_id: Session code
            user_id: User ID
            role: User role (admin, controller, player)
        """
        try:
            attendees_data = AttendeeDataService.get_attendees_for_broadcast(session_id)
            
            await self._broadcast.broadcast_to_session(
                session_id,
                "attendee:connected",
                {
                    "user_id": user_id,
                    "role": role,
                    "attendees": attendees_data.get("attendees", []),
                    "total": attendees_data.get("total", 0),
                },
                # Broadcast to all roles
            )
            
            self._logger.info(
                f"[EventService] Client connected | session={session_id} | "
                f"user={user_id} | role={role}"
            )
        
        except Exception as e:
            self._logger.error(
                f"[EventService] Error on client connected: {str(e)}",
                exc_info=True
            )
    
    async def on_client_disconnected(self, session_id: str, user_id: str) -> None:
        """
        Handle client disconnection event.
        
        Args:
            session_id: Session code
            user_id: User ID
        """
        try:
            attendees_data = AttendeeDataService.get_attendees_for_broadcast(session_id)
            
            await self._broadcast.broadcast_to_session(
                session_id,
                "attendee:disconnected",
                {
                    "user_id": user_id,
                    "attendees": attendees_data.get("attendees", []),
                    "total": attendees_data.get("total", 0),
                },
            )
            
            self._logger.info(
                f"[EventService] Client disconnected | session={session_id} | user={user_id}"
            )
        
        except Exception as e:
            self._logger.error(
                f"[EventService] Error on client disconnected: {str(e)}",
                exc_info=True
            )
    
    async def on_queue_changed(self, session_id: str) -> None:
        """
        Handle queue change event (reservation added, removed, or reordered).
        
        Args:
            session_id: Session code
        """
        try:
            queue_data = QueueDataService.get_queue_for_broadcast(session_id)
            
            await self._broadcast.broadcast_to_session(
                session_id,
                "queue:updated",
                queue_data,
            )
            
            self._logger.info(
                f"[EventService] Queue updated | session={session_id} | "
                f"queue_size={queue_data.get('total', 0)}"
            )
        
        except Exception as e:
            self._logger.error(
                f"[EventService] Error on queue changed: {str(e)}",
                exc_info=True
            )
    
    async def on_player_position_updated(self, session_id: str) -> None:
        """
        Handle player position update event (called periodically, 2-5s interval).
        
        Args:
            session_id: Session code
        """
        try:
            player_data = PlayerDataService.get_player_position_for_broadcast(session_id)
            
            await self._broadcast.broadcast_to_session(
                session_id,
                "player:position",
                player_data,
            )
            
            # DEBUG: log at debug level to avoid spam
            self._logger.debug(
                f"[EventService] Player position | session={session_id} | "
                f"elapsed={player_data.get('elapsed_seconds')}s"
            )
        
        except Exception as e:
            self._logger.error(
                f"[EventService] Error on player position updated: {str(e)}",
                exc_info=True
            )
    
    async def on_player_started(self, session_id: str, song_id: str, title: str) -> None:
        """
        Handle song playback started event.
        
        Args:
            session_id: Session code
            song_id: Song ID
            title: Song title
        """
        try:
            await self._broadcast.broadcast_to_session(
                session_id,
                "song:playing",
                {
                    "song_id": song_id,
                    "title": title,
                },
            )
            
            self._logger.info(
                f"[EventService] Song started | session={session_id} | "
                f"song={title} ({song_id})"
            )
        
        except Exception as e:
            self._logger.error(
                f"[EventService] Error on player started: {str(e)}",
                exc_info=True
            )
    
    async def on_download_progress(
        self, session_id: str, video_id: str, progress_data: dict
    ) -> None:
        """
        Handle download progress event (admin-only).
        
        Args:
            session_id: Session code
            video_id: Video being downloaded
            progress_data: Progress info (bytes, percentage, etc.)
        """
        try:
            await self._broadcast.broadcast_to_session(
                session_id,
                "download:progress",
                {
                    "video_id": video_id,
                    **progress_data,
                },
                roles=["admin"],  # Admin-only
            )
            
            self._logger.debug(
                f"[EventService] Download progress | session={session_id} | "
                f"video={video_id} | {progress_data}"
            )
        
        except Exception as e:
            self._logger.error(
                f"[EventService] Error on download progress: {str(e)}",
                exc_info=True
            )
