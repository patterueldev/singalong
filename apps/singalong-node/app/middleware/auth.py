"""Authentication middleware for validating Bearer tokens"""

from functools import wraps

import jwt
from fastapi import Depends, HTTPException, Header, status

from app.config import settings
from app.services.auth_service import AuthService


# Global auth service instance
_auth_service = None


def get_auth_service() -> AuthService:
    """Get or initialize the global auth service"""
    global _auth_service
    if _auth_service is None:
        _auth_service = AuthService(
            api_key=settings.jwt_secret_key,
            algorithm=settings.jwt_algorithm,
            access_token_expire_seconds=settings.jwt_access_token_expire_seconds,
            refresh_token_expire_seconds=settings.jwt_refresh_token_expire_seconds,
        )
    return _auth_service


def verify_bearer_token(authorization: str = Header(None)) -> dict:
    """
    Verify Bearer token from Authorization header

    Args:
        authorization: Value of Authorization header

    Returns:
        Decoded token payload

    Raises:
        HTTPException: If token is missing, invalid, or expired
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
        )

    # Parse "Bearer <token>"
    parts = authorization.split()
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


def require_role(*allowed_roles: str):
    """
    Decorator to require a specific role

    Args:
        allowed_roles: Role(s) that are allowed

    Returns:
        Decorator function
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, token_payload: dict = Depends(verify_bearer_token), **kwargs):
            user_role = token_payload.get("role")
            if user_role not in allowed_roles:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Insufficient permissions. Required role(s): {', '.join(allowed_roles)}",
                )
            return await func(*args, token_payload=token_payload, **kwargs)
        return wrapper
    return decorator
