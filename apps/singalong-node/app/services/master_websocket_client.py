"""
Master WebSocket Client for Node

Node connects to Master's WebSocket endpoint to receive real-time events:
- download:progress - Download progress updates
- download:complete - Download finished (trigger catalog sync)
- catalog:updated - New videos indexed
- system:health - Periodic heartbeat

Connection established on Node startup, persists for the session.
Handles JWT authentication and automatic reconnection on disconnect.
"""

import asyncio
import logging
import json
from typing import Optional, Callable, Any

import websockets
from websockets.client import WebSocketClientProtocol
import jwt

from app.config import settings

logger = logging.getLogger(__name__)


class MasterWebSocketClient:
    """Client for receiving events from Master WebSocket"""

    def __init__(self):
        """Initialize WebSocket client"""
        self.master_url = settings.master_url
        self.master_api_key = settings.master_api_key
        self.websocket: Optional[WebSocketClientProtocol] = None
        self.access_token: Optional[str] = None
        self.is_connected = False
        self.reconnect_delay = 1  # Start with 1 second
        self.max_reconnect_delay = 30  # Max 30 seconds
        self.running = False

        # Event handlers (can be registered externally)
        self.handlers: dict[str, Callable[[dict], Any]] = {}

    def register_handler(self, event_type: str, handler: Callable[[dict], Any]) -> None:
        """
        Register handler for specific event type.

        Args:
            event_type: Event type to handle (e.g., 'download:progress')
            handler: Async or sync function to call when event received
        """
        self.handlers[event_type] = handler

    async def _get_access_token(self) -> bool:
        """
        Exchange API key for JWT access token from Master.

        Returns:
            True if token obtained successfully, False otherwise
        """
        try:
            async with __import__("httpx").AsyncClient() as client:
                response = await client.post(
                    f"{self.master_url}/api/auth/exchange",
                    json={"api_key": self.master_api_key},
                    timeout=5,
                )

                if response.status_code == 200:
                    data = response.json()
                    self.access_token = data.get("access_token")
                    logger.info("✓ JWT token obtained from Master")
                    return True
                else:
                    logger.error(f"✗ Failed to get token: {response.status_code}")
                    return False

        except Exception as e:
            logger.error(f"✗ Token exchange error: {e}")
            return False

    async def connect(self) -> bool:
        """
        Connect to Master's WebSocket endpoint.

        Returns:
            True if connection successful, False otherwise
        """
        try:
            # Get fresh token
            if not await self._get_access_token():
                return False

            # Connect to WebSocket
            ws_url = f"{self.master_url.replace('http', 'ws')}/ws?token={self.access_token}"
            logger.info(f"Connecting to Master WebSocket: {self.master_url}/ws")

            self.websocket = await websockets.connect(ws_url, ping_interval=20, ping_timeout=20)
            self.is_connected = True
            self.reconnect_delay = 1  # Reset reconnect delay on successful connection
            logger.info("✓ WebSocket connection established with Master")
            return True

        except Exception as e:
            logger.error(f"✗ WebSocket connection failed: {e}")
            return False

    async def listen(self) -> None:
        """
        Listen for messages from Master and dispatch to handlers.

        This runs in a loop and processes incoming WebSocket messages.
        Handles disconnections and triggers reconnection.
        """
        self.running = True

        while self.running:
            if not self.is_connected:
                # Try to reconnect
                logger.info(f"Reconnecting to Master (wait {self.reconnect_delay}s)...")
                await asyncio.sleep(self.reconnect_delay)

                if await self.connect():
                    # Successfully reconnected
                    pass
                else:
                    # Increase delay for next attempt (exponential backoff)
                    self.reconnect_delay = min(self.reconnect_delay * 2, self.max_reconnect_delay)
                    continue

            try:
                # Receive message from Master
                message = await self.websocket.recv()
                await self._handle_message(message)

            except websockets.exceptions.ConnectionClosed:
                logger.warning("WebSocket disconnected from Master")
                self.is_connected = False

            except asyncio.CancelledError:
                logger.info("WebSocket listener cancelled")
                self.running = False
                break

            except Exception as e:
                logger.error(f"Error receiving message: {e}")
                self.is_connected = False

    async def _handle_message(self, message: str) -> None:
        """
        Parse and dispatch WebSocket message to registered handler.

        Args:
            message: JSON message from Master
        """
        try:
            data = json.loads(message)
            event_type = data.get("type")
            event_data = data.get("data", {})

            logger.debug(f"[WS MESSAGE] type={event_type}")

            # Call registered handler if exists
            if event_type in self.handlers:
                handler = self.handlers[event_type]
                if asyncio.iscoroutinefunction(handler):
                    await handler(event_data)
                else:
                    handler(event_data)
            else:
                logger.debug(f"No handler registered for event type: {event_type}")

        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON message: {e}")
        except Exception as e:
            logger.error(f"Error handling message: {e}")

    async def disconnect(self) -> None:
        """Close WebSocket connection and stop listening"""
        self.running = False
        if self.websocket:
            await self.websocket.close()
            self.is_connected = False
            logger.info("WebSocket disconnected")


# Global singleton instance
_master_ws_client: Optional[MasterWebSocketClient] = None


def get_master_websocket_client() -> MasterWebSocketClient:
    """Get or create global WebSocket client instance"""
    global _master_ws_client
    if _master_ws_client is None:
        _master_ws_client = MasterWebSocketClient()
    return _master_ws_client
