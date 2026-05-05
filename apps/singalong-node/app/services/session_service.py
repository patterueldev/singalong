"""Session management service"""

import logging
import uuid
import random
import string
from datetime import datetime, timezone
from typing import Optional, List
from sqlalchemy.orm import Session as SQLSession

from app.models.db_models import Session, SessionUser, SessionStatus

logger = logging.getLogger(__name__)


class SessionService:
    """Manages karaoke sessions"""

    def __init__(self, db: SQLSession):
        self.db = db

    def create_session(
        self,
        title: str,
        created_by_user_id: str,
        vibes: Optional[str] = None,
        max_users: Optional[int] = None,
    ) -> Session:
        """
        Create a new karaoke session

        Args:
            title: Session title
            created_by_user_id: UUID of user creating session
            vibes: Optional comma-separated vibes (party, upbeat, chill, etc)
            max_users: Optional max user limit

        Returns:
            Created Session object

        Raises:
            ValueError: If title is empty
        """
        if not title or not title.strip():
            raise ValueError("Session title cannot be empty")

        # Generate unique numeric code (0-9998)
        code = self._generate_session_code()

        session = Session(
            code=code,
            title=title.strip(),
            vibes=vibes,
            max_users=str(max_users) if max_users else None,
            created_by=uuid.UUID(created_by_user_id),
            status=SessionStatus.ACTIVE,
        )

        self.db.add(session)
        self.db.commit()
        self.db.refresh(session)

        logger.info(f"Session created: {code} - {title}")

        return session

    def get_session(self, session_code: str) -> Optional[Session]:
        """Get session by numeric code (e.g., "0001")"""
        return self.db.query(Session).filter(Session.code == session_code).first()

    def list_sessions(self, status: Optional[str] = None) -> List[Session]:
        """List sessions, optionally filtered by status"""
        query = self.db.query(Session)

        if status:
            query = query.filter(Session.status == status)

        return query.order_by(Session.created_at.desc()).all()

    def add_user_to_session(self, session_code: str, user_id: str) -> SessionUser:
        """
        Add user to session

        Args:
            session_code: Session numeric code (e.g., "0001")
            user_id: User UUID

        Returns:
            SessionUser record

        Raises:
            ValueError: If session not found, user already in session, or max users reached
        """
        try:
            user_uuid = uuid.UUID(user_id)
        except ValueError:
            raise ValueError("Invalid user_id format")

        # Check session exists
        session = self.get_session(session_code)
        if not session:
            raise ValueError("Session not found")

        # Check user not already in session
        existing = self.db.query(SessionUser).filter(
            SessionUser.session_code == session_code,
            SessionUser.user_id == user_uuid,
        ).first()

        if existing:
            raise ValueError("User already in session")

        # Check max users limit
        if session.max_users:
            max_limit = int(session.max_users)
            user_count = self.db.query(SessionUser).filter(
                SessionUser.session_code == session_code
            ).count()
            if user_count >= max_limit:
                raise ValueError(f"Session full (max {max_limit} users)")

        # Add user
        session_user = SessionUser(
            id=uuid.uuid4(),
            session_code=session_code,
            user_id=user_uuid,
        )

        self.db.add(session_user)
        self.db.commit()
        self.db.refresh(session_user)

        logger.info(f"User {user_id} added to session {session_code}")

        return session_user

    def remove_user_from_session(self, session_code: str, user_id: str) -> None:
        """Remove user from session"""
        try:
            user_uuid = uuid.UUID(user_id)
        except ValueError:
            raise ValueError("Invalid user_id format")

        self.db.query(SessionUser).filter(
            SessionUser.session_code == session_code,
            SessionUser.user_id == user_uuid,
        ).delete()

        self.db.commit()

        logger.info(f"User {user_id} removed from session {session_code}")

    def get_session_users(self, session_code: str) -> List[dict]:
        """Get all users in session"""
        session_users = self.db.query(SessionUser).filter(
            SessionUser.session_code == session_code
        ).order_by(SessionUser.joined_at).all()

        return [
            {
                "user_id": str(su.user_id),
                "joined_at": su.joined_at.isoformat(),
            }
            for su in session_users
        ]

    def get_session_user_count(self, session_code: str) -> int:
        """Get number of users in session"""
        return self.db.query(SessionUser).filter(
            SessionUser.session_code == session_code
        ).count()

    def update_session_status(self, session_code: str, status: str) -> Session:
        """Update session status"""
        session = self.get_session(session_code)
        if not session:
            raise ValueError("Session not found")

        session.status = SessionStatus(status)

        if status == SessionStatus.ENDED:
            session.ended_at = datetime.now(timezone.utc)

        self.db.commit()
        self.db.refresh(session)

        logger.info(f"Session {session_code} status updated to {status}")

        return session

    @staticmethod
    def _generate_session_code() -> str:
        """Generate random numeric session code (0000-9998 as zero-padded string, 9999 reserved for admin)"""
        numeric_code = random.randint(0, 9998)
        return f"{numeric_code:04d}"  # Zero-pad to 4 digits (e.g., "0001", "0042", "9998")
