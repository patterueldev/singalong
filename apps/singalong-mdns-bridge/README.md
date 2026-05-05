# mDNS Bridge for Singalong Node

Simple mDNS service advertisement bridge that runs on the Docker host network and advertises the Singalong Node service via mDNS.

## Why?

When the Node service runs in a Docker bridge network container, it cannot broadcast mDNS to the host machine due to multicast isolation. This bridge application runs with `host` network mode, allowing it to broadcast mDNS that is discoverable from the macOS host.

## Usage

### Docker Compose

```yaml
mdns-bridge:
  build:
    context: .
    dockerfile: infrastructure/development/mdns-bridge.dockerfile
  container_name: singalong-mdns-bridge
  network_mode: host
  environment:
    - NODE_HOST=singalong-node  # Docker hostname or IP
    - NODE_PORT=5002
    - MDNS_SERVICE_NAME=Singalong Node
    - MDNS_SERVICE_TYPE=_singalong-node._tcp
```

## Environment Variables

- `NODE_HOST`: Hostname or IP of Node service (default: localhost)
- `NODE_PORT`: Port of Node service (default: 5002)
- `MDNS_SERVICE_NAME`: mDNS service display name (default: Singalong Node)
- `MDNS_SERVICE_TYPE`: mDNS service type (default: _singalong-node._tcp)

## Testing

From macOS:
```bash
dns-sd -B _singalong-node._tcp local.
```
