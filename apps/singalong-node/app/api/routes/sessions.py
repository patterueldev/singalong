"""Session management API routes for Node"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session as DBSession

from app.database import get_db
from app.models.db_models import Session
from app.models.schemas import (
    CreateSessionRequest,
    SessionResponse,
    SessionListResponse,
    SessionUsersResponse,
    UserInSessionResponse,
    ErrorResponse,
)

router = APIRouter(prefix="/api/sessions", tags=["Sessions"])


@router.post("", response_model=SessionResponse, status_code=status.HTTP_201_CREATED)
async def create_session(
    request: CreateSessionRequest, db: DBSession = Depends(get_db)
) -> SessionResponse:
    """
    Create a new session on this node.
    
    Admin-only endpoint. When creating a new party session, automatically ends
    other active party sessions (but NOT session 9999).
    
    Args:
        request: CreateSessionRequest with session_id, title, optional session_code
        db: Database session
        
    Returns:
        SessionResponse with created session details
        
    Raises:
        HTTPException: If validation fails (session_id already exists, invalid format, etc.)
    """
    # Validate session_id format (4 digits, 0000-9999)
    try:
        session_num = int(request.session_id)
        if session_num < 0 or session_num > 9999:
            raise ValueError()
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "code": "INVALID_SESSION_ID",
                "message": "Session ID must be 4-digit number (0000-9999)",
            },
        )

    # Check if session_id already exists
    existing = db.query(Session).filter(Session.session_id == request.session_id).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "SESSION_EXISTS",
                "message": f"Session {request.session_id} already exists",
            },
        )

    # If creating a new party session (not 9999), end other party sessions
    if request.session_id != "9999":
        # Find all active party sessions (not admin session)
        active_parties = (
            db.query(Session)
            .filter(
                Session.status == "ACTIVE",
                Session.is_admin_session == "FALSE",
            )
            .all()
        )

        # End them
        for party in active_parties:
            party.status = "ENDED"
            db.add(party)

    # Create new session
    new_session = Session(
        session_id=request.session_id,
        title=request.title,
        session_code=request.session_code,
        status="ACTIVE",
        is_admin_session="FALSE",
    )

    db.add(new_session)
    db.commit()
    db.refresh(new_session)

    return SessionResponse(
        id=str(new_session.id),
        session_id=new_session.session_id,
        title=new_session.title,
        status=new_session.status,
        is_admin_session=new_session.is_admin_session == "TRUE",
        created_at=new_session.created_at.isoformat(),
        ended_at=new_session.ended_at.isoformat() if new_session.ended_at else None,
    )


@router.get("", response_model=SessionListResponse)
async def list_sessions(db: DBSession = Depends(get_db)) -> SessionListResponse:
    """
    List all sessions on this node.
    
    Args:
        db: Database session
        
    Returns:
        SessionListResponse with all sessions
    """
    sessions = db.query(Session).order_by(Session.created_at.desc()).all()

    session_responses = [
        SessionResponse(
            id=str(s.id),
            session_id=s.session_id,
            title=s.title,
            status=s.status,
            is_admin_session=s.is_admin_session == "TRUE",
            created_at=s.created_at.isoformat(),
            ended_at=s.ended_at.isoformat() if s.ended_at else None,
            user_count=0,  # TODO: Query user count from membership table
        )
        for s in sessions
    ]

    return SessionListResponse(sessions=session_responses, total=len(session_responses))


@router.delete("/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_session(session_id: str, db: DBSession = Depends(get_db)) -> None:
    """
    End a session on this node.
    
    Admin-only endpoint. Sets session status to ENDED. Users in this session
    will receive errors on subsequent API calls.
    
    Args:
        session_id: 4-digit session ID to end
        db: Database session
        
    Raises:
        HTTPException: If session not found or already ended
    """
    # Validate session_id format
    if len(session_id) != 4 or not session_id.isdigit():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "code": "INVALID_SESSION_ID",
                "message": "Session ID must be 4-digit number",
            },
        )

    session = (
        db.query(Session).filter(Session.session_id == session_id).first()
    )

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "SESSION_NOT_FOUND",
                "message": f"Session {session_id} not found",
            },
        )

    if session.status == "ENDED":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "SESSION_ALREADY_ENDED",
                "message": f"Session {session_id} is already ended",
            },
        )

    # Don't allow ending session 9999
    if session.is_admin_session == "TRUE":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "CANNOT_END_ADMIN_SESSION",
                "message": "Cannot end admin session 9999",
            },
        )

    # End the session
    session.status = "ENDED"
    db.add(session)
    db.commit()


@router.get("/{session_id}/users", response_model=SessionUsersResponse)
async def get_session_users(
    session_id: str, db: DBSession = Depends(get_db)
) -> SessionUsersResponse:
    """
    Get list of users in a specific session.
    
    Args:
        session_id: 4-digit session ID
        db: Database session
        
    Returns:
        SessionUsersResponse with list of users
        
    Raises:
        HTTPException: If session not found
    """
    # Validate session_id format
    if len(session_id) != 4 or not session_id.isdigit():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "code": "INVALID_SESSION_ID",
                "message": "Session ID must be 4-digit number",
            },
        )

    session = (
        db.query(Session).filter(Session.session_id == session_id).first()
    )

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "SESSION_NOT_FOUND",
                "message": f"Session {session_id} not found",
            },
        )

    # TODO: Query from user_session_membership table
    # For now, return empty list
    users = []

    return SessionUsersResponse(
        session_id=session_id,
        users=users,
        total=len(users),
    )
