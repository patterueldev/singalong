"""
Abstract repository interface for WebSocket connection management.

Follows repository pattern for testability and abstraction.
Concrete implementation can be swapped for mocks in tests.
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Set, Optional
from fastapi import WebSocket


class IWebSocketConnectionRepository(ABC):
    """
    Abstract interface for managing WebSocket connections.
    
    Handles connection storage, retrieval, and lifecycle.
    Implementations must support per-session connection tracking.
    """
    
    @abstractmethod
    async def connect(self, session_id: str, websocket: WebSocket, role: str) -> None:
        """
        Register a new WebSocket connection.
        
        Args:
            session_id: Session code
            websocket: WebSocket connection
            role: User role (admin, controller, player)
        """
        pass
    
    @abstractmethod
    async def disconnect(self, session_id: str, websocket: WebSocket) -> None:
        """
        Unregister a WebSocket connection.
        
        Args:
            session_id: Session code
            websocket: WebSocket connection to remove
        """
        pass
    
    @abstractmethod
    def get_session_clients(self, session_id: str) -> List[WebSocket]:
        """
        Get all active WebSocket clients for a session.
        
        Args:
            session_id: Session code
            
        Returns:
            List of active WebSocket connections
        """
        pass
    
    @abstractmethod
    def get_session_clients_by_role(
        self, session_id: str, roles: Optional[List[str]] = None
    ) -> List[WebSocket]:
        """
        Get WebSocket clients by role filter.
        
        Args:
            session_id: Session code
            roles: List of roles to filter (admin, controller, player)
                   If None, return all
                   
        Returns:
            List of WebSocket connections matching role filter
        """
        pass
    
    @abstractmethod
    def get_active_sessions(self) -> List[str]:
        """
        Get all sessions with active connections.
        
        Returns:
            List of session codes
        """
        pass
    
    @abstractmethod
    def get_session_client_count(self, session_id: str) -> int:
        """
        Get number of active clients in a session.
        
        Args:
            session_id: Session code
            
        Returns:
            Number of active WebSocket connections
        """
        pass
