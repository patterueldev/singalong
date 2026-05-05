"""mDNS service broadcasting via zeroconf (cross-platform)."""
import logging
import socket
import threading
import time
from typing import Optional

from zeroconf import IPVersion, ServiceInfo, Zeroconf

from app.services.mdns.interfaces import BroadcasterInterface

logger = logging.getLogger(__name__)


class MDNSBroadcaster(BroadcasterInterface):
    """Broadcasts Singalong Node via zeroconf (macOS, Linux, Windows)."""

    def __init__(
        self,
        service_name: str = "Singalong Node",
        service_type: str = "_singalong-node._tcp",
        port: int = 5002,
    ):
        """Initialize broadcaster.
        
        Args:
            service_name: mDNS service name
            service_type: mDNS service type (e.g., _http._tcp)
            port: Port number for the service
        """
        self.service_name = service_name
        self.service_type = service_type
        self.port = port
        self.zeroconf: Optional[Zeroconf] = None
        self.service_info: Optional[ServiceInfo] = None
        self._is_broadcasting = False

    def start(self, node_url: str) -> bool:
        """Start broadcasting mDNS service via zeroconf.
        
        Args:
            node_url: URL of the Node service (used for validation, not in broadcast)
            
        Returns:
            True if broadcast started successfully
        """
        try:
            # Get local IP
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                s.connect(("8.8.8.8", 80))
                local_ip = s.getsockname()[0]
                s.close()
            except Exception:
                hostname = socket.gethostname()
                local_ip = socket.gethostbyname(hostname)

            logger.info(f"Detected network IP: {local_ip}")

            # Get hostname for mDNS
            try:
                hostname = socket.gethostname()
                if hostname.endswith(".local"):
                    hostname = hostname[:-6]
            except Exception:
                hostname = "singalong"

            # Create ServiceInfo with proper hostname format
            service_name_with_type = f"{self.service_name}.{self.service_type}.local."
            
            self.service_info = ServiceInfo(
                name=service_name_with_type,
                type_=f"{self.service_type}.local.",
                port=self.port,
                addresses=[socket.inet_aton(local_ip)],
                server=f"{hostname}.local.",
                properties={
                    "version": "0.1.0",
                    "description": "Singalong Node Service",
                },
            )

            logger.info(f"Starting mDNS broadcast with zeroconf")
            logger.info(f"  Service: {self.service_name}")
            logger.info(f"  Type: {self.service_type}.local.")
            logger.info(f"  Port: {self.port}")
            logger.info(f"  Hostname: {hostname}.local.")
            logger.info(f"  IPv4: {local_ip}")

            # Start zeroconf in a background thread to avoid event loop issues
            # Zeroconf expects isolated threading context
            def register_in_thread():
                try:
                    # Create Zeroconf instance in the thread
                    self.zeroconf = Zeroconf(
                        ip_version=IPVersion.V4Only,
                        interfaces=["0.0.0.0"],
                    )
                    # Register service
                    self.zeroconf.register_service(
                        self.service_info,
                        allow_name_change=True,
                    )
                    self._is_broadcasting = True
                    logger.info(
                        f"✓ mDNS broadcast started | "
                        f"service={self.service_name} | "
                        f"port={self.port} | "
                        f"host={hostname}.local. | "
                        f"ip={local_ip}"
                    )
                except Exception as e:
                    logger.error(f"Error registering mDNS in thread: {e}", exc_info=True)
                    self._is_broadcasting = False
            
            # Start registration in daemon thread
            thread = threading.Thread(target=register_in_thread, daemon=True)
            thread.start()
            
            # Brief wait to allow registration to start
            time.sleep(0.5)
            return True

        except Exception as e:
            logger.error(f"Failed to start mDNS broadcast: {e}", exc_info=True)
            self._is_broadcasting = False
            return False

    def stop(self):
        """Stop broadcasting mDNS service."""
        try:
            if self.service_info and self.zeroconf:
                self.zeroconf.unregister_service(self.service_info)
                self.zeroconf.close()
                self._is_broadcasting = False
                logger.info("✓ mDNS broadcast stopped")
        except Exception as e:
            logger.error(f"Error stopping mDNS broadcast: {e}")

    @property
    def is_broadcasting(self) -> bool:
        """Check if currently broadcasting."""
        return self._is_broadcasting

    def __del__(self):
        """Cleanup on deletion."""
        self.stop()

