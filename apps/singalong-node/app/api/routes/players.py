"""Player device registration and management routes"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.middleware.auth import verify_bearer_token
from app.models.schemas import (
    AdminActivatePlayerRequest,
    AdminPlayerListResponse,
    PlayerQueueResponse,
    PlayerRegisterRequest,
    PlayerStatusResponse,
)
from app.services.player_manager import PlayerManager

router = APIRouter(prefix="/api/players", tags=["Players"])


def get_player_manager() -> PlayerManager:
    """Get player manager singleton"""
    manager = PlayerManager.get_instance()
    if not manager:
        raise HTTPException(
            status_code=500, detail="Player manager not initialized"
        )
    return manager


def require_admin_role(token_payload: dict = Depends(verify_bearer_token)) -> dict:
    """Verify the token has admin role"""
    user_role = token_payload.get("role")
    if user_role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin role required",
        )
    return token_payload


@router.post("/register", response_model=PlayerStatusResponse, status_code=201)
async def register_player(
    request: PlayerRegisterRequest,
    manager: PlayerManager = Depends(get_player_manager),
) -> PlayerStatusResponse:
    """
    Register a new player device

    Validates the provided API key against NODE_PLAYER_API_KEYS env var.
    Creates a pending player record that must be activated by admin.

    Args:
        request: Player registration request with api_key and player_name
        manager: Player manager service

    Returns:
        PlayerStatusResponse with player_id and pending status

    Raises:
        HTTPException 401: If API key is invalid
    """
    player_id, success = manager.register_player(
        api_key=request.api_key,
        player_name=request.player_name,
        device_type=request.device_type,
    )

    if not success:
        raise HTTPException(
            status_code=401, detail="Invalid player API key"
        )

    # Get the created player status
    player_status = manager.get_player_status(player_id)
    if not player_status:
        raise HTTPException(status_code=500, detail="Failed to retrieve player status")

    return PlayerStatusResponse(**player_status)


@router.get("/{player_id}/status", response_model=PlayerStatusResponse)
async def get_player_status(
    player_id: str,
    manager: PlayerManager = Depends(get_player_manager),
) -> PlayerStatusResponse:
    """
    Get current player status

    Polling endpoint used by players to check if they've been activated.

    Args:
        player_id: Player UUID
        manager: Player manager service

    Returns:
        PlayerStatusResponse with current status (pending or active)

    Raises:
        HTTPException 404: If player not found
    """
    player_status = manager.get_player_status(player_id)
    if not player_status:
        raise HTTPException(status_code=404, detail="Player not found")

    return PlayerStatusResponse(**player_status)


@router.get("/{player_id}/queue", response_model=PlayerQueueResponse)
async def get_player_queue(
    player_id: str,
    db: Session = Depends(get_db),
    manager: PlayerManager = Depends(get_player_manager),
) -> PlayerQueueResponse:
    """
    Get the song queue for a player

    Only works if player status is "active". Returns list of reserved songs
    in order, ready for playback.

    Args:
        player_id: Player UUID
        db: Database session
        manager: Player manager service

    Returns:
        PlayerQueueResponse with list of queued songs

    Raises:
        HTTPException 404: If player not found
        HTTPException 403: If player not active
    """
    # Verify player exists and is active
    player_status = manager.get_player_status(player_id)
    if not player_status:
        raise HTTPException(status_code=404, detail="Player not found")

    if player_status["status"] != "active":
        raise HTTPException(
            status_code=403,
            detail="Player not yet activated or not active"
        )

    # TODO: Query database for session_id and fetch reservations
    # For MVP, return empty queue (structure is correct for testing)
    # This will be implemented once session/reservation schema is finalized

    return PlayerQueueResponse(queue=[], total=0)


@router.post("/{player_id}/now-playing/{song_id}", status_code=204)
async def report_now_playing(
    player_id: str,
    song_id: str,
    manager: PlayerManager = Depends(get_player_manager),
) -> None:
    """
    Report that a song is now playing

    Updates the player's current song. Used by player to notify node
    of what's currently being displayed.

    Args:
        player_id: Player UUID
        song_id: Song UUID
        manager: Player manager service

    Raises:
        HTTPException 404: If player not found
        HTTPException 403: If player not active
    """
    player_status = manager.get_player_status(player_id)
    if not player_status:
        raise HTTPException(status_code=404, detail="Player not found")

    if player_status["status"] != "active":
        raise HTTPException(status_code=403, detail="Player not active")

    manager.report_now_playing(player_id, song_id)


@router.post("/{player_id}/completed/{song_id}", status_code=204)
async def report_song_completed(
    player_id: str,
    song_id: str,
    manager: PlayerManager = Depends(get_player_manager),
) -> None:
    """
    Report that a song has finished playing

    Updates the player's state and marks song as completed.
    Future: Triggers queue advancement logic.

    Args:
        player_id: Player UUID
        song_id: Song UUID
        manager: Player manager service

    Raises:
        HTTPException 404: If player not found
        HTTPException 403: If player not active
    """
    player_status = manager.get_player_status(player_id)
    if not player_status:
        raise HTTPException(status_code=404, detail="Player not found")

    if player_status["status"] != "active":
        raise HTTPException(status_code=403, detail="Player not active")

    manager.report_completed(player_id)


# Admin endpoints
@router.post("/admin/activate/{player_id}", response_model=PlayerStatusResponse)
async def activate_player(
    player_id: str,
    request: AdminActivatePlayerRequest,
    token_payload: dict = Depends(require_admin_role),
    manager: PlayerManager = Depends(get_player_manager),
) -> PlayerStatusResponse:
    """
    Admin: Activate a pending player

    Changes player status from "pending" to "active" and assigns a session.
    Only admins can perform this action.

    Args:
        player_id: Player UUID
        request: Activation request with session_id
        token_payload: Verified admin token
        manager: Player manager service

    Returns:
        PlayerStatusResponse with updated status="active"

    Raises:
        HTTPException 404: If player not found
        HTTPException 403: If not admin
    """
    player_status = manager.activate_player(player_id, request.session_id)
    if not player_status:
        raise HTTPException(status_code=404, detail="Player not found")

    return PlayerStatusResponse(**player_status)


@router.get("/admin/list", response_model=AdminPlayerListResponse)
async def list_all_players(
    status: str | None = None,
    token_payload: dict = Depends(require_admin_role),
    manager: PlayerManager = Depends(get_player_manager),
) -> AdminPlayerListResponse:
    """
    Admin: List all players

    Returns list of all registered players, optionally filtered by status.

    Args:
        status: Optional status filter (pending, active, disconnected)
        token_payload: Verified admin token
        manager: Player manager service

    Returns:
        AdminPlayerListResponse with list of all players
    """
    if status == "pending":
        players_list = manager.get_pending_players_list()
    else:
        players_list = manager.get_all_players_list()

    return AdminPlayerListResponse(
        players=[PlayerStatusResponse(**p) for p in players_list],
        total=len(players_list),
    )
