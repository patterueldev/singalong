"""
Event bus for decoupled pub/sub communication.

Allows any part of the app to emit events without knowing about WebSocket layer,
and WebSocket layer can listen without being imported by business logic.
"""

import logging
from typing import Callable, Dict, List, Any
from enum import Enum

logger = logging.getLogger(__name__)


class Event(str, Enum):
    """Available system events"""
    
    # Reservation events
    QUEUE_CHANGED = "queue.changed"
    RESERVATION_CREATED = "reservation.created"
    RESERVATION_CANCELLED = "reservation.cancelled"
    RESERVATION_STATUS_UPDATED = "reservation.status_updated"
    
    # Player events
    PLAYER_STARTED = "player.started"
    PLAYER_STOPPED = "player.stopped"
    PLAYER_PAUSED = "player.paused"
    PLAYER_POSITION_UPDATED = "player.position_updated"
    
    # Connection events
    CLIENT_CONNECTED = "client.connected"
    CLIENT_DISCONNECTED = "client.disconnected"
    
    # Download events
    DOWNLOAD_STARTED = "download.started"
    DOWNLOAD_PROGRESS = "download.progress"
    DOWNLOAD_COMPLETED = "download.completed"


class EventBus:
    """
    Central pub/sub event system.
    
    Decouples business logic from WebSocket layer:
    - Business logic calls event_bus.emit(event, **kwargs)
    - WebSocket layer subscribes to events and broadcasts to clients
    - No imports between business logic and WebSocket code
    """
    
    def __init__(self):
        self._handlers: Dict[str, List[Callable]] = {}
        self._logger = logger
    
    def subscribe(self, event_type: str, handler: Callable) -> None:
        """
        Subscribe a handler to an event.
        
        Args:
            event_type: Event to listen for (use Event enum)
            handler: Async callable(session_id, **kwargs) or sync callable(**kwargs)
        """
        if event_type not in self._handlers:
            self._handlers[event_type] = []
        
        self._handlers[event_type].append(handler)
        self._logger.debug(f"[EventBus] Subscribed {handler.__name__} to {event_type}")
    
    def unsubscribe(self, event_type: str, handler: Callable) -> None:
        """Remove a handler from an event."""
        if event_type in self._handlers:
            self._handlers[event_type].remove(handler)
            self._logger.debug(f"[EventBus] Unsubscribed {handler.__name__} from {event_type}")
    
    async def emit(self, event_type: str, **kwargs) -> None:
        """
        Emit an event and call all subscribed handlers.
        
        Args:
            event_type: Event to emit (use Event enum)
            **kwargs: Arbitrary event data (session_id, song_id, etc.)
        """
        handlers = self._handlers.get(event_type, [])
        
        if not handlers:
            self._logger.debug(f"[EventBus] No handlers for {event_type}")
            return
        
        self._logger.info(f"[EventBus] Emitting {event_type} with {len(handlers)} handler(s)")
        
        for handler in handlers:
            try:
                # Check if handler is async
                if hasattr(handler, "__await__") or (
                    hasattr(handler, "__self__")
                    and hasattr(handler.__self__, "__class__")
                ):
                    # Could be async, try to call it
                    result = handler(**kwargs)
                    if hasattr(result, "__await__"):
                        await result
                else:
                    # Regular sync function or method
                    handler(**kwargs)
            except Exception as e:
                self._logger.error(
                    f"[EventBus] Error in handler {handler.__name__} for {event_type}: {str(e)}",
                    exc_info=True,
                )


# Global event bus instance
_event_bus: EventBus = None


def get_event_bus() -> EventBus:
    """Get or initialize the global event bus."""
    global _event_bus
    if _event_bus is None:
        _event_bus = EventBus()
    return _event_bus


def init_event_bus() -> EventBus:
    """Initialize the event bus (called during app startup)."""
    global _event_bus
    _event_bus = EventBus()
    logger.info("[EventBus] Initialized")
    return _event_bus
