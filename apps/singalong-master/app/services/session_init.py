"""Session initialization service - auto-creates session 9999 on startup"""

import os
from datetime import datetime, timezone
from sqlalchemy.orm import Session as DBSession

from app.models.db_models import Session


def init_admin_session(db: DBSession) -> Session:
    """
    Initialize or verify admin session (9999) exists on startup.
    
    If session 9999 doesn't exist, create it with:
    - is_admin_session = TRUE
    - status = ACTIVE
    - passcode from ADMIN_SESSION_CODE env var
    - created_at = now
    
    If accidentally deleted, recreate on next startup.
    
    Args:
        db: Database session
        
    Returns:
        Session object for session 9999
    """
    admin_session_passcode = os.getenv("ADMIN_SESSION_CODE", "admin9999")
    
    # Check if session 9999 exists
    existing = db.query(Session).filter(
        Session.session_id == "9999"
    ).first()
    
    if existing:
        # Session exists, just return it
        # (In future, could update passcode if env var changed)
        return existing
    
    # Create session 9999
    admin_session = Session(
        node_id="master",  # Sessions from Master are marked with node_id="master"
        session_id="9999",
        title="Admin Workspace",
        session_code=admin_session_passcode,
        status="ACTIVE",
        created_by_admin_id=None,  # System-created
        is_admin_session="TRUE",
        created_at=datetime.now(timezone.utc),
    )
    
    db.add(admin_session)
    db.commit()
    db.refresh(admin_session)
    
    print(f"✓ Created admin session 9999")
    return admin_session


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
