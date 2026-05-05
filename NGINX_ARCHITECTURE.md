# Nginx Gateway Architecture

## Overview

Singalong uses a unified Nginx reverse proxy gateway to provide access to the Node group services (Node API, Admin, Controller) through a single entry point.

```
┌─────────────────────────────────────────────┐
│         Nginx Reverse Proxy                 │
│         (port 80)                           │
└──────────────────┬──────────────────────────┘
                   │
       ┌───────────┼───────────┐
       │           │           │
   /api/*      /admin/*   /controller/*
       │           │           │
       ▼           ▼           ▼
   Node API    Admin UI   Controller UI
   (5002)      (3001)     (3002)
```

## Access Paths

### API Endpoints
**Path:** `/api/*`  
**Backend:** singalong-node:5002  
**Use Case:** Node API, WebSocket connections  
**Example:** `http://localhost/api/health`, `http://localhost/api/songs`

### Admin Dashboard
**Path:** `/admin/*`  
**Backend:** singalong-admin:3001  
**Use Case:** Admin management interface  
**Example:** `http://localhost/admin`

### Controller (Future)
**Path:** `/controller/*`  
**Backend:** singalong-controller:3002  
**Use Case:** User-facing karaoke interface  
**Example:** `http://localhost/controller`

### Root
**Path:** `/`  
**Behavior:** Redirect to `/admin`

## Network Architecture

### Docker Compose Setup
All services are on the same `singalong-network`:
- Services communicate internally (no port exposure)
- Only Nginx listens on port 80 (external)
- Nginx proxies requests to internal services

### Service Ports (Internal Only)
- Nginx: 80
- Node: 5002 (internal only, accessed via `/api`)
- Admin: 3001 (internal only, accessed via `/admin`)
- Controller: 3002 (internal only, accessed via `/controller`)

## Frontend Configuration

### API Base URL
Frontends use **relative paths** to access the API through Nginx:

```typescript
// apps/singalong-admin/.env / apps/singalong-controller/.env
VITE_API_BASE_URL=/api
```

This means:
- All API calls are made to `/api/*` (relative to current origin)
- Works identically whether accessing via `localhost`, `thursday.local`, or `singalong.nicenature.space`
- No CORS issues (same origin for frontend and API)

## LAN Access

### Prerequisites
1. Local DNS must resolve `thursday.local` to your macOS IP:
   ```bash
   # Check your macOS IP
   ifconfig | grep "inet " | grep -v 127
   
   # Add to /etc/hosts (optional - better: use Bonjour/mDNS)
   192.168.x.x   thursday.local
   ```

2. Or use mDNS discovery (automatic):
   ```bash
   # Verify thursday.local resolves
   ping thursday.local
   ```

### Access Admin on LAN
```
http://thursday.local/admin
```

When you access this:
1. Nginx receives the request on port 80
2. Routes to Admin service internally (3001)
3. Admin loads and makes API calls to `/api`
4. Nginx routes `/api` calls to Node (5002)

## Remote Access

### Prerequisites
Cloudflare tunnel configured to route to Nginx on port 80

### Access Admin Remotely
```
https://singalong.nicenature.space/admin
```

When you access this:
1. Cloudflare tunnel routes to Nginx on port 80
2. Everything else is identical to LAN access
3. Same URLs, same behavior, no frontend changes needed

## Routing Details

### Nginx Configuration
See `infrastructure/development/nginx.conf` for:
- Upstream service definitions
- Location blocks with proxy settings
- WebSocket upgrade headers (for real-time features)
- Security headers
- Gzip compression

### Key Headers Passed to Backends
- `Host` — Original request hostname
- `X-Real-IP` — Client's real IP
- `X-Forwarded-For` — Proxy chain
- `X-Forwarded-Proto` — Original protocol (http/https)
- `Upgrade` / `Connection` — For WebSocket

## Health Checks

Nginx has a built-in health check that calls `/api/health`:
```bash
# Check Nginx health
docker-compose ps singalong-nginx
```

If health check fails (service unhealthy), Nginx container exits with status indicator.

## Development vs Production

### Development (Current)
- Nginx on localhost:80
- Access: `localhost/admin`, `localhost/api`
- Services on bridge network (internal)

### Production (Future)
- Nginx behind Cloudflare tunnel
- Access: `singalong.nicenature.space/admin`
- Possible upgrades:
  - SSL/TLS certificates
  - Rate limiting
  - Authentication at Nginx layer
  - Load balancing

## Troubleshooting

### Nginx won't start
```bash
# Check Nginx logs
docker-compose logs nginx

# Verify config
docker run --rm -v $(pwd)/infrastructure/development/nginx.conf:/etc/nginx/conf.d/default.conf:ro nginx:1.25-alpine nginx -t
```

### Services unreachable through Nginx
```bash
# Check if services are running
docker-compose ps

# Check Nginx can see services
docker-compose exec nginx nslookup singalong-node
docker-compose exec nginx nslookup singalong-admin
```

### CORS errors in frontend
- Frontend should use relative paths (`/api`)
- Avoid hardcoded absolute URLs
- Verify `VITE_API_BASE_URL=/api` in .env

### WebSocket connections failing
- Check Nginx has `Upgrade` and `Connection` headers (configured)
- Verify WebSocket endpoint is under `/api/` path
- Check Node WebSocket is actually listening

## Future: Controller Integration

When adding Controller:
1. Controller already routed to `/controller/*` in Nginx config
2. Update Controller's `VITE_API_BASE_URL=/api`
3. No Nginx changes needed
4. Uncomment Controller in docker-compose.yml (if commented)
5. Test access at `http://localhost/controller`

## References

- Nginx Documentation: http://nginx.org/
- Docker Compose Networking: https://docs.docker.com/compose/networking/
- Reverse Proxy Patterns: https://en.wikipedia.org/wiki/Reverse_proxy
