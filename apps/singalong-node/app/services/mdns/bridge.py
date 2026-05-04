"""MDNSBridgeService - manages mDNS broadcaster lifecycle."""
import logging
from typing import Optional

from app.services.mdns.broadcaster import MDNSBroadcaster
from app.services.mdns.interfaces import BroadcasterInterface

logger = logging.getLogger(__name__)


class MDNSBridgeService:
    """Manages mDNS broadcasting lifecycle for the Node service."""

    def __init__(self, broadcaster: Optional[BroadcasterInterface] = None):
        """Initialize bridge service.
        
        Args:
            broadcaster: Optional custom broadcaster implementation. 
                        Defaults to MDNSBroadcaster if None.
        """
        self.broadcaster = broadcaster or MDNSBroadcaster()
        self._node_url: Optional[str] = None

    def start(self, node_url: str = "http://localhost:5002"):
        """Start broadcasting Node availability via mDNS.
        
        Args:
            node_url: URL of the Node service
        """
        logger.info(f"Starting mDNS bridge service...")
        self._node_url = node_url
        
        try:
            success = self.broadcaster.start(node_url)
            if success:
                logger.info("✓ mDNS bridge service started successfully")
            else:
                logger.warning("✗ Failed to start mDNS broadcaster")
        except Exception as e:
            logger.error(f"Error starting mDNS bridge service: {e}", exc_info=True)

    def stop(self):
        """Stop broadcasting Node availability."""
        logger.info("Stopping mDNS bridge service...")
        try:
            self.broadcaster.stop()
            logger.info("✓ mDNS bridge service stopped")
        except Exception as e:
            logger.error(f"Error stopping mDNS bridge service: {e}", exc_info=True)

    @property
    def is_broadcasting(self) -> bool:
        """Check if mDNS broadcasting is active."""
        return self.broadcaster.is_broadcasting
