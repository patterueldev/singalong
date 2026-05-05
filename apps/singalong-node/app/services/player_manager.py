"""Player registration and management service"""

import logging
import uuid
from datetime import datetime
from typing import Optional, Dict, List

logger = logging.getLogger(__name__)


class PlayerRegistration:
    """Represents a registered player"""

    def __init__(
        self,
        player_id: str,
        player_name: str,
        device_type: str,
        registered_at: datetime,
    ):
        self.player_id = player_id
        self.player_name = player_name
        self.device_type = device_type
        self.registered_at = registered_at
        self.status = "pending"  # pending, active, disconnected
        self.activated_at: Optional[datetime] = None
        self.session_id: Optional[str] = None
        self.current_song_id: Optional[str] = None


class PlayerManager:
    """Manages player registration and lifecycle"""

    _instance: Optional["PlayerManager"] = None
    _valid_api_keys: List[str] = []

    def __init__(self):
        self.players: Dict[str, PlayerRegistration] = {}
        logger.info("PlayerManager initialized")

    @classmethod
    def create_singleton(cls, valid_api_keys: List[str]) -> "PlayerManager":
        """Create or get singleton instance"""
        if cls._instance is None:
            cls._instance = cls()
            cls._valid_api_keys = valid_api_keys
        return cls._instance

    @classmethod
    def get_instance(cls) -> "PlayerManager":
        """Get singleton instance"""
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def register_player(
        self, api_key: str, player_name: str, device_type: str
    ) -> tuple[str, str]:
        """
        Register a new player with API key validation

        Args:
            api_key: API key from player config
            player_name: Human-readable player name
            device_type: Device type (xcode, windows, web, etc)

        Returns:
            Tuple of (player_id, status)

        Raises:
            ValueError: If API key is invalid
        """
        # Validate API key
        logger.debug(f"Validating API key. Received: '{api_key}', Valid keys: {self._valid_api_keys}")
        if api_key not in self._valid_api_keys:
            logger.warning(f"Player registration failed: invalid API key. Received: '{api_key}'")
            raise ValueError("Invalid player API key")

        # Generate player ID
        player_id = str(uuid.uuid4())

        # Create registration
        registration = PlayerRegistration(
            player_id=player_id,
            player_name=player_name,
            device_type=device_type,
            registered_at=datetime.utcnow(),
        )

        # Store in memory
        self.players[player_id] = registration

        logger.info(
            f"Player registered: {player_name} ({device_type}) - ID: {player_id}"
        )

        return player_id, registration.status

    def get_player(self, player_id: str) -> Optional[PlayerRegistration]:
        """Get player by ID"""
        return self.players.get(player_id)

    def get_player_status(self, player_id: str) -> dict:
        """Get player status for polling"""
        player = self.get_player(player_id)
        if not player:
            raise ValueError("Player not found")

        return {
            "player_id": player.player_id,
            "status": player.status,
            "activated_at": player.activated_at.isoformat() if player.activated_at else None,
            "session_id": player.session_id,
            "message": self._get_status_message(player),
        }

    def activate_player(self, player_id: str, session_id: str) -> dict:
        """Activate a registered player (admin only)"""
        player = self.get_player(player_id)
        if not player:
            raise ValueError("Player not found")

        player.status = "active"
        player.activated_at = datetime.utcnow()
        player.session_id = session_id

        logger.info(f"Player activated: {player.player_name} - session: {session_id}")

        return self.get_player_status(player_id)

    def get_pending_players(self) -> List[dict]:
        """Get all pending players (admin only)"""
        return [
            {
                "player_id": p.player_id,
                "player_name": p.player_name,
                "status": p.status,
                "device_type": p.device_type,
                "registered_at": p.registered_at.isoformat(),
            }
            for p in self.players.values()
            if p.status == "pending"
        ]

    def get_all_players(self, status: Optional[str] = None) -> List[dict]:
        """Get all players, optionally filtered by status"""
        result = []
        for p in self.players.values():
            if status and p.status != status:
                continue

            result.append(
                {
                    "player_id": p.player_id,
                    "player_name": p.player_name,
                    "status": p.status,
                    "device_type": p.device_type,
                    "session_id": p.session_id,
                    "current_song_id": p.current_song_id,
                    "registered_at": p.registered_at.isoformat(),
                    "activated_at": p.activated_at.isoformat() if p.activated_at else None,
                }
            )

        return result

    def report_now_playing(self, player_id: str, song_id: str) -> None:
        """Update the currently playing song"""
        player = self.get_player(player_id)
        if not player:
            raise ValueError("Player not found")

        if player.status != "active":
            raise ValueError("Player is not active")

        player.current_song_id = song_id
        logger.info(f"Player {player.player_name} now playing: {song_id}")

    def report_completed(self, player_id: str, song_id: str) -> None:
        """Mark song as completed"""
        player = self.get_player(player_id)
        if not player:
            raise ValueError("Player not found")

        if player.status != "active":
            raise ValueError("Player is not active")

        if player.current_song_id == song_id:
            player.current_song_id = None

        logger.info(f"Player {player.player_name} completed song: {song_id}")

    def disconnect_player(self, player_id: str) -> None:
        """Mark player as disconnected"""
        player = self.get_player(player_id)
        if player:
            player.status = "disconnected"
            logger.info(f"Player disconnected: {player.player_name}")

    @staticmethod
    def _get_status_message(player: PlayerRegistration) -> str:
        """Get human-readable status message"""
        if player.status == "pending":
            return "Awaiting admin activation"
        elif player.status == "active":
            return "Player activated and ready to play"
        elif player.status == "disconnected":
            return "Player disconnected"
        else:
            return f"Status: {player.status}"
