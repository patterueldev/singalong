# Singalong Player - Apple Platforms

A native SwiftUI player application for iOS, macOS, tvOS, and iPadOS.

## Platforms Supported

- **macOS** 13.0+
- **iOS** 16.0+
- **iPadOS** 16.0+
- **tvOS** 16.0+

## Architecture

### Phase P2: Player Discovery & WebSocket Connection

#### What's Implemented

1. **mDNS Discovery Service** (`MDNSDiscoveryService.swift`)
   - Scans local network for `_singalong-node._tcp` services
   - Resolves service IPs and stores discovered nodes
   - Real-time updates when nodes appear/disappear

2. **WebSocket Discovery Manager** (`WebSocketDiscoveryManager.swift`)
   - Manages multiple concurrent WebSocket connections to discovered nodes
   - Sends registration message on connect: `{"type": "register", "name": "...", "platform": "..."}`
   - Handles incoming registration response: `{"type": "registered", "player_id": "..."}`
   - Listens for lock message: `{"type": "lock", "session_code": "...", "token": "..."}`

3. **App State** (`PlayerAppState.swift`)
   - Central state management using SwiftUI's `@StateObject`
   - Coordinates mDNS discovery and WebSocket connections
   - Tracks connection status per node
   - Manages UI updates via `@Published` properties

4. **Idle Screen** (`IdleScreen.swift`)
   - Lists discovered nodes with connection status
   - Shows "Searching..." when discovery is active
   - Allows manual connection with "Connect" button
   - Manual setup sheet for URL + API Key fallback
   - Dark mode enforced (color scheme: dark)

### Protocol Details

#### Discovery Phase WebSocket Messages

**Player → Node (Register)**
```json
{
  "type": "register",
  "name": "Pat's MacBook",
  "platform": "macos"
}
```

**Node → Player (Registered)**
```json
{
  "type": "registered",
  "player_id": "uuid-1234"
}
```

**Node → Player (Lock)**
```json
{
  "type": "lock",
  "session_code": "0001",
  "token": "jwt-token"
}
```

## Building

### Xcode (Recommended)

```bash
# Open in Xcode
open singalong-player-apple/singalong-player-apple.xcodeproj

# Build for iOS
xcodebuild build -scheme singalong-player-apple -destination "generic/platform=iOS"

# Build for macOS
xcodebuild build -scheme singalong-player-apple -destination "generic/platform=macOS"
```

### Swift Package Manager (CLI)

```bash
# Build
swift build

# Test
swift test

# Run
swift run SingalongPlayer
```

## Architecture Decisions

1. **Native Swift over React Native**: Better support for tvOS/watchOS, faster performance, native video player access
2. **SwiftUI over UIKit**: Modern, declarative UI framework with better multi-platform support
3. **Actor-based Concurrency**: Uses Swift Concurrency for thread-safe WebSocket management
4. **mDNS via NetServiceBrowser**: Native API, no external dependencies, Bonjour support

## Known Limitations

- Manual setup UI not yet connected to actual connection logic (will be in P2.8)
- Playback WebSocket connection not yet implemented (P2.7)
- No automatic reconnection logic yet (P2.9)

## Next Steps (Phase P2 Remaining)

1. **P2.7**: Implement playback WebSocket connection to `ws://NODE:5002/api/session/{code}/player/ws`
2. **P2.8**: Connect manual setup button to actual connection
3. **P2.9**: Add reconnection logic with exponential backoff
4. **P3**: Implement playback screen with video player and controls
