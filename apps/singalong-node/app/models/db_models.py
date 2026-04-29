"""Database models for Node authentication"""

import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlalchemy import Column, DateTime, Enum as SQLEnum, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class UserRole(str, Enum):
    """User role enumeration"""
    CONTROLLER = "controller"
    ADMIN = "admin"
    PLAYER = "player"


def utc_now():
    """Get current UTC datetime"""
    return datetime.now(timezone.utc)


class User(Base):
    """User model - local cache of authenticated users (source of truth is Master)"""
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    nickname_or_username = Column(String(255), nullable=False, unique=True, index=True)
    role = Column(SQLEnum(UserRole), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)

    def __repr__(self):
        return f"<User {self.id}: {self.nickname_or_username} ({self.role})>"


class PlayerConnection(Base):
    """Player connection model - tracks active player sessions"""
    __tablename__ = "player_connections"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    player_id = Column(UUID(as_uuid=True), nullable=False, unique=True, index=True)
    connected_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)
    last_heartbeat = Column(DateTime(timezone=True), nullable=False, default=utc_now)

    def __repr__(self):
        return f"<PlayerConnection {self.player_id}>"


class Song(Base):
    """Song model - local cache of songs (Master is source of truth)"""

    __tablename__ = "songs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String(255), nullable=False, index=True)
    artist = Column(String(255), nullable=False, index=True)
    duration = Column(String(10), nullable=True)  # in seconds, as string for SQLite compatibility
    genre = Column(String(100), nullable=True, index=True)
    year = Column(String(4), nullable=True)  # as string for SQLite compatibility
    youtube_url = Column(String(500), nullable=True)  # original YouTube URL
    file_path = Column(String(500), nullable=True)  # where the file is stored locally
    status = Column(String(20), nullable=False, default="DRAFT", index=True)  # DRAFT, DOWNLOADING, COMPLETED, FAILED
    requested_by_admin_id = Column(String(255), nullable=True)  # which admin requested
    error_message = Column(String(500), nullable=True)  # if status is FAILED
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now, index=True)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now)

    def __repr__(self):
        return f"<Song {self.title} by {self.artist}>"


class SessionStatus(str, Enum):
    """Session status enumeration"""
    ACTIVE = "active"
    PAUSED = "paused"
    ENDED = "ended"


class Session(Base):
    """Karaoke session model"""
    __tablename__ = "sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code = Column(String(10), nullable=False, unique=True, index=True)
    title = Column(String(255), nullable=False)
    vibes = Column(String(500), nullable=True)  # Comma-separated or JSON string
    max_users = Column(String(10), nullable=True)  # Store as string for SQLite compat
    created_by = Column(UUID(as_uuid=True), nullable=False, index=True)
    status = Column(SQLEnum(SessionStatus), nullable=False, default=SessionStatus.ACTIVE)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)
    ended_at = Column(DateTime(timezone=True), nullable=True)

    def __repr__(self):
        return f"<Session {self.code}: {self.title} ({self.status})>"


class SessionUser(Base):
    """Tracks users in a session"""
    __tablename__ = "session_users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    joined_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)
    
    # Composite unique constraint - user can only join session once
    __table_args__ = (UniqueConstraint('session_id', 'user_id', name='uq_session_user'),)

    def __repr__(self):
        return f"<SessionUser session={self.session_id} user={self.user_id}>"
