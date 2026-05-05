"""mDNS broadcasting service for Node discovery"""

import logging
from zeroconf import ServiceInfo, Zeroconf
from typing import Optional

logger = logging.getLogger(__name__)


class MDNSBroadcaster:
    """Handles mDNS broadcasting of Node service"""
    
    _instance = None
    _zeroconf: Optional[Zeroconf] = None
    _service_info: Optional[ServiceInfo] = None
    
    def __init__(self):
        pass
    
    @classmethod
    def get_instance(cls) -> "MDNSBroadcaster":
        """Get singleton instance"""
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance
    
    @classmethod
    def reset(cls):
        """Reset singleton (for testing)"""
        cls._instance = None
        cls._zeroconf = None
        cls._service_info = None
    
    def broadcast(self, node_name: str = "Singalong Node", port: int = 5002) -> bool:
        """
        Start broadcasting Node service via mDNS
        
        Args:
            node_name: Human-readable name for the Node (e.g., "Singalong Node")
            port: Port number Node is listening on
            
        Returns:
            True if broadcast started successfully, False otherwise
        
        Note: mDNS broadcast may fail in containerized environments (Docker).
        This is non-fatal - players can still discover nodes via manual URL entry.
        """
        try:
            # Create Zeroconf instance with a timeout
            # In containers, this may fail due to network configuration
            import threading
            
            def _do_broadcast():
                try:
                    self._zeroconf = Zeroconf(interfaces=["0.0.0.0"])
                    
                    # Create service info
                    # Service name format: <instance>.<service>.<domain>
                    # Instance: "Singalong Node"
                    # Service: _singalong-node._tcp (underscores are part of DNS-SD spec)
                    # Domain: local.
                    service_type = "_singalong-node._tcp.local."
                    
                    self._service_info = ServiceInfo(
                        service_type,
                        f"{node_name}.{service_type}",
                        port=port,
                        properties={
                            "node_name": node_name,
                            "service": "singalong-node",
                        },
                    )
                    
                    # Register the service
                    self._zeroconf.register_service(self._service_info)
                    logger.info(
                        f"[mDNS] Node broadcast started | name={node_name} | "
                        f"service={service_type} | port={port}"
                    )
                except Exception as e:
                    logger.warning(
                        f"[mDNS] Broadcast failed (non-fatal) | error={type(e).__name__}: {str(e)}"
                    )
            
            # Try to broadcast in background thread with timeout
            thread = threading.Thread(target=_do_broadcast, daemon=True)
            thread.start()
            thread.join(timeout=2.0)  # Wait max 2 seconds
            
            return True
            
        except Exception as e:
            logger.warning(
                f"[mDNS] Broadcast setup failed (non-fatal, continuing) | "
                f"error={type(e).__name__}: {str(e)}"
            )
            # Don't fail startup if mDNS fails - it's optional for Docker containers
            return False
    
    def stop_broadcast(self) -> None:
        """Stop mDNS broadcasting"""
        try:
            if self._service_info and self._zeroconf:
                self._zeroconf.unregister_service(self._service_info)
                logger.info("[mDNS] Node broadcast stopped")
            
            if self._zeroconf:
                self._zeroconf.close()
                self._zeroconf = None
                self._service_info = None
                
        except Exception as e:
            logger.error(f"[mDNS] Stop broadcast failed | error={str(e)}", exc_info=True)
