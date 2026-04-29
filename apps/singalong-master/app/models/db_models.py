"""Database models for Master authentication"""

import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlalchemy import Column, DateTime, Enum as SQLEnum, String, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class UserRole(str, Enum):
    """User role enumeration"""

    SUPERADMIN = "superadmin"
    ADMIN = "admin"
    PLAYER = "player"
    CONTROLLER = "controller"


def utc_now():
    """Get current UTC datetime"""
    return datetime.now(timezone.utc)


class User(Base):
    """User model - stores all users with their roles and credentials"""

    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(255), nullable=True, unique=True, index=True)
    password_hash = Column(String(255), nullable=True)
    role = Column(SQLEnum(UserRole), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)

    def __repr__(self):
        return f"<User {self.id}: {self.username} ({self.role})>"


class Session(Base):
    """Session model - tracks karaoke sessions per node"""

    __tablename__ = "sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    node_id = Column(String(255), nullable=False, index=True)
    session_id = Column(String(4), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    session_code = Column(String(255), nullable=True)  # Passcode, optional
    status = Column(String(10), nullable=False, default="ACTIVE", index=True)  # ACTIVE or ENDED
    created_by_admin_id = Column(String(255), nullable=True)
    is_admin_session = Column(String(5), nullable=False, default="FALSE")  # TRUE only for 9999
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)
    ended_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (UniqueConstraint("node_id", "session_id", name="uq_node_session"),)

    def __repr__(self):
        return f"<Session {self.node_id}:{self.session_id}>"


class UserSessionMembership(Base):
    """User session membership model - tracks which users are in which sessions"""

    __tablename__ = "user_session_membership"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_nickname = Column(String(255), nullable=False, index=True)
    session_id = Column(String(4), nullable=False, index=True)
    node_id = Column(String(255), nullable=False, index=True)
    joined_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)
    left_at = Column(DateTime(timezone=True), nullable=True)
    user_role = Column(String(20), nullable=False)  # controller, admin, player

    __table_args__ = (
        UniqueConstraint("user_nickname", "node_id", "session_id", name="uq_user_node_session"),
    )

    def __repr__(self):
        return f"<UserSessionMembership {self.user_nickname} @ {self.node_id}:{self.session_id}>"


class UserSessionHistory(Base):
    """User session history model - tracks user joins/leaves for recommendations"""

    __tablename__ = "user_session_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    node_id = Column(String(255), nullable=False, index=True)
    session_id = Column(String(4), nullable=False, index=True)
    nickname = Column(String(255), nullable=True)
    joined_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)
    left_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (UniqueConstraint("user_id", "node_id", "session_id", name="uq_user_node_session"),)

    def __repr__(self):
        return f"<UserSessionHistory {self.user_id} @ {self.node_id}:{self.session_id}>"


class Song(Base):
    """Song model - stores karaoke songs with metadata and download status"""

    __tablename__ = "songs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String(255), nullable=False, index=True)
    artist = Column(String(255), nullable=False, index=True)
    duration = Column(String(10), nullable=True)  # in seconds, as string for SQLite compatibility
    genre = Column(String(100), nullable=True, index=True)
    year = Column(String(4), nullable=True)  # as string for SQLite compatibility
    youtube_url = Column(String(500), nullable=True)  # original YouTube URL
    file_path = Column(String(500), nullable=True)  # where the file is stored
    status = Column(String(20), nullable=False, default="DRAFT", index=True)  # DRAFT, ACTIVE, ARCHIVED, CORRUPTED
    requested_by_admin_id = Column(String(255), nullable=True)  # which admin requested
    error_message = Column(String(500), nullable=True)  # if status is FAILED
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now, index=True)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now)

    def __repr__(self):
        return f"<Song {self.title} by {self.artist}>"


class DraftSong(Base):
    """Draft song model - tracks songs being downloaded before finalization"""

    __tablename__ = "draft_songs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    video_id = Column(String(50), nullable=True, index=True)  # YouTube video ID
    title = Column(String(255), nullable=False)
    artist = Column(String(255), nullable=True)
    duration = Column(String(10), nullable=True)  # in seconds
    language = Column(String(20), nullable=True)  # detected language
    requested_by_node_id = Column(String(255), nullable=False, index=True)  # which node requested
    enhanced_metadata = Column(String(4000), nullable=True)  # JSON string of user-edited metadata
    status = Column(String(20), nullable=False, default="pending", index=True)  # pending, downloading, completed, failed, archived, corrupted
    download_progress = Column(String(3), nullable=False, default="0")  # 0-100
    error_message = Column(String(500), nullable=True)  # error if failed
    file_path = Column(String(500), nullable=True)  # where the file will be stored
    file_size = Column(String(20), nullable=True)  # size in bytes
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now, index=True)
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    finalized_at = Column(DateTime(timezone=True), nullable=True)

    def __repr__(self):
        return f"<DraftSong {self.title} ({self.status})>"
