# 🚀 Singalong Player Apple - Quick Start Guide

## What Just Happened

The Xcode project has been reorganized with a proper structure. You now have:

```
singalong-player-apple/
├── SingalongPlayer/              ← Source files (organized by module)
│   ├── App/                      ← App entry point and state
│   ├── Models/                   ← Data models
│   ├── Services/                 ← Business logic (mDNS, WebSocket)
│   ├── Views/                    ← SwiftUI views
│   ├── Assets.xcassets/          ← App icons and images
│   ├── Info.plist                ← App configuration
│   └── Preview Assets.xcassets/  ← Xcode preview assets
├── SingalongPlayer.xcodeproj/    ← Xcode project file
├── SingalongPlayer.xcworkspace/  ← Xcode workspace
├── Package.swift                 ← Swift Package Manager definition
├── AGENTS.md                     ← Technical documentation
└── setup.sh                      ← Setup script (already run)
```

## ✅ What's Ready

- ✅ All 7 Swift source files organized and ready
- ✅ Info.plist configured with network permissions
- ✅ Assets folder structure created
- ✅ Xcode project files in place
- ✅ Swift Package Manager support via Package.swift
- ✅ Workspace configured for development

## 🎯 Next: Open in Xcode

### Option 1: Open Workspace (Recommended)
```bash
open "apps/singalong-player-apple/SingalongPlayer.xcworkspace"
```
This is the recommended way to open the project for development.

### Option 2: Open Project Directly
```bash
open "apps/singalong-player-apple/SingalongPlayer.xcodeproj"
```

### Option 3: Open via Xcode Menu
1. Launch Xcode
2. File → Open
3. Navigate to `apps/singalong-player-apple/`
4. Select `SingalongPlayer.xcworkspace`

## ⚙️ Configuration Checklist (in Xcode)

Once opened, you'll need to configure:

### 1. Team & Bundle ID
- [ ] Select project in Xcode navigator
- [ ] Select "SingalongPlayer" target
- [ ] Go to "Signing & Capabilities"
- [ ] Select your Team ID (or choose "Add Account")
- [ ] Bundle ID: `com.nicenature.singalong-player` (should be pre-filled)

### 2. Capabilities
- [ ] Click "+ Capability" button
- [ ] Add: **Local Network** (for mDNS discovery)
- [ ] Add: **Bonjour** (for mDNS service discovery)
- Both are required for player discovery to work

### 3. Build Settings
- [ ] Deployment Target: iOS 16.0 minimum
- [ ] Swift Language Version: 5.9
- [ ] Info.plist Location: `SingalongPlayer/Info.plist`

### 4. Supported Platforms
The app is configured to build for:
- [ ] iOS (default)
- [ ] macOS (requires mac target)
- [ ] tvOS (requires tvOS target)

To enable additional platforms:
1. Select project in Xcode
2. Select target
3. Go to "Build Phases"
4. Add build targets for macOS and tvOS

## 🔨 Build & Run

### Build the App
```
Cmd + B
```

### Run on iOS Simulator
```
Cmd + R
```
(Xcode will prompt you to select simulator)

### Run on Physical Device
1. Connect iPad/iPhone via USB
2. Select device in Xcode toolbar
3. Press Cmd + R

## 🧪 Test the Flow

Once running, the player should:

1. **On App Launch** → Display "Searching for nodes..."
2. **mDNS Scan** → Auto-discover Singalong Nodes on local network
3. **WebSocket Connect** → For each discovered node, establish WS connection
4. **Show Nodes** → Display discovered nodes in scrollable list

**To test discovery:**
1. Ensure `singalong-node` is running on your network
   ```bash
   cd apps/singalong-node && poetry run uvicorn app.main:app --port 5002
   ```
2. Run player app in simulator
3. You should see the node appear in ~5 seconds
4. If you tap a node, it will show as "Connected"

## 📝 Common Issues & Fixes

### Issue: "No signing certificate found"
**Solution:**
- Click "Add Account" in Signing & Capabilities
- Sign in with your Apple ID
- Select your Team ID from dropdown

### Issue: "Bonjour permission denied"
**Solution:**
- Ensure Info.plist has these keys:
  - `NSLocalNetworkUsageDescription`
  - `NSBonjourUsageDescription`
  - `NSBonjourServices` array with `_singalong-node._tcp`
- Go to Capabilities and enable "Local Network"

### Issue: mDNS discovery not finding nodes
**Solution:**
1. Ensure Node is running: `curl http://localhost:5002/health`
2. Node must be on same network as simulator/device
3. Check Node logs for mDNS broadcast: `docker logs singalong-node`
4. Try tapping "Refresh" button in player app

### Issue: Can't build or compile errors
**Solution:**
1. Clean build folder: Cmd + Shift + K
2. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/`
3. Close Xcode and reopen workspace
4. Build again: Cmd + B

## 📚 Project Structure Details

### App/ - Application State & Entry Point
- **SingalongPlayerApp.swift** - SwiftUI @main entry point, sets up window groups for multi-platform
- **PlayerAppState.swift** - @MainActor state coordinator that bridges mDNS discovery and WebSocket connections

### Models/ - Data Structures
- **DiscoveredNode.swift** - Represents a discovered Singalong Node (name, ip, port, status)
- **WebSocketMessages.swift** - Codable enums for WebSocket protocol (register, lock, commands)

### Services/ - Core Business Logic
- **MDNSDiscoveryService.swift** - Actor-based mDNS scanner using NetServiceBrowser
- **WebSocketDiscoveryManager.swift** - Actor-based WebSocket connection manager for discovery phase

### Views/ - User Interface
- **IdleScreen.swift** - Main UI showing discovered nodes, status indicators, manual setup

## 🔗 Integration Points

When the player discovers a node and the admin selects it:

1. **Discovery Phase** (current):
   - Player connects to `ws://NODE-IP:5002/api/player/ws`
   - Admin sees available players via `GET /api/sessions/{code}/available-players`
   - Admin selects player via `POST /api/sessions/{code}/select-player`

2. **Lock-In Phase** (next):
   - Node sends: `{type: lock, session_code, token}` to player
   - Player closes connections to other nodes
   - Both establish session-specific connection at `/api/session/{code}/player/ws`

## 🚦 Next Steps After Build

Once you can build and run the player:

1. ✅ Test mDNS discovery with running Node
2. ✅ Verify WebSocket connection in Node logs
3. ✅ Test Admin UI player selection
4. ✅ Verify lock message is received
5. 📋 Implement playback WebSocket connection (Phase P2.7)
6. 📋 Add reconnection logic (Phase P2.9)

## 💬 Need Help?

Refer to the detailed AGENTS.md file for:
- Architecture overview
- Service descriptions
- Protocol specifications
- State management details
- Error handling patterns

```bash
# Quick reference
cat AGENTS.md
```

---

**Status**: ✅ Ready for Xcode

Open the workspace and start building! 🎉
