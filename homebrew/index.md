# Singalong Homebrew Tap

Homebrew formulas for Singalong services.

## Quick Start

```bash
# Install
brew tap patterueldev/singalong
brew install singalong-mdns-bridge

# Start service
brew services start singalong-mdns-bridge

# Check status
brew services list
```

## Formulas

### singalong-mdns-bridge
mDNS service discovery bridge for Singalong Node on macOS.

- Advertises Node service on local network
- Automatically checks Node health before advertising
- Runs as macOS LaunchDaemon service
- Starts on boot, auto-restarts if crashes

**Requirements:**
- macOS 10.13+
- Homebrew
- Python 3.10+
- Node service running on `http://localhost:5002`

**Installation:**
```bash
brew install singalong-mdns-bridge
```

**Service Control:**
```bash
brew services start singalong-mdns-bridge
brew services stop singalong-mdns-bridge
brew services restart singalong-mdns-bridge
```

**Logs:**
```bash
tail -f /usr/local/var/log/singalong-mdns-bridge.log
```

## Development

For local development without Homebrew:
```bash
cd apps/singalong-mdns-bridge
poetry install
bash run.sh
```

See [homebrew/README.md](homebrew/README.md) for detailed setup instructions.
