"""Authentication API routes"""

from fastapi import APIRouter, Header, HTTPException, status

from app.database import SessionLocal
from app.middleware.auth import get_auth_service
from app.models.db_models import User, UserRole
from app.models.schemas import (
    AuthResponse,
    ExchangeTokenRequest,
    RefreshTokenRequest,
    SuperadminAuthRequest,
    TokenResponse,
    TokenValidationResponse,
    UserResponse,
)
from app.services.user_auth_service import UserAuthService

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/exchange", response_model=TokenResponse)
async def exchange_api_key(request: ExchangeTokenRequest) -> TokenResponse:
    """
    Exchange API key for JWT tokens

    This endpoint is called by Node services to authenticate with Master.
    The API key must match one of the MASTER_API_KEY entries (comma-separated).

    Args:
        request: Request with api_key field

    Returns:
        TokenResponse with access_token and refresh_token

    Raises:
        HTTPException 401: If API key is invalid
    """
    from app.main import settings

    # Validate API key - check against any of the configured keys
    valid_keys = [key.strip() for key in settings.master_api_key.split(",")]
    if request.api_key not in valid_keys:
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


@router.post("/superadmin", response_model=AuthResponse)
async def authenticate_superadmin(request: SuperadminAuthRequest) -> AuthResponse:
    """
    Authenticate as superadmin

    Args:
        request: Request with username and password

    Returns:
        AuthResponse with JWT tokens and user info

    Raises:
        HTTPException 401: If username or password is invalid
    """
    db = SessionLocal()
    try:
        # Find superadmin user
        user = db.query(User).filter(User.username == request.username).first()
        if not user or user.role != UserRole.SUPERADMIN:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid username or password",
            )

        # Verify password
        user_auth = UserAuthService()
        if not user_auth._verify_password(request.password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid username or password",
            )

        # Generate tokens
        access_token = user_auth._generate_token(
            user_id=str(user.id),
            role=user.role.value,
            token_type="access",
            expires_in_seconds=user_auth.access_token_expire_seconds,
        )
        refresh_token = user_auth._generate_token(
            user_id=str(user.id),
            role=user.role.value,
            token_type="refresh",
            expires_in_seconds=user_auth.refresh_token_expire_seconds,
        )

        return AuthResponse(
            token=access_token,
            refresh_token=refresh_token,
            expires_in=user_auth.access_token_expire_seconds,
            refresh_expires_in=user_auth.refresh_token_expire_seconds,
            user=UserResponse(
                id=str(user.id),
                username=user.username,
                role=user.role.value,
                nickname=None,
            ),
        )
    finally:
        db.close()


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
    Validate an access token (API key or user-level)

    Args:
        authorization: Authorization header (Bearer <token>)

    Returns:
        TokenValidationResponse with token details

    Raises:
        HTTPException 401: If token is missing, invalid, or expired
    """
    from app.main import settings

    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
        )

    auth_service = get_auth_service()
    token = authorization.replace("Bearer ", "")

    # Try API key JWT secret first (for API key tokens)
    try:
        payload = auth_service.validate_token(token)
        return TokenValidationResponse(
            status="valid",
            sub=payload.get("sub"),
            iat=payload.get("iat"),
            exp=payload.get("exp"),
            expires_in=payload.get("expires_in"),
        )
    except Exception:
        pass

    # Try user JWT secret (for user-level tokens like superadmin)
    try:
        import jwt

        payload = jwt.decode(
            token, settings.user_jwt_secret, algorithms=["HS256"]
        )
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
