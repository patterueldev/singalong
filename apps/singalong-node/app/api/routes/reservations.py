"""Song reservation API endpoints"""

import logging
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session as SQLSession

from app.database import get_db
from app.models.schemas import (
    CreateReservationRequest,
    ReservationResponse,
    ReservationDetailResponse,
    UpdateReservationStatusRequest,
    QueueResponse,
    QueueItemResponse,
)
from app.services.reservation_service import ReservationService
from app.models.db_models import Reservation, Song

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/sessions", tags=["Reservations"])


@router.post("/{session_id}/reservations", status_code=201, response_model=ReservationResponse)
async def create_reservation(
    session_id: str,
    request: CreateReservationRequest,
    db: SQLSession = Depends(get_db),
) -> ReservationResponse:
    """
    Create a new song reservation in a session

    Args:
        session_id: Session UUID
        request: Reservation request (song_id, user_id)
        db: Database session

    Returns:
        ReservationResponse with reservation details

    Raises:
        HTTPException: 400 if invalid, 404 if not found, 409 if duplicate
    """
    try:
        import uuid as uuid_module
        
        # Convert string UUIDs to UUID objects
        try:
            session_uuid = uuid_module.UUID(session_id)
            song_uuid = uuid_module.UUID(request.song_id)
            user_uuid = uuid_module.UUID(request.user_id)
        except (ValueError, AttributeError):
            raise ValueError("Invalid UUID format")
        
        reservation_service = ReservationService(db)
        reservation = reservation_service.create_reservation(
            session_id=session_uuid,
            song_id=song_uuid,
            user_id=user_uuid,
        )

        logger.info(f"Reservation created: {reservation.id} (song={request.song_id})")

        return ReservationResponse(
            id=str(reservation.id),
            session_id=str(reservation.session_id),
            song_id=str(reservation.song_id),
            position=reservation.position,
            status=reservation.status.value,
            reserved_at=reservation.reserved_at.isoformat(),
            started_at=reservation.started_at.isoformat() if reservation.started_at else None,
            completed_at=reservation.completed_at.isoformat() if reservation.completed_at else None,
            cancelled_at=reservation.cancelled_at.isoformat() if reservation.cancelled_at else None,
        )

    except ValueError as e:
        if "already reserved" in str(e):
            raise HTTPException(status_code=409, detail=str(e))
        elif "not found" in str(e):
            raise HTTPException(status_code=404, detail=str(e))
        else:
            raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.exception(f"Error creating reservation: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to create reservation")


@router.get("/{session_id}/reservations", response_model=dict)
async def list_reservations(
    session_id: str,
    status: str = None,
    db: SQLSession = Depends(get_db),
) -> dict:
    """
    List all reservations for a session

    Args:
        session_id: Session UUID
        status: Optional status filter (pending, playing, completed, cancelled)
        db: Database session

    Returns:
        Dictionary with reservations list and metadata

    Raises:
        HTTPException: 404 if session not found
    """
    try:
        import uuid as uuid_module
        reservation_service = ReservationService(db)
        from app.models.db_models import Session
        
        # Convert session_id to UUID for database query
        try:
            session_uuid = uuid_module.UUID(session_id)
        except (ValueError, AttributeError):
            raise HTTPException(status_code=400, detail="Invalid session ID format")
        
        # Verify session exists
        session = db.query(Session).filter(Session.id == session_uuid).first()
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")

        # List reservations
        reservations = reservation_service.list_reservations(
            session_id=session_uuid,
            status=status,
        )

        # Join with song details
        result = []
        for res in reservations:
            song = db.query(Song).filter(Song.id == res.song_id).first()
            if song:
                result.append({
                    "reservation_id": str(res.id),
                    "session_id": str(res.session_id),
                    "song_id": str(res.song_id),
                    "song_title": song.title,
                    "song_artist": song.artist or "",
                    "position": res.position,
                    "status": res.status.value,
                    "reserved_by": str(res.user_id),
                    "reserved_at": res.reserved_at.isoformat(),
                })

        return {
            "reservations": result,
            "total": len(result),
            "session_id": session_id,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error listing reservations: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to list reservations")


@router.put("/{session_id}/reservations/{reservation_id}/status", response_model=ReservationResponse)
async def update_reservation_status(
    session_id: str,
    reservation_id: str,
    request: UpdateReservationStatusRequest,
    db: SQLSession = Depends(get_db),
) -> ReservationResponse:
    """
    Update reservation status (admin endpoint)

    Args:
        session_id: Session UUID
        reservation_id: Reservation UUID
        request: Status update request
        db: Database session

    Returns:
        Updated ReservationResponse

    Raises:
        HTTPException: 400 if invalid status, 404 if not found
    """
    try:
        from app.models.db_models import ReservationStatus
        
        reservation_service = ReservationService(db)
        
        # Validate status
        try:
            new_status = ReservationStatus(request.status)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid status: {request.status}. Must be one of: pending, playing, completed, cancelled"
            )

        # Update
        reservation = reservation_service.update_status(
            reservation_id=reservation_id,
            new_status=new_status,
        )

        logger.info(f"Reservation {reservation_id} status updated to {new_status.value}")

        return ReservationResponse(
            id=str(reservation.id),
            session_id=str(reservation.session_id),
            song_id=str(reservation.song_id),
            position=reservation.position,
            status=reservation.status.value,
            reserved_at=reservation.reserved_at.isoformat(),
            started_at=reservation.started_at.isoformat() if reservation.started_at else None,
            completed_at=reservation.completed_at.isoformat() if reservation.completed_at else None,
            cancelled_at=reservation.cancelled_at.isoformat() if reservation.cancelled_at else None,
        )

    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.exception(f"Error updating reservation: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to update reservation")


@router.delete("/{session_id}/reservations/{reservation_id}", status_code=204)
async def cancel_reservation(
    session_id: str,
    reservation_id: str,
    db: SQLSession = Depends(get_db),
) -> None:
    """
    Cancel a song reservation

    Args:
        session_id: Session UUID
        reservation_id: Reservation UUID
        db: Database session

    Raises:
        HTTPException: 404 if not found
    """
    try:
        reservation_service = ReservationService(db)
        reservation_service.cancel_reservation(reservation_id=reservation_id)

        logger.info(f"Reservation {reservation_id} cancelled")

    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.exception(f"Error cancelling reservation: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to cancel reservation")


@router.get("/{session_id}/queue", response_model=QueueResponse)
async def get_session_queue(
    session_id: str,
    db: SQLSession = Depends(get_db),
) -> QueueResponse:
    """
    Get the karaoke queue for a session (for player app)

    Args:
        session_id: Session UUID
        db: Database session

    Returns:
        QueueResponse with ordered songs

    Raises:
        HTTPException: 404 if session not found
    """
    try:
        import uuid as uuid_module
        from app.models.db_models import Session
        
        # Convert session_id to UUID
        try:
            session_uuid = uuid_module.UUID(session_id)
        except (ValueError, AttributeError):
            raise HTTPException(status_code=400, detail="Invalid session ID format")
        
        # Verify session exists
        session = db.query(Session).filter(Session.id == session_uuid).first()
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")

        reservation_service = ReservationService(db)
        reservations = reservation_service.get_upcoming_queue(session_id=session_uuid)

        # Build queue response
        queue = []
        current_position = 0
        
        for res in reservations:
            song = db.query(Song).filter(Song.id == res.song_id).first()
            if song:
                # Parse duration (stored as string for SQLite compat)
                duration = 0
                try:
                    duration = int(song.duration) if song.duration else 0
                except (ValueError, TypeError):
                    duration = 0

                queue_item = {
                    "position": res.position,
                    "id": str(res.id),
                    "song_id": str(res.song_id),
                    "title": song.title,
                    "artist": song.artist or "",
                    "reserved_by": str(res.user_id),
                    "status": res.status.value,
                    "duration_seconds": duration,
                }
                queue.append(queue_item)

                # Track currently playing
                if res.status.value == "playing":
                    current_position = res.position

        return QueueResponse(
            queue=queue,
            current_position=current_position,
            total=len([r for r in reservations if r.status.value == "pending"]),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error getting queue: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get queue")
