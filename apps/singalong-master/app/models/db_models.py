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
