"""Authentication service - JWT token generation and validation"""

import time
from datetime import datetime, timedelta, timezone

import jwt

from app.main import settings


class AuthService:
    """Handles JWT token generation, validation, and refresh"""

    def __init__(
        self,
        api_keys: str,
        algorithm: str = "HS256",
        access_token_expire_seconds: int = 3600,
        refresh_token_expire_seconds: int = 604800,
    ):
        """
        Initialize auth service

        Args:
            api_keys: Comma-separated API keys (e.g., "key1,key2,key3")
            algorithm: JWT algorithm (HS256 default)
            access_token_expire_seconds: Access token TTL in seconds (default 1 hour)
            refresh_token_expire_seconds: Refresh token TTL in seconds (default 7 days)
        """
        # Parse comma-separated keys and strip whitespace
        self.api_keys = [key.strip() for key in api_keys.split(",")]
        # Use the first key as the primary secret for JWT operations
        self.api_key = self.api_keys[0]
        self.algorithm = algorithm
        self.access_token_expire_seconds = access_token_expire_seconds
        self.refresh_token_expire_seconds = refresh_token_expire_seconds
        self.service_name = "singalong-master"

    def exchange_api_key(self) -> tuple[str, str, int, int]:
        """
        Exchange API key for JWT tokens

        Returns:
            Tuple of (access_token, refresh_token, access_expires_in, refresh_expires_in)
        """
        access_token = self._generate_token(
            token_type="access", expires_in_seconds=self.access_token_expire_seconds
        )
        refresh_token = self._generate_token(
            token_type="refresh", expires_in_seconds=self.refresh_token_expire_seconds
        )
        return (
            access_token,
            refresh_token,
            self.access_token_expire_seconds,
            self.refresh_token_expire_seconds,
        )

    def refresh_access_token(self, refresh_token: str) -> tuple[str, str, int, int]:
        """
        Validate refresh token and generate new access + refresh tokens

        Args:
            refresh_token: JWT refresh token to validate

        Returns:
            Tuple of (new_access_token, new_refresh_token, access_expires_in, refresh_expires_in)

        Raises:
            jwt.ExpiredSignatureError: If refresh token is expired
            jwt.InvalidTokenError: If refresh token is invalid
        """
        # Validate refresh token with any of the valid API keys
        payload = None
        for api_key in self.api_keys:
            try:
                payload = jwt.decode(
                    refresh_token, api_key, algorithms=[self.algorithm]
                )
                break
            except jwt.ExpiredSignatureError:
                # If token is expired, raise immediately (don't try other keys)
                raise
            except jwt.InvalidTokenError:
                continue

        if payload is None:
            raise jwt.InvalidTokenError("Invalid token")

        # Check token type
        if payload.get("token_type") != "refresh":
            raise jwt.InvalidTokenError("Invalid token type")

        # Check service name
        if payload.get("service_name") != self.service_name:
            raise jwt.InvalidTokenError("Invalid service name in token")

        # Generate new tokens
        access_token = self._generate_token(
            token_type="access", expires_in_seconds=self.access_token_expire_seconds
        )
        new_refresh_token = self._generate_token(
            token_type="refresh", expires_in_seconds=self.refresh_token_expire_seconds
        )

        return (
            access_token,
            new_refresh_token,
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
        # Validate token with any of the valid API keys
        payload = None
        last_error = None
        for api_key in self.api_keys:
            try:
                payload = jwt.decode(token, api_key, algorithms=[self.algorithm])
                break
            except jwt.ExpiredSignatureError as e:
                # If token is expired, raise immediately (don't try other keys)
                raise
            except jwt.InvalidTokenError as e:
                last_error = e
                continue

        if payload is None:
            raise jwt.InvalidTokenError("Invalid token")

        # Check service name
        if payload.get("service_name") != self.service_name:
            raise jwt.InvalidTokenError("Invalid service name in token")

        # Calculate expires_in
        exp = payload.get("exp", 0)
        now = int(time.time())
        expires_in = max(0, exp - now)

        payload["expires_in"] = expires_in
        return payload

    def _generate_token(self, token_type: str, expires_in_seconds: int) -> str:
        """
        Generate JWT token

        Args:
            token_type: Type of token ("access" or "refresh")
            expires_in_seconds: Token TTL in seconds

        Returns:
            Encoded JWT token
        """
        now = datetime.now(timezone.utc)
        exp = now + timedelta(seconds=expires_in_seconds)

        payload = {
            "sub": self.service_name,
            "service_name": self.service_name,
            "iat": int(now.timestamp()),
            "exp": int(exp.timestamp()),
            "token_type": token_type,
        }

        token = jwt.encode(payload, self.api_key, algorithm=self.algorithm)
        return token
