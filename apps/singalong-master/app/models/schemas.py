"""Pydantic request and response schemas"""

from pydantic import BaseModel, Field


class ExchangeTokenRequest(BaseModel):
    """Request to exchange API key for JWT tokens"""

    api_key: str = Field(..., min_length=8, description="API key from environment (min 8 characters)")


class SuperadminAuthRequest(BaseModel):
    """Request to authenticate as superadmin"""

    username: str = Field(..., min_length=1, description="Superadmin username")
    password: str = Field(..., min_length=1, description="Superadmin password")


class UserResponse(BaseModel):
    """User information response"""

    id: str = Field(..., description="User ID (UUID)")
    username: str = Field(..., description="Username")
    role: str = Field(..., description="User role (superadmin, admin, player, controller)")
    nickname: str | None = Field(None, description="Optional nickname")


class TokenResponse(BaseModel):
    """JWT tokens response"""

    access_token: str = Field(..., description="JWT access token (1 hour TTL)")
    refresh_token: str = Field(..., description="JWT refresh token (7 days TTL)")
    token_type: str = Field(default="Bearer", description="Token type")
    expires_in: int = Field(default=3600, description="Access token expiry in seconds")
    refresh_expires_in: int = Field(
        default=604800, description="Refresh token expiry in seconds"
    )


class AuthResponse(BaseModel):
    """Full authentication response with user info"""

    token: str = Field(..., description="JWT access token")
    refresh_token: str = Field(..., description="JWT refresh token")
    token_type: str = Field(default="Bearer", description="Token type")
    expires_in: int = Field(default=3600, description="Access token expiry in seconds")
    refresh_expires_in: int = Field(
        default=604800, description="Refresh token expiry in seconds"
    )
    user: UserResponse = Field(..., description="Authenticated user info")


class RefreshTokenRequest(BaseModel):
    """Request to refresh an access token"""

    refresh_token: str = Field(..., description="JWT refresh token")


class TokenValidationResponse(BaseModel):
    """Response from token validation"""

    status: str = Field(default="valid", description="Token status")
    sub: str = Field(..., description="Token subject (service identifier)")
    iat: int = Field(..., description="Token issued at (timestamp)")
    exp: int = Field(..., description="Token expiration time (timestamp)")
    expires_in: int = Field(..., description="Seconds until expiration")


class ErrorResponse(BaseModel):
    """Standard error response"""

    status: str = Field(default="error", description="Status indicator")
    code: str = Field(..., description="Error code")
    message: str = Field(..., description="Human-readable error message")
    details: dict = Field(default_factory=dict, description="Additional error details")

