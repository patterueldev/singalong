"""User authentication service - handles user validation and JWT generation"""

import time
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple

import bcrypt
import jwt
from sqlalchemy.orm import Session

from app.main import settings
from app.models.db_models import User, UserRole, UserSessionHistory


class UserAuthService:
    """Handles user authentication and JWT token generation"""

    def __init__(
        self,
        algorithm: str = "HS256",
        access_token_expire_seconds: int = 3600,
        refresh_token_expire_seconds: int = 604800,
    ):
        """
        Initialize user auth service

        Args:
            algorithm: JWT algorithm (HS256 default)
            access_token_expire_seconds: Access token TTL in seconds (default 1 hour)
            refresh_token_expire_seconds: Refresh token TTL in seconds (default 7 days)
        """
        # JWT secret for user tokens (separate from API key auth)
        self.jwt_secret = settings.user_jwt_secret
        self.algorithm = algorithm
        self.access_token_expire_seconds = access_token_expire_seconds
        self.refresh_token_expire_seconds = refresh_token_expire_seconds
        self.service_name = "singalong-master"

    def authenticate_controller(
        self, db: Session, nickname: str, session_id: str, node_id: str
    ) -> Tuple[str, str, int, int, User]:
        """
        Authenticate controller user (attendee)

        Creates user if doesn't exist, records session join.

        Args:
            db: Database session
            nickname: User's nickname
            session_id: 4-digit session ID
            node_id: Node identifier

        Returns:
            Tuple of (access_token, refresh_token, access_expires_in, refresh_expires_in, user)

        Raises:
            ValueError: If session_id is invalid
        """
        if not session_id.isdigit() or len(session_id) != 4:
            raise ValueError("session_id must be a 4-digit string")

        # Find or create controller user with nickname
        user = db.query(User).filter(User.username == nickname).first()
        if not user:
            user = User(username=nickname, role=UserRole.CONTROLLER)
            db.add(user)
            db.commit()
            db.refresh(user)

        # Record session history
        session_record = UserSessionHistory(
            user_id=user.id,
            node_id=node_id,
            session_id=session_id,
            nickname=nickname,
        )
        db.add(session_record)
        db.commit()

        # Generate tokens
        access_token = self._generate_token(
            user_id=str(user.id),
            role=user.role.value,
            token_type="access",
            expires_in_seconds=self.access_token_expire_seconds,
        )
        refresh_token = self._generate_token(
            user_id=str(user.id),
            role=user.role.value,
            token_type="refresh",
            expires_in_seconds=self.refresh_token_expire_seconds,
        )

        return (
            access_token,
            refresh_token,
            self.access_token_expire_seconds,
            self.refresh_token_expire_seconds,
            user,
        )

    def authenticate_admin(
        self, db: Session, username: str, password: str, node_id: str
    ) -> Tuple[str, str, int, int, User]:
        """
        Authenticate admin user

        Args:
            db: Database session
            username: Admin username
            password: Admin password
            node_id: Node identifier

        Returns:
            Tuple of (access_token, refresh_token, access_expires_in, refresh_expires_in, user)

        Raises:
            ValueError: If username or password invalid
        """
        user = db.query(User).filter(User.username == username).first()
        if not user or user.role != UserRole.ADMIN:
            raise ValueError("Invalid username or password")

        if not self._verify_password(password, user.password_hash):
            raise ValueError("Invalid username or password")

        # Record session history
        session_record = UserSessionHistory(
            user_id=user.id,
            node_id=node_id,
            session_id="9999",  # Admin sessions use special ID
        )
        db.add(session_record)
        db.commit()

        # Generate tokens
        access_token = self._generate_token(
            user_id=str(user.id),
            role=user.role.value,
            token_type="access",
            expires_in_seconds=self.access_token_expire_seconds,
        )
        refresh_token = self._generate_token(
            user_id=str(user.id),
            role=user.role.value,
            token_type="refresh",
            expires_in_seconds=self.refresh_token_expire_seconds,
        )

        return (
            access_token,
            refresh_token,
            self.access_token_expire_seconds,
            self.refresh_token_expire_seconds,
            user,
        )

    def authenticate_player(
        self, db: Session, session_id: str, node_id: str
    ) -> Tuple[str, str, int, int, User]:
        """
        Authenticate player (first-come-first-served)

        Creates anonymous player, records connection.

        Args:
            db: Database session
            session_id: 4-digit session ID
            node_id: Node identifier

        Returns:
            Tuple of (access_token, refresh_token, access_expires_in, refresh_expires_in, user)

        Raises:
            ValueError: If session_id is invalid or player already connected
        """
        if not session_id.isdigit() or len(session_id) != 4:
            raise ValueError("session_id must be a 4-digit string")

        # Create anonymous player user
        user = User(role=UserRole.PLAYER)
        db.add(user)
        db.commit()
        db.refresh(user)

        # Record session history
        session_record = UserSessionHistory(
            user_id=user.id,
            node_id=node_id,
            session_id=session_id,
        )
        db.add(session_record)
        db.commit()

        # Generate tokens
        access_token = self._generate_token(
            user_id=str(user.id),
            role=user.role.value,
            token_type="access",
            expires_in_seconds=self.access_token_expire_seconds,
        )
        refresh_token = self._generate_token(
            user_id=str(user.id),
            role=user.role.value,
            token_type="refresh",
            expires_in_seconds=self.refresh_token_expire_seconds,
        )

        return (
            access_token,
            refresh_token,
            self.access_token_expire_seconds,
            self.refresh_token_expire_seconds,
            user,
        )

    def refresh_user_token(self, db: Session, refresh_token: str) -> Tuple[str, str, int, int]:
        """
        Validate refresh token and generate new access token

        Args:
            db: Database session
            refresh_token: JWT refresh token

        Returns:
            Tuple of (new_access_token, new_refresh_token, access_expires_in, refresh_expires_in)

        Raises:
            jwt.ExpiredSignatureError: If token is expired
            jwt.InvalidTokenError: If token is invalid
        """
        payload = jwt.decode(refresh_token, self.jwt_secret, algorithms=[self.algorithm])

        if payload.get("token_type") != "refresh":
            raise jwt.InvalidTokenError("Invalid token type")

        user_id = payload.get("sub")
        if not user_id:
            raise jwt.InvalidTokenError("Missing user_id in token")

        # Verify user still exists
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise jwt.InvalidTokenError("User not found")

        # Generate new tokens
        access_token = self._generate_token(
            user_id=user_id,
            role=payload.get("role"),
            token_type="access",
            expires_in_seconds=self.access_token_expire_seconds,
        )
        new_refresh_token = self._generate_token(
            user_id=user_id,
            role=payload.get("role"),
            token_type="refresh",
            expires_in_seconds=self.refresh_token_expire_seconds,
        )

        return (
            access_token,
            new_refresh_token,
            self.access_token_expire_seconds,
            self.refresh_token_expire_seconds,
        )

    def validate_token(self, token: str) -> dict:
        """
        Validate JWT user token

        Args:
            token: JWT token to validate

        Returns:
            Token payload if valid

        Raises:
            jwt.ExpiredSignatureError: If token is expired
            jwt.InvalidTokenError: If token is invalid
        """
        payload = jwt.decode(token, self.jwt_secret, algorithms=[self.algorithm])

        # Calculate expires_in
        exp = payload.get("exp", 0)
        now = int(time.time())
        expires_in = max(0, exp - now)

        payload["expires_in"] = expires_in
        return payload

    def _generate_token(
        self, user_id: str, role: str, token_type: str, expires_in_seconds: int
    ) -> str:
        """
        Generate JWT user token

        Args:
            user_id: User ID
            role: User role
            token_type: Type of token ("access" or "refresh")
            expires_in_seconds: Token TTL in seconds

        Returns:
            Encoded JWT token
        """
        now = datetime.now(timezone.utc)
        exp = now + timedelta(seconds=expires_in_seconds)

        payload = {
            "sub": user_id,
            "role": role,
            "iat": int(now.timestamp()),
            "exp": int(exp.timestamp()),
            "token_type": token_type,
        }

        token = jwt.encode(payload, self.jwt_secret, algorithm=self.algorithm)
        return token

    @staticmethod
    def _hash_password(password: str) -> str:
        """Hash password with bcrypt"""
        return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

    @staticmethod
    def _verify_password(password: str, password_hash: str) -> bool:
        """Verify password with bcrypt"""
        return bcrypt.checkpw(password.encode(), password_hash.encode())
