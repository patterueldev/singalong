"""Authentication API routes"""

from fastapi import APIRouter, Header, HTTPException, status

from app.middleware.auth import get_auth_service
from app.models.schemas import (
    ErrorResponse,
    ExchangeTokenRequest,
    RefreshTokenRequest,
    TokenResponse,
    TokenValidationResponse,
)

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/exchange", response_model=TokenResponse)
async def exchange_api_key(request: ExchangeTokenRequest) -> TokenResponse:
    """
    Exchange API key for JWT tokens

    This endpoint is called by Node services to authenticate with Master.
    The API key must match the MASTER_API_KEY in environment variables.

    Args:
        request: Request with api_key field

    Returns:
        TokenResponse with access_token and refresh_token

    Raises:
        HTTPException 401: If API key is invalid
    """
    from app.main import settings

    # Validate API key
    if request.api_key != settings.master_api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
        )

    # Generate tokens
    auth_service = get_auth_service()
    access_token, refresh_token, access_expires, refresh_expires = (
        auth_service.exchange_api_key()
    )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=access_expires,
        refresh_expires_in=refresh_expires,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_access_token(request: RefreshTokenRequest) -> TokenResponse:
    """
    Refresh an access token using a refresh token

    Args:
        request: Request with refresh_token field

    Returns:
        TokenResponse with new access_token and refresh_token

    Raises:
        HTTPException 401: If refresh token is invalid or expired
    """
    auth_service = get_auth_service()

    try:
        access_token, new_refresh_token, access_expires, refresh_expires = (
            auth_service.refresh_access_token(request.refresh_token)
        )

        return TokenResponse(
            access_token=access_token,
            refresh_token=new_refresh_token,
            expires_in=access_expires,
            refresh_expires_in=refresh_expires,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        )


@router.get("/validate", response_model=TokenValidationResponse)
async def validate_token(
    authorization: str | None = Header(None),
) -> TokenValidationResponse:
    """
    Validate an access token

    Args:
        authorization: Authorization header (Bearer <token>)

    Returns:
        TokenValidationResponse with token details

    Raises:
        HTTPException 401: If token is missing, invalid, or expired
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
        )

    auth_service = get_auth_service()
    try:
        payload = auth_service.validate_token(authorization.replace("Bearer ", ""))
        return TokenValidationResponse(
            status="valid",
            sub=payload.get("sub"),
            iat=payload.get("iat"),
            exp=payload.get("exp"),
            expires_in=payload.get("expires_in"),
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )
