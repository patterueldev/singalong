"""Player registration and management endpoints"""

import logging
from typing import Optional
from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel, Field
from app.services.player_manager import PlayerManager
from app.middleware.auth import verify_bearer_token

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/players", tags=["Players"])


class PlayerRegisterRequest(BaseModel):
    """Player registration request"""

    api_key: str = Field(..., description="Player API key from configuration")
    player_name: str = Field(..., description="Human-readable player name")
    device_type: str = Field(
        ..., description="Device type (xcode, windows, web, etc)"
    )


class PlayerStatusResponse(BaseModel):
    """Player status response"""

    player_id: str = Field(..., description="Unique player ID")
    status: str = Field(..., description="Player status (pending, active, disconnected)")
    activated_at: Optional[str] = Field(None, description="When player was activated")
    session_id: Optional[str] = Field(None, description="Assigned session ID")
    message: str = Field(..., description="Human-readable status message")


class PlayerListResponse(BaseModel):
    """Player list response"""

    player_id: str = Field(..., description="Unique player ID")
    player_name: str = Field(..., description="Player name")
    status: str = Field(..., description="Player status")
    device_type: str = Field(..., description="Device type")
    session_id: str = Field(None, description="Assigned session ID")
    current_song_id: str = Field(None, description="Currently playing song")
    registered_at: str = Field(..., description="Registration timestamp")
    activated_at: str = Field(None, description="Activation timestamp")


def verify_admin(token_payload: dict = Depends(verify_bearer_token)) -> dict:
    """Verify that token has admin role"""
    role = token_payload.get("role")
    if role != "admin":
        raise HTTPException(status_code=403, detail="Admin role required")
    return token_payload


@router.post("/register", status_code=201, response_model=PlayerStatusResponse)
async def register_player(request: PlayerRegisterRequest) -> PlayerStatusResponse:
    """
    Register a new player

    Player provides valid API key from configuration.
    Returns player_id which player uses for polling status.

    Status starts as 'pending' - admin must activate before player can play.

    Args:
        request: PlayerRegisterRequest with api_key, player_name, device_type

    Returns:
        PlayerStatusResponse with player_id and pending status

    Raises:
        HTTPException: 401 if API key is invalid
    """
    try:
        player_manager = PlayerManager.get_instance()

        # Register player
        player_id, status = player_manager.register_player(
            api_key=request.api_key,
            player_name=request.player_name,
            device_type=request.device_type,
        )

        # Get full status
        player_status = player_manager.get_player_status(player_id)

        logger.info(
            f"Player registered: {request.player_name} (ID: {player_id})",
        )

        return PlayerStatusResponse(**player_status)

    except ValueError as e:
        logger.warning(f"Player registration failed: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid player API key")

    except Exception as e:
        logger.exception(f"Error registering player: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to register player")


@router.get("/{player_id}/status", response_model=PlayerStatusResponse)
async def get_player_status(player_id: str) -> PlayerStatusResponse:
    """
    Get player status (polling endpoint)

    No authentication required - player polls this endpoint every 5 seconds.
    Status transitions from 'pending' to 'active' when admin activates.

    Args:
        player_id: Player UUID from registration

    Returns:
        PlayerStatusResponse with current status

    Raises:
        HTTPException: 404 if player not found
    """
    try:
        player_manager = PlayerManager.get_instance()

        # Get status
        player_status = player_manager.get_player_status(player_id)

        return PlayerStatusResponse(**player_status)

    except ValueError as e:
        logger.warning(f"Player status check failed: {str(e)}")
        raise HTTPException(status_code=404, detail="Player not found")

    except Exception as e:
        logger.exception(f"Error getting player status: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get player status")


@router.get("/{player_id}/queue")
async def get_player_queue(player_id: str) -> dict:
    """
    Get song queue for player

    Only works if player status is 'active'.
    Returns ordered list of songs to play.

    Args:
        player_id: Player UUID

    Returns:
        Queue with song list (empty for MVP)

    Raises:
        HTTPException: 403 if player not active, 404 if not found
    """
    try:
        player_manager = PlayerManager.get_instance()

        # Check player exists and is active
        player = player_manager.get_player(player_id)
        if not player:
            raise ValueError("Player not found")

        if player.status != "active":
            raise HTTPException(
                status_code=403,
                detail="Player not yet activated or not active",
            )

        # For MVP, return empty queue
        # TODO: Query sessions/reservations tables for actual queue
        return {"queue": []}

    except HTTPException:
        raise

    except ValueError as e:
        logger.warning(f"Queue fetch failed: {str(e)}")
        raise HTTPException(status_code=404, detail="Player not found")

    except Exception as e:
        logger.exception(f"Error getting queue: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get queue")


@router.post("/{player_id}/now-playing/{song_id}", status_code=204)
async def report_now_playing(player_id: str, song_id: str) -> None:
    """
    Report currently playing song

    Called by player when starting to play a song.

    Args:
        player_id: Player UUID
        song_id: Song UUID

    Raises:
        HTTPException: 404 if player not found, 403 if not active
    """
    try:
        player_manager = PlayerManager.get_instance()

        # Report now playing
        player_manager.report_now_playing(player_id, song_id)

        logger.info(f"Player {player_id} now playing: {song_id}")

    except ValueError as e:
        if "not found" in str(e):
            raise HTTPException(status_code=404, detail="Player not found")
        else:
            raise HTTPException(status_code=403, detail=str(e))

    except Exception as e:
        logger.exception(f"Error reporting now playing: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to report playback")


@router.post("/{player_id}/completed/{song_id}", status_code=204)
async def report_completed(player_id: str, song_id: str) -> None:
    """
    Report song completed

    Called by player when song finishes.
    Auto-advances to next song in queue (future feature).

    Args:
        player_id: Player UUID
        song_id: Song UUID

    Raises:
        HTTPException: 404 if player not found, 403 if not active
    """
    try:
        player_manager = PlayerManager.get_instance()

        # Report completed
        player_manager.report_completed(player_id, song_id)

        logger.info(f"Player {player_id} completed: {song_id}")

    except ValueError as e:
        if "not found" in str(e):
            raise HTTPException(status_code=404, detail="Player not found")
        else:
            raise HTTPException(status_code=403, detail=str(e))

    except Exception as e:
        logger.exception(f"Error reporting completed: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to report completion")


@router.post("/admin/{player_id}/activate", response_model=PlayerStatusResponse)
async def activate_player(
    player_id: str,
    session_id: str,
    admin_token: dict = Depends(verify_admin),
) -> PlayerStatusResponse:
    """
    Activate a pending player (admin only)

    Called by admin to approve and activate a registered player.
    Updates status to 'active' and assigns session_id.

    Args:
        player_id: Player UUID
        session_id: 4-digit session ID to assign
        admin_token: Admin authentication token

    Returns:
        PlayerStatusResponse with updated status

    Raises:
        HTTPException: 404 if player not found, 401 if not admin
    """
    try:
        player_manager = PlayerManager.get_instance()

        # Activate player
        player_status = player_manager.activate_player(player_id, session_id)

        logger.info(f"Player {player_id} activated by admin")

        return PlayerStatusResponse(**player_status)

    except ValueError as e:
        logger.warning(f"Player activation failed: {str(e)}")
        raise HTTPException(status_code=404, detail="Player not found")

    except Exception as e:
        logger.exception(f"Error activating player: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to activate player")


@router.get("/admin/list", response_model=dict)
async def list_players(
    status: str = None,
    admin_token: dict = Depends(verify_admin),
) -> dict:
    """
    List all players (admin only)

    Args:
        status: Optional filter by status (pending, active, disconnected)
        admin_token: Admin authentication token

    Returns:
        List of players
    """
    try:
        player_manager = PlayerManager.get_instance()

        # Get players
        players = player_manager.get_all_players(status=status)

        logger.info(f"Admin fetched {len(players)} player(s)")

        return {"players": players}

    except Exception as e:
        logger.exception(f"Error listing players: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to list players")
