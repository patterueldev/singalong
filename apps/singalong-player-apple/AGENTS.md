# Singalong Player App (Apple Platforms) - AGENTS.md

## Overview

**singalong-player-apple** is a native SwiftUI application for iOS, macOS, iPad, and tvOS that acts as the playback device for Singalong karaoke sessions.

**Technology Stack**:
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Platforms**: iOS 16+, macOS 13+, iPadOS 16+, tvOS 16+
- **Network**: URLSessionWebSocketTask, NetServiceBrowser (mDNS)
- **Concurrency**: Swift Actors and async/await

**Ports**: N/A (client application, connects to Node at port 5002)

---

## 1. Architecture Overview

The player app implements a **three-phase lifecycle**:

```
┌─────────────────────────────────────────────────────┐
│ PHASE 1: DISCOVERY                                  │
│ ─────────────────────────────────────────────────   │
│ • mDNS scan for Nodes                               │
│ • Display list of found nodes                       │
│ • User taps "Connect" for desired node              │
│ • Open WebSocket to Node discovery endpoint         │
│ • Send: {"type": "register", "name": "...", ...}   │
│ • Receive: {"type": "registered", "player_id": ".."}
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ PHASE 2: LOCK-IN                                    │
│ ─────────────────────────────────────────────────   │
│ • Wait for admin to select this player              │
│ • Receive: {"type": "lock", "session_code": "..."}
│ • Close discovery WS connections to OTHER nodes     │
│ • Prepare to open playback WS                       │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ PHASE 3: PLAYBACK                                   │
│ ─────────────────────────────────────────────────   │
│ • Open session-specific WS: /api/session/{code}/... │
│ • Receive playback commands (play/pause/seek)       │
│ • Send status updates (progress, current_time)      │
│ • Handle disconnections gracefully                  │
└─────────────────────────────────────────────────────┘
```

**Key Point**: The player is **always a client**, never a server. It discovers nodes via mDNS and initiates WebSocket connections to them.

---

## 2. File Structure

```
singalong-player-apple/
├── Sources/
│   ├── App/
│   │   ├── SingalongPlayerApp.swift        # Main app entry point
│   │   └── PlayerAppState.swift            # Central state management
│   │
│   ├── Models/
│   │   ├── DiscoveredNode.swift            # Data models for nodes/connections
│   │   └── WebSocketMessages.swift         # Protocol message types
│   │
│   ├── Services/
│   │   ├── MDNSDiscoveryService.swift      # mDNS scanner (NetServiceBrowser)
│   │   └── WebSocketDiscoveryManager.swift # WebSocket connection manager
│   │
│   └── Views/
│       └── IdleScreen.swift                # UI for discovery phase
│
├── README.md                               # User-facing documentation
└── AGENTS.md                               # This file (for AI agents)
```

---

## 3. Key Services

### 3.1 MDNSDiscoveryService (Actor)

**Location**: `Services/MDNSDiscoveryService.swift`

**Responsibility**: Scan local network for Singalong Node services via mDNS

**Key Methods**:
- `startDiscovery()` - Start scanning for `_singalong-node._tcp` services
- `stopDiscovery()` - Stop scanning and clear nodes
- `getDiscoveredNodes()` - Return current list of discovered nodes
- `getNode(byId:)` - Get specific node by service name

**Callbacks**:
- `onNodesUpdated` - Called when node list changes
- `onNodeAdded` - Called when new node discovered
- `onNodeRemoved` - Called when node disappears

**Implementation Details**:
- Uses `NetServiceBrowser` for mDNS discovery
- `NetServiceDelegate` for address resolution
- Async/actor-based for thread safety
- Extracts IPv4 address from mDNS announcement
- Stores nodes in-memory in `discoveredNodes` dict

**Testing**: 
- mDNS works in iOS simulator (can discover real nodes on same network)
- macOS Simulator may have network issues (use physical macOS for testing)
- tvOS and watchOS simulators don't support mDNS well (test on devices)

---

### 3.2 WebSocketDiscoveryManager (Actor)

**Location**: `Services/WebSocketDiscoveryManager.swift`

**Responsibility**: Manage WebSocket connections to multiple nodes during discovery phase

**Key Methods**:
- `connect(to:)` - Open WebSocket to a discovered node
  - Creates URLSessionWebSocketTask
  - Sends register message: `{"type": "register", "name": "...", "platform": "..."}`
  - Starts receiving loop
  
- `disconnect(fromNodeId:)` - Close connection to specific node
- `disconnectAll()` - Close all node connections
- `send(message:toNodeId:)` - Send message to specific node
- `getStatus(forNodeId:)` - Check connection status

**Callbacks**:
- `onMessageReceived` - Called when message from node arrives
- `onConnectionStatusChanged` - Called when connection status changes
- `onConnectionClosed` - Called when connection closes

**Message Protocol** (Discovery Phase):

Sent by Player:
```swift
.register(name: "Pat's MacBook", platform: "macos")  // Initial handshake
.pong                                                // In response to Node pings
```

Received from Node:
```swift
.registered(playerId: "uuid")           // Response to register
.lock(sessionCode: "0001", token: "...") // Admin selected this player
.error(code: "...", message: "...")     // Error from Node
```

**Status Tracking**:
- `disconnected` - Not connected
- `connecting` - Connection in progress
- `connected` - Connected, registered with Node
- `locked` - Admin has locked this player to a session (transition state)
- `error` - Connection error

---

### 3.3 PlayerAppState (StateObject)

**Location**: `App/PlayerAppState.swift`

**Responsibility**: Central app state management, coordinates mDNS and WebSocket

**Key Properties**:
- `discoveredNodes: [DiscoveredNode]` - List of found nodes
- `activeConnections: [String: NodeConnectionStatus]` - Per-node status
- `selectedNodeId: String?` - Currently locked node
- `lockedSessionCode: String?` - Session code from lock message
- `lockedSessionToken: String?` - JWT token for playback WS
- `playerId: String?` - Player ID assigned by Node
- `isDiscovering: Bool` - Whether mDNS scan is active

**Key Methods**:
- `startDiscovery()` - Begin mDNS scan
- `stopDiscovery()` - Stop mDNS scan
- `connectToNode(_:)` - Open WebSocket to node
- `disconnectAll()` - Close all WebSocket connections
- `handleLockMessage(sessionCode:token:fromNodeId:)` - Process lock message

**Callbacks Setup**:
- Sets up `MDNSDiscoveryService.onNodesUpdated` to update UI
- Sets up `WebSocketDiscoveryManager.onMessageReceived` to handle Node messages

**State Updates Flow**:
```
User taps Idle Screen
    ↓
startDiscovery()
    ↓
MDNSDiscoveryService finds nodes
    ↓
onNodesUpdated callback fires
    ↓
discoveredNodes updated, UI refreshes
    ↓
User taps "Connect" on node
    ↓
connectToNode() opens WebSocket
    ↓
onConnectionStatusChanged fires periodically
    ↓
activeConnections dict updated, UI shows status
    ↓
Node sends .registered message
    ↓
playerId set
    ↓
[Later] Admin selects player in Admin UI
    ↓
Node sends .lock message
    ↓
handleLockMessage() called
    ↓
selectedNodeId set, lockedSessionCode/token saved
    ↓
(Next phase: Open playback WS using these values)
```

---

## 4. Views

### 4.1 IdleScreen

**Location**: `Views/IdleScreen.swift`

**Purpose**: Show discovered nodes and allow player selection (PHASE P2.4-P2.6)

**UI Components**:
1. **Header**: "Singalong Player" with discovery status
2. **Status Indicator**: Spinning circle + text ("Discovering..." or "Ready")
3. **Nodes List**: ScrollView of NodeCard for each discovered node
4. **Empty State**: "No Nodes Found" message when list is empty
5. **Error Banner**: Shows error message if connection fails
6. **Control Buttons**:
   - "Refresh" button - Restart discovery scan
   - "Manual Setup" - Open sheet for URL + API Key entry (low-key, iOS/macOS only)

**NodeCard Component**:
- Displays: Node name, IP:port, connection status, lock indicator
- Color-coded status (gray=disconnected, yellow=connecting, green=connected, purple=locked)
- "Connect" button (only shown if disconnected)
- Selected node highlighted with purple border

**Dark Mode**: Enforced via `preferredColorScheme(.dark)`
- Background: `#16171d` (dark charcoal)
- Text: `#ffffff` (white)
- Secondary text: `#9ca3af` (gray)
- Accent: `#c084fc` (purple)

---

## 5. Models

### 5.1 DiscoveredNode

```swift
struct DiscoveredNode: Identifiable, Hashable {
    let id: String          // mDNS service name
    var name: String        // "Singalong Node"
    var host: String        // "node.local"
    var port: Int           // 5002
    var ipAddress: String?  // "192.168.1.100"
    var discoveredAt: Date
    
    var discoveryWSURL: URL? // ws://192.168.1.100:5002/api/player/ws
}
```

### 5.2 WebSocket Messages

**PlayerMessage enum** (sent TO node):
- `register(name: String, platform: String)`
- `locked(playerId: String)`
- `auth(sessionCode: String, token: String)`
- `ping`

**NodeMessage enum** (received FROM node):
- `registered(playerId: String)`
- `lock(sessionCode: String, token: String)`
- `pong`
- `error(code: String, message: String)`

Both support Codable for JSON serialization.

---

## 6. Concurrency Model

The app uses **Swift Concurrency** (actors + async/await):

```
┌──────────────────────────────┐
│ PlayerAppState (@MainActor)  │  Main thread UI state
└──────────────────────────────┘
              ↓ calls
    ┌─────────────────────┐
    │ MDNSDiscoveryService│  Scans network, callback to main
    │ (Actor)             │
    └─────────────────────┘
              +
    ┌─────────────────────────────┐
    │ WebSocketDiscoveryManager   │  Handles WebSocket, callbacks to main
    │ (Actor)                     │
    └─────────────────────────────┘

Updates flow: Actor → @MainActor callback → @Published property → SwiftUI refresh
```

**Thread Safety**:
- `MDNSDiscoveryService` and `WebSocketDiscoveryManager` are actors (isolated)
- All mutable state is protected by actor isolation
- Callbacks use `DispatchQueue.main.async` to update MainActor state
- No explicit locks needed

---

## 7. Platform-Specific Behavior

### iOS / iPadOS
- Full touch controls
- Manual setup sheet support
- Runs in portrait or landscape

### macOS
- Touch trackpad controls supported
- Manual setup sheet support
- Can be resizable window
- Can support multiple windows (future)

### tvOS
- Remote control (Siri Remote)
- No manual setup (mDNS only)
- "Connect" button navigable via remote

### Manual Setup (iOS/macOS only)
- Low-key button at bottom of Idle Screen
- Sheet modal with:
  - URL input field: `ws://192.168.1.100:5002`
  - API Key input field (optional)
  - Connect button

---

## 8. Development Workflow

### Creating Xcode Project (One-Time Setup)

1. Create iOS App project with SwiftUI
2. Add macOS, tvOS targets
3. Create shared sources for common code
4. Configure Info.plist for network access

**Info.plist Requirements**:
```xml
<key>NSBonjourServices</key>
<array>
    <string>_singalong-node._tcp</string>
</array>
<key>NSLocalNetworkUsageDescription</key>
<string>Singalong Player needs to discover karaoke nodes on your local network</string>
<key>NSBonjourUsageDescription</key>
<string>Singalong Player discovers karaoke nodes using Bonjour (mDNS)</string>
```

### Testing Discovery Locally

1. Start Node server: `docker-compose up node`
2. Open Terminal, check Node's mDNS broadcast:
   ```bash
   dns-sd -B _singalong-node._tcp
   ```
3. Should see: `Singalong Node` appear in list
4. Build and run Player app
5. mDNS discovery should find the Node
6. Player UI should show Node in discovered list

### Testing WebSocket Connection

1. Connect player to Node
2. Check Node logs:
   ```bash
   docker-compose logs node | grep "Player"
   ```
3. Should see: `Player 'Pat's MacBook' connected [platform: ios]`
4. Player UI should show status: "Connected"

---

## 9. Known Issues & Limitations

1. **mDNS in Simulator**: Works in iOS/iPadOS simulators if Node is on same network. tvOS/watchOS simulators don't support mDNS well (use physical devices).

2. **Playback WS Not Yet Implemented**: Only discovery phase is complete. Playback connection happens in P2.7.

3. **Manual Setup Not Connected**: Button exists but doesn't do anything yet. Will be implemented in P2.8.

4. **No Reconnection Logic**: If WebSocket drops, connection stays dead. Will add exponential backoff in P2.9.

5. **tvOS Remote**: Menu button handling not yet optimized for tvOS remote navigation.

---

## 10. Future Phases

### Phase P2.7: Playback WebSocket
- Implement playback WS connection to `/api/session/{code}/player/ws`
- Use token from lock message for authentication
- Add message handlers for play/pause/seek commands

### Phase P2.8: Playback Screen
- Show video player (AVPlayer)
- Display queue (if applicable)
- Show progress seekbar
- Show current song info

### Phase P2.9: Resilience
- Reconnection logic with exponential backoff
- Handle graceful shutdown
- Detect node disconnection and fallback to discovery

### Phase P3: Multi-Node Support
- Allow player to maintain multiple node connections
- Switch between nodes without full reconnect
- Session presets/favorites

---

## 11. Code Conventions

- **Naming**: PascalCase for types, camelCase for properties/methods
- **Comments**: Document public APIs and non-obvious logic
- **Error Handling**: Use `Result` types and `throws` for recoverable errors
- **Logging**: Use `print()` with `[Component]` prefix for debugging
- **Testing**: Unit tests in `Tests/` directory (TODO)

---

## 12. Relevant Documentation

- **[API_CONTRACT_AUTHENTICATION.md](../docs/API_CONTRACT_AUTHENTICATION.md)** - Auth flow (Node-Master)
- **[PROJECT_OVERVIEW.md](../docs/PROJECT_OVERVIEW.md)** - System architecture
- **[IMPLEMENTATION_PHASES.md](../docs/IMPLEMENTATION_PHASES.md)** - Phase breakdown including P2
