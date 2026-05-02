"""Session initialization service - auto-creates admin session on startup"""

import uuid
import logging
from datetime import datetime, timezone
from sqlalchemy.orm import Session as DBSession

from app.models.db_models import Session, SessionStatus

logger = logging.getLogger(__name__)


def init_admin_session(db: DBSession) -> Session:
    """
    Initialize or verify admin session exists on startup.
    
    Admin session has code "9999" (reserved for admins) with special permissions for managing the Node.
    
    Args:
        db: Database session
        
    Returns:
        Session object for admin session
    """
    # Check if admin session already exists
    existing = db.query(Session).filter(
        Session.code == "9999"
    ).first()
    
    if existing:
        # Admin session exists, just return it
        return existing
    
    # Create admin session with system user ID
    admin_session = Session(
        code="9999",  # Reserved admin code (4-digit string)
        title="Admin Workspace",
        vibes="",  # No vibes for admin
        max_users=None,  # Unlimited for admin
        created_by=uuid.uuid4(),  # System-created (no specific user)
        status=SessionStatus.ACTIVE,
        created_at=datetime.now(timezone.utc),
        ended_at=None,
    )
    
    db.add(admin_session)
    db.commit()
    db.refresh(admin_session)
    
    print(f"✓ Created admin session with code '9999'")
    return admin_session


def cleanup_extra_sessions(db: DBSession, allowed_codes: list = None) -> None:
    """
    Deactivate all sessions except those in allowed_codes.
    
    Node should only have specific sessions active (e.g., 9999 for admin, 4369 for testing).
    All other sessions should be ended.
    
    Args:
        db: Database session
        allowed_codes: List of session codes to keep active (e.g., ["9999", "4369"])
    """
    if allowed_codes is None:
        allowed_codes = ["9999", "4369"]
    
    # Find all active sessions NOT in allowed_codes
    extra_sessions = db.query(Session).filter(
        Session.status == SessionStatus.ACTIVE,
        ~Session.code.in_(allowed_codes)
    ).all()
    
    if extra_sessions:
        logger.info(f"Ending {len(extra_sessions)} non-whitelisted session(s)")
        for session in extra_sessions:
            logger.info(f"  - Session {session.code}: {session.title}")
            session.status = SessionStatus.ENDED
            session.ended_at = datetime.now(timezone.utc)
        
        db.commit()
        print(f"✓ Ended {len(extra_sessions)} extra session(s)")
    else:
        logger.debug("No extra sessions to end")


def ensure_admin_session_exists(db: DBSession) -> None:
    """
    Wrapper function to ensure admin session exists.
    Safe to call multiple times (idempotent).
    
    Args:
        db: Database session
    """
    try:
        init_admin_session(db)
    except Exception as e:
        print(f"⚠ Warning: Failed to initialize admin session: {e}")
        # Don't fail startup if session initialization fails
        pass


def cleanup_node_sessions(db: DBSession, allowed_codes: list = None) -> None:
    """
    Wrapper function to clean up extra sessions on Node startup.
    
    Node should only have whitelisted sessions active. This ensures we don't
    have stray sessions from previous test runs or imports.
    
    Args:
        db: Database session
        allowed_codes: List of session codes to keep active
    """
    try:
        cleanup_extra_sessions(db, allowed_codes)
    except Exception as e:
        logger.warning(f"Failed to cleanup extra sessions: {e}")
        # Don't fail startup if cleanup fails
        pass
