"""Pydantic schemas for authentication"""

from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


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


# Player Schemas
class PlayerRegisterRequest(BaseModel):
    """Request to register a player device"""

    api_key: str = Field(..., min_length=10, description="Player API key")
    player_name: str = Field(..., min_length=1, max_length=255, description="Player display name")
    device_type: str | None = Field(None, description="Device type (xcode, windows, web)")


class PlayerStatusResponse(BaseModel):
    """Player registration status response"""

    player_id: str = Field(..., description="Player UUID")
    player_name: str = Field(..., description="Player display name")
    status: str = Field(..., description="Status (pending, active, disconnected)")
    registered_at: str | None = Field(None, description="ISO 8601 registration timestamp")
    activated_at: str | None = Field(None, description="ISO 8601 activation timestamp")
    session_id: str | None = Field(None, description="Assigned session ID")
    current_song_id: str | None = Field(None, description="Currently playing song ID")


class PlayerQueueItem(BaseModel):
    """Single item in player queue"""

    position: int = Field(..., description="Queue position (1-based)")
    song_id: str = Field(..., description="Song UUID")
    title: str = Field(..., description="Song title")
    artist: str = Field(..., description="Artist name")
    reserved_by: str = Field(..., description="Nickname of person who reserved")
    duration_seconds: int | None = Field(None, description="Duration in seconds")


class PlayerQueueResponse(BaseModel):
    """Player queue response"""

    queue: list[PlayerQueueItem] = Field(default_factory=list, description="List of queued songs")
    total: int = Field(default=0, description="Total songs in queue")


class AdminActivatePlayerRequest(BaseModel):
    """Request to activate a pending player"""

    session_id: str = Field(..., min_length=4, max_length=4, description="Session to assign")


class AdminPlayerListResponse(BaseModel):
    """Admin list of all players"""

    players: list[PlayerStatusResponse] = Field(
        default_factory=list, description="List of players"
    )
    total: int = Field(default=0, description="Total players")


class IdentifyRequest(BaseModel):
    """Request to identify song metadata from YouTube URL"""

    url: str = Field(
        ...,
        min_length=10,
        description="YouTube URL",
        example="https://www.youtube.com/watch?v=...",
    )


class SongMetadataResponse(BaseModel):
    """Song metadata extracted from video source (source-agnostic)"""

    # Core extracted metadata from source
    videoId: str = Field(..., description="Video ID (e.g., YouTube video ID)")
    source: str = Field(default="youtube", description="Source (youtube, spotify, etc.)")
    title: str = Field(..., description="Video title as-is from source")
    artist: str = Field(default="", description="Artist name (empty string if not available)")
    duration: int = Field(..., description="Duration in seconds")
    thumbnail: str = Field(..., description="Thumbnail image URL")
    year: str = Field(default="", description="Release year (empty string if not available)")
    language: str = Field(default="", description="Video language (empty string if not available)")
    url: str = Field(..., description="Full URL to video")
    tags: list[str] = Field(default_factory=list, description="Tags/keywords from metadata")


class DownloadSongRequest(BaseModel):
    """Request to download and finalize a song"""

    url: str = Field(
        ...,
        min_length=10,
        description="YouTube URL",
        example="https://www.youtube.com/watch?v=...",
    )
    title: str = Field(
        ..., min_length=1, description="Song title (user-edited)"
    )
    artist: Optional[str] = Field(
        default="", description="Artist name (user-edited)"
    )
    user_id: Optional[str] = Field(default="", description="User requesting download")
    reserve: bool = Field(
        default=False, description="Auto-reserve after download"
    )


class DownloadStatusResponse(BaseModel):
    """Response for download status check"""

    song_id: str = Field(..., description="Song/Draft ID", alias="songId")
    status: str = Field(
        ...,
        description="Download status (pending, downloading, completed, failed)",
    )
    progress: int = Field(default=0, description="Progress percentage 0-100")
    message: str = Field(default="", description="Status message")
    error: Optional[str] = Field(default=None, description="Error message if failed")

    model_config = ConfigDict(populate_by_name=True)

# Reservation schemas
class CreateReservationRequest(BaseModel):
    """Create reservation request"""
    song_id: str = Field(..., description="Song UUID")
    user_id: str = Field(..., description="User UUID")


class ReservationResponse(BaseModel):
    """Reservation response"""
    reservation_id: str = Field(alias="id", description="Reservation UUID")
    session_id: str = Field(..., description="Session UUID")
    song_id: str = Field(..., description="Song UUID")
    position: int = Field(..., description="Queue position (1-based)")
    status: str = Field(..., description="Reservation status")
    reserved_at: str = Field(..., description="Reservation timestamp")
    started_at: Optional[str] = Field(None, description="When playing started")
    completed_at: Optional[str] = Field(None, description="When completed")
    cancelled_at: Optional[str] = Field(None, description="When cancelled")

    model_config = ConfigDict(from_attributes=True)


class ReservationDetailResponse(BaseModel):
    """Detailed reservation with song info"""
    reservation_id: str = Field(alias="id", description="Reservation UUID")
    session_id: str = Field(..., description="Session UUID")
    song_id: str = Field(..., description="Song UUID")
    song_title: str = Field(..., description="Song title")
    song_artist: str = Field(..., description="Song artist")
    position: int = Field(..., description="Queue position")
    status: str = Field(..., description="Reservation status")
    reserved_by: str = Field(..., description="User ID who reserved")
    reserved_at: str = Field(..., description="Reservation timestamp")

    model_config = ConfigDict(from_attributes=True)


class UpdateReservationStatusRequest(BaseModel):
    """Update reservation status request"""
    status: str = Field(..., description="New status (pending, playing, completed, cancelled)")


class QueueItemResponse(BaseModel):
    """Queue item for player app"""
    position: int = Field(..., description="Queue position")
    reservation_id: str = Field(alias="id", description="Reservation UUID")
    song_id: str = Field(..., description="Song UUID")
    title: str = Field(..., description="Song title")
    artist: str = Field(..., description="Song artist")
    reserved_by: str = Field(..., description="User nickname/ID")
    status: str = Field(..., description="Reservation status (pending, playing)")
    duration_seconds: int = Field(..., description="Song duration in seconds")

    model_config = ConfigDict(from_attributes=True)


class QueueResponse(BaseModel):
    """Complete queue for a session"""
    queue: List[QueueItemResponse] = Field(..., description="Ordered list of songs")
    current_position: int = Field(default=0, description="Current playing position (0 if none)")
    total: int = Field(default=0, description="Total pending songs")


# Enhancement Schemas
class SongEnhanceRequest(BaseModel):
    """Request to enhance song metadata"""
    youtube_url: str = Field(..., description="YouTube URL of the song")
    title: Optional[str] = Field(None, min_length=1, max_length=255, description="Song title")
    artist: Optional[str] = Field(None, min_length=1, max_length=255, description="Artist name")
    year: Optional[int] = Field(None, ge=1900, le=2100, description="Release year")
    language: Optional[str] = Field(None, max_length=2, description="Language code (ISO 639-1)")
    genre: Optional[str] = Field(None, max_length=50, description="Genre classification")
    duration_seconds: Optional[int] = Field(None, ge=1, description="Duration in seconds")
    additional_notes: Optional[str] = Field(None, max_length=1000, description="Additional notes")

    model_config = ConfigDict(from_attributes=True)


class EnhancedSongMetadataResponse(BaseModel):
    """Response with enhanced song metadata"""
    youtube_url: str = Field(..., description="YouTube URL")
    title: Optional[str] = Field(None, description="Song title")
    artist: Optional[str] = Field(None, description="Artist name")
    year: Optional[int] = Field(None, description="Release year")
    language: Optional[str] = Field(None, description="Language code")
    genre: Optional[str] = Field(None, description="Genre")
    duration_seconds: Optional[int] = Field(None, description="Duration in seconds")
    additional_notes: Optional[str] = Field(None, description="Additional notes")
    enhanced_at: str = Field(..., description="Timestamp of enhancement")
    ready_to_download: bool = Field(default=True, description="Ready for download")

    model_config = ConfigDict(from_attributes=True)
