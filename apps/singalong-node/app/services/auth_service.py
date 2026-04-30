"""Authentication service - JWT token generation and validation"""

import logging
import time
from datetime import datetime, timedelta, timezone

import jwt
from sqlalchemy.orm import Session as SQLSession

from app.config import settings
from app.models.db_models import PlayerConnection, User, UserRole, Session
from app.services.graphql_client import MasterGraphQLClient, GraphQLError, HTTPException

logger = logging.getLogger(__name__)


class AuthService:
    """Handles JWT token generation and validates users via Master GraphQL"""

    def __init__(
        self,
        api_key: str,
        algorithm: str = "HS256",
        access_token_expire_seconds: int = 10800,
        refresh_token_expire_seconds: int = 604800,
    ):
        """
        Initialize auth service

        Args:
            api_key: Secret key for JWT signing (Node-specific)
            algorithm: JWT algorithm (HS256 default)
            access_token_expire_seconds: Access token TTL in seconds (default 3 hours)
            refresh_token_expire_seconds: Refresh token TTL in seconds (default 7 days)
        """
        self.api_key = api_key
        self.algorithm = algorithm
        self.access_token_expire_seconds = access_token_expire_seconds
        self.refresh_token_expire_seconds = refresh_token_expire_seconds
        self.service_name = "singalong-node"
        self.graphql_client = MasterGraphQLClient(
            graphql_url=settings.master_graphql_url,
            timeout=settings.master_timeout,
        )

    async def authenticate_controller(
        self, nickname: str, session_id: str, node_id: str, db: SQLSession
    ) -> tuple[str, str, str, int, int]:
        """
        Authenticate a controller (attendee) user via Master GraphQL

        Args:
            nickname: Controller nickname
            session_id: 4-digit session ID
            node_id: Node UUID
            db: Database session

        Returns:
            Tuple of (access_token, refresh_token, role, access_expires_in, refresh_expires_in)

        Raises:
            ValueError: If session doesn't exist, not active, or Master GraphQL auth fails
        """
        # Validate session exists and is active
        try:
            session_code = int(session_id)
        except ValueError:
            raise ValueError(f"Invalid session ID format: {session_id}")
        
        session = db.query(Session).filter(Session.code == session_code).first()
        if not session:
            raise ValueError(f"Session {session_id} does not exist")
        
        if session.status != "active":
            raise ValueError(f"Session {session_id} is not active (status: {session.status})")
        
        try:
            # Call Master GraphQL to authenticate controller
            response = await self.graphql_client.authenticate_controller(
                nickname=nickname,
                session_id=session_id,
                node_id=node_id,
            )

            # Extract user info from GraphQL response
            mutation_data = response.get("authenticateController", {})
            user_data = mutation_data.get("user", {})
            user_id = user_data.get("id")

            if not user_id:
                raise ValueError("Failed to authenticate controller: invalid response")

            # Create or update local user cache
            import uuid as uuid_module
            try:
                user_uuid = uuid_module.UUID(user_id)
            except (ValueError, TypeError):
                user_uuid = uuid_module.uuid4()
            
            user = db.query(User).filter(User.id == user_uuid).first()
            if not user:
                user = User(
                    id=user_uuid,
                    nickname_or_username=nickname,
                    role="controller",
                )
                db.add(user)
                db.commit()
                db.refresh(user)

            # Generate Node-specific JWT tokens
            access_token = self._generate_token(
                user_id=str(user_uuid),
                role="controller",
                token_type="access",
                expires_in_seconds=self.access_token_expire_seconds,
            )
            refresh_token = self._generate_token(
                user_id=user_id,
                role="controller",
                token_type="refresh",
                expires_in_seconds=self.refresh_token_expire_seconds,
            )

            return (
                access_token,
                refresh_token,
                "controller",
                self.access_token_expire_seconds,
                self.refresh_token_expire_seconds,
            )

        except (GraphQLError, HTTPException) as e:
            logger.error(f"Master GraphQL error: {str(e)}")
            raise ValueError(f"Failed to authenticate controller: {str(e)}")

    async def authenticate_admin(
        self, username: str, password: str, node_id: str, db: SQLSession
    ) -> tuple[str, str, str, int, int]:
        """
        Authenticate an admin user via Master GraphQL

        Args:
            username: Admin username
            password: Admin password
            node_id: Node UUID
            db: Database session

        Returns:
            Tuple of (access_token, refresh_token, role, access_expires_in, refresh_expires_in)

        Raises:
            ValueError: If Master GraphQL authentication fails
        """
        try:
            # Call Master GraphQL to authenticate admin
            response = await self.graphql_client.authenticate_admin(
                username=username,
                password=password,
                node_id=node_id,
            )

            # Extract user info from GraphQL response
            mutation_data = response.get("authenticateAdmin", {})
            user_data = mutation_data.get("user", {})
            user_id = user_data.get("id")

            if not user_id:
                raise ValueError("Failed to authenticate admin: invalid response")

            # Create or update local user cache
            import uuid as uuid_module
            try:
                user_uuid = uuid_module.UUID(user_id)
            except (ValueError, TypeError):
                user_uuid = uuid_module.uuid4()

            user = db.query(User).filter(User.id == user_uuid).first()
            if not user:
                user = User(
                    id=user_uuid,
                    nickname_or_username=username,
                    role="admin",
                )
                db.add(user)
                db.commit()
                db.refresh(user)

            # Generate Node-specific JWT tokens
            access_token = self._generate_token(
                user_id=str(user_uuid),
                role="admin",
                token_type="access",
                expires_in_seconds=self.access_token_expire_seconds,
            )
            refresh_token = self._generate_token(
                user_id=user_id,
                role="admin",
                token_type="refresh",
                expires_in_seconds=self.refresh_token_expire_seconds,
            )

            return (
                access_token,
                refresh_token,
                "admin",
                self.access_token_expire_seconds,
                self.refresh_token_expire_seconds,
            )

        except (GraphQLError, HTTPException) as e:
            logger.error(f"Master GraphQL error: {str(e)}")
            raise ValueError(f"Failed to authenticate admin: {str(e)}")

    async def authenticate_player(
        self, session_id: str, node_id: str, db: SQLSession
    ) -> tuple[str, str, str, int, int]:
        """
        Authenticate a player user via Master GraphQL

        Args:
            session_id: 4-digit session ID
            node_id: Node UUID
            db: Database session

        Returns:
            Tuple of (access_token, refresh_token, role, access_expires_in, refresh_expires_in)

        Raises:
            ValueError: If session doesn't exist, not active, another player connected, or Master auth fails
        """
        # Validate session exists and is active
        try:
            session_code = int(session_id)
        except ValueError:
            raise ValueError(f"Invalid session ID format: {session_id}")
        
        session = db.query(Session).filter(Session.code == session_code).first()
        if not session:
            raise ValueError(f"Session {session_id} does not exist")
        
        if session.status != "active":
            raise ValueError(f"Session {session_id} is not active (status: {session.status})")
        
        try:
            # Check if another player is already connected (local Node rule)
            existing_connection = db.query(PlayerConnection).first()
            if existing_connection:
                raise ValueError("Another player is already connected")

            # Call Master GraphQL to authenticate player
            response = await self.graphql_client.authenticate_player(
                session_id=session_id,
                node_id=node_id,
            )

            # Extract user info from GraphQL response
            mutation_data = response.get("authenticatePlayer", {})
            user_data = mutation_data.get("user", {})
            user_id = user_data.get("id")

            if not user_id:
                raise ValueError("Failed to authenticate player: invalid response")

            # Create or update local user cache
            import uuid as uuid_module
            try:
                user_uuid = uuid_module.UUID(user_id)
            except (ValueError, TypeError):
                user_uuid = uuid_module.uuid4()

            user = db.query(User).filter(User.id == user_uuid).first()
            if not user:
                user = User(
                    id=user_uuid,
                    nickname_or_username=f"player-{str(user_uuid)[:8]}",
                    role="player",
                )
                db.add(user)
                db.commit()
                db.refresh(user)

            # Create player connection
            connection = PlayerConnection(player_id=user_uuid)
            db.add(connection)
            db.commit()

            # Generate Node-specific JWT tokens
            access_token = self._generate_token(
                user_id=str(user_uuid),
                role="player",
                token_type="access",
                expires_in_seconds=self.access_token_expire_seconds,
            )
            refresh_token = self._generate_token(
                user_id=user_id,
                role="player",
                token_type="refresh",
                expires_in_seconds=self.refresh_token_expire_seconds,
            )

            return (
                access_token,
                refresh_token,
                "player",
                self.access_token_expire_seconds,
                self.refresh_token_expire_seconds,
            )

        except (GraphQLError, HTTPException) as e:
            logger.error(f"Master GraphQL error: {str(e)}")
            raise ValueError(f"Failed to authenticate player: {str(e)}")

    def refresh_token(self, refresh_token: str, db: SQLSession) -> tuple[str, str, str, int, int]:
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

