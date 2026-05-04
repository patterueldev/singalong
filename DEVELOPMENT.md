# Singalong Development Guide

## Quick Start: Running All Services

**The ONLY way to run services in development:**

```bash
cd /Users/pat/Projects/PAT/singalong

# Start all services with hot-reload
docker-compose up -d --build

# Verify everything started
docker-compose ps

# View logs
docker-compose logs -f

# Stop everything
docker-compose down
```

**Services will be ready at:**
- Admin Dashboard: http://localhost:3001
- Node API: http://localhost:5002
- Controller: http://localhost:3002

---

## DO NOT:

❌ `poetry run uvicorn app.main:app --port 5001`
❌ `cd apps/singalong-admin && yarn dev`
❌ `MASTER_URL=http://localhost:5001 DEBUG=True poetry run...`

These bypass docker-compose and require manual environment setup that is already handled by docker-compose.yml.

---

## Common Tasks

### View Node Logs
```bash
docker-compose logs -f node
```

### View Admin Logs
```bash
docker-compose logs -f admin
```

### Restart a Service
```bash
docker-compose restart admin
docker-compose restart node
```

### Rebuild a Service (after dependency changes)
```bash
docker-compose up -d --build node
docker-compose up -d --build admin
```

### Access Node Bash Shell
```bash
docker-compose exec node bash
```

### Test API Health
```bash
curl http://localhost:5002/health
```

### Check Environment Variables in Container
```bash
docker-compose exec node env | grep -i debug
docker-compose exec admin env | grep -i vite
```

---

## Docker Compose Services

### Node (Backend)
- **Port**: 5002
- **Language**: Python (FastAPI)
- **Hot Reload**: Yes (volume mount `./apps/singalong-node:/app`)
- **Database**: SQLite at `/data/node/singalong_node.db`
- **Status Endpoint**: GET http://localhost:5002/health

### Admin (Frontend)
- **Port**: 3001
- **Language**: TypeScript (React/Vite)
- **Hot Reload**: Yes (volume mount `./apps/singalong-admin:/app`)
- **API URL**: http://localhost:5002 (from `.env` VITE_NODE_URL)

### Controller (Frontend)
- **Port**: 3002
- **Language**: TypeScript (React/Vite)
- **Hot Reload**: Yes (volume mount `./apps/singalong-controller:/app`)
- **API URL**: http://localhost:5002 (from `.env` VITE_NODE_URL)

### Master (Backend - COMMENTED OUT)
- **Status**: Disabled in docker-compose.yml (see line 9)
- **To Enable**: Uncomment lines 9-25 in docker-compose.yml
- **Port**: 5001
- **Note**: Node depends on Master, so both must be running if you uncomment it

---

## Environment Configuration

All configuration is in `.env` file. Key variables:

```
MASTER_PUBLIC_URL=https://singalong-master-development.nicenature.space
NODE_MASTER_API_KEY=dev-key-production-secret-1234567890
OPENAI_KEY=sk-proj-...
VITE_NODE_URL=https://singalong-dev.nicenature.space/node1
```

- **Debug Mode**: Set in docker-compose.yml `environment` section
- **Database**: Stored in `./data/` directory (volume mount)

---

## Troubleshooting

### Services Won't Start
```bash
# Check if ports are in use
lsof -i :5002  # Node
lsof -i :3001  # Admin
lsof -i :3002  # Controller

# If in use, kill the process or change port in docker-compose.yml
```

### Hot Reload Not Working
- Ensure volume mount is correct in docker-compose.yml
- Check that file changes are saved (not pending in editor)
- Restart container: `docker-compose restart admin`

### API Connection Errors
- Verify Node is running: `docker-compose ps node`
- Check Node health: `curl http://localhost:5002/health`
- Verify Admin environment variables: `docker-compose exec admin env | grep VITE_NODE_URL`

### Database Issues
- SQLite database at `./data/node/singalong_node.db`
- Delete database to reset: `rm ./data/node/singalong_node.db`
- Restart Node: `docker-compose restart node` (it will re-initialize)

---

## Development Workflow

### Adding a New Dependency (Backend)

1. Edit `apps/singalong-node/pyproject.toml`
2. Rebuild container: `docker-compose up -d --build node`
3. Dependencies automatically installed in container

### Adding a New Dependency (Frontend)

1. Edit `apps/singalong-admin/package.json`
2. Rebuild container: `docker-compose up -d --build admin`
3. Dependencies automatically installed in container

### Making Code Changes

1. Edit source files (no restart needed for hot-reload services)
2. Admin: Changes visible in browser within 2-3 seconds
3. Node: Changes visible immediately (FastAPI reload)
4. If changes don't appear: Restart container manually

---

## Testing

All testing is done through the running containers:

```bash
# Test Node endpoint
curl http://localhost:5002/health

# Test Admin page
curl http://localhost:3001

# View container logs
docker-compose logs -f node
```

---

## Production Consideration

This development setup with docker-compose is **not** the same as production. In production:
- Use actual authentication (Master GraphQL)
- Use real database (PostgreSQL, not SQLite)
- Don't expose DEBUG endpoints
- Use proper secrets management (not .env files)
