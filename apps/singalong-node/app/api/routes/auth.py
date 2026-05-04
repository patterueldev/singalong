"""Authentication routes"""

import jwt
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.middleware.auth import get_auth_service
from app.models.schemas import (
    AuthAdminRequest,
    AuthControllerRequest,
    AuthPlayerRequest,
    RefreshTokenRequest,
    TokenResponse,
)

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/controller", response_model=TokenResponse, status_code=201)
async def authenticate_controller(
    request: AuthControllerRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    """
    Authenticate as a controller (attendee)

    Args:
        request: Controller auth request (nickname, session_id)
        db: Database session

    Returns:
        TokenResponse with access/refresh tokens and role

    Raises:
        HTTPException 400: If request is invalid or Master auth fails
    """
    auth_service = get_auth_service()

    try:
        access_token, refresh_token, role, access_expires, refresh_expires = (
            await auth_service.authenticate_controller(
                nickname=request.nickname,
                session_id=request.session_id,
                node_id=settings.node_id,
                db=db,
            )
        )

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=access_expires,
            refresh_expires_in=refresh_expires,
            role=role,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.post("/admin", response_model=TokenResponse, status_code=201)
async def authenticate_admin(
    request: AuthAdminRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    """
    Authenticate as an admin (manager)

    Args:
        request: Admin auth request (username, password)
        db: Database session

    Returns:
        TokenResponse with access/refresh tokens and role

    Raises:
        HTTPException 401: If credentials are invalid
        HTTPException 400: If request is invalid or Master auth fails
    """
    auth_service = get_auth_service()

    try:
        access_token, refresh_token, role, access_expires, refresh_expires = (
            await auth_service.authenticate_admin(
                username=request.username,
                password=request.password,
                node_id=settings.node_id,
                db=db,
            )
        )

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=access_expires,
            refresh_expires_in=refresh_expires,
            role=role,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )


@router.post("/player", response_model=TokenResponse, status_code=201)
async def authenticate_player(
    request: AuthPlayerRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    """
    Authenticate as a player (playback device)

    Args:
        request: Player auth request (session_id)
        db: Database session

    Returns:
        TokenResponse with access/refresh tokens and role

    Raises:
        HTTPException 409: If another player is already connected
        HTTPException 400: If request is invalid or Master auth fails
    """
    auth_service = get_auth_service()

    try:
        access_token, refresh_token, role, access_expires, refresh_expires = (
            await auth_service.authenticate_player(
                session_id=request.session_id,
                node_id=settings.node_id,
                db=db,
            )
        )

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=access_expires,
            refresh_expires_in=refresh_expires,
            role=role,
        )
    except ValueError as e:
        error_str = str(e)
        if "already connected" in error_str:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=error_str,
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=error_str,
            )


@router.post("/refresh", response_model=TokenResponse, status_code=200)
async def refresh_tokens(
    request: RefreshTokenRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    """
    Refresh access token using refresh token

    Args:
        request: Refresh token request
        db: Database session

    Returns:
        TokenResponse with new access/refresh tokens and role

    Raises:
        HTTPException 401: If refresh token is invalid or expired
        HTTPException 400: If request is invalid
    """
    auth_service = get_auth_service()

    try:
        access_token, refresh_token, role, access_expires, refresh_expires = (
            auth_service.refresh_token(request.refresh_token, db)
        )

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=access_expires,
            refresh_expires_in=refresh_expires,
            role=role,
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token has expired",
        )
    except jwt.InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid refresh token: {str(e)}",
        )



@router.post("/admin-dev", response_model=TokenResponse, status_code=201)
async def authenticate_admin_dev(db: Session = Depends(get_db)) -> TokenResponse:
    """
    **DEVELOPMENT ONLY** - Bypass admin authentication for testing
    
    This endpoint is only available in development mode (DEBUG=True).
    It returns a valid admin token without requiring Master auth.
    
    **DO NOT USE IN PRODUCTION**
    """
    if not settings.debug:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Dev endpoint only available in DEBUG mode",
        )
    
    auth_service = get_auth_service()
    
    try:
        access_token, refresh_token, role, access_expires, refresh_expires = (
            auth_service.create_admin_token(node_id=settings.node_id)
        )
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=access_expires,
            refresh_expires_in=refresh_expires,
            role=role,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create dev token: {str(e)}",
        )
