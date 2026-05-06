"""Authentication middleware for validating Bearer tokens"""

from functools import wraps

import jwt
from fastapi import Depends, HTTPException, Header, status

from app.config import settings
from app.services.auth_service import AuthService
from app.api.dependencies import TokenPayload


# Global auth service instance
_auth_service = None


def get_auth_service() -> AuthService:
    """Get or initialize the global auth service"""
    global _auth_service
    import logging
    logger = logging.getLogger(__name__)
    if _auth_service is None:
        logger.info("[AuthService] Creating new AuthService instance")
        _auth_service = AuthService(
            api_key=settings.jwt_secret_key,
            algorithm=settings.jwt_algorithm,
            access_token_expire_seconds=settings.jwt_access_token_expire_seconds,
            refresh_token_expire_seconds=settings.jwt_refresh_token_expire_seconds,
        )
        logger.info(f"[AuthService] AuthService instance created: {id(_auth_service)}")
    logger.info(f"[AuthService] Returning instance {id(_auth_service)}")
    return _auth_service


def verify_bearer_token(authorization: str = Header(None)) -> TokenPayload:
    """
    Verify Bearer token from Authorization header

    Args:
        authorization: Value of Authorization header

    Returns:
        TokenPayload object wrapping the decoded token payload

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
        return TokenPayload(payload)
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


def verify_admin_role(token_payload: dict = Depends(verify_bearer_token)) -> dict:
    """
    Verify that the token payload has admin role
    
    Args:
        token_payload: Decoded JWT token payload
        
    Returns:
        The token payload if role is admin
        
    Raises:
        HTTPException: If role is not admin
    """
    user_role = token_payload.get("role")
    if user_role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin role required to access this resource",
        )
    return token_payload
