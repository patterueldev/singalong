"""mDNS bridge application - advertises Node service via mDNS (pure Python, OS-agnostic)"""
import logging
import os
import signal
import socket
import time
from zeroconf import InterfaceChoice, ServiceInfo, Zeroconf

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


class MDNSBridge:
    """Advertises Singalong Node service via mDNS using zeroconf (pure Python)"""

    def __init__(
        self,
        node_host: str = "localhost",
        node_port: int = 5002,
        service_name: str = "Singalong Node",
        service_type: str = "_singalong-node._tcp",
    ):
        self.node_host = node_host
        self.node_port = node_port
        self.service_name = service_name
        self.service_type = service_type
        self.zeroconf = None
        self.service_info = None

    def _get_host_ip(self):
        """Get the actual host IP address (not loopback)"""
        try:
            # Connect to a public DNS server to determine local IP
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            # Fallback to localhost if we can't determine IP
            return "127.0.0.1"

    def start(self):
        """Start mDNS broadcasting using zeroconf"""
        try:
            # Determine the IP to advertise
            if self.node_host in ("localhost", "127.0.0.1"):
                advertise_ip = self._get_host_ip()
            else:
                try:
                    advertise_ip = socket.gethostbyname(self.node_host)
                except socket.gaierror:
                    logger.error(f"Failed to resolve node host: {self.node_host}")
                    return False

            logger.info(f"Starting mDNS bridge...")
            logger.info(f"  Service: {self.service_name}")
            logger.info(f"  Type: {self.service_type}.local.")
            logger.info(f"  Node host: {self.node_host} → {advertise_ip}")
            logger.info(f"  Node port: {self.node_port}")

            # Create service info with the advertised IP
            service_name_with_type = f"{self.service_name}.{self.service_type}.local."
            ip_bytes = socket.inet_aton(advertise_ip)

            self.service_info = ServiceInfo(
                name=service_name_with_type,
                type_=f"{self.service_type}.local.",
                port=self.node_port,
                addresses=[ip_bytes],
                properties={
                    "version": "0.1.0",
                    "description": "Singalong Node Service",
                },
            )

            # Initialize Zeroconf with Default interfaces
            # This skips loopback and uses actual network interfaces
            # Works on macOS, Linux, Windows - OS-agnostic
            logger.info("Initializing Zeroconf with default network interfaces...")
            self.zeroconf = Zeroconf(interfaces=InterfaceChoice.Default)

            logger.info("Registering service with mDNS...")
            self.zeroconf.register_service(self.service_info)

            # Give it a moment to register
            time.sleep(0.5)

            logger.info(
                f"✓ mDNS bridge started | "
                f"service={self.service_name} | "
                f"port={self.node_port} | "
                f"ip={advertise_ip}"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to start mDNS bridge: {e}", exc_info=True)
            return False

    def stop(self):
        """Stop mDNS broadcasting"""
        try:
            if self.service_info and self.zeroconf:
                self.zeroconf.unregister_service(self.service_info)
                self.zeroconf.close()
                logger.info("✓ mDNS bridge stopped")
        except Exception as e:
            logger.error(f"Error stopping mDNS bridge: {e}")


def main():
    """Main entry point"""
    # Configuration from environment
    node_host = os.getenv("NODE_HOST", "localhost")
    node_port = int(os.getenv("NODE_PORT", "5002"))
    service_name = os.getenv("MDNS_SERVICE_NAME", "Singalong Node")
    service_type = os.getenv("MDNS_SERVICE_TYPE", "_singalong-node._tcp")

    bridge = MDNSBridge(
        node_host=node_host,
        node_port=node_port,
        service_name=service_name,
        service_type=service_type,
    )

    # Start mDNS bridge
    if not bridge.start():
        logger.error("Failed to start mDNS bridge")
        return 1

    # Handle graceful shutdown
    def signal_handler(sig, frame):
        logger.info("Shutting down mDNS bridge...")
        bridge.stop()
        exit(0)

    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    # Keep running
    logger.info("mDNS bridge running. Press Ctrl+C to stop.")
    try:
        signal.pause()
    except KeyboardInterrupt:
        logger.info("Shutting down...")
        bridge.stop()
        return 0


if __name__ == "__main__":
    exit(main())
