"""Pydantic request and response schemas"""

from pydantic import BaseModel, Field


class ExchangeTokenRequest(BaseModel):
    """Request to exchange API key for JWT tokens"""

    api_key: str = Field(..., description="API key from environment")


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


# Session Schemas
class SessionResponse(BaseModel):
    """Session information response"""

    id: str = Field(..., description="Session UUID")
    node_id: str = Field(..., description="Node ID this session belongs to")
    session_id: str = Field(..., description="4-digit session code (0000-9999)")
    title: str = Field(..., description="Session title")
    status: str = Field(..., description="Session status (ACTIVE or ENDED)")
    is_admin_session: bool = Field(..., description="Whether this is the special admin session (9999)")
    created_at: str = Field(..., description="ISO 8601 creation timestamp")
    ended_at: str | None = Field(None, description="ISO 8601 end timestamp (null if still active)")
    user_count: int = Field(default=0, description="Number of users in session")

    class Config:
        from_attributes = True


class UserSessionMembershipResponse(BaseModel):
    """User session membership information"""

    id: str = Field(..., description="Membership UUID")
    user_nickname: str = Field(..., description="User nickname")
    session_id: str = Field(..., description="4-digit session code")
    node_id: str = Field(..., description="Node ID")
    user_role: str = Field(..., description="Role of user (controller, admin, player)")
    joined_at: str = Field(..., description="ISO 8601 join timestamp")
    left_at: str | None = Field(None, description="ISO 8601 leave timestamp")

    class Config:
        from_attributes = True


# Song Schemas
class CreateSongRequest(BaseModel):
    """Request to create/add a new song"""

    youtube_url: str = Field(..., description="YouTube URL for the song")
    title: str = Field(..., description="Song title")
    artist: str = Field(..., description="Artist name")
    duration: int | None = Field(None, description="Duration in seconds")
    genre: str | None = Field(None, description="Music genre")
    year: int | None = Field(None, description="Release year")

    class Config:
        from_attributes = True


class SongResponse(BaseModel):
    """Song information response"""

    id: str = Field(..., description="Song UUID")
    title: str = Field(..., description="Song title")
    artist: str = Field(..., description="Artist name")
    duration: int | None = Field(None, description="Duration in seconds")
    genre: str | None = Field(None, description="Music genre")
    year: int | None = Field(None, description="Release year")
    status: str = Field(..., description="Song status (DRAFT, DOWNLOADING, COMPLETED, FAILED)")
    created_at: str = Field(..., description="ISO 8601 creation timestamp")
    updated_at: str = Field(..., description="ISO 8601 last update timestamp")

    class Config:
        from_attributes = True


class SongListResponse(BaseModel):
    """List of songs response"""

    songs: list[SongResponse] = Field(..., description="List of songs")
    total: int = Field(..., description="Total number of songs")

    class Config:
        from_attributes = True


class SongStatusResponse(BaseModel):
    """Song download status response"""

    song_id: str = Field(..., description="Song UUID")
    status: str = Field(..., description="Current status (DRAFT, DOWNLOADING, COMPLETED, FAILED)")
    progress: int = Field(0, description="Download progress (0-100)")
    error_message: str | None = Field(None, description="Error message if status is FAILED")

    class Config:
        from_attributes = True
