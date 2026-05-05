# mDNS Bridge for Singalong Node

Pure Python mDNS service advertisement for the Singalong Node service.

## Architecture Decision

**This bridge runs on the HOST MACHINE (macOS), NOT in Docker.**

### Why Not Docker?

Docker on macOS uses Lima (Linux VM) which has an isolated network (10.0.2.0/24). Even with `network_mode: host`, the bridge broadcasts on Lima's network, not your real LAN. Linux servers on your actual LAN (192.168.x.x) cannot reach Lima's internal network.

**Solution:** Run the bridge directly on macOS host → broadcasts to 192.168.254.119 → discoverable by all LAN devices.

## Usage

### Start the Bridge

```bash
cd apps/singalong-mdns-bridge
poetry install
bash run.sh
```

This starts the bridge as a foreground process. Leave it running while you're developing.

### Start in Background

```bash
cd apps/singalong-mdns-bridge
poetry run python app.py > bridge.log 2>&1 &
```

### Environment Variables

- `NODE_HOST`: Node service hostname/IP (default: localhost)
- `NODE_PORT`: Node service port (default: 5002)
- `MDNS_SERVICE_NAME`: Service display name (default: Singalong Node)
- `MDNS_SERVICE_TYPE`: Service type (default: _singalong-node._tcp)

## Testing Discovery

### macOS
```bash
dns-sd -B _singalong-node._tcp local.
# Expected: Singalong Node appears in list
```

### Linux
```bash
avahi-browse -r _singalong-node._tcp
# Expected: Service details show 192.168.254.119:5002
```

## How It Works

1. **Startup:** Resolves NODE_HOST to IP, initializes Zeroconf
2. **Broadcasting:** Registers mDNS service on actual network interfaces
3. **Discovery:** Appears in `dns-sd` and `avahi-browse` searches
4. **Shutdown:** Gracefully unregisters service (clean Rmv event)

## Dependencies

- `zeroconf`: Pure Python mDNS library (supports macOS, Linux, Windows)
- `python-dotenv`: Configuration loading
- Python 3.10+

