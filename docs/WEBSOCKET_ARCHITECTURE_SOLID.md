# WebSocket Architecture: SOLID Design & MVC Pattern

## Overview

The Node WebSocket layer follows **SOLID principles** and **MVC (Model-View-Controller)** architectural patterns to ensure testability, maintainability, and clean separation of concerns.

**Key Achievement**: Business logic is completely decoupled from WebSocket concerns. Any part of the application can emit events without importing WebSocket code.

---

## Architecture Layers

```
┌────────────────────────────────────────────────────────────────────┐
│                    Event Bus (Pub/Sub)                              │
│                    (Decoupling layer)                               │
│ - Emits events from any part of app                                 │
│ - Routes to subscribed handlers                                     │
│ - No imports needed between Business Logic ↔ WebSocket              │
└─────────────────┬──────────────────────────────────────────────────┘
                  │
   ┌──────────────┴───────────────┐
   │                              │
   ▼                              ▼
   Business Logic            WebSocket Handlers
   (Routes)                  (EventService)
   - Reservation.create()    - on_queue_changed()
   - Player.start()          - on_client_connected()
   - Download.complete()     - on_player_position_updated()
   emit(Event.X)             await broadcast(...)
   
   [No WebSocket imports!]   [No business logic imports!]
   
   ┌──────────────────────────────────────────────────────────────┐
   │                   WebSocket Services Layer                    │
   ├──────────────────────────────────────────────────────────────┤
   │  DataServices          BroadcastService   EventService        │
   │  (SRP: Fetch)          (SRP: Send)        (SRP: Orchestrate) │
   │  - QueueDataService    - broadcast_to_   - on_queue_changed()│
   │  - PlayerDataService     session()        - on_player_*()     │
   │  - AttendeeDataService - broadcast_to_   - on_download_*()   │
   │  - SessionDataService    user()           - send_initial_     │
   │                        - broadcast_to_     state()            │
   │                          all_sessions()   - on_client_*()     │
   └─────────────────┬──────────────────────────────────────────────┘
                     │
   ┌─────────────────┴──────────────────────────────────┐
   │   Repository (Abstraction Layer)                   │
   │   IWebSocketConnectionRepository                   │
   │  - connect(session_id, ws, role)                   │
   │  - disconnect(session_id, ws)                      │
   │  - get_session_clients(session_id)                 │
   │  - get_session_clients_by_role(session_id, roles)  │
   │  - get_active_sessions()                           │
   │  - get_session_client_count(session_id)            │
   └─────────────────┬──────────────────────────────────┘
                     │
   ┌─────────────────┴──────────────────────────────────┐
   │   WebSocketConnectionManager (Concrete)            │
   │  - Dict[session_id] → Set[WebSocket]               │
   │  - Dict[session_id][role] → Set[WebSocket]         │
   │  - Implements IWebSocketConnectionRepository       │
   └─────────────────┬──────────────────────────────────┘
                     │
                     ▼
              WebSocket Clients
              (Browser, Admin, Controller)
```

---

## SOLID Principle Compliance

### Single Responsibility Principle (SRP)

**Each service has ONE reason to change:**

| Service | Responsibility | Reason to Change |
|---------|-----------------|-----------------|
| EventBus | Event routing | Event subscription mechanism changes |
| QueueDataService | Fetch & format queue | Queue schema changes |
| BroadcastService | Send to WebSocket clients | WebSocket API changes |
| EventService | Orchestrate events | Business rule for what to broadcast changes |
| WebSocketConnectionManager | Manage connections | Connection tracking strategy changes |

**Example: Queue format changes**
- Only `QueueDataService.get_queue_for_broadcast()` needs modification
- `EventService.on_queue_changed()` calls it - no changes needed
- Broadcast layer - no changes needed
- Tests - easily replace with mock QueueDataService

### Open/Closed Principle (OCP)

**Systems are open for extension, closed for modification:**

✅ **Add new event type without modifying existing code:**
```python
# In event_bus.py
class Event(str, Enum):
    NEW_EVENT_TYPE = "new.event"

# In websocket_service_container.py
event_bus.subscribe(Event.NEW_EVENT_TYPE, event_service.on_new_event)

# In websocket_event_service.py
async def on_new_event(self, **kwargs):
    await self._broadcast.broadcast_to_session(...)

# In your business logic (no WS imports!)
await event_bus.emit(Event.NEW_EVENT_TYPE, ...)
```

No existing code changes. Purely additive.

### Liskov Substitution Principle (LSP)

**Subtypes are substitutable for base types:**

```python
# Abstract interface
class IWebSocketConnectionRepository(ABC):
    async def connect(self, session_id, websocket, role): ...
    async def disconnect(self, session_id, websocket): ...
    # ... etc

# Concrete implementation
class WebSocketConnectionManager(IWebSocketConnectionRepository):
    # Implements all abstract methods

# Broadcast service depends on abstraction, not concrete class
class WebSocketBroadcastService:
    def __init__(self, connection_repo: IWebSocketConnectionRepository):
        self._repo = connection_repo

# In tests, substitute with mock
class MockConnectionRepository(IWebSocketConnectionRepository):
    async def connect(self, ...): ...  # Mock implementation
    # ... etc

# Test with mock (no real WebSocket connections!)
broadcast_svc = WebSocketBroadcastService(MockConnectionRepository())
```

### Interface Segregation Principle (ISP)

**Clients depend only on interfaces they use:**

- `BroadcastService` depends on `IWebSocketConnectionRepository`
- `EventService` depends on `BroadcastService`
- `DataService` depends only on database (no WebSocket dependency)
- Business logic depends only on `EventBus`

No service is forced to depend on unused interfaces.

### Dependency Inversion Principle (DIP)

**Depend on abstractions, not concrete implementations:**

```
High-level (Business Logic)
        ▲
        │ emits
        │
    EventBus (Abstraction)
        ▲
        │ subscribes
        │
    EventService (Abstraction)
        ▲
        │ depends
        │
    DataService (Abstraction)
    BroadcastService (Abstraction)
        ▲
        │ depends
        │
    IWebSocketConnectionRepository (Abstraction)
        ▲
        │ implements
        │
    WebSocketConnectionManager (Concrete)
```

All dependencies flow toward abstractions, enabling:
- Easy testing (inject mocks)
- Easy extension (new implementations)
- Zero coupling between layers

---

## MVC Architecture Pattern

### Model: Data Services Layer
**Responsibility**: Fetch and format data for views

```
- QueueDataService
  - get_queue_for_broadcast() → Dict[queue, total]
  
- PlayerDataService
  - get_player_position_for_broadcast() → Dict[elapsed, remaining, %]
  
- SessionDataService
  - get_session_for_broadcast() → Dict[id, title, vibes, ...]
  
- AttendeeDataService
  - get_attendees_for_broadcast() → Dict[attendees, total]
```

**Characteristics:**
- Database queries only
- Data formatting only (no business logic)
- Zero WebSocket operations
- Pure functions (no state)

### View: WebSocket Clients
**Responsibility**: Render real-time data for users

```
- Browser JS (Controller)
  - Listen on ws://host/ws/session_id
  - Render queue on queue:updated
  - Render position on player:position
  - Render attendees on attendee:*
  
- Browser JS (Admin)
  - Same as controller
  - Plus: admin-only events (download:progress, etc)
```

### Controller: Event Service + WebSocket Endpoint
**Responsibility**: Orchestrate requests and route to services

```
EventService (Application Controller)
├─ on_queue_changed(session_id)
│   ├─ QueueDataService.get_queue_for_broadcast()
│   └─ BroadcastService.broadcast_to_session()
│
├─ on_client_connected(session_id, user_id, role)
│   ├─ AttendeeDataService.get_attendees_for_broadcast()
│   └─ BroadcastService.broadcast_to_session()
│
└─ on_player_position_updated(session_id)
    ├─ PlayerDataService.get_player_position_for_broadcast()
    └─ BroadcastService.broadcast_to_session()

WebSocket Endpoint (HTTP Controller)
├─ Validate JWT
├─ Manager.connect()
├─ EventService.send_initial_state()  ← load model
└─ Emit EVENT.CLIENT_CONNECTED       ← orchestrate
```

**Characteristics:**
- Routes HTTP/WebSocket requests to services
- Orchestrates service calls
- No data fetching (delegates to model)
- No direct WebSocket sending (delegates to broadcast service)

---

## Event Flow Example: Adding a Reservation

### Step 1: User submits reservation via HTTP
```
POST /api/sessions/{id}/reservations
└─ ReservationController
   ├─ Create reservation in DB
   └─ await event_bus.emit(Event.QUEUE_CHANGED, session_id=...)
      [No WebSocket imports in routes!]
```

### Step 2: Event bus routes to subscribers
```
EventBus.emit(Event.QUEUE_CHANGED, session_id="9999")
└─ Call all subscribers to QUEUE_CHANGED
   └─ EventService.on_queue_changed(session_id="9999")
```

### Step 3: EventService orchestrates
```
EventService.on_queue_changed(session_id="9999")
├─ QueueDataService.get_queue_for_broadcast("9999")
│  └─ Query DB: SELECT * FROM reservations WHERE session="9999" ...
│     Return formatted: {"queue": [...], "total": 5}
│
└─ BroadcastService.broadcast_to_session("9999", "queue:updated", data)
   └─ ConnectionRepository.get_session_clients("9999")
      └─ Return: [ws1, ws2, ws3]  (3 clients in this session)
         └─ Send JSON to each: {"type": "queue:updated", "data": {...}}
            └─ Browser receives
               └─ React re-renders queue list
```

### Key Points
1. ✅ **No tight coupling**: Reservation endpoint never imports WebSocket code
2. ✅ **Testable**: Mock EventBus, DataServices, BroadcastService independently
3. ✅ **Extensible**: Add new events without changing existing code
4. ✅ **Maintainable**: Change queue format in ONE place (QueueDataService)

---

## Service Container & Dependency Injection

### Initialization
```python
# In main.py lifespan
from app.services.websocket_service_container import init_websocket_services

service_container = init_websocket_services()

# This does:
# 1. Create EventBus
# 2. Create WebSocketConnectionManager
# 3. Create WebSocketBroadcastService(manager)
# 4. Create WebSocketEventService(broadcast)
# 5. Subscribe handlers to event bus
# 6. Print "✓ All WebSocket services initialized"
```

### Service Access
```python
# In endpoints or anywhere in the app
from app.services.websocket_service_container import get_service_container

container = get_service_container()
event_bus = container.get_event_bus()
await event_bus.emit(Event.QUEUE_CHANGED, session_id="9999")

# No imports of WebSocket services!
# Only imports of EventBus - which is event delivery mechanism
```

---

## Testing Strategy

### Unit Test: Data Service
```python
async def test_queue_data_service():
    """Test queue data formatting without WebSocket or DB"""
    # Mock database query
    mock_db = MockDatabase()
    mock_db.add_reservation("song-1", "user-1", position=1)
    
    # Call service
    queue_data = QueueDataService.get_queue_for_broadcast("9999")
    
    # Assert
    assert queue_data["queue"][0]["title"] == "Song Title"
    assert queue_data["total"] == 1
    # [No WebSocket connections created!]
```

### Unit Test: Broadcast Service
```python
async def test_broadcast_to_session():
    """Test broadcasting without real connections"""
    # Mock repository
    mock_repo = MockConnectionRepository()
    mock_repo.add_client("9999", MockWebSocket())
    
    # Create service
    broadcast_svc = WebSocketBroadcastService(mock_repo)
    
    # Broadcast
    sent_count = await broadcast_svc.broadcast_to_session(
        "9999", "queue:updated", {"queue": []}
    )
    
    # Assert
    assert sent_count == 1
    assert mock_repo.last_sent_message.type == "queue:updated"
    # [No real database queries!]
```

### Unit Test: Event Service
```python
async def test_on_queue_changed():
    """Test event orchestration without real data"""
    # Mock services
    mock_data_svc = MockQueueDataService()
    mock_data_svc.return_queue([...])
    
    mock_broadcast_svc = MockBroadcastService()
    
    # Create service
    event_svc = WebSocketEventService(mock_broadcast_svc)
    
    # Emit event
    await event_svc.on_queue_changed("9999")
    
    # Assert
    assert mock_broadcast_svc.was_called("queue:updated", "9999")
    # [All three layers tested independently!]
```

### Integration Test: End-to-end
```python
async def test_reservation_triggers_broadcast():
    """Test full flow: HTTP → EventBus → WebSocket"""
    # Use real services
    container = init_websocket_services()
    
    # Simulate WebSocket connection
    mock_ws = AsyncMock()
    manager = container.get_connection_manager()
    await manager.connect("9999", mock_ws, "controller")
    
    # Create reservation (emits event)
    await create_reservation(session_id="9999", song_id="s1", user_id="u1")
    
    # Assert WebSocket was sent message
    assert mock_ws.send_json.called
    message = mock_ws.send_json.call_args[0][0]
    assert message["type"] == "queue:updated"
```

---

## Extending the Architecture

### Adding a New Event Type

1. **Define event** (event_bus.py):
```python
class Event(str, Enum):
    RATING_SUBMITTED = "rating.submitted"
```

2. **Create handler** (websocket_event_service.py):
```python
async def on_rating_submitted(self, session_id: str, song_id: str, rating: int):
    rating_data = {"song_id": song_id, "rating": rating}
    await self._broadcast.broadcast_to_session(
        session_id, "rating:submitted", rating_data
    )
```

3. **Subscribe handler** (websocket_service_container.py):
```python
event_bus.subscribe(Event.RATING_SUBMITTED, event_service.on_rating_submitted)
```

4. **Emit from business logic** (anywhere):
```python
await event_bus.emit(Event.RATING_SUBMITTED, session_id="9999", song_id="s1", rating=5)
```

**No other code changes needed!**

### Adding Role-Based Filtering

```python
# Current
await self._broadcast.broadcast_to_session(session_id, event_type, data)

# Add role filter
await self._broadcast.broadcast_to_session(
    session_id, event_type, data,
    roles=["admin"]  # ← Only send to admins
)
```

Service Container handles role assignment during connection.

---

## Files Reference

| File | Purpose | Lines | SOLID Focus |
|------|---------|-------|------------|
| event_bus.py | Pub/sub system | 165 | Dependency Inversion |
| websocket_repository.py | Abstract interface | 75 | Liskov Substitution |
| websocket_data_service.py | Model layer | 190 | Single Responsibility |
| websocket_broadcast_service.py | Broadcast layer | 145 | Single Responsibility |
| websocket_event_service.py | Controller/Orchestration | 320 | Open/Closed |
| websocket_service_container.py | DI container | 200 | Dependency Inversion |
| node_websocket_server.py | Concrete repository | 210 | Liskov Substitution |
| api/routes/websocket.py | HTTP endpoint | 250 | Single Responsibility |

**Total: ~1,550 lines of well-organized, SOLID-compliant code**

---

## Performance Considerations

### Connection Management
- ✅ Per-session connection tracking (O(1) lookups)
- ✅ Role-based connection filtering (avoid iterating all)
- ✅ Automatic cleanup of disconnected clients

### Broadcasting
- ✅ Concurrent sends to multiple clients (async/await)
- ✅ Graceful handling of closed connections
- ✅ No blocking database queries during broadcast

### Data Services
- ⚠️ **Future optimization**: Cache frequently accessed data
  - Queue doesn't change often - cache between updates
  - Player position updates 2-5s - consider in-memory state
  - Session metadata - very stable, excellent caching candidate

---

## Security Considerations

### Authentication
- ✅ JWT validation on WebSocket connect
- ✅ Token extracted from Authorization header
- ✅ Re-validation supported in incoming messages

### Authorization
- ✅ Role extracted from JWT payload
- ✅ Role-based event filtering (admin-only broadcasts)
- ✅ Future: user-specific message filtering

### Data Safety
- ✅ No sensitive data in broadcast payloads
- ✅ User IDs sent but no passwords/tokens
- ✅ Admin events filtered from non-admin clients

---

## Conclusion

This architecture achieves **maximum testability, extensibility, and maintainability** through strict adherence to SOLID principles and MVC pattern:

- **Zero coupling** between business logic and WebSocket code
- **Single responsibility** for each service
- **Dependency injection** throughout
- **Interface abstraction** for easy testing and swapping
- **Event-driven** for decoupling across components

Adding new features, events, or changing data formats requires modifications in **only ONE layer**, making the codebase highly maintainable as it grows.
