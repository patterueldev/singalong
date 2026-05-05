"""mDNS service broadcasting via system dns-sd (macOS)."""
import logging
import socket
import subprocess
import time
from typing import Optional

from app.services.mdns.interfaces import BroadcasterInterface

logger = logging.getLogger(__name__)


class MDNSBroadcaster(BroadcasterInterface):
    """Broadcasts Singalong Node via system dns-sd (macOS)."""

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
        self.process: Optional[subprocess.Popen] = None
        self._is_broadcasting = False

    def start(self, node_url: str) -> bool:
        """Start broadcasting mDNS service via dns-sd command.
        
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

            host_target = f"{hostname}.local."

            # Use dns-sd command which registers with system mDNSResponder
            # This ensures IPv4 A records are properly advertised to all clients
            cmd = [
                "dns-sd",
                "-R",
                self.service_name,
                self.service_type,
                "local.",
                str(self.port),
                host_target,
            ]

            logger.info(f"Starting mDNS broadcast with dns-sd")
            logger.info(f"  Service: {self.service_name}")
            logger.info(f"  Type: {self.service_type}.local.")
            logger.info(f"  Port: {self.port}")
            logger.info(f"  Hostname: {host_target}")
            logger.info(f"  IPv4: {local_ip}")

            # Start the process
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
            )

            # Give dns-sd time to register
            time.sleep(1)

            # Check if process is still running
            if self.process.poll() is None:
                self._is_broadcasting = True
                logger.info(
                    f"✓ mDNS broadcast started | "
                    f"service={self.service_name} | "
                    f"port={self.port} | "
                    f"host={host_target} | "
                    f"ip={local_ip}"
                )
                return True
            else:
                # Process exited - check stdout/stderr
                stdout = self.process.stdout.read() if self.process.stdout else ""
                stderr = self.process.stderr.read() if self.process.stderr else ""
                logger.error(f"dns-sd process failed immediately")
                logger.error(f"stdout: {stdout}")
                logger.error(f"stderr: {stderr}")
                self._is_broadcasting = False
                return False

        except FileNotFoundError:
            logger.error("dns-sd command not found. Make sure you're on macOS.")
            self._is_broadcasting = False
            return False
        except Exception as e:
            logger.error(f"Failed to start mDNS broadcast: {e}")
            self._is_broadcasting = False
            return False

    def stop(self):
        """Stop broadcasting mDNS service."""
        try:
            if self.process:
                self.process.terminate()
                try:
                    self.process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    self.process.kill()
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
