"""Authentication middleware for validating Bearer tokens"""

import time

import jwt
from fastapi import HTTPException, status

from app.main import settings
from app.services.auth_service import AuthService


# Global auth service instance
_auth_service = None


def get_auth_service() -> AuthService:
    """Get or initialize the global auth service"""
    global _auth_service
    if _auth_service is None:
        _auth_service = AuthService(
            api_key=settings.master_api_key,
            algorithm=settings.jwt_algorithm,
            access_token_expire_seconds=settings.jwt_access_token_expire_seconds,
            refresh_token_expire_seconds=settings.jwt_refresh_token_expire_seconds,
        )
    return _auth_service


def verify_bearer_token(authorization_header: str) -> dict:
    """
    Verify Bearer token from Authorization header

    Args:
        authorization_header: Value of Authorization header

    Returns:
        Decoded token payload

    Raises:
        HTTPException: If token is missing, invalid, or expired
    """
    if not authorization_header:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
        )

    # Parse "Bearer <token>"
    parts = authorization_header.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format",
        )

    token = parts[1]
    auth_service = get_auth_service()

    try:
        payload = auth_service.validate_token(token)
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
        )
    except jwt.InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token validation failed: {str(e)}",
        )
