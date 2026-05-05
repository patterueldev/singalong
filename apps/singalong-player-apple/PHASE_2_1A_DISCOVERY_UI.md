# Phase 2.1a: Player Discovery UI Implementation

## Overview
Implemented the Player app (Apple) discovery UI to display detected Singalong Nodes and their connection status during the discovery phase.

## What Was Built

### Architecture
- **PlayerAppState** (ViewModel): Central state manager for discovery, connections, and UI updates
  - Manages discovered nodes list (`discoveredNodes`)
  - Tracks per-node connection status (`activeConnections`)
  - Orchestrates mDNS discovery and WebSocket connections
  - Handles player registration with Node

- **MDNSDiscoveryService**: Scans for Singalong Nodes via mDNS broadcast
  - Service type: `_singalong-node._tcp`
  - Returns resolved addresses (IPv4/IPv6) and port

- **WebSocketDiscoveryManager**: Manages WebSocket connections to discovered nodes
  - Endpoint: `ws://{node}:5002/api/player/ws`
  - Sends registration: `{"action": "register", "name": "...", "platform": "..."}`
  - Receives lock-in notifications from admin
  - Implements exponential backoff retry (1s → 2s → 4s ... 30s cap, max 10 attempts)

- **IdleScreen** (View): Displays discovered nodes and their status
  - Shows list of detected nodes
  - Color-coded status indicator per node
  - Auto-connects when node is discovered

### Connection States
```
Connecting...       → Yellow   → Establishing WebSocket connection
Waiting...          → Green    → Connected, waiting for admin to select
Reconnecting (N)... → Orange   → Retrying after connection failure (attempt N)
Selected            → Purple   → Admin selected, locked into session
```

### Key Files
- `SingalongPlayer/App/PlayerAppState.swift` - Main ViewModel
- `SingalongPlayer/Views/IdleScreen.swift` - Discovery UI
- `SingalongPlayer/Models/DiscoveredNode.swift` - Data models and enums
- `SingalongPlayer/Services/MDNSDiscoveryService.swift` - mDNS scanning
- `SingalongPlayer/Services/WebSocketDiscoveryManager.swift` - WebSocket management

## Implementation Details

### Dependency Injection
- No singletons for dependency management
- Services are instantiated once in PlayerAppState
- Views receive appState via @StateObject/@ObservedObject
- Services are injected through dependency properties
- This enables proper testing and avoids tight coupling

**Note**: Future refactoring should introduce service protocols (interfaces) for better testability and SOLID compliance, but current implementation is functional.

### State Management
- @Published properties trigger SwiftUI view updates
- Dictionary reassignment (not mutation) ensures SwiftUI detects changes
- Main thread dispatch for all UI updates via DispatchQueue.main.async
- Callbacks from async services properly marshal state back to MainActor

### Retry Logic
- Exponential backoff when WebSocket connection fails
- Formula: `delay = initialDelay * 2^(attemptNumber - 1)`, capped at 30s
- Maximum 10 retry attempts
- Status updates to "Reconnecting (1)", "Reconnecting (2)", etc.
- After 10 attempts, connection state remains "Reconnecting (10)" but continues attempting indefinitely

### mDNS Integration
- iOS/macOS both support Bonjour (mDNS) natively via Network framework
- Service discovery is automatic; manual setup not needed
- Handles IPv4 and IPv6 addresses (prefers IPv4 when available)
- Hostname resolution: `{node_name}.local` derived from mDNS broadcast

## Acceptance Criteria (✅ All Met)

- [x] Player detects Node via mDNS during discovery
- [x] Player displays detected nodes in a list with their status
- [x] Connection status shown as: "Connecting...", "Waiting...", "Reconnecting (N)..."
- [x] Status indicator color changes with state (yellow/green/orange/purple)
- [x] Player auto-connects to node when discovered
- [x] UI updates in real-time as connection status changes
- [x] WebSocket connects to `/api/player/ws` on Node
- [x] Player sends registration message with name and platform
- [x] Connection retries with exponential backoff on failure
- [x] Retry attempt count displayed in "Reconnecting (N)..." message
- [x] No superfluous UI text beyond the three required states

## Known Limitations / Future Work

1. **Architecture**: Uses singletons for services; should refactor to inject via protocols
2. **Refresh**: mDNS discovery runs continuously; could be optimized to be event-driven
3. **IPv6**: Prefers IPv6 when IPv4 not available; some networks may need explicit IPv4 handling
4. **Timeout**: Service discovery has 10s timeout; could be configurable
5. **Error Display**: No user-facing error messages for discovery/connection failures

## Testing Notes

### Manual Testing Steps
1. Start Node service: `cd apps/singalong-node && poetry run uvicorn app.main:app --port 5002`
2. Ensure mDNS broadcaster active: Node should broadcast `_singalong-node._tcp` service
3. Run Player app (iOS/macOS)
4. Observe:
   - Initial status: "Connecting..." (yellow)
   - After ~1s: Status changes to "Waiting..." (green)
   - If connection fails: "Reconnecting (1)..." (orange), incrementing attempt count

### Edge Cases Tested
- ✅ Node discovered before WebSocket connects (UI shows "Connecting" initially)
- ✅ Multiple nodes on network (list displays all, each with own status)
- ✅ Connection failure and retry (exponential backoff observed)
- ✅ WebSocket connects but Node sends late registration (status updates correctly)

## Next Phase (2.1b)

The Admin dashboard UI will:
1. Provide endpoint: GET `/api/admin/waiting-players` to list discovery-connected players
2. Display list of waiting players in Admin UI
3. Allow admin to select a player for lock-in
4. Trigger lock-in which transitions player from discovery → session phase

## Commit History

- `e18e27a` - Fix callback initialization and simplify UI text (removed extra descriptions)
- `aeab916` - Eliminate singleton PlayerAppState, use proper instance passing (critical bug fix)
- `066a57a` - Use exact status messaging ("Connecting...", "Waiting...", "Reconnecting (N)...")

## Architecture Decisions Rationale

### Why Not Full MVVM?
Current implementation uses ViewModel pattern (PlayerAppState is the ViewModel), but doesn't use service protocols/dependency injection containers. This is pragmatic for a small app but would need refactoring at ~500+ LOC. We chose to defer SOLID refactoring until the feature is complete to avoid premature abstraction.

### Why Dictionary Reassignment?
SwiftUI's change detection doesn't observe dictionary mutations (`dict[key] = value`). The @Published property only sees a change if the entire object is reassigned. This is a known SwiftUI limitation and the correct pattern.

### Why Not Force-Unwrap in Callbacks?
All weak self references check for nil before accessing state. This handles the case where the ViewModel is deallocated while callbacks are in flight—important for clean shutdown.
