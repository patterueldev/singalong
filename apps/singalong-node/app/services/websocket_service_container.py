"""
Dependency injection and service initialization.

Sets up all WebSocket services with proper dependency wiring.
Called during app startup to initialize the service hierarchy.
"""

import logging
from app.services.event_bus import EventBus, Event, init_event_bus
from app.services.node_websocket_server import WebSocketConnectionManager
from app.services.websocket_broadcast_service import WebSocketBroadcastService
from app.services.websocket_event_service import WebSocketEventService

logger = logging.getLogger(__name__)


class WebSocketServiceContainer:
    """
    Dependency injection container for WebSocket services.
    
    Wires up all service dependencies and provides access to them.
    Follows constructor injection pattern for testability.
    """
    
    def __init__(self):
        self._initialized = False
        self._event_bus: EventBus = None
        self._connection_manager: WebSocketConnectionManager = None
        self._broadcast_service: WebSocketBroadcastService = None
        self._event_service: WebSocketEventService = None
    
    def initialize(self) -> None:
        """
        Initialize all services with proper dependency wiring.
        
        Order is important:
        1. Event bus (pub/sub system)
        2. Connection manager (repository)
        3. Broadcast service (uses repository)
        4. Event service (uses broadcast service)
        5. Subscribe event handlers to event bus
        """
        if self._initialized:
            logger.warning("[ServiceContainer] Already initialized")
            return
        
        logger.info("[ServiceContainer] Initializing WebSocket services...")
        
        # 1. Initialize event bus
        self._event_bus = init_event_bus()
        
        # 2. Initialize connection manager (singleton)
        self._connection_manager = WebSocketConnectionManager()
        logger.info("[ServiceContainer] Created WebSocketConnectionManager")
        
        # 3. Initialize broadcast service (depends on connection manager)
        self._broadcast_service = WebSocketBroadcastService(self._connection_manager)
        logger.info("[ServiceContainer] Created WebSocketBroadcastService")
        
        # 4. Initialize event service (depends on broadcast service)
        self._event_service = WebSocketEventService(self._broadcast_service)
        logger.info("[ServiceContainer] Created WebSocketEventService")
        
        # 5. Subscribe event handlers to event bus
        self._subscribe_handlers()
        
        self._initialized = True
        logger.info("[ServiceContainer] ✓ All WebSocket services initialized")
    
    def _subscribe_handlers(self) -> None:
        """Subscribe event handlers to event bus."""
        event_service = self._event_service
        event_bus = self._event_bus
        
        # Queue events
        event_bus.subscribe(Event.QUEUE_CHANGED, event_service.on_queue_changed)
        event_bus.subscribe(Event.RESERVATION_CREATED, event_service.on_queue_changed)
        event_bus.subscribe(Event.RESERVATION_CANCELLED, event_service.on_queue_changed)
        event_bus.subscribe(Event.RESERVATION_STATUS_UPDATED, event_service.on_queue_changed)
        
        # Player events
        event_bus.subscribe(Event.PLAYER_STARTED, self._handle_player_started)
        event_bus.subscribe(Event.PLAYER_POSITION_UPDATED, event_service.on_player_position_updated)
        
        # Connection events
        event_bus.subscribe(Event.CLIENT_CONNECTED, self._handle_client_connected)
        event_bus.subscribe(Event.CLIENT_DISCONNECTED, event_service.on_client_disconnected)
        
        # Download events
        event_bus.subscribe(Event.DOWNLOAD_PROGRESS, self._handle_download_progress)
        
        logger.info("[ServiceContainer] ✓ Event handlers subscribed to event bus")
    
    async def _handle_player_started(
        self, session_id: str, song_id: str, title: str
    ) -> None:
        """Wrapper for player started event"""
        await self._event_service.on_player_started(session_id, song_id, title)
    
    async def _handle_client_connected(
        self, session_id: str, user_id: str, role: str
    ) -> None:
        """Wrapper for client connected event"""
        await self._event_service.on_client_connected(session_id, user_id, role)
    
    async def _handle_download_progress(
        self, session_id: str, video_id: str, progress_data: dict
    ) -> None:
        """Wrapper for download progress event"""
        await self._event_service.on_download_progress(session_id, video_id, progress_data)
    
    # Getters for services
    def get_event_bus(self) -> EventBus:
        """Get event bus (for emitting events)"""
        if not self._initialized:
            raise RuntimeError("ServiceContainer not initialized. Call initialize() first.")
        return self._event_bus
    
    def get_connection_manager(self) -> WebSocketConnectionManager:
        """Get WebSocket connection manager"""
        if not self._initialized:
            raise RuntimeError("ServiceContainer not initialized. Call initialize() first.")
        return self._connection_manager
    
    def get_broadcast_service(self) -> WebSocketBroadcastService:
        """Get broadcast service"""
        if not self._initialized:
            raise RuntimeError("ServiceContainer not initialized. Call initialize() first.")
        return self._broadcast_service
    
    def get_event_service(self) -> WebSocketEventService:
        """Get event service"""
        if not self._initialized:
            raise RuntimeError("ServiceContainer not initialized. Call initialize() first.")
        return self._event_service


# Global service container
_container: WebSocketServiceContainer = None


def get_service_container() -> WebSocketServiceContainer:
    """Get or create the global service container"""
    global _container
    if _container is None:
        _container = WebSocketServiceContainer()
    return _container


def init_websocket_services() -> WebSocketServiceContainer:
    """Initialize all WebSocket services during app startup"""
    global _container
    _container = WebSocketServiceContainer()
    _container.initialize()
    return _container
