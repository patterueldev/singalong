"""Database models for Node authentication"""

import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlalchemy import Column, DateTime, Enum as SQLEnum, String, UniqueConstraint, Integer
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


class ReservationStatus(str, Enum):
    """Reservation status enumeration"""
    PENDING = "pending"
    PLAYING = "playing"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class Reservation(Base):
    """Song reservation for a session"""
    __tablename__ = "reservations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    song_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    position = Column(Integer, nullable=False, index=True)  # Queue position (1-based)
    status = Column(SQLEnum(ReservationStatus), nullable=False, default=ReservationStatus.PENDING)
    reserved_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    cancelled_at = Column(DateTime(timezone=True), nullable=True)

    # Composite unique constraint - one instance per song per session
    __table_args__ = (UniqueConstraint('session_id', 'song_id', name='uq_session_song_reservation'),)

    def __repr__(self):
        return f"<Reservation {self.position}: {self.song_id} in {self.session_id} ({self.status})>"


class DownloadQueue(Base):
    """Tracks song downloads requested from Master"""
    __tablename__ = "download_queue"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    video_id = Column(String(255), nullable=False, unique=True, index=True)  # YouTube video ID
    title = Column(String(500), nullable=False)  # Song title
    master_download_id = Column(String(36), nullable=False, index=True)  # Master's draft song UUID
    status = Column(String(50), nullable=False, default="pending", index=True)  # pending, downloading, completed, failed
    progress = Column(Integer, nullable=False, default=0)  # 0-100 percent
    file_path = Column(String(1000), nullable=True)  # Local file path when completed
    error_message = Column(String(1000), nullable=True)  # Error details if failed
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now, index=True)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)
    completed_at = Column(DateTime(timezone=True), nullable=True)

    def __repr__(self):
        return f"<DownloadQueue {self.video_id} ({self.status})>"
