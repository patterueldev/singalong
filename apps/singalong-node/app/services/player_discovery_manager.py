"""Player discovery manager for handling player WebSocket connections during discovery phase"""

import logging
import uuid
from dataclasses import dataclass, field
from typing import Dict, Optional
from datetime import datetime, timezone

from fastapi import WebSocket

logger = logging.getLogger(__name__)


@dataclass
class PlayerInfo:
    """Information about a connected player"""
    player_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    name: str = ""
    platform: str = ""
    status: str = "discovering"  # discovering, locked, disconnected
    session_code: Optional[str] = None
    connected_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    ws_connection: Optional[WebSocket] = None
    
    def to_dict(self):
        """Convert to dictionary for API responses"""
        return {
            "id": self.player_id,
            "name": self.name,
            "platform": self.platform,
            "status": self.status,
        }


class PlayerDiscoveryManager:
    """Manages player discovery WebSocket connections"""
    
    _instance = None
    
    def __init__(self):
        self.players: Dict[str, PlayerInfo] = {}
        self._lock = None
    
    @classmethod
    def get_instance(cls) -> "PlayerDiscoveryManager":
        """Get singleton instance"""
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance
    
    @classmethod
    def reset(cls):
        """Reset singleton (for testing)"""
        cls._instance = None
    
    async def register_player(
        self,
        name: str,
        platform: str,
        websocket: WebSocket,
        player_id: str = None,
    ) -> PlayerInfo:
        """
        Register a new player discovery connection or reconnect existing player
        
        Args:
            name: Player name (e.g., "Pat's MacBook")
            platform: Platform (macos, ios, ipados, tvos)
            websocket: WebSocket connection from player
            player_id: Optional player ID for reconnections (reuses same ID)
            
        Returns:
            PlayerInfo object with assigned (or reused) player_id
        """
        # Reconnection: reuse existing player_id, update connection
        if player_id and player_id in self.players:
            player = self.players[player_id]
            old_status = player.status
            player.ws_connection = websocket
            player.status = "discovering"
            player.connected_at = datetime.now(timezone.utc)
            logger.info(
                f"[Discovery] reconnect | player_id={player_id[:8]}...{player_id[-4:]} | "
                f"name={name} | {old_status}→discovering"
            )
            return player
        
        # New player: generate UUID if not provided
        if player_id is None:
            player_id = str(uuid.uuid4())
        
        # Create new player entry
        player = PlayerInfo(
            player_id=player_id,
            name=name,
            platform=platform,
            ws_connection=websocket,
        )
        self.players[player_id] = player
        
        logger.info(
            f"[Discovery] register | player_id={player_id[:8]}...{player_id[-4:]} | "
            f"name={name} | platform={platform} | status=discovering"
        )
        return player
    
    async def unregister_player(self, player_id: str) -> None:
        """
        Unregister a player connection
        
        Args:
            player_id: Player ID to unregister
        """
        if player_id in self.players:
            player = self.players.pop(player_id)
            logger.info(
                f"[Player Discovery] Player unregistered | player_id={player_id} | "
                f"name={player.name}"
            )
    
    def lock_player(self, player_id: str, session_code: str) -> Optional[PlayerInfo]:
        """
        Lock a player to a session
        
        Transitions player from discovering -> locked state
        
        Args:
            player_id: Player ID to lock
            session_code: Session code to lock to
            
        Returns:
            PlayerInfo if successful, None if player not found
        """
        if player_id not in self.players:
            logger.warning(f"[Discovery] lock_failed | player_id={player_id[:8]}...{player_id[-4:]} | not_in_memory")
            return None
        
        player = self.players[player_id]
        old_status = player.status
        player.status = "locked"
        player.session_code = session_code
        
        logger.info(
            f"[Discovery] lock | player_id={player_id[:8]}...{player_id[-4:]} | "
            f"session={session_code} | name={player.name} | {old_status}→locked"
        )
        return player
    
    def unlock_player(self, player_id: str) -> Optional[PlayerInfo]:
        """
        Unlock a player from a session
        
        Transitions player from locked -> discovering state
        
        Args:
            player_id: Player ID to unlock
            
        Returns:
            PlayerInfo if successful, None if player not found
        """
        if player_id not in self.players:
            logger.warning(f"[Discovery] unlock_failed | player_id={player_id[:8]}...{player_id[-4:]} | not_in_memory")
            return None
        
        player = self.players[player_id]
        old_status = player.status
        player.status = "discovering"
        player.session_code = None
        
        logger.info(
            f"[Discovery] unlock | player_id={player_id[:8]}...{player_id[-4:]} | "
            f"name={player.name} | {old_status}→discovering"
        )
        return player
    
    def get_player(self, player_id: str) -> Optional[PlayerInfo]:
        """Get player info by ID"""
        return self.players.get(player_id)
    
    def get_available_players(self) -> list[PlayerInfo]:
        """Get all players in discovering state (available for selection)"""
        return [p for p in self.players.values() if p.status == "discovering"]
    
    def get_session_player(self, session_code: str) -> Optional[PlayerInfo]:
        """Get locked player for a session"""
        for player in self.players.values():
            if player.session_code == session_code and player.status == "locked":
                return player
        return None
    
    def get_all_players(self) -> list[PlayerInfo]:
        """Get all connected players"""
        return list(self.players.values())
