"""Player registration and management service"""

import uuid
from datetime import datetime
from typing import Optional


class PlayerRegistration:
    """In-memory player registration record"""

    def __init__(
        self,
        player_id: str,
        player_name: str,
        status: str = "pending",
        registered_at: Optional[datetime] = None,
    ):
        self.player_id = player_id
        self.player_name = player_name
        self.status = status  # pending, active, disconnected
        self.registered_at = registered_at or datetime.utcnow()
        self.activated_at: Optional[datetime] = None
        self.session_id: Optional[str] = None
        self.current_song_id: Optional[str] = None

    def to_dict(self) -> dict:
        """Convert to dict for responses"""
        return {
            "player_id": self.player_id,
            "player_name": self.player_name,
            "status": self.status,
            "registered_at": self.registered_at.isoformat() + "Z" if self.registered_at else None,
            "activated_at": self.activated_at.isoformat() + "Z" if self.activated_at else None,
            "session_id": self.session_id,
            "current_song_id": self.current_song_id,
        }


class PlayerRegistry:
    """In-memory registry for player registrations"""

    def __init__(self, valid_api_keys: list[str]):
        """
        Initialize player registry with valid API keys

        Args:
            valid_api_keys: List of valid player API keys from NODE_PLAYER_API_KEYS env var
        """
        self.players: dict[str, PlayerRegistration] = {}
        self.valid_api_keys = valid_api_keys

    def validate_api_key(self, api_key: str) -> bool:
        """Check if api_key is in valid keys list"""
        return api_key in self.valid_api_keys

    def register_player(
        self, api_key: str, player_name: str, device_type: Optional[str] = None
    ) -> Optional[PlayerRegistration]:
        """
        Register a new player

        Args:
            api_key: Player API key to validate
            player_name: Human-readable name for the player
            device_type: Optional device type (xcode, windows, web)

        Returns:
            PlayerRegistration if valid, None if api_key invalid
        """
        if not self.validate_api_key(api_key):
            return None

        # Create new player registration
        player_id = str(uuid.uuid4())
        player = PlayerRegistration(
            player_id=player_id,
            player_name=player_name,
        )

        self.players[player_id] = player
        return player

    def get_player(self, player_id: str) -> Optional[PlayerRegistration]:
        """Get player by ID"""
        return self.players.get(player_id)

    def activate_player(self, player_id: str, session_id: str) -> Optional[PlayerRegistration]:
        """
        Activate a pending player

        Args:
            player_id: Player to activate
            session_id: Session to assign

        Returns:
            Updated PlayerRegistration if found, None if not found
        """
        player = self.players.get(player_id)
        if not player:
            return None

        player.status = "active"
        player.session_id = session_id
        player.activated_at = datetime.utcnow()
        return player

    def get_pending_players(self) -> list[PlayerRegistration]:
        """Get all pending players awaiting activation"""
        return [p for p in self.players.values() if p.status == "pending"]

    def get_active_players(self) -> list[PlayerRegistration]:
        """Get all active players"""
        return [p for p in self.players.values() if p.status == "active"]

    def get_all_players(self) -> list[PlayerRegistration]:
        """Get all players"""
        return list(self.players.values())

    def report_now_playing(self, player_id: str, song_id: str) -> Optional[PlayerRegistration]:
        """Update current song being played"""
        player = self.players.get(player_id)
        if player:
            player.current_song_id = song_id
        return player

    def report_completed(self, player_id: str) -> Optional[PlayerRegistration]:
        """Clear current song (mark as completed)"""
        player = self.players.get(player_id)
        if player:
            player.current_song_id = None
        return player


class PlayerManager:
    """Manager for player registration and status"""

    _instance: Optional["PlayerManager"] = None

    def __init__(self, valid_api_keys: list[str]):
        """Initialize player manager with valid API keys"""
        self.registry = PlayerRegistry(valid_api_keys)

    @staticmethod
    def create_singleton(valid_api_keys: list[str]) -> "PlayerManager":
        """Create or get singleton instance"""
        if PlayerManager._instance is None:
            PlayerManager._instance = PlayerManager(valid_api_keys)
        return PlayerManager._instance

    @staticmethod
    def get_instance() -> Optional["PlayerManager"]:
        """Get singleton instance"""
        return PlayerManager._instance

    def register_player(
        self, api_key: str, player_name: str, device_type: Optional[str] = None
    ) -> tuple[Optional[str], bool]:
        """
        Register a player

        Returns:
            (player_id, success) - player_id is None if api_key invalid
        """
        player = self.registry.register_player(api_key, player_name, device_type)
        if player is None:
            return None, False
        return player.player_id, True

    def get_player_status(self, player_id: str) -> Optional[dict]:
        """Get player status"""
        player = self.registry.get_player(player_id)
        if not player:
            return None
        return player.to_dict()

    def activate_player(self, player_id: str, session_id: str) -> Optional[dict]:
        """Activate a player and assign session"""
        player = self.registry.activate_player(player_id, session_id)
        if not player:
            return None
        return player.to_dict()

    def get_pending_players_list(self) -> list[dict]:
        """Get list of pending players"""
        return [p.to_dict() for p in self.registry.get_pending_players()]

    def get_all_players_list(self) -> list[dict]:
        """Get list of all players"""
        return [p.to_dict() for p in self.registry.get_all_players()]

    def report_now_playing(self, player_id: str, song_id: str) -> Optional[dict]:
        """Report current song"""
        player = self.registry.report_now_playing(player_id, song_id)
        if not player:
            return None
        return player.to_dict()

    def report_completed(self, player_id: str) -> Optional[dict]:
        """Report song completed"""
        player = self.registry.report_completed(player_id)
        if not player:
            return None
        return player.to_dict()
