"""mDNS bridge application - advertises Node service via mDNS (pure Python, OS-agnostic)"""
import logging
import os
import signal
import socket
import time
import httpx
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
        gateway_port: int = 80,
        service_name: str = "Singalong Node",
        service_type: str = "_singalong-node._tcp",
        health_check_enabled: bool = True,
        health_check_timeout: int = 30,
    ):
        self.node_host = node_host
        self.gateway_port = gateway_port  # Port that Nginx/gateway listens on
        self.service_name = service_name
        self.service_type = service_type
        self.health_check_enabled = health_check_enabled
        self.health_check_timeout = health_check_timeout
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

    def _check_node_health(self) -> bool:
        """Check if Node service is healthy by calling its /api/health through Nginx gateway"""
        if not self.health_check_enabled:
            return True

        try:
            # Always check through Nginx gateway (port 80) for consistency
            # Nginx routes /api/* to Node service
            check_url = "http://localhost/api/health"

            # Check health with timeout
            response = httpx.get(check_url, timeout=self.health_check_timeout)
            is_healthy = response.status_code == 200
            
            if is_healthy:
                logger.info(f"✓ Node health check passed: {check_url}")
            else:
                logger.warning(
                    f"✗ Node health check failed: {check_url} "
                    f"(status={response.status_code})"
                )
            return is_healthy
        except Exception as e:
            logger.warning(f"✗ Node health check error: {e}")
            return False

    def start(self):
        """Start mDNS broadcasting using zeroconf"""
        try:
            # Check Node health before advertising
            if not self._check_node_health():
                logger.error("Node is not healthy. Cannot advertise service.")
                return False

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
            logger.info(f"  Gateway port: {self.gateway_port} (Nginx)")

            # Create service info with the advertised IP and gateway port
            service_name_with_type = f"{self.service_name}.{self.service_type}.local."
            ip_bytes = socket.inet_aton(advertise_ip)

            self.service_info = ServiceInfo(
                name=service_name_with_type,
                type_=f"{self.service_type}.local.",
                port=self.gateway_port,  # Advertise Nginx gateway port
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
                f"gateway_port={self.gateway_port} | "
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
    gateway_port = int(os.getenv("GATEWAY_PORT", "80"))  # Nginx gateway port
    service_name = os.getenv("MDNS_SERVICE_NAME", "Singalong Node")
    service_type = os.getenv("MDNS_SERVICE_TYPE", "_singalong-node._tcp")

    bridge = MDNSBridge(
        node_host=node_host,
        gateway_port=gateway_port,
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
