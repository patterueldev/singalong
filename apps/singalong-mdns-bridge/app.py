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
        health_poll_interval: int = 5,
    ):
        self.node_host = node_host
        self.gateway_port = gateway_port  # Port that Nginx/gateway listens on
        self.service_name = service_name
        self.service_type = service_type
        self.health_check_enabled = health_check_enabled
        self.health_check_timeout = health_check_timeout
        self.health_poll_interval = health_poll_interval  # Seconds between health checks
        self.zeroconf = None
        self.service_info = None
        self.is_registered = False  # Track registration state
        self.should_run = True  # Control flag for polling loop

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

    def _get_hostname(self):
        """Get the machine's hostname (e.g., thursday.local)"""
        try:
            hostname = socket.gethostname()
            # Ensure .local suffix for mDNS
            if not hostname.endswith(".local"):
                hostname = f"{hostname}.local"
            return hostname
        except Exception:
            return "singalong-node.local"  # Fallback

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

    def _register_service(self):
        """Register the service with mDNS"""
        if self.is_registered:
            return
        
        try:
            logger.info("Registering service with mDNS...")
            self.zeroconf.register_service(self.service_info)
            time.sleep(0.5)
            self.is_registered = True
            logger.info(f"✓ Service registered: {self.service_name}")
        except Exception as e:
            # NonUniqueNameException is expected if service is being re-registered
            if "NonUniqueNameException" in str(type(e)):
                logger.warning(
                    f"Service already registered or name conflict: {self.service_name}. "
                    f"Retrying in next poll cycle."
                )
            else:
                logger.error(f"Failed to register service: {e}", exc_info=True)
            self.is_registered = False

    def _unregister_service(self):
        """Unregister the service from mDNS"""
        if not self.is_registered:
            return
        
        try:
            logger.info("Unregistering service from mDNS...")
            self.zeroconf.unregister_service(self.service_info)
            self.is_registered = False
            logger.info(f"✓ Service unregistered: {self.service_name}")
        except Exception as e:
            logger.error(f"Failed to unregister service: {e}")

    def _initialize_zeroconf(self):
        """Initialize Zeroconf instance (one-time setup)"""
        if self.zeroconf is not None:
            return
        
        try:
            logger.info("Initializing Zeroconf with default network interfaces...")
            self.zeroconf = Zeroconf(interfaces=InterfaceChoice.Default)
        except Exception as e:
            logger.error(f"Failed to initialize Zeroconf: {e}")
            raise

    def _polling_loop(self):
        """Continuously check Node health and manage service registration"""
        logger.info(
            f"Starting health polling loop (interval: {self.health_poll_interval}s)"
        )
        
        while self.should_run:
            try:
                is_healthy = self._check_node_health()
                
                if is_healthy and not self.is_registered:
                    # Node came online - register service
                    self._register_service()
                elif not is_healthy and self.is_registered:
                    # Node went offline - unregister service
                    self._unregister_service()
                
                # Sleep before next check
                time.sleep(self.health_poll_interval)
                
            except Exception as e:
                logger.error(f"Error in polling loop: {e}")
                time.sleep(self.health_poll_interval)

    def start(self):
        """Start mDNS bridge with continuous health polling"""
        try:
            # Determine the IP to advertise (once at startup)
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

            # Get the machine hostname (e.g., thursday.local)
            machine_hostname = self._get_hostname()
            logger.info(f"  Machine hostname: {machine_hostname}")

            # Create service info with the advertised IP, gateway port, and hostname
            service_name_with_type = f"{self.service_name}.{self.service_type}.local."
            ip_bytes = socket.inet_aton(advertise_ip)

            self.service_info = ServiceInfo(
                name=service_name_with_type,
                type_=f"{self.service_type}.local.",
                port=self.gateway_port,  # Advertise Nginx gateway port
                server=machine_hostname,  # Advertise machine hostname (e.g., thursday.local)
                addresses=[ip_bytes],
                properties={
                    "version": "0.1.0",
                    "description": "Singalong Node Service",
                    "hostname": machine_hostname,
                },
            )

            # Initialize Zeroconf
            self._initialize_zeroconf()

            logger.info(
                f"✓ mDNS bridge initialized | "
                f"service={self.service_name} | "
                f"gateway_port={self.gateway_port} | "
                f"ip={advertise_ip}"
            )
            
            # Start polling loop - this will block indefinitely
            self._polling_loop()
            return True

        except Exception as e:
            logger.error(f"Failed to start mDNS bridge: {e}", exc_info=True)
            return False

    def stop(self):
        """Stop mDNS bridge and clean up"""
        self.should_run = False  # Signal polling loop to stop
        try:
            if self.is_registered and self.service_info and self.zeroconf:
                self._unregister_service()
            if self.zeroconf:
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
    health_poll_interval = int(os.getenv("HEALTH_POLL_INTERVAL", "5"))

    bridge = MDNSBridge(
        node_host=node_host,
        gateway_port=gateway_port,
        service_name=service_name,
        service_type=service_type,
        health_poll_interval=health_poll_interval,
    )

    # Handle graceful shutdown
    def signal_handler(sig, frame):
        logger.info("Shutting down mDNS bridge...")
        bridge.stop()
        exit(0)

    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    # Start mDNS bridge (polling loop runs indefinitely)
    logger.info("mDNS bridge starting with continuous health polling...")
    try:
        bridge.start()  # This blocks until signal_handler is called
    except KeyboardInterrupt:
        logger.info("Shutting down...")
        bridge.stop()
        return 0
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        bridge.stop()
        return 1


if __name__ == "__main__":
    exit(main())
