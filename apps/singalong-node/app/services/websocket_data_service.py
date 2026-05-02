"""
Data services for fetching and formatting WebSocket event payloads.

Each data service handles ONE data domain (Queue, Player, Attendees, etc).
Follows Single Responsibility Principle: only fetch and format, no broadcasting.
"""

import logging
from typing import List, Dict, Optional
from app.database import SessionLocal
from app.models.db_models import Session as SessionModel, Reservation, ReservationStatus

logger = logging.getLogger(__name__)


class QueueDataService:
    """Fetches and formats queue/reservation data for broadcasts"""
    
    @staticmethod
    def get_queue_for_broadcast(session_id: str) -> Dict:
        """
        Fetch active reservations and format for WebSocket broadcast.
        
        Args:
            session_id: Session code (e.g., "0001")
            
        Returns:
            Dict with formatted queue data
        """
        db = SessionLocal()
        
        try:
            # Fetch session
            session = db.query(SessionModel).filter(
                SessionModel.code == session_id
            ).first()
            
            if not session:
                logger.warning(f"[DataService] Session not found: {session_id}")
                return {"queue": [], "total": 0}
            
            # Fetch active reservations in order
            reservations = (
                db.query(Reservation)
                .filter(
                    Reservation.session_id == session.id,
                    Reservation.status == ReservationStatus.ACTIVE,
                )
                .order_by(Reservation.order_index.asc())
                .all()
            )
            
            # Format queue
            queue = []
            for idx, reservation in enumerate(reservations, 1):
                queue.append(
                    {
                        "position": idx,
                        "reservation_id": str(reservation.id),
                        "song_id": str(reservation.song_id),
                        "title": reservation.song.title,
                        "artist": reservation.song.artist,
                        "reserved_by": reservation.reserved_by or "Unknown",
                        "duration": int(reservation.song.duration) if reservation.song.duration else 0,
                    }
                )
            
            return {
                "queue": queue,
                "total": len(queue),
            }
        
        except Exception as e:
            logger.error(
                f"[DataService] Error fetching queue: {str(e)}",
                exc_info=True
            )
            return {"queue": [], "total": 0}
        
        finally:
            db.close()


class PlayerDataService:
    """Fetches and formats player state data for broadcasts"""
    
    @staticmethod
    def get_player_position_for_broadcast(session_id: str) -> Dict:
        """
        Fetch current player position and format for broadcast.
        
        TODO: Integrate with actual player manager when available
        
        Args:
            session_id: Session code
            
        Returns:
            Dict with player position data
        """
        # Placeholder: will integrate with PlayerManager in next phase
        return {
            "elapsed_seconds": 0,
            "remaining_seconds": 0,
            "percentage": 0.0,
        }


class AttendeeDataService:
    """Fetches and formats attendee/user data for broadcasts"""
    
    @staticmethod
    def get_attendees_for_broadcast(session_id: str) -> Dict:
        """
        Fetch active session attendees and format for broadcast.
        
        Args:
            session_id: Session code
            
        Returns:
            Dict with formatted attendees list
        """
        db = SessionLocal()
        
        try:
            # Fetch session
            session = db.query(SessionModel).filter(
                SessionModel.code == session_id
            ).first()
            
            if not session:
                return {"attendees": [], "total": 0}
            
            # For now, return empty (TODO: fetch from connection manager or user sessions table)
            attendees = []
            
            return {
                "attendees": attendees,
                "total": len(attendees),
            }
        
        except Exception as e:
            logger.error(
                f"[DataService] Error fetching attendees: {str(e)}",
                exc_info=True
            )
            return {"attendees": [], "total": 0}
        
        finally:
            db.close()


class SessionDataService:
    """Fetches and formats session metadata for broadcasts"""
    
    @staticmethod
    def get_session_for_broadcast(session_id: str) -> Dict:
        """
        Fetch session metadata and format for initial state.
        
        Args:
            session_id: Session code
            
        Returns:
            Dict with session metadata
        """
        db = SessionLocal()
        
        try:
            session = db.query(SessionModel).filter(
                SessionModel.code == session_id
            ).first()
            
            if not session:
                return {}
            
            return {
                "session_id": session.code,
                "session_title": session.title,
                "vibes": session.vibes or "",
                "max_users": session.max_users or "",
                "created_at": session.created_at.isoformat() if session.created_at else None,
                "status": session.status.value if session.status else "unknown",
            }
        
        except Exception as e:
            logger.error(
                f"[DataService] Error fetching session: {str(e)}",
                exc_info=True
            )
            return {}
        
        finally:
            db.close()
