"""Event handlers for Node WebSocket broadcasting"""

import logging
from typing import Optional, Dict
from datetime import datetime
from sqlalchemy.orm import Session as SQLSession

from app.services.node_websocket_server import get_websocket_manager
from app.models.db_models import Session as SessionModel, Reservation, ReservationStatus
from app.database import SessionLocal

logger = logging.getLogger(__name__)


class NodeSessionEventHandlers:
    """Handlers for events originating from Node (player state, queue changes, etc)"""

    # Note: send_initial_state() removed - use REST endpoint GET /api/sessions/{id}/state
    # for initial data load instead. WebSocket now handles updates only.

    @staticmethod
    async def broadcast_song_playing(
        session_id: str,
        song_id: str,
        title: str,
        artist: str,
        duration_seconds: int,
    ):
        """
        Broadcast when a song starts playing

        Args:
            session_id: Session code (e.g., "0001")
            song_id: Song ID from database
            title: Song title
            artist: Artist name
            duration_seconds: Song duration in seconds
        """
        manager = get_websocket_manager()

        event_data = {
            "song_id": song_id,
            "title": title,
            "artist": artist,
            "duration_seconds": duration_seconds,
        }

        await manager.broadcast_to_session(session_id, "song:playing", event_data)
        logger.info(
            f"[WS] Broadcast song:playing | session={session_id} | "
            f"song_id={song_id} | title={title}"
        )

    @staticmethod
    async def broadcast_player_position(
        session_id: str,
        elapsed_seconds: int,
        remaining_seconds: int,
        percentage: float,
    ):
        """
        Broadcast current player position (called every 2-5 seconds)

        Args:
            session_id: Session code
            elapsed_seconds: Seconds elapsed
            remaining_seconds: Seconds remaining
            percentage: Percentage complete (0-100)
        """
        manager = get_websocket_manager()

        event_data = {
            "elapsed_seconds": elapsed_seconds,
            "remaining_seconds": remaining_seconds,
            "percentage": round(percentage, 2),
        }

        await manager.broadcast_to_session(session_id, "player:position", event_data)
        # Debug logging at trace level to avoid spam
        logger.debug(
            f"[WS] Broadcast player:position | session={session_id} | "
            f"{elapsed_seconds}s / {remaining_seconds}s remaining ({percentage:.1f}%)"
        )

    @staticmethod
    async def broadcast_queue_updated(session_id: str):
        """
        Broadcast when the queue/reservations change (song added, removed, reordered)

        Args:
            session_id: Session code
        """
        logger.info(f"[BROADCAST] broadcast_queue_updated called for session {session_id}")
        manager = get_websocket_manager()
        logger.info(f"[BROADCAST] WebSocket manager obtained: {manager}")
        db = SessionLocal()

        try:
            # Fetch updated queue
            session = db.query(SessionModel).filter(SessionModel.code == session_id).first()
            if not session:
                logger.warning(
                    f"[WS] Session not found for queue broadcast: {session_id}"
                )
                return

            # Get all reservations in order (using correct field names)
            reservations = (
                db.query(Reservation)
                .filter(Reservation.session_code == session.code)
                .order_by(Reservation.position.asc())
                .all()
            )

            # Build queue data
            queue = []
            for reservation in reservations:
                queue.append(
                    {
                        "queue_id": str(reservation.id),
                        "song_id": str(reservation.song_id),
                        "song_title": reservation.song_title or "Unknown Song",
                        "position": reservation.position,
                        "status": reservation.status.value,
                        "reserved_by": reservation.reserved_by_nickname or "Unknown",
                        "reserved_by_id": str(reservation.user_id) if reservation.user_id else None,
                        "queued_at": reservation.reserved_at.isoformat() if reservation.reserved_at else None,
                    }
                )

            event_data = {"queue": queue}

            logger.info(f"[BROADCAST] Calling manager.broadcast_to_session with {len(queue)} items")
            await manager.broadcast_to_session(session_id, "queue:updated", event_data)
            logger.info(
                f"[WS] Broadcast queue:updated | session={session_id} | "
                f"queue_size={len(queue)}"
            )
        finally:
            db.close()

    @staticmethod
    async def broadcast_download_progress(
        session_id: str,
        video_id: str,
        progress_percent: float,
        title: str,
    ):
        """
        Broadcast download progress (admin-only event)

        Args:
            session_id: Session code
            video_id: Video ID being downloaded
            progress_percent: Percentage complete (0-100)
            title: Song title
        """
        manager = get_websocket_manager()

        event_data = {
            "video_id": video_id,
            "progress_percent": round(progress_percent, 2),
            "title": title,
        }

        # Broadcast to admin role only
        await manager.broadcast_to_session(
            session_id, "download:progress", event_data, roles=["admin"]
        )
        logger.info(
            f"[WS] Broadcast download:progress (admin-only) | session={session_id} | "
            f"video_id={video_id} | {progress_percent:.1f}%"
        )

    @staticmethod
    async def broadcast_attendee_list(session_id: str):
        """
        Broadcast list of connected attendees (admin-only event)

        Args:
            session_id: Session code
        """
        manager = get_websocket_manager()

        # Get connected clients by role for this session
        clients_by_role = manager.get_session_clients_by_role(session_id)

        event_data = {
            "attendees": [
                {
                    "role": role,
                    "count": count,
                }
                for role, count in clients_by_role.items()
            ],
            "total": sum(clients_by_role.values()),
        }

        # Broadcast to admin role only
        await manager.broadcast_to_session(
            session_id, "attendee:list", event_data, roles=["admin"]
        )
        logger.debug(
            f"[WS] Broadcast attendee:list (admin-only) | session={session_id} | "
            f"total={event_data['total']}"
        )


def get_node_session_event_handlers() -> type:
    """Dependency injection wrapper for event handlers"""
    return NodeSessionEventHandlers
