# Singalong Session Progress - Feature: Player Discovery & WebSocket Connection

## What Was Accomplished in Latest Session

### 1. Identified & Resolved Lima VM Networking Issue ✅
- **Problem**: Docker port forwarding in Lima VM wasn't exposing port 5002 to host network
- **Impact**: iPad/Player couldn't connect to Node via hostname or IP address
- **Root Cause**: Lima VM configuration not properly mapping `0.0.0.0:5002`
- **Solution**: Fixed Lima VM Docker networking
- **Verification**: `curl http://thursday.local:5002/health` now works from any host on network

### 2. Fixed iOS AppTransportSecurity (ATS) Configuration ✅
- **Problem**: iOS blocks HTTP connections by default, requires HTTPS
- **Solution**: Added NSAppTransportSecurity exception to Info.plist:
  - Allow HTTP for `.local` domain (mDNS resolved hostnames)
  - Allow HTTP for localhost (development)
- **Files Modified**: `SingalongPlayer/Info.plist`

### 3. Fixed Trailing Dot in mDNS Hostname ✅
- **Problem**: mDNS returns hostname with trailing dot (e.g., `thursday.local.`)
- **Impact**: URL became `ws://thursday.local.:5002` (invalid)
- **Solution**: Strip trailing dot in `DiscoveredNode.discoveryWSURL`
- **Files Modified**: `apps/singalong-player-apple/SingalongPlayer/Models/DiscoveredNode.swift`

### 4. **[NEW] Merged singalong-mdns-bridge into singalong-node** ✅
- **Problem**: Separate mdns-bridge service was redundant once Node was accessible
- **Solution**: Integrated mDNS broadcasting as background service in Node:
  - Created `app/services/mdns/` module with SOLID principles:
    - `interfaces.py`: `BroadcasterInterface` abstraction
    - `broadcaster.py`: `MDNSBroadcaster` (dns-sd implementation)
    - `bridge.py`: `MDNSBridgeService` (lifecycle management)
  - Integrated into FastAPI lifespan (startup/shutdown)
  - Added config options: `MDNS_BROADCAST_ENABLED`, `MDNS_SERVICE_NAME`, etc.
  - Updated `pyproject.toml` with zeroconf + requests dependencies
- **Result**: Single deployable Node artifact, no separate bridge app needed
- **Files Modified/Created**:
  - Created: `app/services/mdns/` (4 files)
  - Modified: `app/main.py`, `app/config.py`, `pyproject.toml`, `poetry.lock`
  - Deleted: `apps/singalong-mdns-bridge/`, `infrastructure/development/mdns-bridge.dockerfile`
  - Modified: `docker-compose.yml` (removed mdns-bridge service)

## Current System Architecture

```
iOS/macOS Player App
├── mDNS Discovery (NetServiceBrowser)
│   └── Resolves: _singalong-node._tcp → hostname:5002
│
└── WebSocket Connection
    └── ws://thursday.local:5002/api/player/ws
         ↓
Docker (Lima VM on macOS)
└── singalong-node (port 5002)
    ├── mDNS Broadcasting (background service)
    ├── REST APIs (sessions, songs, etc.)
    ├── WebSocket /api/player/ws (Player connections)
    └── WebSocket /ws (Master communication)
```

## What's Working ✅

1. **Node mDNS Broadcasting**: Starts automatically in Docker, broadcasts _singalong-node._tcp
2. **iOS AppTransportSecurity**: HTTP allowed for .local domains (mDNS hostnames)
3. **Hostname Resolution**: mDNS returns valid hostname without trailing dot
4. **Network Accessibility**: Lima VM now exposes Docker port 5002 to host network
5. **Node Health**: `curl http://localhost:5002/health` returns 200

## What Needs Testing

### Immediate (Critical Path):
1. [ ] **Player WebSocket Connection**: Can Player app establish ws:// connection to Node?
   - Test: Run Player app, observe console for connection logs
   - Expected: Connection successful, player receives welcome/setup message

2. [ ] **Session Creation**: Can Player create a session via WebSocket?
   - Test: Player connects → should auto-create or join session
   - Expected: Session code displayed on Player

3. [ ] **IPv6 Handling**: mDNS returns IPv6 addresses - does Player handle them?
   - Current: Player extracts IPv6 but may fail to connect
   - Issue: IPv6 link-local addresses need %interface scope
   - Consider: Prefer IPv4 A records over IPv6 AAAA records

### Secondary (Integration):
4. [ ] **Player API Endpoints**: Test `/api/player/ws` endpoint
5. [ ] **Session WebSocket**: Test player connecting to session via /api/sessions/{code}/ws
6. [ ] **Admin Dashboard**: Can admin see active players/sessions?
7. [ ] **Cross-device**: Test Player discovering Node from another device on network

## Outstanding Technical Debt

### Player App IPv6 Issue:
- **Current**: Player discovers both IPv4 and IPv6 addresses from mDNS
- **Problem**: IPv6 link-local addresses (fe80::...) fail to connect without %interface scope
- **Solution Options**:
  1. Prefer IPv4 A records (simplest)
  2. Add %interface scope to IPv6 addresses (more complex)
  3. Try all addresses with fallback logic

### Authentication Flow:
- **Node → Master**: Uses GraphQL mutations (implemented)
- **Player → Node**: Should use `/api/player/register` endpoint then WebSocket
- **Current Status**: Need to verify player registration endpoint exists and works

## Files Modified This Session

### Created:
- `apps/singalong-node/app/services/mdns/__init__.py`
- `apps/singalong-node/app/services/mdns/interfaces.py`
- `apps/singalong-node/app/services/mdns/broadcaster.py`
- `apps/singalong-node/app/services/mdns/bridge.py`

### Modified:
- `apps/singalong-node/app/main.py` - integrated MDNSBridgeService in lifespan
- `apps/singalong-node/app/config.py` - added mDNS configuration fields
- `apps/singalong-node/pyproject.toml` - added zeroconf, requests dependencies
- `apps/singalong-node/poetry.lock` - regenerated with new deps
- `apps/singalong-player-apple/SingalongPlayer/Info.plist` - added ATS exceptions
- `apps/singalong-player-apple/SingalongPlayer/Models/DiscoveredNode.swift` - strip trailing dot
- `docker-compose.yml` - removed mdns-bridge service

### Deleted:
- `apps/singalong-mdns-bridge/` - entire directory
- `infrastructure/development/mdns-bridge.dockerfile`

## How to Resume Next Session

### 1. Verify Infrastructure is Running
```bash
# Check Docker services
docker-compose ps

# Verify Node is healthy
curl http://localhost:5002/health

# Verify mDNS broadcast (macOS only)
timeout 3 dns-sd -B _singalong-node._tcp local.
```

### 2. Test Player App
```bash
# Build Player app
cd apps/singalong-player-apple
xcode-build -workspace SingalongPlayer.xcworkspace -scheme SingalongPlayer

# Or open in Xcode and run
open SingalongPlayer.xcworkspace
```

### 3. Check Console Logs
Watch for:
- `[mDNS] ✓ Found service: 'Singalong Node'`
- `[mDNS] ✓ netServiceDidResolveAddress called`
- `[DiscoveredNode] Generated URL: ws://thursday.local:5002/api/player/ws`
- `[WS Discovery] ===== CONNECTING TO NODE =====`
- Success: `[PlayerApp] Successfully connected to node`

## Key Git Commit

Latest commit: `feat: Merge singalong-mdns-bridge into singalong-node as background service`
- Hash: Can be found with `git log --oneline | head -1`
- Changes: 23 files changed, 788 insertions (+), 117 deletions (-)

## Next Phase: Player Connection Lifecycle & Admin Selection (Phase 2)

### Phase 2.1: Player UI Enhancement for Connection Status

**What Needs Implementation:**
1. **Apple Platform App** (runs on iOS, iPad, macOS, tvOS)
   - [ ] Update UI to show connection status after WebSocket connects to Node
   - [ ] Display "Waiting for admin selection" (or shorter status text) when connected
   - [ ] Show list of detected mDNS nodes with current connection status
   - **Goal**: Player shows it's connected and waiting, not just "attempting"

2. **Admin Dashboard**
   - [ ] Create "Waiting Players" panel/list
   - [ ] Display all players currently connected via WebSocket discovery
   - [ ] Add "Select Player" UI control (button, checkbox, etc.)
   - [ ] Once admin selects a player, show "Lock In" action button
   - **Goal**: Admin can see and select from available players

### Phase 2.2: Connection Lock-In & State Transition

**What Needs Implementation:**
When admin "locks in" a selected player:

1. **Node Side**:
   - [ ] Stop mDNS broadcasting (`MDNSBridgeService.stop()`)
   - [ ] Stop discovery WebSocket listener (`/api/player/ws`)
   - [ ] Transition selected player to dedicated command WebSocket (`/api/sessions/{code}/ws`)

2. **Player Side**:
   - [ ] Disconnect from all Node discovery WebSockets
   - [ ] Stop mDNS discovery listener
   - [ ] Connect to dedicated session command WebSocket
   - [ ] Update UI: "Connected to Singalong Node" or similar

3. **UI/UX**:
   - [ ] Admin: Show player is now "locked in" / "active"
   - [ ] Player: Show "Ready" or "Connected" status with session code
   - [ ] Both: Indicate that discovery phase is complete

### Phase 2.3: Disconnect Handling (Two Scenarios)

**Scenario A: Intentional Disconnect (Admin-Initiated)**
- Admin clicks "Stop Session" or similar on Player
- [ ] **Node**: Restarts mDNS broadcaster, restarts discovery WebSocket listener
- [ ] **Player**: Restarts mDNS discovery, returns to "Waiting for Node" state
- [ ] **UI**: Both reset to discovery phase

**Scenario B: Accidental Disconnect (Network Glitch)**
- WebSocket connection drops unexpectedly
- [ ] **Node**: Attempts to reconnect to locked-in player (with backoff/retry logic)
- [ ] **Player**: Attempts to reconnect to Node (with backoff/retry logic)
- [ ] **UI**: Show "Reconnecting..." status on both sides
- [ ] **Recovery**: If reconnect succeeds within timeout, continue session
- [ ] **Admin Override**: Admin can manually force disconnect → triggers Scenario A

**Edge Case: Player App Restart**
- [ ] Player app explicitly closed/force-quit
- [ ] Node detects disconnection, waits for reconnect attempt
- [ ] Admin can either:
  - [ ] Wait for Player to reconnect (appears in discovery again)
  - [ ] Force close and release Node (returns to discovery mode)
- [ ] Player app restarted → starts fresh mDNS discovery

### Architecture for Phase 2

```
┌─────────────────────────────────────────────────────────────┐
│ DISCOVERY PHASE (Current State)                              │
├─────────────────────────────────────────────────────────────┤
│ Node:   Broadcasting mDNS + listening on /api/player/ws      │
│ Player: Discovering via mDNS + connected to /api/player/ws   │
│ Admin:  Can see list of "Waiting" players                    │
└────────────────┬────────────────────────────────────────────┘
                 │ Admin selects player and "locks in"
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ ACTIVE SESSION PHASE (Desired State)                         │
├─────────────────────────────────────────────────────────────┤
│ Node:   mDNS OFF, /api/player/ws OFF, listening on           │
│         /api/sessions/{code}/ws                              │
│ Player: Discovery OFF, connected to /api/sessions/{code}/ws  │
│ Admin:  Can send commands to locked-in player                │
└────────────────┬────────────────────────────────────────────┘
                 │ Admin intentional disconnect
                 ├──→ Return to DISCOVERY PHASE
                 │
                 │ Or connection drops (accidental)
                 ├──→ Both retry reconnect
                 ├──→ If succeed: stay in ACTIVE SESSION
                 └──→ If timeout/admin overrides: return to DISCOVERY PHASE
```

### Critical State Management Requirements

- **No Overlap**: When in ACTIVE SESSION phase, discovery must be completely off (no mDNS, no discovery WS)
- **Clean Transitions**: Ensure WebSocket connections are properly closed before opening new ones
- **Retry Logic**: Implement exponential backoff for accidental disconnects (don't hammer server)
- **Session Isolation**: Once player locked in, it can only communicate via session endpoint, not discovery endpoint
- **Admin Control**: Admin must have explicit controls to:
  - Force player reconnect
  - Force player disconnect
  - Clear/reset player list

## Next Priority Actions (Phase 2)

1. **Phase 2.1: Player UI Status**
   - Update Player app to display "Waiting for admin selection" after WebSocket connection
   - Add status indicator on Player UI

2. **Phase 2.1: Admin Dashboard**
   - Create endpoint `/api/admin/waiting-players` to list discovery-connected players
   - Build Admin UI to display waiting player list
   - Add "Select" and "Lock In" controls

3. **Phase 2.2: Connection Lock-In Logic**
   - Implement admin endpoint to lock in player (POST `/api/admin/players/{player_id}/lock-in`)
   - Node code: Stop mDNS + discovery WS
   - Notify Player to transition to session WS
   - Verify player can communicate via session endpoint

4. **Phase 2.3: Disconnect Handling**
   - Implement retry logic with exponential backoff
   - Add force-disconnect endpoint for admin
   - Handle both intentional and accidental disconnects
   - Add UI status indicators for reconnecting/retrying

5. **Testing & Verification**
   - Test full discovery → lock-in → active session flow
   - Test intentional disconnect → rediscovery
   - Test accidental disconnect → reconnect
   - Test admin force-disconnect

## Session Statistics
- **Duration**: Fixed Lima VM networking → merged mdns-bridge → ~3 hours
- **Blockers Resolved**: 2 (Lima VM port forwarding, ATS configuration)
- **Services Integrated**: 1 (mdns-bridge into Node)
- **Build Status**: ✅ All services building and running
- **Next Phase**: Player UI status + Admin dashboard + Connection lifecycle management
- **Ready for**: Phase 2 implementation in new session


