# Singalong Infrastructure Setup

This directory contains Docker Compose configurations for deploying Singalong across separate Master and Node VMs.

## Directory Structure

```
infrastructure/
├── development/          # Local development (all services in one compose)
├── local-release/       # Local release (separate Master and Node)
│   ├── master/          # Master service + PostgreSQL
│   └── node/            # Node service + PostgreSQL + optional frontends
├── production-release/  # Production release (GHCR images)
│   ├── master/          # Master service (GHCR image)
│   ├── node/            # Node service (GHCR image)
│   └── .env.example     # Environment template for production
└── release/             # Dockerfiles for building release images
    ├── master.dockerfile
    └── node.dockerfile
```

## Deployment Models

### 1. Local Release (local-release/)
**Use Case**: Testing separate VM deployment locally, CI/CD builds

**How it works**:
- Builds Docker images from local Dockerfiles
- Master and Node run as separate Docker services
- Each has their own PostgreSQL database
- Frontend services can be optionally deployed on Node VM

**Setup**:
```bash
# Start Master service
cd infrastructure/local-release/master
docker-compose up -d

# Start Node service (waits for Master to be healthy)
cd infrastructure/local-release/node
docker-compose up -d
```

**Key Features**:
- ✅ Builds from `infrastructure/release/{service}.dockerfile`
- ✅ PostgreSQL 16 Alpine for each service
- ✅ Network isolation with `singalong-network` bridge
- ✅ Health checks on startup
- ✅ Volume management for persistent data
- ✅ Automatic restart on failure
- ✅ Frontend services available (commented, uncomment to enable)

### 2. Production Release (production-release/)
**Use Case**: Production deployment with pre-built images from GHCR

**How it works**:
- Uses pre-built Docker images from GitHub Container Registry
- No local build needed
- Expects external PostgreSQL databases (for security)
- Optimized for production environments

**Setup**:
```bash
# Copy environment template
cp infrastructure/production-release/master/.env.example infrastructure/production-release/master/.env
# Edit .env with production values

# Start Master service
cd infrastructure/production-release/master
docker-compose up -d

# For Node
cp infrastructure/production-release/node/.env.example infrastructure/production-release/node/.env
# Edit .env with production values

cd infrastructure/production-release/node
docker-compose up -d
```

**Key Features**:
- ✅ Uses GHCR images: `ghcr.io/patterueldev/singalong-{master,node}:${IMAGE_TAG}`
- ✅ Expects external PostgreSQL (not Docker-managed)
- ✅ Environment variable driven configuration
- ✅ Flexible volume paths
- ✅ Frontend services available (commented)
- ✅ Structured logging with rotation

## VM Deployment Architecture

### Recommended Setup for Homeserver

**Master VM**:
```
┌─────────────────────────────┐
│      Master VM              │
├─────────────────────────────┤
│  singalong-master (5001)    │
│  PostgreSQL (5432)          │
│  Videos Volume              │
└─────────────────────────────┘
```

**Node VM** (can be same host or different):
```
┌─────────────────────────────┐
│       Node VM               │
├─────────────────────────────┤
│  singalong-node (5002)      │
│  PostgreSQL (5433)          │
│  Admin UI (3001)  [opt]     │
│  Controller UI (3002) [opt] │
│  Videos Volume              │
│  Data Volume                │
└─────────────────────────────┘
```

## Environment Variables

### Critical Variables (must match between Master and Node)

| Variable | Master | Node | Purpose |
|----------|--------|------|---------|
| `MASTER_API_KEY` | Set | NODE_MASTER_API_KEY | Node→Master authentication |
| `NODE_MASTER_API_KEY` | - | Set | Must match MASTER_API_KEY |
| `USER_JWT_SECRET` | Set | - | User token signing secret |
| `JWT_SECRET_KEY` | - | Set | JWT token signing (local users) |
| `MASTER_URL` | - | Set | Node must know Master location |

### Database Configuration

**Local Release** (Docker-managed):
```bash
# Master
DATABASE_URL=postgresql://master_user:master_password_dev@master-db:5432/singalong_master

# Node
DATABASE_URL=postgresql://node_user:node_password_dev@node-db:5432/singalong_node
```

**Production Release** (External PostgreSQL):
```bash
# Master
DATABASE_URL=postgresql://master_user:password@your-pg-host:5432/singalong_master

# Node
DATABASE_URL=postgresql://node_user:password@your-pg-host:5433/singalong_node
```

## Volume Management

### Master Volumes
```yaml
master-videos:       # Downloaded/stored videos
master-logs:         # Application logs
master-db-data:      # PostgreSQL data
```

### Node Volumes
```yaml
node-videos:         # Videos synced from Master
node-data:           # Local song database, caches
node-logs:           # Application logs
node-db-data:        # PostgreSQL data
```

## Networking

### Docker Network Bridge
- Network: `singalong-network`
- Subnet: `172.25.0.0/16`
- DNS: Services can communicate via hostname (e.g., `http://master:5001`)

### Between VMs
When Master and Node are on different VMs:
1. Update `MASTER_URL` in Node config to point to Master VM IP/hostname
2. Ensure firewalls allow traffic on required ports:
   - 5001 (Master API)
   - 5002 (Node API)
   - 5432/5433 (PostgreSQL)

## Deployment Steps

### Step 1: Prepare VMs
```bash
# On both Master and Node VMs
sudo apt update && sudo apt install -y docker.io docker-compose git
sudo usermod -aG docker $USER
```

### Step 2: Clone Repository
```bash
git clone https://github.com/patterueldev/singalong.git
cd singalong
```

### Step 3: Deploy Master VM
```bash
cd infrastructure/local-release/master  # or production-release/master
docker-compose up -d
docker-compose logs -f master
```

### Step 4: Deploy Node VM
Update `MASTER_URL` to point to Master VM's IP/hostname:
```bash
cd infrastructure/local-release/node  # or production-release/node
# Edit docker-compose.yml or .env with correct MASTER_URL
docker-compose up -d
docker-compose logs -f node
```

### Step 5: Verify Connectivity
```bash
# From Node VM, test Master connectivity
curl http://{MASTER_IP}:5001/health

# Check logs
docker-compose logs node | grep "Master"
```

## Quick Reference Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f {service-name}

# Stop services
docker-compose down

# Rebuild images (local-release only)
docker-compose up -d --build

# Check service status
docker-compose ps

# Execute command in container
docker-compose exec {service} bash

# View environment variables
docker-compose exec {service} env

# Inspect volumes
docker volume ls
docker volume inspect {volume-name}
```

## Troubleshooting

### Node can't reach Master
```bash
# Check network connectivity
docker-compose exec node ping master

# Check MASTER_URL environment variable
docker-compose exec node env | grep MASTER_URL

# Check Master service health
curl http://{MASTER_IP}:5001/health
```

### Database connection issues
```bash
# Check database is running
docker-compose ps | grep -E "db|postgres"

# Check database logs
docker-compose logs {service}-db

# Test database connection
docker-compose exec {service} psql -U user -d database -h db-host -c "SELECT 1"
```

### Image pull failures (production-release)
```bash
# Ensure you're logged into GHCR
docker login ghcr.io

# Check available images
docker images | grep singalong

# Try pulling manually
docker pull ghcr.io/patterueldev/singalong-master:latest
```

## Security Considerations

### Sensitive Data Protection
1. **Never commit `.env` files** - they contain secrets
2. **Use strong random values** for:
   - `MASTER_API_KEY`
   - `JWT_SECRET_KEY`
   - `USER_JWT_SECRET`
   - Database passwords
3. **Rotate secrets regularly** in production

### Network Security
1. Use TLS/HTTPS for Node↔Master communication (in production)
2. Restrict database access to application containers
3. Use firewall rules to limit port exposure
4. Run containers as non-root (already configured)

### Database Security
1. Use strong PostgreSQL passwords (not `dev` credentials)
2. Store databases on encrypted volumes
3. Regular backups of `{service}-db-data` volumes
4. Restrict database access to specific IPs if possible

## Next Steps

1. **Test locally** with `local-release/` setup
2. **Set up GHCR** for image storage (optional, for production)
3. **Prepare production PostgreSQL** instances
4. **Deploy to separate VMs** using `production-release/`
5. **Set up monitoring** for health checks and logs
6. **Configure backups** for database and video volumes

---

For more information, see:
- [Project Overview](../docs/PROJECT_OVERVIEW.md)
- [API Contract](../docs/API_CONTRACT_AUTHENTICATION.md)
- [Implementation Phases](../docs/IMPLEMENTATION_PHASES.md)
