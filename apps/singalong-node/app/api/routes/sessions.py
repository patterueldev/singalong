"""Session management endpoints"""

import logging
import uuid
from typing import Optional
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session as SQLSession

from app.database import get_db
from app.middleware.auth import verify_bearer_token
from app.services.session_service import SessionService

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
