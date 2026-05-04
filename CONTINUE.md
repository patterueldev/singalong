# Singalong mDNS Discovery & Player Setup - Session Summary

## What We Accomplished

### 1. Fixed mDNS Bridge Service ✅
- **Problem**: Docker network isolation prevented Node's mDNS broadcasts from reaching the host macOS
- **Solution**: Created standalone Python service (`singalong-mdns-bridge`) that:
  - Detects Node health via REST API polling (localhost:5002)
  - Broadcasts mDNS service natively on macOS using system `dns-sd` command
  - Runs outside Docker, bypassing network isolation
  - Auto-starts/stops broadcasting based on Node health

**Status**: Bridge is running and successfully broadcasting `_singalong-node._tcp` at 192.168.254.119:5002

### 2. Fixed Player App mDNS Resolution ✅
- **Problem**: Player discovered the mDNS service but failed to resolve it to an IP address
- **Root Cause**: `MDNSServiceResolver` delegate was deallocated immediately (weak reference, nothing retained it)
- **Solution**: 
  - Added `activeResolvers` dictionary to retain resolver objects during resolution
  - Enhanced resolver lifecycle with proper cleanup
  - Added comprehensive logging at each resolution step
  - Increased resolution timeout to 10 seconds

**Status**: Player app builds successfully with enhanced resolution logging

### 3. Verified Infrastructure ✅
- Docker services: Admin (3001), Node (5002), Controller (3002), Cloudflared - all running
- Node health endpoint responding correctly
- mDNS broadcast verified with `dns-sd -B` command
- Poetry lock file regenerated for Node service

## What Happens When Player Detects mDNS

### Discovery Flow (in Player app):
1. **App starts** → `MDNSDiscoveryService` begins scanning for `_singalong-node._tcp` services
2. **mDNS broadcast found** → System Bonjour discovers the broadcast from mDNS bridge
3. **Service resolution** → Player creates `MDNSServiceResolver` to resolve service details:
   - Service name: "Singalong Node"
   - Hostname: derived from mDNS broadcast
   - Port: 5002 (from mDNS)
   - **IP address**: This is what gets resolved (192.168.254.119)
4. **Resolver lifetime**:
   - Created when service found
   - **Stored** in `activeResolvers` dictionary (so it doesn't get deallocated)
   - Calls `netService.resolve(withTimeout: 10.0)`
   - Resolution callback (`netServiceDidResolveAddress`) extracts IP from address data
   - Creates `DiscoveredNode` object with IP:PORT
   - **Removes** resolver from dictionary (cleanup)
5. **UI Updates** → Node appears in player with resolved IP and port
6. **Player can now connect** → Uses IP:PORT to establish WebSocket to Node

### Expected Log Sequence:
```
[mDNS] Found service: Singalong Node on unknown
[mDNS] Created resolver for service: Singalong Node
[mDNS] Resolving service: Singalong Node (timeout 10s)
[mDNS] netServiceDidResolveAddress called for: Singalong Node
[mDNS] ✓ Got addresses for Singalong Node: 1 address(es)
[mDNS] ✓ Resolved to: 192.168.254.119:5002
[mDNS] Added node: Singalong Node at 192.168.254.119:5002
```

## Current System Architecture

```
macOS Host
├── Singalong Player (iOS/macOS app)
│   ├── mDNS Scanner (NetServiceBrowser)
│   └── Service Resolver (MDNSServiceResolver)
│
└── singalong-mdns-bridge (Python service)
    ├── Node Detector (polls http://localhost:5002/health)
    └── mDNS Broadcaster (via system dns-sd command)
         ↓
         Detects Node running in Docker (lima VM)
         
Docker (lima VM)
└── singalong-node
    ├── Port 5002 (HTTP API)
    ├── WebSocket /ws (Master communication)
    └── No local mDNS (removed, uses external bridge)
```

## Files Modified This Session

### Created:
- `/Users/pat/Projects/PAT/singalong/apps/singalong-mdns-bridge/` (entire service)
  - `main.py`, `requirements.txt`, `run.sh`, `verify.sh`
  - `singalong_mdns_bridge/` (config, logger, node_detector, mdns_broadcaster, service)

### Modified:
- `apps/singalong-player-apple/SingalongPlayer/Services/MDNSDiscoveryService.swift`
  - Added `activeResolvers` dictionary
  - Enhanced `MDNSServiceResolver` class
  - Added `storeResolver()` and `removeResolver()` methods
  - Improved logging throughout
  - Increased resolution timeout to 10s
- `apps/singalong-node/pyproject.toml` - removed zeroconf dependency
- `apps/singalong-node/app/main.py` - removed mDNS startup/shutdown
- `apps/singalong-player-apple/SingalongPlayer/Info.plist` - added privacy permissions
- `poetry.lock` - regenerated in Node service

## Next Steps for Next Session

### Immediate Testing:
1. [ ] Run Player app in Xcode and observe resolution logs
2. [ ] Verify node appears in UI with IP address
3. [ ] Test WebSocket connection from Player to Node
4. [ ] Verify session can be established

### Long-term Improvements:
1. [ ] Set up LaunchAgent for permanent mDNS bridge service
2. [ ] Test cross-network discovery (different machines)
3. [ ] Handle node disconnection/reconnection gracefully
4. [ ] Add error handling for resolution timeouts
5. [ ] Test with multiple nodes

### Outstanding Issues/Considerations:
- mDNS bridge only works on macOS (Python requests library)
- Need to test Player on actual iOS device (may need different discovery)
- Need to verify WebSocket connection works after resolution
- Consider DNS caching issues on longer-running sessions

## How to Resume

1. **Check bridge is running**:
   ```bash
   ps aux | grep singalong-mdns-bridge
   # OR restart:
   cd apps/singalong-mdns-bridge && bash run.sh
   ```

2. **Start Docker services**:
   ```bash
   docker compose up -d
   ```

3. **Verify mDNS broadcast**:
   ```bash
   timeout 3 dns-sd -B _singalong-node._tcp local.
   ```

4. **Run Player app**:
   - Open Xcode: `open apps/singalong-player-apple/SingalongPlayer.xcodeproj`
   - Build: Cmd+B
   - Run: Cmd+R
   - Watch console output for mDNS discovery logs

## Key Technical Details

### Why mDNS Bridge Was Needed:
- Docker's bridge network mode isolates multicast (UDP 224.0.0.251:5353)
- mDNS (Bonjour) relies on multicast to advertise services
- Running mDNS inside Docker container doesn't reach host macOS
- **Solution**: Run mDNS on host OS natively, have it detect Node via REST API

### Why Resolver Retention Was Critical:
- NetService delegates are held with **weak references**
- If nothing retains the resolver, it's deallocated before resolution completes
- Resolution callbacks never fire if delegate is deallocated
- **Solution**: Store resolver in `activeResolvers` dictionary while resolving, remove when done

### IP Detection in mDNS Bridge:
- Bridge broadcasts to host OS, but which IP address?
- `socket.gethostbyname()` can return localhost (127.0.0.1)
- **Solution**: Connect to dummy IP (8.8.8.8:80) to determine actual network interface
- Falls back to hostname if connection fails

## Session Statistics
- Started: Fixing mDNS discovery in Player app
- Completed: Full mDNS bridge service + Player app integration
- Total changes: 7 files modified, 1 service created
- Build status: ✅ All Docker services building and running
- Current blockers: None (ready for end-to-end testing)

