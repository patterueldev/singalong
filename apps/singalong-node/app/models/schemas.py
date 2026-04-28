"""Pydantic schemas for authentication"""

from pydantic import BaseModel, Field


class AuthControllerRequest(BaseModel):
    """Request schema for controller authentication"""
    nickname: str = Field(..., min_length=1, max_length=255, description="Controller nickname")
    session_id: str = Field(..., min_length=4, max_length=4, description="4-digit session ID")


class AuthAdminRequest(BaseModel):
    """Request schema for admin authentication"""
    username: str = Field(..., min_length=1, max_length=255, description="Admin username")
    password: str = Field(..., min_length=1, description="Admin password")


class AuthPlayerRequest(BaseModel):
    """Request schema for player authentication"""
    session_id: str = Field(..., min_length=4, max_length=4, description="4-digit session ID")


class RefreshTokenRequest(BaseModel):
    """Request schema for token refresh"""
    refresh_token: str = Field(..., description="Refresh token")


class TokenResponse(BaseModel):
    """Response schema for token endpoints"""
    access_token: str = Field(..., description="JWT access token")
    refresh_token: str = Field(..., description="JWT refresh token")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: int = Field(..., description="Access token expiration in seconds")
    refresh_expires_in: int = Field(..., description="Refresh token expiration in seconds")
    role: str = Field(..., description="User role")


# Session Schemas
class CreateSessionRequest(BaseModel):
    """Request to create a new session"""
    session_id: str = Field(..., min_length=4, max_length=4, description="4-digit session code")
    title: str = Field(..., min_length=1, max_length=255, description="Session title")
    session_code: str | None = Field(None, description="Optional passcode for session")


class SessionResponse(BaseModel):
    """Session information response"""
    id: str = Field(..., description="Session UUID")
    session_id: str = Field(..., description="4-digit session code")
    title: str = Field(..., description="Session title")
    status: str = Field(..., description="Session status (ACTIVE or ENDED)")
    is_admin_session: bool = Field(..., description="Whether this is admin session (9999)")
    created_at: str = Field(..., description="ISO 8601 creation timestamp")
    ended_at: str | None = Field(None, description="ISO 8601 end timestamp")

    class Config:
        from_attributes = True


class SessionListResponse(BaseModel):
    """List of sessions response"""
    sessions: list[SessionResponse] = Field(default_factory=list, description="List of sessions")
    total: int = Field(default=0, description="Total number of sessions")


class UserInSessionResponse(BaseModel):
    """User information in a session context"""
    user_nickname: str = Field(..., description="User nickname")
    user_role: str = Field(..., description="User role in session")
    joined_at: str = Field(..., description="ISO 8601 join timestamp")


class SessionUsersResponse(BaseModel):
    """List of users in a session"""
    session_id: str = Field(..., description="4-digit session code")
    users: list[UserInSessionResponse] = Field(default_factory=list, description="Users in session")
    total: int = Field(default=0, description="Total users in session")


class ErrorResponse(BaseModel):
    """Standard error response"""
    status: str = Field(default="error", description="Status indicator")
    code: str = Field(..., description="Error code")
    message: str = Field(..., description="Error message")
    details: dict = Field(default_factory=dict, description="Additional details")


# Song Schemas
class CreateSongRequest(BaseModel):
    """Request to create/add a new song"""

    youtube_url: str = Field(..., description="YouTube URL for the song")
    title: str = Field(..., description="Song title")
    artist: str = Field(..., description="Artist name")
    duration: int | None = Field(None, description="Duration in seconds")
    genre: str | None = Field(None, description="Music genre")
    year: int | None = Field(None, description="Release year")


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

    songs: list[SongResponse] = Field(default_factory=list, description="List of songs")
    total: int = Field(default=0, description="Total number of songs")


class SongStatusResponse(BaseModel):
    """Song download status response"""

    song_id: str = Field(..., description="Song UUID")
    status: str = Field(..., description="Current status (DRAFT, DOWNLOADING, COMPLETED, FAILED)")
    progress: int = Field(0, description="Download progress (0-100)")
    error_message: str | None = Field(None, description="Error message if status is FAILED")

