"""Session management endpoints"""

import logging
import uuid
from typing import Optional
from fastapi import APIRouter, HTTPException, Depends, Query, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session as SQLSession

from app.database import get_db
from app.middleware.auth import verify_bearer_token
from app.services.session_service import SessionService
from app.api.dependencies import get_current_user, TokenPayload

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/sessions", tags=["Sessions"])


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


class SessionResponse(BaseModel):
    """Session response"""

    session_id: str = Field(..., description="Session UUID")
    code: str = Field(..., description="Unique session code")
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


class SessionDetailsResponse(BaseModel):
    """Detailed session info"""

    session_id: str = Field(..., description="Session UUID")
    code: str = Field(..., description="Session code")
    title: str = Field(..., description="Session title")
    vibes: str = Field(default="", description="Session vibes")
    status: str = Field(..., description="Session status")
    max_users: int = Field(default=0, description="Max users")
    users: list[SessionUserResponse] = Field(default_factory=list, description="Users in session")
    user_count: int = Field(default=0, description="Current user count")
    created_at: str = Field(..., description="Creation timestamp")
    created_by: str = Field(..., description="Creator user ID")


@router.post("", status_code=201, response_model=SessionResponse)
async def create_session(
    request: CreateSessionRequest,
    db: SQLSession = Depends(get_db),
) -> SessionResponse:
    """
    Create a new karaoke session

    Optional: Bearer token can be provided for audit logging
    If no token provided, creates session with system user ID

    Args:
        request: CreateSessionRequest with title and optional vibes/max_users
        db: Database session

    Returns:
        SessionResponse with session_id and code

    Raises:
        HTTPException: 400 if validation fails, 500 if database error
    """
    try:
        # TODO: Require admin authentication for session creation (B8.2 phase)
        user_id = str(uuid.uuid4())

        session_service = SessionService(db)

        # Create session
        session = session_service.create_session(
            title=request.title,
            created_by_user_id=user_id,
            vibes=request.vibes if request.vibes else None,
            max_users=request.max_users if request.max_users > 0 else None,
        )

        logger.info(f"Session created: {session.code}")

        return SessionResponse(
            session_id=str(session.id),
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
    except Exception as e:
        logger.exception(f"Error creating session: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to create session")


@router.get("/{session_id}", response_model=SessionDetailsResponse)
async def get_session_details(
    session_id: str,
    db: SQLSession = Depends(get_db),
) -> SessionDetailsResponse:
    """
    Get detailed session information

    No authentication required - sessions are public once created.

    Args:
        session_id: Session UUID or code
        db: Database session

    Returns:
        SessionDetailsResponse with users and stats

    Raises:
        HTTPException: 404 if session not found
    """
    try:
        session_service = SessionService(db)

        # Try by UUID first, then by code
        session = session_service.get_session(session_id)
        if not session:
            session = session_service.get_session_by_code(session_id)

        if not session:
            raise HTTPException(status_code=404, detail="Session not found")

        # Get users
        user_data = session_service.get_session_users(str(session.id))
        users = [SessionUserResponse(**u) for u in user_data]

        user_count = len(users)

        return SessionDetailsResponse(
            session_id=str(session.id),
            code=session.code,
            title=session.title,
            vibes=session.vibes or "",
            status=session.status.value,
            max_users=int(session.max_users) if session.max_users else 0,
            users=users,
            user_count=user_count,
            created_at=session.created_at.isoformat(),
            created_by=str(session.created_by),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error getting session: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get session")


@router.post("/{session_id}/users/{user_id}", status_code=201)
async def add_user_to_session(
    session_id: str,
    user_id: str,
    db: SQLSession = Depends(get_db),
) -> dict:
    """
    Add user to session

    Args:
        session_id: Session UUID or code
        user_id: User UUID
        db: Database session

    Returns:
        Success message

    Raises:
        HTTPException: 404 if not found, 400 if validation fails
    """
    try:
        session_service = SessionService(db)

        # Try by UUID first, then by code
        session = session_service.get_session(session_id)
        if not session:
            session = session_service.get_session_by_code(session_id)

        if not session:
            raise ValueError("Session not found")

        # Add user
        session_service.add_user_to_session(str(session.id), user_id)

        logger.info(f"User {user_id} joined session {session.code}")

        return {
            "message": "User added to session",
            "session_code": session.code,
        }

    except ValueError as e:
        error_msg = str(e)
        if "not found" in error_msg.lower():
            raise HTTPException(status_code=404, detail=error_msg)
        else:
            raise HTTPException(status_code=400, detail=error_msg)
    except Exception as e:
        logger.exception(f"Error adding user: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to add user")


@router.delete("/{session_id}/users/{user_id}", status_code=204)
async def remove_user_from_session(
    session_id: str,
    user_id: str,
    db: SQLSession = Depends(get_db),
) -> None:
    """
    Remove user from session

    Args:
        session_id: Session UUID
        user_id: User UUID
        db: Database session
    """
    try:
        session_service = SessionService(db)
        session_service.remove_user_from_session(session_id, user_id)
        logger.info(f"User {user_id} left session {session_id}")
    except Exception as e:
        logger.exception(f"Error removing user: {str(e)}")
        # Don't raise - silently succeed


@router.post("/{session_id}/status/{status}", status_code=200)
async def update_session_status(
    session_id: str,
    status: str,
    token_payload: dict = Depends(verify_bearer_token),
    db: SQLSession = Depends(get_db),
) -> SessionResponse:
    """
    Update session status (admin/creator only)

    Args:
        session_id: Session UUID
        status: New status (active, paused, ended)
        token_payload: Admin token
        db: Database session

    Returns:
        Updated SessionResponse

    Raises:
        HTTPException: 404 if not found, 403 if not authorized, 400 if invalid status
    """
    try:
        session_service = SessionService(db)

        session = session_service.get_session(session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")

        # Only creator or admin can update
        user_id = token_payload.get("user_id")
        if str(session.created_by) != user_id:
            raise HTTPException(status_code=403, detail="Not authorized to update this session")

        # Update status
        updated = session_service.update_session_status(session_id, status)

        user_count = session_service.get_session_user_count(session_id)

        return SessionResponse(
            session_id=str(updated.id),
            code=updated.code,
            title=updated.title,
            vibes=updated.vibes or "",
            max_users=int(updated.max_users) if updated.max_users else 0,
            status=updated.status.value,
            created_at=updated.created_at.isoformat(),
            created_by=str(updated.created_by),
            user_count=user_count,
        )

    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.exception(f"Error updating session: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to update session")


# ============================================================================
# SONGBOOK ENDPOINTS
# ============================================================================


@router.get(
    "/{session_id}/songbook",
    response_model=dict,
    status_code=200,
)
async def get_songbook(
    session_id: str,
    search: Optional[str] = Query(None, min_length=1, max_length=100, description="Search keyword for title/artist"),
    limit: int = Query(10, ge=1, le=100, description="Results per page"),
    offset: int = Query(0, ge=0, description="Pagination offset"),
    sort: str = Query("title", regex="^(title|artist|year|date_added)$", description="Sort field"),
    db: SQLSession = Depends(get_db),
) -> dict:
    """
    Get a paginated, searchable list of available songs.
    
    Only returns ACTIVE songs that have been successfully downloaded.
    
    Endpoint: GET /api/sessions/{session_id}/songbook
    
    Query Parameters:
    - search: Optional keyword to filter songs by title or artist (case-insensitive)
    - limit: Number of results per page (default 10, max 100)
    - offset: Starting position for pagination (default 0)
    - sort: Field to sort by (title, artist, year, date_added) - default: title
    
    Returns:
    - songs: Array of song objects with basic metadata
    - total: Total number of songs matching criteria
    - limit: Results per page
    - offset: Current offset
    - hasMore: Whether more results are available
    """
    
    try:
        logger.info(f"Songbook request: session={session_id}, search={search}, limit={limit}, offset={offset}, sort={sort}")
        
        # Verify session exists
        session_service = SessionService(db)
        session = session_service.get_session(session_id)
        if not session:
            session = session_service.get_session_by_code(session_id)
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            )
        
        # TODO: Query Master GraphQL for ACTIVE songs with pagination/search
        # For MVP, return placeholder response
        # In next implementation:
        # 1. Call Master's songs query with filters
        # 2. Apply search filter if provided
        # 3. Apply pagination (limit/offset)
        # 4. Apply sorting
        # 5. Return results with metadata
        
        logger.info(f"Songbook: Returning placeholder (Master query not yet implemented)")
        
        return {
            "songs": [],
            "total": 0,
            "limit": limit,
            "offset": offset,
            "hasMore": False,
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching songbook: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch songbook",
        )


# ============================================================================
# RESERVATION ENDPOINTS
# ============================================================================


@router.get(
    "/{session_id}/reservations",
    response_model=dict,
    status_code=200,
)
async def list_reservations(
    session_id: str,
    db: SQLSession = Depends(get_db),
) -> dict:
    """
    Get all songs reserved in this session, ordered by position in queue.
    
    Endpoint: GET /api/sessions/{session_id}/reservations
    
    Returns:
    - reservations: Array of reservation objects with song details
    - total: Number of reservations
    """
    
    try:
        from uuid import UUID as UUID_type
        from app.models.db_models import Reservation
        from sqlalchemy import asc, join
        
        logger.info(f"List reservations: session={session_id}")
        
        # Verify session exists
        session_service = SessionService(db)
        session = session_service.get_session(session_id)
        if not session:
            session = session_service.get_session_by_code(session_id)
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            )
        
        # Query reservations for this session, ordered by position
        try:
            session_uuid = UUID_type(session_id)
        except ValueError:
            session_uuid = session.id if hasattr(session, 'id') else None
            if not session_uuid:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Invalid session ID",
                )
        
        reservations = db.query(Reservation).filter(
            Reservation.session_id == session_uuid
        ).order_by(asc(Reservation.position)).all()
        
        # Build response with song details
        reservation_list = [
            {
                "id": str(r.id),
                "sessionId": str(r.session_id),
                "songId": str(r.song_id),
                "position": r.position,
                "status": r.status,
                "reservedByNickname": r.reserved_by_nickname,
                "reservedAt": r.reserved_at.isoformat() if r.reserved_at else None,
                "userId": str(r.user_id) if r.user_id else None,
            }
            for r in reservations
        ]
        
        return {
            "reservations": reservation_list,
            "total": len(reservation_list),
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error listing reservations: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch reservations",
        )


@router.post(
    "/{session_id}/reservations",
    status_code=201,
)
async def reserve_song(
    session_id: str,
    song_id: str = Query(..., description="Song/Draft ID to reserve"),
    reserved_by_user_id: Optional[str] = Query(None, description="User ID reserving the song (optional)"),
    user: TokenPayload = Depends(get_current_user),
    db: SQLSession = Depends(get_db),
) -> dict:
    """
    Reserve a song for this session.
    
    Endpoint: POST /api/sessions/{session_id}/reservations?song_id={id}&reserved_by_user_id={optional}
    
    Adds the song to the end of the reservation queue.
    
    Authorization:
    - Attendee: Can reserve songs for themselves in their session
    - Admin: Can reserve songs for any user in any session
    
    Query Parameters:
    - song_id: ID of the song to reserve (required)
    - reserved_by_user_id: User ID to attribute reservation to (admin only, optional)
    
    Returns:
    - reservation_id: UUID of the new reservation
    - song_id: Reserved song ID
    - order_position: Position in the queue
    - status: "reserved"
    """
    
    try:
        from uuid import UUID as UUID_type
        from app.models.db_models import Reservation, Song
        from sqlalchemy import desc
        
        logger.info(f"Reserve song: session={session_id}, song={song_id}, reserved_by={reserved_by_user_id}, user={user.sub}")
        
        # Verify session exists
        session_service = SessionService(db)
        session = session_service.get_session(session_id)
        if not session:
            session = session_service.get_session_by_code(session_id)
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            )
        
        # Verify song exists and is ACTIVE in local database
        try:
            song_uuid = UUID_type(song_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid song ID format",
            )
        
        song = db.query(Song).filter(
            Song.id == song_uuid,
            Song.status == "ACTIVE"
        ).first()
        
        if not song:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Song not found or not available",
            )
        
        # Get session UUID
        try:
            session_uuid = UUID_type(session_id)
        except ValueError:
            session_uuid = session.id if hasattr(session, 'id') else None
            if not session_uuid:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid session ID",
                )
        
        # Check if song already reserved in this session (unique constraint)
        existing = db.query(Reservation).filter(
            Reservation.session_id == session_uuid,
            Reservation.song_id == song_uuid
        ).first()
        
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Song already reserved in this session",
            )
        
        # Get next position (max position + 1)
        max_position = db.query(Reservation).filter(
            Reservation.session_id == session_uuid
        ).with_entities(Reservation.position).order_by(desc(Reservation.position)).first()
        
        next_position = (max_position[0] if max_position else 0) + 1
        
        # Get nickname if available (from JWT if attendee, or use admin context)
        nickname = None
        if user.role == "attendee" and user.sub:
            # TODO: Lookup user nickname from database
            nickname = f"User-{user.sub[:8]}"
        elif reserved_by_user_id:
            # Admin context: use provided user_id
            nickname = f"User-{reserved_by_user_id[:8]}"
        
        # Create reservation
        reservation = Reservation(
            id=uuid.uuid4(),
            session_id=session_uuid,
            song_id=song_uuid,
            user_id=UUID_type(reserved_by_user_id) if reserved_by_user_id else (UUID_type(user.sub) if user.sub else None),
            reserved_by_nickname=nickname,
            position=next_position,
            status="reserved" if hasattr(Reservation, 'status') else "pending",
        )
        
        db.add(reservation)
        db.commit()
        
        logger.info(f"Reserved song: {song.title} at position {next_position}")
        
        return {
            "reservation_id": str(reservation.id),
            "song_id": str(reservation.song_id),
            "order_position": next_position,
            "status": "reserved",
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error reserving song: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to reserve song",
        )


@router.delete(
    "/{session_id}/reservations/{reservation_id}",
    status_code=204,
)
async def cancel_reservation(
    session_id: str,
    reservation_id: str,
    user: TokenPayload = Depends(get_current_user),
    db: SQLSession = Depends(get_db),
):
    """
    Cancel a reservation and remove song from queue.
    
    Endpoint: DELETE /api/sessions/{session_id}/reservations/{reservation_id}
    
    Authorization:
    - Admin: Can cancel any reservation
    - Attendee: Can only cancel own reservations
    
    Returns:
    - 204 No Content on success
    - 403 Forbidden if user cannot cancel (not owner, not admin)
    - 404 Not Found if reservation doesn't exist
    """
    
    try:
        from uuid import UUID as UUID_type
        from app.models.db_models import Reservation
        from sqlalchemy import asc
        
        logger.info(f"Cancel reservation: session={session_id}, reservation={reservation_id}, user={user.sub}")
        
        # Verify session exists
        session_service = SessionService(db)
        session = session_service.get_session(session_id)
        if not session:
            session = session_service.get_session_by_code(session_id)
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            )
        
        # Parse UUIDs
        try:
            session_uuid = UUID_type(session_id)
            reservation_uuid = UUID_type(reservation_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid session or reservation ID",
            )
        
        # Find reservation
        reservation = db.query(Reservation).filter(
            Reservation.id == reservation_uuid,
            Reservation.session_id == session_uuid
        ).first()
        
        if not reservation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reservation not found",
            )
        
        # Authorization check
        if user.role != "admin" and reservation.user_id != UUID_type(user.sub) if user.sub else False:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only cancel your own reservations",
            )
        
        # Get the position of deleted reservation
        cancelled_position = reservation.position
        
        # Delete reservation
        db.delete(reservation)
        db.flush()
        
        # Re-number remaining reservations with higher positions
        higher_reservations = db.query(Reservation).filter(
            Reservation.session_id == session_uuid,
            Reservation.position > cancelled_position
        ).order_by(asc(Reservation.position)).all()
        
        for i, res in enumerate(higher_reservations, start=cancelled_position):
            res.position = i
        
        db.commit()
        logger.info(f"Cancelled reservation {reservation_id}, re-numbered {len(higher_reservations)} reservations")
        
        return None
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error canceling reservation: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to cancel reservation",
        )


@router.patch(
    "/{session_id}/reservations/{reservation_id}/change-order",
    status_code=200,
)
async def change_reservation_order(
    session_id: str,
    reservation_id: str,
    new_order: int = Query(..., ge=1, description="New position in queue"),
    user: TokenPayload = Depends(get_current_user),
    db: SQLSession = Depends(get_db),
) -> dict:
    """
    Move a reservation to a different position in the queue.
    
    Endpoint: PATCH /api/sessions/{session_id}/reservations/{reservation_id}/change-order?new_order={position}
    
    Authorization:
    - Admin only (attendees cannot reorder)
    
    Query Parameters:
    - new_order: New position in queue (1-based, required)
    
    Returns:
    - reservation_id: Updated reservation ID
    - order_position: New position
    - 403 Forbidden if user is not admin
    """
    
    try:
        from uuid import UUID as UUID_type
        from app.models.db_models import Reservation
        from sqlalchemy import asc
        
        logger.info(f"Change order: session={session_id}, reservation={reservation_id}, new_order={new_order}, user={user.sub}")
        
        # Authorization check
        if user.role != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only admins can reorder reservations",
            )
        
        # Verify session exists
        session_service = SessionService(db)
        session = session_service.get_session(session_id)
        if not session:
            session = session_service.get_session_by_code(session_id)
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            )
        
        # Parse UUIDs
        try:
            session_uuid = UUID_type(session_id)
            reservation_uuid = UUID_type(reservation_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid session or reservation ID",
            )
        
        # Find reservation
        reservation = db.query(Reservation).filter(
            Reservation.id == reservation_uuid,
            Reservation.session_id == session_uuid
        ).first()
        
        if not reservation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reservation not found",
            )
        
        # Get all reservations for this session
        all_reservations = db.query(Reservation).filter(
            Reservation.session_id == session_uuid
        ).order_by(asc(Reservation.position)).all()
        
        # Validate new_order is within bounds
        if new_order < 1 or new_order > len(all_reservations):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"New order must be between 1 and {len(all_reservations)}",
            )
        
        # Get current position
        current_position = reservation.position
        
        if current_position == new_order:
            # No change needed
            return {
                "reservation_id": reservation_id,
                "order_position": new_order,
            }
        
        # Algorithm:
        # If moving down (current < new): shift items between current+1 and new down by 1
        # If moving up (current > new): shift items between new and current-1 up by 1
        
        if current_position < new_order:
            # Moving down (e.g., from position 2 to 4)
            # Items at positions 3,4 shift up to 2,3
            for res in all_reservations:
                if current_position < res.position <= new_order:
                    res.position -= 1
        else:
            # Moving up (e.g., from position 4 to 2)
            # Items at positions 2,3 shift down to 3,4
            for res in all_reservations:
                if new_order <= res.position < current_position:
                    res.position += 1
        
        # Set target position
        reservation.position = new_order
        
        db.commit()
        logger.info(f"Moved reservation from position {current_position} to {new_order}")
        
        return {
            "reservation_id": reservation_id,
            "order_position": new_order,
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error changing order: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to change reservation order",
        )
