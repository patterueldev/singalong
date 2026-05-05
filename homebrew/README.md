# Homebrew Tap for Singalong

Official Homebrew formulas for Singalong services.

## Installation

### Add the tap
```bash
brew tap patterueldev/singalong https://github.com/patterueldev/singalong.git
```

### Install mdns-bridge
```bash
brew install singalong-mdns-bridge
```

### Start as a service
```bash
# Start immediately
brew services start singalong-mdns-bridge

# View logs
tail -f $(brew --prefix)/var/log/singalong-mdns-bridge.log

# Stop service
brew services stop singalong-mdns-bridge

# Restart service
brew services restart singalong-mdns-bridge
```

## Configuration

Environment variables can be set in:
```bash
/usr/local/etc/singalong/mdns-bridge.env
```

Or passed to Homebrew services:
```bash
# Edit the LaunchDaemon plist
nano ~/Library/LaunchAgents/homebrew.mxcl.singalong-mdns-bridge.plist
```

## Development

For local development, use the shell script directly:
```bash
cd apps/singalong-mdns-bridge
bash run.sh
```

## Uninstall

```bash
# Stop the service first
brew services stop singalong-mdns-bridge

# Uninstall
brew uninstall singalong-mdns-bridge

# Remove tap (optional)
brew untap patterueldev/singalong
```

## Troubleshooting

**Service won't start:**
```bash
# Check Homebrew services status
brew services list

# View detailed logs
log stream --predicate 'eventMessage contains[cd] "singalong"'

# Check LaunchDaemon status
launchctl list | grep singalong
```

**Node health check failing:**
Make sure Node service is running on `http://localhost:5002` and responding to `/health` endpoint before starting the bridge.

**Port already in use:**
The bridge uses port 5353 for mDNS. Verify it's not already bound:
```bash
lsof -i :5353
```
