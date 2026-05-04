"""Abstract interfaces for mDNS broadcasting."""
from abc import ABC, abstractmethod


class BroadcasterInterface(ABC):
    """Interface for mDNS service broadcasters."""

    @abstractmethod
    def start(self, node_url: str) -> bool:
        """Start broadcasting the service.
        
        Args:
            node_url: URL of the Node service
            
        Returns:
            True if broadcast started successfully, False otherwise
        """
        pass

    @abstractmethod
    def stop(self):
        """Stop broadcasting the service."""
        pass

    @property
    @abstractmethod
    def is_broadcasting(self) -> bool:
        """Check if currently broadcasting."""
        pass
