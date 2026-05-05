"""
FastAPI dependencies for common request validation and authorization.
"""

from typing import Optional
from fastapi import Depends, HTTPException, Header, status
from app.middleware.auth import verify_bearer_token


class TokenPayload:
    """Simplified token payload container"""
    def __init__(self, payload: dict):
        self.sub = payload.get("sub")  # user ID
        self.role = payload.get("role")  # user role (admin, controller, etc.)
        self.service_name = payload.get("service_name")  # service that issued token
        self.payload = payload
    
    def __repr__(self):
        return f"<TokenPayload sub={self.sub} role={self.role}>"


async def get_current_user(
    token_payload: dict = Depends(verify_bearer_token),
) -> TokenPayload:
    """
    Extract and validate current user from JWT token.
    
    Args:
        token_payload: Decoded JWT payload from verify_bearer_token
    
    Returns:
        TokenPayload: User claims from token (sub, role, etc.)
        
    Raises:
        HTTPException: If token is invalid or missing required claims
    """
    if not token_payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
        )
    
    # Validate required fields
    if not token_payload.get("sub"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing 'sub' claim",
        )
    
    if not token_payload.get("role"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing 'role' claim",
        )
    
    return TokenPayload(token_payload)


async def get_session_id(
    session_id: Optional[str] = None,
    user: TokenPayload = Depends(get_current_user),
) -> str:
    """
    Extract and validate sessionId from request.
    
    Rules:
    - Admin role: sessionId is optional (defaults to "9999" for admin workspace)
    - Attendee/Controller role: sessionId is required and must not be empty
    
    Args:
        session_id: SessionId from URL path parameter or query parameter
        user: Current authenticated user from token
        
    Returns:
        str: Validated sessionId
        
    Raises:
        HTTPException 400: If attendee omits sessionId or it's empty
        HTTPException 403: If non-admin tries to access admin workspace (9999)
    """
    # Admin workspace ID - reserved for admin operations without a real session
    ADMIN_WORKSPACE_ID = "9999"
    
    # Handle missing or empty sessionId
    if not session_id or session_id.strip() == "":
        if user.role == "admin":
            # Admin can omit sessionId, defaults to admin workspace
            return ADMIN_WORKSPACE_ID
        else:
            # Attendee/controller must provide sessionId
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="sessionId is required for your role",
            )
    
    session_id = session_id.strip()
    
    # Non-admin users cannot access admin workspace
    if session_id == ADMIN_WORKSPACE_ID and user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot access admin workspace",
        )
    
    return session_id


async def validate_session_exists(
    session_id: str = Depends(get_session_id),
    user: TokenPayload = Depends(get_current_user),
) -> dict:
    """
    Validate that a session exists.
    
    For MVP, this is a placeholder. In future, will query Master for session data.
    
    Args:
        session_id: SessionId to validate
        user: Current authenticated user
        
    Returns:
        dict: Session metadata
        
    Raises:
        HTTPException 404: If session not found
        HTTPException 403: If user cannot access this session
    """
    # Admin workspace is always valid
    if session_id == "9999":
        return {"id": "9999", "name": "Admin Workspace"}
    
    # TODO: Query Master for session validation
    # For MVP, accept any non-admin sessionId as valid
    # Future: Call Master GraphQL: query { session(id: sessionId) { id, title, ... } }
    # This validates:
    # - Session exists
    # - User has permission to access it
    # - Session is still active
    
    return {"id": session_id}
