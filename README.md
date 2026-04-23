# Singalong - Distributed Karaoke Management System

## Project Overview

**Singalong** is a modern, distributed karaoke management system that enables local karaoke nodes to communicate with a central master server. The system provides administrators with song management capabilities through a web-based interface, and features a controller application for users to explore and reserve songs in real-time.

Built with a microservices architecture, Singalong separates concerns across backend and frontend services, each deployable and scalable independently while maintaining seamless communication through REST APIs.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      SINGALONG SYSTEM                        │
└─────────────────────────────────────────────────────────────┘

                      SINGALONG-MASTER
                   (Python/FastAPI - Port 5001)
              Central Repository & Data Management
                            │
                            │ (Video files, metadata)
                            ▼
                      SINGALONG-NODE
                   (Python/FastAPI - Port 5002)
              Local Karaoke Server & Coordinator
                        ┌───┴───┐
                        │       │
                        ▼       ▼
        SINGALONG-ADMIN      SINGALONG-CONTROLLER
      (React/TypeScript)    (React/TypeScript)
        Port 3001             Port 3002
    Admin Management UI    User Interaction UI
```

---

## Service Relationships & Data Flow

### Communication Hierarchy

**singalong-master** (Root Service)
- Central authority for all karaoke video data and metadata
- Stores and serves complete song library
- Acts as source of truth for system data

**singalong-node** (Bridge Service)
- Communicates with master to fetch/sync karaoke files
- Acts as local gateway for frontend applications
- Manages local caching and coordination
- Provides API for admin and controller services

**singalong-admin** (Admin Interface)
- Web UI for system administrators
- Communicates exclusively with local node
- Manages node configuration and operations
- Explores and reserves songs from node

**singalong-controller** (User Interface)
- Web UI for end users
- Communicates exclusively with local node
- Allows song exploration and reservation
- Provides user-friendly karaoke experience

### Data Flow Pattern

```
User/Admin → [Admin/Controller UI] → [Node API] → [Master API]
                                        ↓
                              Local Cache & Processing
```

---

## Technology Stack

| Layer | Technology | Details |
|-------|-----------|---------|
| **Backend** | FastAPI | Modern, async-first Python web framework |
| | Python | 3.10+ (Poetry managed dependencies) |
| **Frontend** | React | 19.x with TypeScript for type safety |
| | TypeScript | ~6.0 for frontend applications |
| | Vite | Fast build tool and dev server |
| | React Router | Navigation and routing |
| | Axios | HTTP client for API communication |
| **Package Managers** | Poetry | Python dependency management |
| | Yarn | Node.js dependency management |
| **Containerization** | Docker | Service containerization |
| | Docker Compose | Multi-service orchestration |
| **Development Tools** | ESLint | JavaScript/TypeScript linting |
| | Black/Ruff | Python code formatting and linting |
| | pytest | Python testing framework |

---

## Local Development Setup

### Prerequisites

- **Docker & Docker Compose**: Required for running all services together
- **Python 3.10+**: For running backend services locally (optional if using Docker)
- **Node.js 18+**: For running frontend services locally (optional if using Docker)
- **Git**: For cloning the repository

### Quick Start with Docker Compose

```bash
# 1. Clone the repository
git clone https://github.com/patterueldev/singalong.git
cd singalong

# 2. Verify Docker and Docker Compose are installed
docker --version
docker-compose --version

# 3. Start all services
docker-compose up

# 4. Access the services
# - Admin Interface: http://localhost:3001
# - Controller Interface: http://localhost:3002
# - Node API: http://localhost:5002
# - Master API: http://localhost:5001
```

### Local Development (Individual Services)

**Backend Services (Python/FastAPI)**

```bash
# Install Python dependencies
cd apps/singalong-master  # or singalong-node
poetry install

# Run the service
poetry run python -m uvicorn app.main:app --host 0.0.0.0 --port 5001 --reload
```

**Frontend Services (React/Vite)**

```bash
# Install Node dependencies
cd apps/singalong-admin  # or singalong-controller
yarn install

# Run development server
yarn dev
# Runs on port 3001 (admin) or 3002 (controller) with hot reload
```

---

## Service Details

| Service | Type | Port | Technology | Purpose |
|---------|------|------|-----------|---------|
| **singalong-master** | Backend | 5001 | FastAPI, Python | Central server storing video files and metadata |
| **singalong-node** | Backend | 5002 | FastAPI, Python | Local server coordinating with master and clients |
| **singalong-admin** | Frontend | 3001 | React, TypeScript, Vite | Administrative interface for system management |
| **singalong-controller** | Frontend | 3002 | React, TypeScript, Vite | User interface for song exploration and reservation |

---

## Environment Variables

### singalong-master

```bash
DEBUG=False              # Enable debug mode
PORT=5001              # Server port
HOST=0.0.0.0           # Server host binding
APP_NAME=singalong-master  # Application name
```

### singalong-node

```bash
DEBUG=False            # Enable debug mode
PORT=5002             # Server port
MASTER_URL=http://singalong-master:5001  # Master server URL
SERVICE_NAME=singalong-node    # Service identifier
```

### singalong-admin

```bash
VITE_API_BASE_URL=http://localhost:5002  # Node API endpoint
```

### singalong-controller

```bash
VITE_API_BASE_URL=http://localhost:5002  # Node API endpoint
```

---

## How to Run

### Docker Compose (All Services Together)

```bash
# Build and start all services
docker-compose up

# Run in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Individual Services

**Master Service**
```bash
cd apps/singalong-master
poetry install
poetry run uvicorn app.main:app --host 0.0.0.0 --port 5001 --reload
```

**Node Service**
```bash
cd apps/singalong-node
poetry install
poetry run uvicorn app.main:app --host 0.0.0.0 --port 5002 --reload
```

**Admin Frontend**
```bash
cd apps/singalong-admin
yarn install
yarn dev  # http://localhost:3001
```

**Controller Frontend**
```bash
cd apps/singalong-controller
yarn install
yarn dev  # http://localhost:3002
```

---

## Project Structure

```
singalong/
├── apps/
│   ├── singalong-master/           # Central server
│   │   ├── app/                    # Application code
│   │   ├── pyproject.toml          # Poetry configuration
│   │   ├── README.md
│   │   └── run.sh
│   ├── singalong-node/             # Local server
│   │   ├── app/                    # Application code
│   │   ├── pyproject.toml          # Poetry configuration
│   │   ├── README.md
│   │   └── run.sh
│   ├── singalong-admin/            # Admin UI
│   │   ├── src/                    # React components
│   │   ├── package.json            # Yarn configuration
│   │   ├── vite.config.ts          # Vite configuration
│   │   └── README.md
│   └── singalong-controller/       # Controller UI
│       ├── src/                    # React components
│       ├── package.json            # Yarn configuration
│       ├── vite.config.ts          # Vite configuration
│       └── README.md
├── infrastructure/                 # Infrastructure configs
├── docker-compose.yml              # Multi-service orchestration
└── README.md                       # This file
```

---

## Contributing Guidelines

### Code Style

- **Python**: Follow PEP 8 using Black (line length: 100) and Ruff for linting
- **TypeScript/React**: Use ESLint configuration provided in each frontend service
- All code should pass type checking (`tsc --noEmit` for TypeScript)

### Development Workflow

1. **Create a feature branch** from `main`
2. **Make your changes** following the code style guidelines
3. **Run tests and linting**:
   ```bash
   # Backend
   poetry run pytest
   poetry run black --check .
   poetry run ruff check .
   
   # Frontend
   yarn lint
   yarn type-check
   ```
4. **Commit with clear messages** describing your changes
5. **Open a pull request** with details about your changes

### Adding New Features

- **New Backend Endpoint**: Add to `app/api/` directory with proper routing and validation
- **New Frontend Page**: Create in `src/pages/` with associated components
- **New Dependencies**: Use `poetry add` (Python) or `yarn add` (Node.js)
- **Documentation**: Update relevant READMEs and AGENTS.md if architectural changes are made

### Testing

- Backend: Write tests in `app/tests/` using pytest
- Frontend: Use appropriate testing libraries as configured in each service
- All tests should pass before submitting a PR

---

## API Documentation

Each service provides API documentation via Swagger UI:

- **Master API**: http://localhost:5001/docs
- **Node API**: http://localhost:5002/docs

---

## Troubleshooting

### Services won't start
- Check port availability (5001, 5002, 3001, 3002)
- Verify Docker daemon is running
- Check environment variables are correctly set

### Cannot connect to Master from Node
- Verify `MASTER_URL` is correctly configured
- Check network connectivity in Docker Compose
- Ensure master service is running before node

### Frontend cannot reach API
- Verify `VITE_API_BASE_URL` points to the correct Node service
- Check CORS configuration in Node service
- Verify Node service is running

---

## License

[Add your project license here]

## Contact & Support

For questions or issues, please contact the Singalong Team or open an issue on GitHub.
