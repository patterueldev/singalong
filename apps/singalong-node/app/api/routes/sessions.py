"""Session management endpoints"""

import logging
import uuid
from typing import Optional
from fastapi import APIRouter, HTTPException, Depends, Query, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session as SQLSession
from sqlalchemy import asc, desc

from app.database import get_db
from app.middleware.auth import verify_bearer_token, verify_admin_role
from app.services.session_service import SessionService
from app.services.node_session_event_handlers import NodeSessionEventHandlers
from app.api.dependencies import get_current_user, TokenPayload
from app.models import db_models
from app.models.db_models import ReservationStatus

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/sessions", tags=["Sessions"])


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================


def _validate_session_exists(session_code: str, db: SQLSession) -> db_models.Session:
    """
    Validate session exists by numeric code (4-digit string like "0001").

    Raises HTTPException 404 if not found.
    Returns the session object if found.
    """
    session = db.query(db_models.Session).filter(db_models.Session.code == session_code).first()

    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    return session


def _check_session_authorization(
    session: db_models.Session, token: TokenPayload, allow_admin_only: bool = False
) -> None:
    """
    Check if user is authorized to modify session.

    Admin: always allowed
    Creator: allowed if allow_admin_only=False
    Others: 403 Forbidden
    """
    if token.role == "admin":
        return

    if allow_admin_only:
        raise HTTPException(status_code=403, detail="Only admins can perform this action")

    # Check if creator
    if str(session.created_by) != token.sub:
        raise HTTPException(
            status_code=403, detail="Only session creator or admin can perform this action"
        )


async def optional_verify_bearer_token(
    authorization: Optional[str] = None,
) -> Optional[dict]:
    """
    Optional Bearer token verification.

    Returns token payload if provided, None otherwise.
    """
    if not authorization or not authorization.startswith("Bearer "):
        return None

    try:
        # Extract token
        token = authorization.split(" ", 1)[1]
        # Could verify here if needed, but for MVP just pass through
        return {"token": token}
    except:
        return None


class CreateSessionRequest(BaseModel):
    """Create session request"""

    title: str = Field(..., min_length=1, max_length=255, description="Session title")
    vibes: str = Field(default="", description="Comma-separated vibes (party, chill, etc)")
    max_users: int = Field(default=0, ge=0, description="Max users (0=unlimited)")


class UpdateSessionRequest(BaseModel):
    """Update session request"""

    title: Optional[str] = Field(None, min_length=1, max_length=255, description="Session title")
    vibes: Optional[str] = Field(None, max_length=500, description="Session vibes")
    status: Optional[str] = Field(
        None, pattern="^(active|paused|ended)$", description="Session status"
    )


class SessionResponse(BaseModel):
    """Session response"""

    code: str = Field(..., description="4-digit session code (0000-9998)")
    title: str = Field(..., description="Session title")
    vibes: str = Field(default="", description="Session vibes")
    max_users: int = Field(default=0, description="Max users")
    status: str = Field(..., description="Session status (active, paused, ended)")
    created_at: str = Field(..., description="Creation timestamp")
    created_by: str = Field(..., description="Creator user ID")
    user_count: int = Field(default=0, description="Current user count")


class SessionUserResponse(BaseModel):
    """Session user info"""

    user_id: str = Field(..., description="User UUID")
    joined_at: str = Field(..., description="Join timestamp")


class AttendeeResponse(BaseModel):
    """Attendee info by nickname"""

    user_id: str = Field(..., description="User UUID")
    nickname: str = Field(..., description="User nickname")
    role: str = Field(..., description="User role (admin, controller, player)")
    joined_at: str = Field(..., description="Join timestamp")


class SessionDetailsResponse(BaseModel):
    """Detailed session info"""

    code: str = Field(..., description="4-digit session code (0000-9998)")
    title: str = Field(..., description="Session title")
    vibes: str = Field(default="", description="Session vibes")
    status: str = Field(..., description="Session status")
    max_users: int = Field(default=0, description="Max users")
    users: list[SessionUserResponse] = Field(default_factory=list, description="Users in session")
    user_count: int = Field(default=0, description="Current user count")
    created_at: str = Field(..., description="Creation timestamp")
    created_by: str = Field(..., description="Creator user ID")
    player_id: Optional[str] = Field(None, description="Locked player ID (None if not assigned)")
    player_name: Optional[str] = Field(None, description="Locked player name (None if not assigned)")


class QueueItemResponse(BaseModel):
    """Queue item response"""

    queue_id: str = Field(..., description="Queue item UUID")
    song_id: str = Field(..., description="Song UUID")
    song_title: str = Field(..., description="Song title")
    position: int = Field(..., description="Position in queue (1-based)")
    status: str = Field(..., description="Queue item status")
    owner_id: Optional[str] = Field(None, description="User ID who reserved")
    owner_nickname: Optional[str] = Field(None, description="Nickname of user who reserved")
    queued_at: str = Field(..., description="Reservation timestamp")


class PlaybackResponse(BaseModel):
    """Playback status response"""

    queue_id: Optional[str] = Field(None, description="Currently playing queue item ID")
    song_id: Optional[str] = Field(None, description="Currently playing song ID")
    position: Optional[int] = Field(None, description="Current song position in queue")
    status: Optional[str] = Field(None, description="Playback status (playing, paused, stopped)")
    progress_seconds: Optional[int] = Field(
        None, description="Current playback progress in seconds"
    )
    duration_seconds: Optional[int] = Field(None, description="Song duration in seconds")
    started_at: Optional[str] = Field(None, description="When playback started")
    paused_at: Optional[str] = Field(None, description="When playback was paused (null if playing)")
    player_id: Optional[str] = Field(None, description="Which player is playing")


class SessionStateResponse(BaseModel):
    """Complete session state response (for initial frontend load)"""

    session: SessionDetailsResponse = Field(..., description="Session metadata")
    player: Optional[PlaybackResponse] = Field(None, description="Current playback state (null if nothing playing)")
    queue: list[QueueItemResponse] = Field(default_factory=list, description="Queue items")


@router.get("", status_code=200, response_model=dict)
async def list_sessions(
    status_filter: Optional[str] = Query(
        None, pattern="^(active|paused|ended)$", description="Filter by status"
    ),
    offset: int = Query(0, ge=0, description="Pagination offset"),
    limit: int = Query(50, ge=1, le=100, description="Results per page"),
    db: SQLSession = Depends(get_db),
    admin: dict = Depends(verify_admin_role),
) -> dict:
    """
    List all sessions (paginated).

    Admin: sees all sessions
    Controller: sees only sessions they've joined

    Query Parameters:
    - status: Optional filter (active, paused, ended)
    - offset: Pagination offset
    - limit: Results per page

    Returns:
    {
      "sessions": [SessionResponse],
      "total": 42,
      "offset": 0,
      "limit": 50
    }
    """
    try:
        # Build query
        query = db.query(db_models.Session)

        # Filter by status if provided
        if status_filter:
            query = query.filter(db_models.Session.status == status_filter)

        # Count total
        total = query.count()

        # Paginate
        sessions = (
            query.order_by(desc(db_models.Session.created_at)).offset(offset).limit(limit).all()
        )

        # Build response
        session_list = []
        for session in sessions:
            user_count = (
                db.query(db_models.SessionUser)
                .filter(db_models.SessionUser.session_code == session.code)
                .count()
            )

            session_list.append(
                SessionResponse(
                    code=session.code,
                    title=session.title,
                    vibes=session.vibes or "",
                    max_users=int(session.max_users) if session.max_users else 0,
                    status=session.status.value,
                    created_at=session.created_at.isoformat(),
                    created_by=str(session.created_by),
                    user_count=user_count,
                )
            )

        return {
            "sessions": session_list,
            "total": total,
            "offset": offset,
            "limit": limit,
        }

    except Exception as e:
        logger.exception(f"Error listing sessions: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to list sessions")


@router.post("", status_code=201, response_model=SessionResponse)
async def create_session(
    request: CreateSessionRequest,
    db: SQLSession = Depends(get_db),
    admin: dict = Depends(verify_admin_role),
) -> SessionResponse:
    """
    Create a new karaoke session (admin only).

    Args:
        request: CreateSessionRequest with title and optional vibes/max_users
        db: Database session
        admin: Bearer token for authorization (admin role required)

    Returns:
        SessionResponse with session_code and code

    Raises:
        HTTPException: 400 if validation fails, 403 if not admin, 500 if database error
    """
    try:
        session_service = SessionService(db)

        # Create session
        session = session_service.create_session(
            title=request.title,
            created_by_user_id=admin.get("sub"),
            vibes=request.vibes if request.vibes else None,
            max_users=request.max_users if request.max_users > 0 else None,
        )

        logger.info(f"Session created: {session.code}")

        return SessionResponse(
            code=session.code,
            title=session.title,
            vibes=session.vibes or "",
            max_users=int(session.max_users) if session.max_users else 0,
            status=session.status.value,
            created_at=session.created_at.isoformat(),
            created_by=str(session.created_by),
            user_count=0,
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error creating session: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to create session")


@router.get("/{session_code}", response_model=SessionDetailsResponse)
async def get_session_details(
    session_code: str,
    db: SQLSession = Depends(get_db),
    admin: dict = Depends(verify_admin_role),
) -> SessionDetailsResponse:
    """
    Get detailed session information.

    Args:
        session_code: Session UUID or code
        db: Database session

    Returns:
        SessionDetailsResponse with users and stats

    Raises:
        HTTPException: 404 if session not found
    """
    try:
        session = _validate_session_exists(session_code, db)

        # Get users
        user_data = (
            db.query(db_models.SessionUser)
            .filter(db_models.SessionUser.session_code == session.code)
            .all()
        )

        users = [
            SessionUserResponse(
                user_id=str(u.user_id),
                joined_at=u.joined_at.isoformat(),
            )
            for u in user_data
        ]

        user_count = len(users)

        return SessionDetailsResponse(
            session_code=str(session.code),
            code=session.code,
            title=session.title,
            vibes=session.vibes or "",
            status=session.status.value,
            max_users=int(session.max_users) if session.max_users else 0,
            users=users,
            user_count=user_count,
            created_at=session.created_at.isoformat(),
            created_by=str(session.created_by),
            player_id=session.player_id,
            player_name=session.player_name,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error getting session: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get session")


@router.put("/{session_code}", response_model=SessionResponse)
async def update_session(
    session_code: str,
    request: UpdateSessionRequest,
    db: SQLSession = Depends(get_db),
    admin: dict = Depends(verify_admin_role),
) -> SessionResponse:
    """
    Update session metadata (admin/creator only).

    Can update: title, vibes, status

    Auth: Admin only
    """
    try:
        session = _validate_session_exists(session_code, db)

        # Update fields
        if request.title:
            session.title = request.title
        if request.vibes is not None:
            session.vibes = request.vibes
        if request.status:
            session.status = request.status

        db.commit()
        logger.info(f"Session updated: {session.code}")

        user_count = (
            db.query(db_models.SessionUser)
            .filter(db_models.SessionUser.session_code == session.code)
            .count()
        )

        return SessionResponse(
            session_code=str(session.code),
            code=session.code,
            title=session.title,
            vibes=session.vibes or "",
            max_users=int(session.max_users) if session.max_users else 0,
            status=session.status.value,
            created_at=session.created_at.isoformat(),
            created_by=str(session.created_by),
            user_count=user_count,
        )

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.exception(f"Error updating session: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to update session")


@router.delete("/{session_code}", status_code=204)
async def delete_session(
    session_code: str,
    db: SQLSession = Depends(get_db),
    admin: dict = Depends(verify_admin_role),
):
    """
    End/archive session (admin only).

    Sets status=ended, ended_at=now
    Cannot delete session 9999 (default session)

    Auth: Admin only
    """
    try:
        session = _validate_session_exists(session_code, db)

        # Cannot delete default session 9999
        if session.code == "9999":
            raise HTTPException(status_code=400, detail="Cannot delete default session (9999)")

        # Set status to ended
        session.status = db_models.SessionStatus.ENDED
        session.ended_at = db_models.utc_now()

        db.commit()
        logger.info(f"Session ended: {session.code}")

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.exception(f"Error deleting session: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to end session")


@router.get("/{session_code}/attendees", response_model=dict)
async def get_attendees(
    session_code: str,
    db: SQLSession = Depends(get_db),
    admin: dict = Depends(verify_admin_role),
) -> dict:
    """
    List attendees (users) in session by nickname.

    Returns list of users with nicknames, roles, and join timestamps.
    """
    try:
        session = _validate_session_exists(session_code, db)

        # Query users in session
        session_users = (
            db.query(db_models.SessionUser)
            .filter(db_models.SessionUser.session_code == session.code)
            .order_by(asc(db_models.SessionUser.joined_at))
            .all()
        )

        attendees = [
            AttendeeResponse(
                user_id=str(u.user_id),
                nickname=str(u.user_id)[:8],  # TODO: Fetch nickname from User table
                role="controller",  # TODO: Fetch actual role from JWT/User
                joined_at=u.joined_at.isoformat(),
            )
            for u in session_users
        ]

        return {
            "attendees": attendees,
            "total": len(attendees),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error listing attendees: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to list attendees")


# ============================================================================
# QUEUE ENDPOINTS (renamed from RESERVATIONS)
# ============================================================================


@router.get("/{session_code}/queue", response_model=dict)
async def list_queue(
    session_code: str,
    user: TokenPayload = Depends(get_current_user),
    db: SQLSession = Depends(get_db),
) -> dict:
    """
    Get all songs reserved in this session (queue), ordered by position.

    Endpoint: GET /api/sessions/{session_code}/queue

    Authorization:
    - Admin: Can view any session queue
    - Controller: Can view session queue

    Returns:
    - queue: Array of queue items
    - total: Number of items in queue
    """

    try:
        session = _validate_session_exists(session_code, db)

        # Query reservations for this session (no join - data is denormalized)
        reservations = (
            db.query(db_models.Reservation)
            .filter(db_models.Reservation.session_code == session.code)
            .order_by(asc(db_models.Reservation.position))
            .all()
        )

        # Build response from denormalized reservation data
        queue_list = [
            QueueItemResponse(
                queue_id=str(r.id),
                song_id=str(r.song_id),
                song_title=r.song_title or "Unknown Song",
                position=r.position,
                status=r.status.value,
                owner_nickname=r.reserved_by_nickname,
                owner_id=str(r.user_id) if r.user_id else None,
                queued_at=r.reserved_at.isoformat() if r.reserved_at else None,
            )
            for r in reservations
        ]

        return {
            "queue": queue_list,
            "total": len(queue_list),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error listing queue: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to fetch queue")


@router.post("/{session_code}/queue", status_code=201, response_model=dict)
async def add_to_queue(
    session_code: str,
    song_id: str = Query(..., description="Song ID to reserve"),
    reserved_by_user_id: Optional[str] = Query(
        None, description="User ID reserving the song (admin only)"
    ),
    user: TokenPayload = Depends(get_current_user),
    db: SQLSession = Depends(get_db),
) -> dict:
    """
    Add song to queue (reserve) in this session.

    Endpoint: POST /api/sessions/{session_code}/queue?song_id={id}

    Authorization:
    - Controller: Can reserve for themselves
    - Admin: Can reserve for any user

    Returns:
    - queue_id: UUID of the new reservation
    - position: Position in queue
    """

    try:
        session = _validate_session_exists(session_code, db)
        
        # Only admin can use reserved_by_user_id parameter
        if reserved_by_user_id and user.role != "admin":
            raise HTTPException(
                status_code=403,
                detail="Only admins can reserve songs for other users"
            )

        # Verify song exists and is ACTIVE
        try:
            song_uuid = uuid.UUID(song_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid song ID format")

        song = (
            db.query(db_models.Song)
            .filter(db_models.Song.id == song_uuid, db_models.Song.status == "ACTIVE")
            .first()
        )

        if not song:
            raise HTTPException(status_code=404, detail="Song not found or not available")

        # Get next position
        max_position = (
            db.query(db_models.Reservation)
            .filter(db_models.Reservation.session_code == session.code)
            .with_entities(db_models.Reservation.position)
            .order_by(desc(db_models.Reservation.position))
            .first()
        )

        next_position = (max_position[0] if max_position else 0) + 1

        # Get the user's actual nickname from the User table
        actual_user = None
        if user.sub:
            try:
                actual_user = db.query(db_models.User).filter(
                    db_models.User.id == uuid.UUID(user.sub)
                ).first()
            except (ValueError, TypeError):
                pass
        
        owner_nickname = actual_user.nickname_or_username if actual_user else None
        owner_id = uuid.UUID(user.sub) if user.sub else None
        
        # If admin is reserving for another user
        if reserved_by_user_id:
            try:
                other_user = db.query(db_models.User).filter(
                    db_models.User.id == uuid.UUID(reserved_by_user_id)
                ).first()
                owner_nickname = other_user.nickname_or_username if other_user else f"User-{reserved_by_user_id[:8]}"
                owner_id = uuid.UUID(reserved_by_user_id)
            except (ValueError, TypeError):
                owner_nickname = f"User-{reserved_by_user_id[:8]}"
                owner_id = uuid.UUID(reserved_by_user_id) if reserved_by_user_id else None

        # Create reservation (denormalized with song title snapshot)
        reservation = db_models.Reservation(
            id=uuid.uuid4(),
            session_code=session.code,
            song_id=song_uuid,
            song_title=song.title,  # Store song title at reservation time
            user_id=owner_id,
            reserved_by_nickname=owner_nickname,
            position=next_position,
            status=ReservationStatus.PENDING,
        )

        db.add(reservation)
        db.commit()

        logger.info(f"Added to queue: {song.title} at position {next_position}")

        # Broadcast queue update to all connected WebSocket clients
        logger.info(f"[BROADCAST] About to broadcast queue:updated for session {session.code} | type={type(session.code).__name__}")
        try:
            await NodeSessionEventHandlers.broadcast_queue_updated(session.code)
            logger.info(f"[BROADCAST] Successfully broadcast queue:updated for session {session.code}")
        except Exception as e:
            logger.warning(f"[BROADCAST] Failed to broadcast queue update: {str(e)}", exc_info=True)

        return {
            "queue_id": str(reservation.id),
            "song_id": str(reservation.song_id),
            "song_title": song.title,
            "position": next_position,
            "status": reservation.status.value,
            "owner_id": str(owner_id) if owner_id else None,
            "owner_nickname": owner_nickname,
            "queued_at": reservation.reserved_at.isoformat(),
        }

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error adding to queue: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to add to queue")


@router.delete("/{session_code}/queue/{queue_id}", status_code=204)
async def remove_from_queue(
    session_code: str,
    queue_id: str,
    user: TokenPayload = Depends(get_current_user),
    db: SQLSession = Depends(get_db),
):
    """
    Remove song from queue (cancel reservation).

    Endpoint: DELETE /api/sessions/{session_code}/queue/{queue_id}

    Authorization:
    - Admin: Can cancel any reservation
    - Controller: Can only cancel own reservations
    """

    try:
        session = _validate_session_exists(session_code, db)

        # Parse UUID
        try:
            queue_uuid = uuid.UUID(queue_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid queue ID")

        # Find reservation
        reservation = (
            db.query(db_models.Reservation)
            .filter(
                db_models.Reservation.id == queue_uuid,
                db_models.Reservation.session_code == session.code,
            )
            .first()
        )

        if not reservation:
            raise HTTPException(status_code=404, detail="Queue item not found")

        # Authorization check
        if user.role != "admin" and str(reservation.user_id) != user.sub:
            raise HTTPException(status_code=403, detail="You can only remove your own reservations")

        # Get the position of deleted reservation
        cancelled_position = reservation.position

        # Delete reservation
        db.delete(reservation)
        db.flush()

        # Re-number remaining reservations with higher positions
        higher_reservations = (
            db.query(db_models.Reservation)
            .filter(
                db_models.Reservation.session_code == session.code,
                db_models.Reservation.position > cancelled_position,
            )
            .order_by(asc(db_models.Reservation.position))
            .all()
        )

        for i, res in enumerate(higher_reservations, start=cancelled_position):
            res.position = i

        db.commit()
        logger.info(f"Removed from queue {queue_id}, re-numbered {len(higher_reservations)} items")

        # Broadcast queue update to all connected WebSocket clients
        try:
            await NodeSessionEventHandlers.broadcast_queue_updated(session.code)
        except Exception as e:
            logger.warning(f"Failed to broadcast queue update: {str(e)}")

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error removing from queue: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to remove from queue")


@router.patch("/{session_code}/queue/{queue_id}/change-order", status_code=200, response_model=dict)
async def change_queue_order(
    session_code: str,
    queue_id: str,
    new_position: int = Query(..., ge=1, description="New position in queue"),
    user: TokenPayload = Depends(get_current_user),
    db: SQLSession = Depends(get_db),
) -> dict:
    """
    Move queue item to different position (admin only).

    Endpoint: PATCH /api/sessions/{session_code}/queue/{queue_id}/change-order?new_position={pos}

    Authorization: Admin only
    """

    try:
        session = _validate_session_exists(session_code, db)

        # Admin only
        if user.role != "admin":
            raise HTTPException(status_code=403, detail="Only admins can reorder queue")

        # Parse UUID
        try:
            queue_uuid = uuid.UUID(queue_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid queue ID")

        # Find reservation
        reservation = (
            db.query(db_models.Reservation)
            .filter(
                db_models.Reservation.id == queue_uuid,
                db_models.Reservation.session_code == session.code,
            )
            .first()
        )

        if not reservation:
            raise HTTPException(status_code=404, detail="Queue item not found")

        # Get all reservations for this session
        all_reservations = (
            db.query(db_models.Reservation)
            .filter(db_models.Reservation.session_code == session.code)
            .order_by(asc(db_models.Reservation.position))
            .all()
        )

        # Validate new_position is within bounds
        if new_position < 1 or new_position > len(all_reservations):
            raise HTTPException(
                status_code=400,
                detail=f"New position must be between 1 and {len(all_reservations)}",
            )

        # Get current position
        current_position = reservation.position

        if current_position == new_position:
            # No change needed
            return {
                "queue_id": queue_id,
                "position": new_position,
            }

        # Algorithm: shift items between old and new position
        if current_position < new_position:
            # Moving down: shift items 3,4 to 2,3
            for res in all_reservations:
                if current_position < res.position <= new_position:
                    res.position -= 1
        else:
            # Moving up: shift items 2,3 to 3,4
            for res in all_reservations:
                if new_position <= res.position < current_position:
                    res.position += 1

        # Set target position
        reservation.position = new_position

        db.commit()
        logger.info(f"Moved queue item from position {current_position} to {new_position}")

        # Broadcast queue update to all connected WebSocket clients
        try:
            await NodeSessionEventHandlers.broadcast_queue_updated(session.code)
        except Exception as e:
            logger.warning(f"Failed to broadcast queue update: {str(e)}")

        return {
            "queue_id": queue_id,
            "position": new_position,
        }

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error changing queue order: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to change queue order")


@router.get("/{session_code}/state", response_model=SessionStateResponse)
async def get_session_state(
    session_code: str,
    user: TokenPayload = Depends(get_current_user),
    db: SQLSession = Depends(get_db),
) -> SessionStateResponse:
    """
    Get complete session state for initial frontend load.

    Combines session metadata, current playback state, and queue.
    Used by frontend on landing page to populate initial UI state.

    Endpoint: GET /api/sessions/{session_code}/state

    Authorization:
    - Admin: Can view any session state
    - Controller: Can view session state
    - Player: Can view session state

    Returns:
    - session: Session metadata (title, vibes, status, etc.)
    - player: Current playback state (null if nothing playing)
    - queue: Array of queued songs

    Example Response:
    ```json
    {
      "session": {
        "code": "9999",
        "title": "Birthday Party",
        "vibes": "upbeat",
        "status": "active",
        "user_count": 5,
        "created_at": "2026-05-02T10:00:00Z",
        "created_by": "admin-uuid",
        "max_users": 50
      },
      "player": {
        "queue_id": "queue-uuid",
        "song_id": "song-uuid",
        "status": "playing",
        "progress_seconds": 45,
        "duration_seconds": 240,
        "started_at": "2026-05-02T10:15:00Z"
      },
      "queue": [
        {
          "queue_id": "queue-1",
          "song_id": "song-1",
          "song_title": "Song Title",
          "position": 1,
          "status": "playing",
          "owner_nickname": "John",
          "queued_at": "2026-05-02T10:10:00Z"
        },
        {
          "queue_id": "queue-2",
          "song_id": "song-2",
          "song_title": "Another Song",
          "position": 2,
          "status": "pending",
          "owner_nickname": "Jane",
          "queued_at": "2026-05-02T10:12:00Z"
        }
      ]
    }
    ```
    """
    try:
        session = _validate_session_exists(session_code, db)

        # Get session details
        session_users = db.query(db_models.SessionUser).filter(
            db_models.SessionUser.session_code == session.code
        ).all()

        session_details = SessionDetailsResponse(
            code=session.code,
            title=session.title,
            vibes=session.vibes or "",
            status=session.status,
            max_users=session.max_users,
            users=[
                SessionUserResponse(
                    user_id=str(su.user_id),
                    joined_at=su.joined_at.isoformat() if su.joined_at else "",
                )
                for su in session_users
            ],
            user_count=len(session_users),
            created_at=session.created_at.isoformat() if session.created_at else "",
            created_by=str(session.created_by) if session.created_by else "",
        )

        # Get current playback state
        playback_data = None
        playback = db.query(db_models.Playback).filter(
            db_models.Playback.session_code == session.code
        ).first()

        if playback and playback.queue_id:
            # Get song details if available
            song_data = None
            if playback.song_id:
                song = db.query(db_models.Song).filter(db_models.Song.id == playback.song_id).first()
                if song:
                    song_data = {
                        "id": str(song.id),
                        "title": song.title,
                        "artist": song.artist,
                        "duration_seconds": song.duration,
                    }

            # Calculate progress
            progress_seconds = 0
            if playback.started_at:
                from datetime import datetime, timezone
                elapsed = (datetime.now(timezone.utc) - playback.started_at).total_seconds()
                if playback.paused_at:
                    elapsed = (playback.paused_at - playback.started_at).total_seconds()
                progress_seconds = int(elapsed)

            # Determine playback status
            playback_status = "stopped"
            if playback.paused_at:
                playback_status = "paused"
            elif playback.started_at:
                playback_status = "playing"

            playback_data = PlaybackResponse(
                queue_id=str(playback.queue_id),
                song_id=str(playback.song_id) if playback.song_id else None,
                position=None,
                status=playback_status,
                progress_seconds=progress_seconds,
                duration_seconds=playback.duration_seconds,
                started_at=playback.started_at.isoformat() if playback.started_at else None,
                paused_at=playback.paused_at.isoformat() if playback.paused_at else None,
                player_id=str(playback.player_id) if playback.player_id else None,
            )

        # Get queue
        reservations = (
            db.query(db_models.Reservation)
            .filter(db_models.Reservation.session_code == session.code)
            .order_by(asc(db_models.Reservation.position))
            .all()
        )

        queue_list = [
            QueueItemResponse(
                queue_id=str(r.id),
                song_id=str(r.song_id),
                song_title=r.song_title or "Unknown Song",
                position=r.position,
                status=r.status.value,
                owner_nickname=r.reserved_by_nickname,
                owner_id=str(r.user_id) if r.user_id else None,
                queued_at=r.reserved_at.isoformat() if r.reserved_at else None,
            )
            for r in reservations
        ]

        return SessionStateResponse(
            session=session_details,
            player=playback_data,
            queue=queue_list,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error getting session state: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get session state")


@router.get("/{session_code}/playback", response_model=Optional[dict])
async def get_playback_status(
    session_code: str,
    db: SQLSession = Depends(get_db),
    admin: dict = Depends(verify_admin_role),
) -> Optional[dict]:
    """
    Get current playback status for session.

    Returns null if nothing playing, otherwise returns current song with progress.
    """
    try:
        session = _validate_session_exists(session_code, db)

        # Query playback for this session
        playback = (
            db.query(db_models.Playback).filter(db_models.Playback.session_code == session.code).first()
        )

        if not playback or not playback.queue_id:
            # No playback active
            return None

        # Get song details if available
        song_data = None
        if playback.song_id:
            song = db.query(db_models.Song).filter(db_models.Song.id == playback.song_id).first()
            if song:
                song_data = {
                    "id": str(song.id),
                    "title": song.title,
                    "artist": song.artist,
                    "duration_seconds": song.duration,
                }

        # Calculate progress
        progress_seconds = 0
        if playback.started_at:
            from datetime import datetime, timezone

            elapsed = (datetime.now(timezone.utc) - playback.started_at).total_seconds()
            if playback.paused_at:
                # Paused: use time until paused
                elapsed = (playback.paused_at - playback.started_at).total_seconds()
            progress_seconds = int(elapsed)

        # Determine playback status
        playback_status = "stopped"
        if playback.paused_at:
            playback_status = "paused"
        elif playback.started_at:
            playback_status = "playing"

        return PlaybackResponse(
            queue_id=str(playback.queue_id),
            song_id=str(playback.song_id) if playback.song_id else None,
            position=None,  # TODO: Get position from queue
            status=playback_status,
            progress_seconds=progress_seconds,
            duration_seconds=playback.duration_seconds,
            started_at=playback.started_at.isoformat() if playback.started_at else None,
            paused_at=playback.paused_at.isoformat() if playback.paused_at else None,
            player_id=str(playback.player_id) if playback.player_id else None,
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error getting playback status: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get playback status")

# ============================================================================
# PLAYER MANAGEMENT ENDPOINTS (P2: Player Discovery)
# ============================================================================


class PlayerInfo(BaseModel):
    """Player information"""
    id: str
    name: str
    platform: str
    status: str


class SelectPlayerRequest(BaseModel):
    """Request to select/lock a player to a session"""
    player_id: str


class SelectPlayerResponse(BaseModel):
    """Response after selecting a player"""
    success: bool
    player_id: str
    player_name: str
    message: str


@router.post("/{session_code}/select-player", status_code=200, response_model=SelectPlayerResponse)
async def select_player(
    session_code: str,
    request: SelectPlayerRequest,
    db: SQLSession = Depends(get_db),
    token: TokenPayload = Depends(verify_bearer_token),
) -> SelectPlayerResponse:
    """
    Select and lock a player to a session.
    
    When an admin selects a player:
    1. Node sends lock message to player over discovery WebSocket
    2. Player closes discovery connection, opens playback connection
    3. Discovery WebSocket server stops (no new player registrations)
    4. Session transitions to playback mode
    
    **Request**:
    ```json
    {
      "player_id": "player-uuid"
    }
    ```
    
    **Response**:
    ```json
    {
      "success": true,
      "player_id": "player-uuid",
      "player_name": "Pat's MacBook",
      "message": "Player locked to session"
    }
    ```
    """
    try:
        # Validate session exists and is active
        session = _validate_session_exists(session_code, db)
        if session.status.value != "active":
            raise HTTPException(
                status_code=400,
                detail=f"Session is not active (status: {session.status.value})",
            )
        
        # Check authorization (admin only)
        _check_session_authorization(session, token, allow_admin_only=True)
        
        # Get player from discovery manager
        from app.services.player_discovery_manager import PlayerDiscoveryManager
        discovery_manager = PlayerDiscoveryManager.get_instance()
        
        player = discovery_manager.get_player(request.player_id)
        if not player:
            raise HTTPException(status_code=404, detail="Player not found")
        
        if player.status != "discovering":
            raise HTTPException(
                status_code=409,
                detail=f"Player is not available (status: {player.status})",
            )
        
        # Lock player to session
        discovery_manager.lock_player(request.player_id, session_code)
        
        # Update session with player info
        session.player_id = request.player_id
        session.player_name = player.name
        db.commit()
        
        # Send lock message to player over WebSocket
        if player.ws_connection:
            try:
                import json
                lock_message = {
                    "type": "lock",
                    "session_code": session_code,
                    "token": "placeholder-token",  # TODO: Generate real token
                }
                await player.ws_connection.send_json(lock_message)
                logger.info(
                    f"[API] Lock message sent to player | "
                    f"player_id={request.player_id} | session={session_code}"
                )
            except Exception as e:
                logger.warning(
                    f"[API] Failed to send lock message to player | error={str(e)}"
                )
                # Don't fail the request if WS send fails
        
        logger.info(
            f"[API] Player selected and locked | player_id={request.player_id} | "
            f"session={session_code} | player_name={player.name}"
        )
        
        return SelectPlayerResponse(
            success=True,
            player_id=request.player_id,
            player_name=player.name,
            message="Player locked to session",
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error selecting player: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to select player")
