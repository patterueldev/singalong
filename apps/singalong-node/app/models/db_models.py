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
    """User model - tracks all authenticated users"""
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    nickname_or_username = Column(String(255), nullable=False, unique=True, index=True)
    role = Column(SQLEnum(UserRole), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)

    def __repr__(self):
        return f"<User {self.id}: {self.nickname_or_username} ({self.role})>"


class AdminCredentials(Base):
    """Admin credentials model - stores admin username/password"""
    __tablename__ = "admin_credentials"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(255), nullable=False, unique=True, index=True)
    password_hash = Column(String(255), nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)

    def __repr__(self):
        return f"<AdminCredentials {self.id}: {self.username}>"


class PlayerCredentials(Base):
    """Player credentials model - stores player username/password"""
    __tablename__ = "player_credentials"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(255), nullable=False, unique=True, index=True)
    password_hash = Column(String(255), nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)

    def __repr__(self):
        return f"<PlayerCredentials {self.id}: {self.username}>"


class PlayerConnection(Base):
    """Player connection model - tracks active player sessions"""
    __tablename__ = "player_connections"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    player_id = Column(UUID(as_uuid=True), nullable=False, unique=True, index=True)
    connected_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)
    last_heartbeat = Column(DateTime(timezone=True), nullable=False, default=utc_now)

    def __repr__(self):
        return f"<PlayerConnection {self.player_id}>"


class Session(Base):
    """Session model - tracks karaoke session metadata"""
    __tablename__ = "sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)
    ended_at = Column(DateTime(timezone=True), nullable=True)

    def __repr__(self):
        return f"<Session {self.id}>"

