# mDNS Bridge: Platform Constraints and Architecture Decision

## Problem Statement

Singalong requires mDNS service discovery to allow controllers and players to discover the Node service on a local network (LAN). Initial implementation attempted to run the mDNS bridge in Docker Compose using `network_mode: host`, which is a common pattern for mDNS services.

**The fundamental issue:** `network_mode: host` does NOT work consistently across all platforms.

## Technical Root Cause

### Docker Desktop on macOS (using Lima)
- Docker Desktop on macOS runs a Linux VM (Lima) for the Docker daemon
- `network_mode: host` in this context means "host of the Linux VM", NOT "host of macOS"
- The Linux VM has an isolated network (10.0.2.0/24) separate from the actual macOS network
- Even with `network_mode: host`, the bridge advertises on the VM's isolated IP (10.0.2.100), not the actual macOS LAN IP (192.168.x.x)
- External devices on the actual LAN cannot reach services advertised on the VM's isolated network
- **Result: mDNS advertisements are invisible to Linux servers on the actual LAN**

### Native Docker on Linux (no VM)
- Docker daemon runs directly on the host OS
- `network_mode: host` directly accesses the host's network interfaces
- mDNS advertisements are visible on the actual LAN
- **Result: Works as expected**

### Windows Docker Desktop (WSL 2)
- Similar to macOS: Docker runs in a virtualized environment
- Behavior likely similar to macOS (not tested)

## Documentation Reference

From Docker documentation and community:
> "Linux Only: This mode natively shares the host's network stack on Linux. On Docker Desktop for Mac or Windows, it typically does not work as expected because Docker runs inside a virtual machine; the container shares the VM's network, not your actual Mac/Windows machine's network."

## Architectural Decision

**Chosen Solution: Platform-Specific mDNS Deployment**

1. **macOS Development/Deployment:**
   - Run mDNS bridge **natively** on macOS (not in Docker)
   - Entry point: `cd apps/singalong-mdns-bridge && bash run.sh`
   - Advertises on actual macOS network interface (e.g., en0 at 192.168.x.x)
   - Visible to all devices on the LAN

2. **Linux Deployment (future):**
   - Run mDNS bridge in Docker using `network_mode: host`
   - Can use the same Docker image already built
   - Will work correctly on native Linux systems
   - Advertises on Linux's actual network interfaces

3. **Other Services (all platforms):**
   - Node, Admin, Controller remain in Docker Compose
   - Use bridge network (standard Docker networking)
   - mDNS bridge connects them to the actual LAN

**Rationale:**
- Maximizes compatibility across platforms
- Leverages each platform's strengths
- No complex networking workarounds needed
- Clear separation of concerns (bridge = LAN discovery, services = internal routing)

## Current Implementation

### Files
- `apps/singalong-mdns-bridge/app.py` — Pure Python zeroconf implementation (OS-agnostic)
- `apps/singalong-mdns-bridge/run.sh` — Startup script for native execution
- `infrastructure/development/mdns-bridge.dockerfile` — Docker image (for Linux deployment)
- `docker-compose.yml` — mdns-bridge service (currently uses `network_mode: host`, disabled on macOS)

### Running on macOS (Development)
```bash
# Terminal 1: Start mDNS bridge natively
cd apps/singalong-mdns-bridge
bash run.sh

# Terminal 2: Start other services in Docker
docker-compose up -d node admin controller
```

### Running on Linux (Future)
```bash
# Single command - bridge runs in Docker with native network access
docker-compose up -d
```

## Known Limitations

1. **macOS requires manual startup:** The mDNS bridge must be started separately from Docker Compose. This is acceptable for development but should be documented in setup guides.

2. **Service detection latency:** When bridge starts, it may take 1-2 seconds to advertise. Controller/Player should have retry logic.

3. **Bridge process lifecycle:** If bridge crashes, services on Docker network still run but mDNS discovery fails. Monitoring/restart logic recommended for production.

## Testing Results

**macOS (Docker Desktop with Lima):**
- Docker-based bridge: ✗ Not visible to Linux avahi-browse
- Native bridge: ✓ Visible to Linux avahi-browse and macOS dns-sd
- IP advertised (native): 192.168.254.119 (actual macOS IP)
- IP advertised (Docker): 10.0.2.100 (Lima isolated network)

**Linux (native Docker):**
- Expected: ✓ Would work with `network_mode: host`
- Not tested due to mDNS constraints

## Future Work

1. **Platform detection:** Detect OS in docker-compose and conditionally include bridge service
2. **Unified deployment:** Create wrapper script that handles platform differences
3. **Monitoring:** Add health checks and monitoring for bridge availability
4. **Documentation:** Add to setup guides with platform-specific instructions

## References

- Docker Networking: https://docs.docker.com/network/host/
- Zeroconf/mDNS: https://en.wikipedia.org/wiki/Zero-configuration_networking
- macOS DNS Service Discovery: `man dns-sd`
- Linux Avahi: https://www.avahi.org/

---

**Decision Date:** 2026-05-05  
**Status:** LOCKED IN - Implementation complete on macOS, ready for Linux testing
