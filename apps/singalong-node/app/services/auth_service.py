"""Authentication service - JWT token generation and validation"""

import time
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from sqlalchemy.orm import Session

from app.models.db_models import AdminCredentials, PlayerConnection, PlayerCredentials, User, UserRole


class AuthService:
    """Handles JWT token generation, validation, and role-based authentication"""

    def __init__(
        self,
        api_key: str,
        algorithm: str = "HS256",
        access_token_expire_seconds: int = 10800,
        refresh_token_expire_seconds: int = 604800,
        bcrypt_rounds: int = 12,
    ):
        """
        Initialize auth service

        Args:
            api_key: Secret key for JWT signing
            algorithm: JWT algorithm (HS256 default)
            access_token_expire_seconds: Access token TTL in seconds (default 3 hours)
            refresh_token_expire_seconds: Refresh token TTL in seconds (default 7 days)
            bcrypt_rounds: Number of bcrypt hashing rounds (default 12)
        """
        self.api_key = api_key
        self.algorithm = algorithm
        self.access_token_expire_seconds = access_token_expire_seconds
        self.refresh_token_expire_seconds = refresh_token_expire_seconds
        self.bcrypt_rounds = bcrypt_rounds
        self.service_name = "singalong-node"

    def authenticate_controller(self, nickname: str, db: Session) -> tuple[str, str, str, int, int]:
        """
        Authenticate a controller (attendee) user

        Args:
            nickname: Unique nickname for the session
            db: Database session

        Returns:
            Tuple of (access_token, refresh_token, role, access_expires_in, refresh_expires_in)

        Raises:
            ValueError: If nickname is already taken
        """
        # Check if nickname already exists
        existing_user = db.query(User).filter(
            User.nickname_or_username == nickname,
            User.role == UserRole.CONTROLLER,
        ).first()

        if existing_user:
            raise ValueError(f"Nickname '{nickname}' is already taken")

        # Create new user
        user = User(
            nickname_or_username=nickname,
            role=UserRole.CONTROLLER,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

        # Generate tokens
        access_token = self._generate_token(
            user_id=str(user.id),
            role=UserRole.CONTROLLER,
            token_type="access",
            expires_in_seconds=self.access_token_expire_seconds,
        )
        refresh_token = self._generate_token(
            user_id=str(user.id),
            role=UserRole.CONTROLLER,
            token_type="refresh",
            expires_in_seconds=self.refresh_token_expire_seconds,
        )

        return (
            access_token,
            refresh_token,
            UserRole.CONTROLLER,
            self.access_token_expire_seconds,
            self.refresh_token_expire_seconds,
        )

    def authenticate_admin(self, username: str, password: str, db: Session) -> tuple[str, str, str, int, int]:
        """
        Authenticate an admin user

        Args:
            username: Admin username
            password: Admin password (plaintext)
            db: Database session

        Returns:
            Tuple of (access_token, refresh_token, role, access_expires_in, refresh_expires_in)

        Raises:
            ValueError: If credentials are invalid
        """
        # Check if admin credentials exist
        admin_creds = db.query(AdminCredentials).filter(
            AdminCredentials.username == username
        ).first()

        if not admin_creds:
            raise ValueError("Invalid admin credentials")

        # Verify password
        if not self._verify_password(password, admin_creds.password_hash):
            raise ValueError("Invalid admin credentials")

        # Check if user exists
        user = db.query(User).filter(
            User.nickname_or_username == username,
            User.role == UserRole.ADMIN,
        ).first()

        # Create user if doesn't exist
        if not user:
            user = User(
                nickname_or_username=username,
                role=UserRole.ADMIN,
            )
            db.add(user)
            db.commit()
            db.refresh(user)

        # Generate tokens
        access_token = self._generate_token(
            user_id=str(user.id),
            role=UserRole.ADMIN,
            token_type="access",
            expires_in_seconds=self.access_token_expire_seconds,
        )
        refresh_token = self._generate_token(
            user_id=str(user.id),
            role=UserRole.ADMIN,
            token_type="refresh",
            expires_in_seconds=self.refresh_token_expire_seconds,
        )

        return (
            access_token,
            refresh_token,
            UserRole.ADMIN,
            self.access_token_expire_seconds,
            self.refresh_token_expire_seconds,
        )

    def authenticate_player(self, username: str, password: str, db: Session) -> tuple[str, str, str, int, int]:
        """
        Authenticate a player (playback device)

        Args:
            username: Player username
            password: Player password (plaintext)
            db: Database session

        Returns:
            Tuple of (access_token, refresh_token, role, access_expires_in, refresh_expires_in)

        Raises:
            ValueError: If credentials are invalid or another player is already connected
        """
        # Check if player credentials exist
        player_creds = db.query(PlayerCredentials).filter(
            PlayerCredentials.username == username
        ).first()

        if not player_creds:
            raise ValueError("Invalid player credentials")

        # Verify password
        if not self._verify_password(password, player_creds.password_hash):
            raise ValueError("Invalid player credentials")

        # Check if another player is already connected
        existing_connection = db.query(PlayerConnection).first()
        if existing_connection:
            raise ValueError("Another player is already connected")

        # Check if user exists
        user = db.query(User).filter(
            User.nickname_or_username == username,
            User.role == UserRole.PLAYER,
        ).first()

        # Create user if doesn't exist
        if not user:
            user = User(
                nickname_or_username=username,
                role=UserRole.PLAYER,
            )
            db.add(user)
            db.commit()
            db.refresh(user)

        # Create player connection
        connection = PlayerConnection(player_id=user.id)
        db.add(connection)
        db.commit()

        # Generate tokens
        access_token = self._generate_token(
            user_id=str(user.id),
            role=UserRole.PLAYER,
            token_type="access",
            expires_in_seconds=self.access_token_expire_seconds,
        )
        refresh_token = self._generate_token(
            user_id=str(user.id),
            role=UserRole.PLAYER,
            token_type="refresh",
            expires_in_seconds=self.refresh_token_expire_seconds,
        )

        return (
            access_token,
            refresh_token,
            UserRole.PLAYER,
            self.access_token_expire_seconds,
            self.refresh_token_expire_seconds,
        )

    def refresh_token(self, refresh_token: str, db: Session) -> tuple[str, str, str, int, int]:
        """
        Validate refresh token and generate new access + refresh tokens

        Args:
            refresh_token: JWT refresh token
            db: Database session

        Returns:
            Tuple of (new_access_token, new_refresh_token, role, access_expires_in, refresh_expires_in)

        Raises:
            jwt.ExpiredSignatureError: If refresh token is expired
            jwt.InvalidTokenError: If refresh token is invalid
        """
        try:
            payload = jwt.decode(refresh_token, self.api_key, algorithms=[self.algorithm])
        except jwt.ExpiredSignatureError:
            raise
        except jwt.InvalidTokenError as e:
            raise jwt.InvalidTokenError(f"Invalid token: {str(e)}")

        # Check token type
        if payload.get("token_type") != "refresh":
            raise jwt.InvalidTokenError("Invalid token type")

        # Check service name
        if payload.get("service_name") != self.service_name:
            raise jwt.InvalidTokenError("Invalid service name in token")

        # Get user to verify role
        user_id = payload.get("sub")
        role = payload.get("role")

        if not user_id or not role:
            raise jwt.InvalidTokenError("Invalid token claims")

        # Generate new tokens with same role
        access_token = self._generate_token(
            user_id=user_id,
            role=role,
            token_type="access",
            expires_in_seconds=self.access_token_expire_seconds,
        )
        new_refresh_token = self._generate_token(
            user_id=user_id,
            role=role,
            token_type="refresh",
            expires_in_seconds=self.refresh_token_expire_seconds,
        )

        return (
            access_token,
            new_refresh_token,
            role,
            self.access_token_expire_seconds,
            self.refresh_token_expire_seconds,
        )

    def validate_token(self, token: str) -> dict:
        """
        Validate JWT token

        Args:
            token: JWT token to validate

        Returns:
            Token payload if valid

        Raises:
            jwt.ExpiredSignatureError: If token is expired
            jwt.InvalidTokenError: If token is invalid
        """
        try:
            payload = jwt.decode(token, self.api_key, algorithms=[self.algorithm])
        except jwt.ExpiredSignatureError:
            raise
        except jwt.InvalidTokenError as e:
            raise jwt.InvalidTokenError(f"Invalid token: {str(e)}")

        # Check service name
        if payload.get("service_name") != self.service_name:
            raise jwt.InvalidTokenError("Invalid service name in token")

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
        Generate JWT token

        Args:
            user_id: User ID to include in token
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
            "service_name": self.service_name,
            "iat": int(now.timestamp()),
            "exp": int(exp.timestamp()),
            "token_type": token_type,
        }

        token = jwt.encode(payload, self.api_key, algorithm=self.algorithm)
        return token

    @staticmethod
    def hash_password(password: str, rounds: int = 12) -> str:
        """
        Hash a password using bcrypt

        Args:
            password: Plaintext password
            rounds: Number of hashing rounds

        Returns:
            Password hash
        """
        salt = bcrypt.gensalt(rounds=rounds)
        return bcrypt.hashpw(password.encode(), salt).decode()

    @staticmethod
    def _verify_password(password: str, password_hash: str) -> bool:
        """
        Verify a password against a hash

        Args:
            password: Plaintext password
            password_hash: Password hash

        Returns:
            True if password matches, False otherwise
        """
        return bcrypt.checkpw(password.encode(), password_hash.encode())
