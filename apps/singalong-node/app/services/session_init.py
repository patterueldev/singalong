"""Session initialization service - auto-creates admin session on startup"""

import os
import uuid
from datetime import datetime, timezone
from sqlalchemy.orm import Session as DBSession

from app.models.db_models import Session, SessionStatus


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
