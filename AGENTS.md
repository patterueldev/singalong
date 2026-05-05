# Singalong Agents Documentation

This document provides comprehensive guidance for AI agents and developers working on the Singalong codebase. It covers the architecture, service details, communication patterns, and development practices.

> **📚 Related Documentation**:
> - **[PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)**: Project vision, user stories, system architecture, and detailed workflows
> - **[IMPLEMENTATION_PHASES.md](docs/IMPLEMENTATION_PHASES.md)**: 10 implementation phases with dependencies, deliverables, and acceptance criteria
> - **[BACKEND_PHASES.md](docs/BACKEND_PHASES.md)**: Backend API development phases (B1-B8) with detailed endpoint specifications and database schemas
> - **[API_CONTRACT_AUTHENTICATION.md](docs/API_CONTRACT_AUTHENTICATION.md)**: Authentication contract between services (Node ↔ Master), JWT tokens, API key exchange
> - **[WEBSOCKET_EVENTS.md](docs/WEBSOCKET_EVENTS.md)**: Real-time WebSocket events, Master broadcasting, Node listening, event handlers
> - **[ADMIN_UI_SPECIFICATION.md](docs/ADMIN_UI_SPECIFICATION.md)**: Admin session UI layout, 4-panel design, and component specs
> 
> **👷 Per-App Documentation**:
> - **[singalong-master/AGENTS.md](apps/singalong-master/AGENTS.md)**: Backend service - data source, downloads, storage
> - **[singalong-node/AGENTS.md](apps/singalong-node/AGENTS.md)**: Backend service - gateway, middleware, search
> - **[singalong-admin/AGENTS.md](apps/singalong-admin/AGENTS.md)**: Frontend - admin dashboard and session management
> - **[singalong-controller/AGENTS.md](apps/singalong-controller/AGENTS.md)**: Frontend - user-facing karaoke interface

---

## 1. Codebase Structure Overview

Singalong is a **monorepo** containing four independent but interconnected services within the `apps/` directory:

```
singalong/
├── apps/
│   ├── singalong-master/        [Backend] Central data repository
│   ├── singalong-node/          [Backend] Local coordination server
│   ├── singalong-admin/         [Frontend] Admin management interface
│   └── singalong-controller/    [Frontend] User interaction interface
├── infrastructure/              [Configuration & deployment]
├── docker-compose.yml           [Local development orchestration]
└── [config files]
```

Each service is independently deployable but designed to work together as a cohesive system. Services communicate via REST APIs using JSON payloads.

---

## 2. Service Inventory

### Service 1: singalong-master

**Type**: Backend Service  
**Role**: Central repository storing all karaoke video files and metadata; the authoritative source of truth.

**Technology Stack**:
- **Framework**: FastAPI 0.104.1+
- **Language**: Python 3.10+
- **Async Runtime**: Uvicorn 0.24.0+
- **Data Validation**: Pydantic 2.5.0+
- **Configuration**: Pydantic Settings, python-dotenv
- **Package Manager**: Poetry

**Port**: 5001 (default)

**Key Files**:
- `app/main.py` - FastAPI application entry point and initialization
- `app/config.py` - Settings management and environment configuration
- `pyproject.toml` - Poetry configuration with dependencies
- `run.sh` - Service startup script
- `.env.example` - Environment variable template

**Key Directories**:
- `app/` - Main application code
  - `api/` - Route handlers for endpoints
  - `models/` - Pydantic models and data structures
  - `services/` - Business logic and service layer
  - `config.py` - Settings and configuration

**Environment Variables**:
- `DEBUG` - Enable debug mode (default: False)
- `PORT` - Server port binding (default: 5001)
- `HOST` - Server host binding (default: 0.0.0.0)
- `APP_NAME` - Application identifier (default: singalong-master)

**Startup Command**:
```bash
cd apps/singalong-master
poetry install
poetry run uvicorn app.main:app --host 0.0.0.0 --port 5001 --reload
```

**API Documentation**: http://localhost:5001/docs (Swagger UI)

---

### Service 2: singalong-node

**Type**: Backend Service  
**Role**: Local karaoke server that communicates with master, coordinates frontend applications, and provides the primary API gateway.

**Technology Stack**:
- **Framework**: FastAPI 0.136.0+
- **Language**: Python 3.10+
- **Async Runtime**: Uvicorn 0.45.0+
- **HTTP Client**: httpx 0.28.1+ (for master communication)
- **Data Validation**: Pydantic 2.13.3+
- **Configuration**: Pydantic Settings, python-dotenv
- **Package Manager**: Poetry

**Port**: 5002 (default)

**Key Files**:
- `app/main.py` - FastAPI application entry point
- `app/config.py` - Settings and configuration management
- `pyproject.toml` - Poetry configuration with dependencies
- `run.sh` - Service startup script
- `.env` - Environment configuration
- `.env.example` - Environment variable template

**Key Directories**:
- `app/` - Main application code
  - `api/` - Route handlers for endpoints
  - `models/` - Pydantic models and data structures
  - `services/` - Business logic for master communication and caching
  - `config.py` - Settings and configuration

**Environment Variables**:
- `DEBUG` - Enable debug mode (default: False)
- `PORT` - Server port binding (default: 5002)
- `MASTER_URL` - URL to master service (default: http://singalong-master:5001)
- `SERVICE_NAME` - Service identifier (default: singalong-node)

**Startup Command**:
```bash
cd apps/singalong-node
poetry install
poetry run uvicorn app.main:app --host 0.0.0.0 --port 5002 --reload
```

**API Documentation**: http://localhost:5002/docs (Swagger UI)

**Health Endpoint**: GET `/health` - Returns service status and master URL

---

### Service 3: singalong-admin

**Type**: Frontend Service (Web UI)  
**Role**: Administrative interface for managing the singalong system, configuring nodes, and managing song inventory.

**Technology Stack**:
- **Framework**: React 19.2.5+
- **Language**: TypeScript ~6.0.2
- **Build Tool**: Vite 8.0.9+
- **Routing**: React Router DOM 6.24.0+
- **HTTP Client**: Axios 1.7.2+
- **Linting**: ESLint 9.39.4+
- **Package Manager**: Yarn

**Port**: 3001 (default)

**Key Files**:
- `src/main.tsx` - React entry point
- `src/App.tsx` - Main application component
- `vite.config.ts` - Vite build configuration
- `tsconfig.json` - TypeScript configuration
- `package.json` - Yarn dependencies and scripts
- `eslint.config.js` - Linting rules
- `index.html` - HTML entry template

**Key Directories**:
- `src/` - Source code
  - `pages/` - Page components (routes)
  - `components/` - Reusable React components
  - `hooks/` - Custom React hooks
  - `services/` - API client functions
  - `App.tsx` - Root application component

**Environment Variables**:
- `VITE_API_BASE_URL` - Base URL for Node API (default: http://localhost:5002)

**Startup Command**:
```bash
cd apps/singalong-admin
yarn install
yarn dev
```

**Available Scripts**:
- `yarn dev` - Start development server (port 3001)
- `yarn build` - Build for production
- `yarn lint` - Run ESLint
- `yarn type-check` - Run TypeScript type checking
- `yarn preview` - Preview production build

**Development Server**: http://localhost:3001

---

### Service 4: singalong-controller

**Type**: Frontend Service (Web UI)  
**Role**: User-facing interface for exploring songs, making reservations, and interacting with the karaoke system.

**Technology Stack**:
- **Framework**: React 19.2.5+
- **Language**: TypeScript ~6.0.2
- **Build Tool**: Vite 8.0.9+
- **Routing**: React Router DOM 7.0.0+
- **HTTP Client**: Axios 1.7.0+
- **Linting**: ESLint 9.39.4+
- **Package Manager**: Yarn

**Port**: 3002 (default, auto-assigned by Vite if 3000 unavailable)

**Key Files**:
- `src/main.tsx` - React entry point
- `src/App.tsx` - Main application component
- `vite.config.ts` - Vite build configuration
- `tsconfig.json` - TypeScript configuration
- `package.json` - Yarn dependencies and scripts
- `eslint.config.js` - Linting rules
- `index.html` - HTML entry template

**Key Directories**:
- `src/` - Source code
  - `pages/` - Page components (routes)
  - `components/` - Reusable React components
  - `hooks/` - Custom React hooks
  - `services/` - API client functions
  - `App.tsx` - Root application component

**Environment Variables**:
- `VITE_API_BASE_URL` - Base URL for Node API (default: http://localhost:5002)

**Startup Command**:
```bash
cd apps/singalong-controller
yarn install
yarn dev
```

**Available Scripts**:
- `yarn dev` - Start development server (port 3002)
- `yarn build` - Build for production
- `yarn lint` - Run ESLint
- `yarn type-check` - Run TypeScript type checking
- `yarn preview` - Preview production build

**Development Server**: http://localhost:3002 (or next available port)

---

## 3. Service Dependencies Graph

```
┌──────────────────────────────────────┐
│     singalong-master                 │
│  (Central Repository, Source of Truth)
└────────────────────┬─────────────────┘
                     │ (REST API)
                     │ Provides: Videos, Metadata
                     │
         ┌───────────▼────────────┐
         │  singalong-node        │
         │  (Local Gateway)       │
         └───────────┬────────────┘
                     │ (REST API)
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼
    ┌──────────────┐      ┌───────────────┐
    │ singalong-   │      │ singalong-    │
    │   admin      │      │  controller   │
    │ (Admin UI)   │      │  (User UI)    │
    └──────────────┘      └───────────────┘
```

**Dependency Rules**:
1. **singalong-node** depends on **singalong-master** (requires master to be running)
2. **singalong-admin** depends on **singalong-node** (requires node to be running)
3. **singalong-controller** depends on **singalong-node** (requires node to be running)
4. **singalong-master** has no dependencies (can run standalone)

**Startup Order**:
1. Start singalong-master first
2. Start singalong-node second
3. Start singalong-admin and singalong-controller in any order

---

## 4. Communication Patterns

### Admin ↔ Node

**Flow**: Admin UI → Node API → Master (for data)

**Typical Operations**:
- Retrieve node status and health information
- Explore available songs/videos in the system
- Reserve songs for karaoke
- Manage node configuration
- Retrieve admin-specific data

**API Endpoint Pattern**: `GET|POST /api/admin/*`

**Expected Response Format**: JSON with status, data, and metadata

### Controller ↔ Node

**Flow**: Controller UI → Node API → Master (for data)

**Typical Operations**:
- Browse available songs
- Search/filter songs by artist, title, genre
- Make song reservations
- View user's reservations
- Get song suggestions

**API Endpoint Pattern**: `GET|POST /api/controller/*`

**Expected Response Format**: JSON with song data, reservations, status

### Node ↔ Master

**Flow**: Node (client) → Master API (server)

**Typical Operations**:
- Authenticate node to master
- Sync song catalog
- Fetch video files
- Store/retrieve metadata
- Report node status

**Master API Endpoints (examples)**:
- `GET /health` - Master service health
- `GET /api/videos` - List all videos
- `GET /api/videos/{id}` - Get specific video
- `POST /api/sync` - Sync node state with master

**Data Format**: JSON with authentication headers

**Error Handling**: All services return standard error responses:
```json
{
  "status": "error",
  "code": "SERVICE_ERROR",
  "message": "Human-readable error message",
  "details": {}
}
```

---

## 5. Common Development Tasks

### Run a Single Service Locally

**Backend Service**:
```bash
cd apps/singalong-master  # or singalong-node
poetry install
poetry run uvicorn app.main:app --host 0.0.0.0 --port 5001 --reload
```

**Frontend Service**:
```bash
cd apps/singalong-admin  # or singalong-controller
yarn install
yarn dev
```

### Run All Services with Docker Compose

```bash
# Start all services
docker-compose up

# Stop all services
docker-compose down

# View logs
docker-compose logs -f [service-name]

# Rebuild services
docker-compose up --build
```

### Debug a Specific Service

**Python Backend** (using Python debugger):
```bash
cd apps/singalong-master
poetry install
poetry run python -m pdb -m uvicorn app.main:app --host 0.0.0.0 --port 5001
```

**React Frontend** (using browser DevTools):
```bash
cd apps/singalong-admin
yarn install
yarn dev
# Open http://localhost:3001, press F12 for DevTools
```

**Check Service Health**:
```bash
curl http://localhost:5001/health  # Master
curl http://localhost:5002/health  # Node
curl http://localhost:3001         # Admin
curl http://localhost:3002         # Controller
```

### Add a New API Endpoint to a Backend Service

1. **Create a router module** in `app/api/routes/`:
```python
# app/api/routes/songs.py
from fastapi import APIRouter

router = APIRouter(prefix="/songs", tags=["Songs"])

@router.get("/")
async def list_songs():
    """List all available songs"""
    return {"songs": []}
```

2. **Import and include in main.py**:
```python
# app/main.py
from app.api.routes import songs

app.include_router(songs.router)
```

3. **Add tests** in `app/tests/`:
```python
# app/tests/test_songs.py
def test_list_songs(client):
    response = client.get("/songs/")
    assert response.status_code == 200
```

### Add a New Page to a Frontend Service

1. **Create page component** in `src/pages/`:
```typescript
// src/pages/NewPage.tsx
import React from 'react';

export default function NewPage() {
  return <div>New Page Content</div>;
}
```

2. **Add route in App.tsx**:
```typescript
// src/App.tsx
import NewPage from './pages/NewPage';

function App() {
  return (
    <Routes>
      <Route path="/new-page" element={<NewPage />} />
    </Routes>
  );
}
```

3. **Add tests** using appropriate testing library

---

## 6. API Contracts (Stubs)

### Master API Endpoints

**Health Check**
```
GET /health
Response: 200 OK
{
  "status": "healthy",
  "app_name": "singalong-master",
  "version": "0.1.0"
}
```

**List Videos**
```
GET /api/videos
Query Parameters: 
  - limit: int (default: 100)
  - offset: int (default: 0)
Response: 200 OK
{
  "videos": [
    {
      "id": "video-uuid",
      "title": "Song Title",
      "artist": "Artist Name",
      "duration": 180,
      "path": "s3://bucket/video.mp4"
    }
  ],
  "total": 1000
}
```

**Get Video**
```
GET /api/videos/{id}
Response: 200 OK
{
  "id": "video-uuid",
  "title": "Song Title",
  "artist": "Artist Name",
  "genre": "Pop",
  "duration": 180,
  "year": 2020,
  "path": "s3://bucket/video.mp4"
}
```

### Node API Endpoints

**Health Check**
```
GET /health
Response: 200 OK
{
  "status": "healthy",
  "service": "singalong-node",
  "master_url": "http://singalong-master:5001"
}
```

**List Songs** (proxies master)
```
GET /api/songs
Query Parameters:
  - limit: int
  - offset: int
  - search: string (optional)
Response: 200 OK
{
  "songs": [...],
  "total": 1000,
  "cached_at": "2024-01-01T12:00:00Z"
}
```

**Make Reservation**
```
POST /api/reservations
Body:
{
  "song_id": "video-uuid",
  "user_id": "user-uuid"
}
Response: 201 Created
{
  "reservation_id": "res-uuid",
  "song_id": "video-uuid",
  "status": "confirmed",
  "created_at": "2024-01-01T12:00:00Z"
}
```

**Get Reservations**
```
GET /api/reservations?user_id={user_id}
Response: 200 OK
{
  "reservations": [
    {
      "id": "res-uuid",
      "song_id": "video-uuid",
      "song_title": "Title",
      "status": "confirmed",
      "created_at": "2024-01-01T12:00:00Z"
    }
  ]
}
```

---

## 7. File Organization Standards

### Backend Services Structure

**Python/FastAPI Standard Layout**:
```
singalong-master/
├── app/
│   ├── __init__.py
│   ├── main.py                 # Entry point
│   ├── config.py               # Settings/configuration
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/             # API endpoint definitions
│   │   │   ├── __init__.py
│   │   │   ├── health.py
│   │   │   ├── songs.py
│   │   │   └── videos.py
│   │   └── dependencies.py     # FastAPI dependencies
│   ├── models/
│   │   ├── __init__.py
│   │   ├── domain.py           # Business domain models
│   │   └── schemas.py          # Pydantic request/response schemas
│   ├── services/
│   │   ├── __init__.py
│   │   ├── song_service.py
│   │   └── video_service.py
│   └── tests/
│       ├── __init__.py
│       ├── test_api.py
│       └── conftest.py
├── pyproject.toml              # Poetry configuration
├── poetry.lock                 # Lock file
├── .env.example                # Example environment
└── run.sh                       # Startup script
```

**Key Convention**:
- **routes/** - All API endpoint handlers (organized by feature)
- **models/** - Data structures (domain models and Pydantic schemas)
- **services/** - Business logic and external service calls
- **tests/** - pytest-based test suite
- **main.py** - FastAPI app instantiation and router registration

### Frontend Services Structure

**React/Vite Standard Layout**:
```
singalong-admin/
├── src/
│   ├── main.tsx                # Entry point
│   ├── App.tsx                 # Root component
│   ├── pages/                  # Page-level components (routes)
│   │   ├── Dashboard.tsx
│   │   ├── Settings.tsx
│   │   └── NotFound.tsx
│   ├── components/             # Reusable components
│   │   ├── Header.tsx
│   │   ├── Navigation.tsx
│   │   └── cards/
│   │       ├── SongCard.tsx
│   │       └── NodeCard.tsx
│   ├── hooks/                  # Custom React hooks
│   │   ├── useApi.ts
│   │   └── useAuth.ts
│   ├── services/               # API client functions
│   │   ├── api.ts              # Axios configuration
│   │   ├── songService.ts
│   │   └── nodeService.ts
│   ├── types/                  # TypeScript types
│   │   └── index.ts
│   └── styles/                 # Global and component styles
│       └── global.css
├── index.html                  # HTML entry
├── vite.config.ts              # Vite configuration
├── tsconfig.json               # TypeScript configuration
├── package.json                # Dependencies
├── eslint.config.js            # Linting rules
└── README.md
```

**Key Convention**:
- **pages/** - Full page components that map to routes
- **components/** - Reusable UI components (atomic/molecular)
- **hooks/** - Custom React hooks for logic reuse
- **services/** - API client wrappers and external service calls
- **types/** - TypeScript interface/type definitions

### Configuration Files

**Backend Configuration** (`pyproject.toml`):
- Poetry dependency management
- Build system configuration
- Tool configurations (Black, Ruff, pytest)

**Frontend Configuration** (`package.json`, `vite.config.ts`):
- Yarn dependency management
- Build and development scripts
- Vite-specific configurations (plugins, server, build)

**Environment Configuration** (`.env` files):
- Service-specific variables
- API endpoints and credentials
- Debug/development flags

---

## 8. Development Best Practices

### Python Backend Development

- **Follow PEP 8**: Use Black for formatting (line length: 100)
- **Type Hints**: Use Python type hints throughout
- **Error Handling**: Use Pydantic ValidationError for API validation
- **Async**: Leverage async/await for I/O operations
- **Testing**: Aim for >80% test coverage with pytest
- **Logging**: Use Python's logging module for debugging

### TypeScript/React Frontend Development

- **Strict Typing**: Enable strict mode in tsconfig.json
- **Component Composition**: Keep components small and focused
- **Props Drilling**: Minimize by using context for shared state
- **Custom Hooks**: Extract stateful logic into reusable hooks
- **API Layer**: Centralize all API calls in service files
- **Error Boundaries**: Implement error handling for reliability

### Cross-Service Communication

- **API Stability**: Version APIs using URL prefixes (`/api/v1/...`)
- **Error Responses**: Always return structured error objects
- **Timeout Handling**: Implement reasonable timeouts for service calls
- **Retry Logic**: Add exponential backoff for transient failures
- **CORS**: Configure appropriate CORS policies

---

## 9. Troubleshooting Guide

### Service Won't Start

**Check**:
1. Port availability: `lsof -i :PORT`
2. Dependencies installed: `poetry install` (Python) or `yarn install` (Node)
3. Environment variables: Verify `.env` file exists
4. Python/Node version: Correct versions installed

### Services Can't Communicate

**Check**:
1. All services running: Use health endpoints
2. Network configuration: Docker Compose network settings
3. URLs/hostnames: Verify correct service addresses
4. Firewall: Check port access

### API Requests Failing

**Check**:
1. Endpoint exists: Review API documentation
2. Request format: Verify JSON structure
3. Authentication: Check headers and credentials
4. CORS: Verify frontend can access backend

---

## 10. Quick Reference

### Port Map
```
singalong-master:     5001
singalong-node:       5002
singalong-admin:      3001
singalong-controller: 3002
```

### Install Dependencies
```bash
# Python
poetry install

# Node.js
yarn install
```

### Run Services
```bash
# All services
docker-compose up

# Individual (Python)
poetry run uvicorn app.main:app --port 5001 --reload

# Individual (React)
yarn dev
```

### Common Tasks
```bash
# Python linting
poetry run black --check .
poetry run ruff check .

# TypeScript linting
yarn lint
yarn type-check

# Python testing
poetry run pytest

# Build for production
# Backend: handled by Docker
# Frontend: yarn build
```

---

## 11. Code Architecture & Design Patterns

### 11.1 SOLID Principles

All code in Singalong must adhere to SOLID principles for maintainability, testability, and scalability:

#### Single Responsibility Principle (SRP)
- **Each class/function does one thing well**
- Routes handle HTTP concerns only (request/response)
- Services handle business logic only
- Models represent data structures only
- Example violation: A route that also calculates business logic
- Example correct: Route calls Service, Service contains logic

#### Open/Closed Principle (OCP)
- **Code should be open for extension, closed for modification**
- Use abstract base classes and interfaces for extensibility
- Avoid modifying existing code when adding features
- Example: Add new search provider by implementing SearchProvider interface, not by modifying SearchService

#### Liskov Substitution Principle (LSP)
- **Subtypes must be substitutable for their base types**
- All implementations of an interface must be interchangeable
- Don't override behavior in unexpected ways
- Example: All authentication strategies should work identically from caller perspective

#### Interface Segregation Principle (ISP)
- **Clients should depend on specific interfaces, not broad ones**
- Create fine-grained interfaces
- Services should require only what they use
- Example: Don't require entire User object; require only name and id fields

#### Dependency Inversion Principle (DIP)
- **Depend on abstractions, not concrete implementations**
- Inject dependencies rather than creating them internally
- Use interfaces/abstract classes as contracts
- Example: Services depend on BaseRepository interface, not PostgresRepository directly

### 11.2 MVC Architecture for REST APIs

Singalong follows **Model-View-Controller** adapted for REST APIs:

```
┌─────────────────────────────────────────────────────────────┐
│                      HTTP Request                            │
└────────────────────────┬──────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │ Controllers/Routes Layer        │ (HTTP Concerns)
        │ ─────────────────────────────   │
        │ • Parse request parameters      │
        │ • Call services                 │
        │ • Format response               │
        │ • Handle HTTP status codes      │
        └────────────────┬─────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │ Services Layer                  │ (Business Logic)
        │ ─────────────────────────────   │
        │ • Core business rules           │
        │ • Data transformation           │
        │ • Orchestration logic           │
        │ • Call repositories             │
        └────────────────┬─────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │ Models Layer                    │ (Data Structure)
        │ ─────────────────────────────   │
        │ • Pydantic schemas              │
        │ • Type definitions              │
        │ • Validation rules              │
        └────────────────┬─────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │ Repository/Data Access Layer    │ (Persistence)
        │ ─────────────────────────────   │
        │ • Database queries              │
        │ • File I/O                      │
        │ • External API calls            │
        └────────────────┬─────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │ Database / External Services    │
        └────────────────────────────────┘
```

#### 11.2.1 Controllers/Routes

**Responsibility**: Handle HTTP protocol concerns

**Rules**:
- Extract parameters from request (path, query, body)
- Validate parameters are present (dependency injection validates types)
- Call appropriate service method
- Format response data
- Return proper HTTP status codes
- Never contain business logic
- Never directly access database

**Location**: `app/api/routes/*.py`

**Example**:
```python
@router.post("/songs")
async def create_song(
    song_request: CreateSongRequest,  # Pydantic model validates
    song_service: SongService = Depends(),  # Injected dependency
) -> SongResponse:
    """Create a new song (route layer)"""
    song = await song_service.create_song(song_request)
    return SongResponse.from_domain(song)
```

#### 11.2.2 Services

**Responsibility**: Implement business logic

**Rules**:
- Contain all business rules and decisions
- Transform data between models and domain objects
- Orchestrate multiple repository calls
- Handle application errors
- Never access HTTP concerns (request, response, status codes)
- Depend on repository interfaces, not implementations
- Testable without HTTP layer

**Location**: `app/services/*.py`

**Example**:
```python
class SongService:
    def __init__(self, song_repo: SongRepository, master_client: MasterClient):
        self.song_repo = song_repo
        self.master_client = master_client
    
    async def create_song(self, request: CreateSongRequest) -> Song:
        """Create song (business logic)"""
        # Validation
        if len(request.title) < 3:
            raise ValueError("Title too short")
        
        # Business logic: if new song, request from master
        existing = await self.song_repo.find_by_title(request.title)
        if existing:
            return existing
        
        # Call master service
        download_request = await self.master_client.request_download(
            request.youtube_url
        )
        
        # Persist
        song = Song(
            title=request.title,
            download_status=download_request.status
        )
        return await self.song_repo.save(song)
```

#### 11.2.3 Models

**Responsibility**: Define data structures and validation

**Rules**:
- Use Pydantic for request/response validation
- Define domain objects (separate from Pydantic models)
- Include validation rules
- No logic beyond data representation
- Immutable when possible (use `frozen=True`)

**Location**: `app/models/*.py`

**Example**:
```python
# Pydantic request model (from API)
class CreateSongRequest(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    artist: str
    youtube_url: str
    
    model_config = ConfigDict(from_attributes=True)

# Pydantic response model (to API)
class SongResponse(BaseModel):
    id: str
    title: str
    status: str
    
    @classmethod
    def from_domain(cls, song: Song) -> "SongResponse":
        return cls(id=song.id, title=song.title, status=song.status)

# Domain model (internal representation)
class Song:
    def __init__(self, id: str, title: str, artist: str, status: str):
        self.id = id
        self.title = title
        self.artist = artist
        self.status = status
```

#### 11.2.4 Repositories

**Responsibility**: Handle data persistence

**Rules**:
- Abstracted behind interfaces
- No business logic (queries only)
- Handle database-specific concerns
- Support testing with mocks
- Compose queries consistently

**Location**: `app/repositories/*.py`

**Example**:
```python
class SongRepository(BaseRepository[Song]):
    async def find_by_title(self, title: str) -> Optional[Song]:
        """Query by title"""
        query = select(SongModel).where(SongModel.title == title)
        result = await self.session.execute(query)
        return result.scalars().first()
    
    async def save(self, song: Song) -> Song:
        """Persist song"""
        model = SongModel.from_domain(song)
        self.session.add(model)
        await self.session.commit()
        return Song.from_model(model)
```

### 11.3 Dependency Injection

All services use **constructor-based dependency injection** via FastAPI's `Depends()`:

**Pattern**:
```python
# Define service with dependencies
class SongService:
    def __init__(self, repo: SongRepository, master_client: MasterClient):
        self.repo = repo
        self.master_client = master_client

# Inject in route
@router.get("/songs/{id}")
async def get_song(
    song_id: str,
    service: SongService = Depends()
) -> SongResponse:
    song = await service.get_song(song_id)
    return SongResponse.from_domain(song)
```

**Benefits**:
- Easy to test (inject mocks)
- Decoupled from implementations
- Follows dependency inversion principle
- FastAPI manages lifecycle

### 11.4 Error Handling

All errors follow a consistent pattern:

**Hierarchy**:
```
Exception
├── DomainException (base for business logic errors)
│   ├── SongNotFound (404)
│   ├── SongAlreadyExists (409)
│   ├── InvalidYouTubeURL (400)
│   └── ...
├── DatabaseException (database errors)
├── ExternalServiceException (master/3rd party failures)
└── ... (others)
```

**Response Format**:
```json
{
  "status": "error",
  "code": "SONG_NOT_FOUND",
  "message": "Song with id '123' does not exist",
  "details": {
    "song_id": "123"
  }
}
```

**Route Handler Pattern**:
```python
@router.get("/songs/{id}")
async def get_song(song_id: str, service: SongService = Depends()):
    try:
        song = await service.get_song(song_id)
        return SongResponse.from_domain(song)
    except SongNotFound as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")
```

### 11.5 Testing Strategy

**Unit Tests** (Services, Models):
- Test business logic in isolation
- Mock repositories and external services
- High coverage (>90%)

**Integration Tests** (Routes + Services + Repositories):
- Test full request/response cycle
- Use test database
- Verify data flow

**E2E Tests** (Services + HTTP):
- Test actual HTTP endpoints
- Use docker-compose for dependencies
- Focus on critical paths

---

## 12. Pull Request Guidelines

When creating a Pull Request, follow these steps to ensure clear communication and proper tracking:

### 12.1 PR Title Format

**Format**: Follow Conventional Commits format
- Examples: `feat: Add user authentication`, `fix: Correct session code validation`, `refactor: Simplify API response structure`

**Process**:
1. Analyze what changed from current branch vs base branch: `git diff origin/base-branch..current-branch --stat`
2. Identify the general scope of changes
3. Write a short, descriptive sentence summarizing the update
4. Prefix with the appropriate type: `feat`, `fix`, `refactor`, `docs`, `chore`, `ci`

**Guidelines**:
- Keep title concise (under 70 characters ideal)
- Describe what was updated in one sentence
- Use lowercase except for proper nouns
- Avoid generic titles like "Updates" or "Improvements"

### 12.2 PR Body Format

**Template**: Follow `.github/pull_request_template.md` structure

Required sections:
- **Summary**: One or two sentences describing the change
- **Motivation**: Why the change is needed, link any issues
- **Testing**: How the change was tested, provide steps and results
- **Release Notes** (optional): Any notes for the release process

**Best Practices**:
- Be specific and detailed in Motivation and Testing sections
- Include commands and output where relevant
- Document any breaking changes clearly
- Link to related issues or documentation

### 12.3 Example Workflow

```bash
# 1. Check what changed
git diff origin/develop..feature-branch --stat

# 2. Create PR title
# Result: "feat: Implement Master and Node backend services"

# 3. Write PR body following template sections
# - Summary: One sentence overview
# - Motivation: Why Master and Node were needed
# - Testing: docker-compose up, release build tests, etc.
# - Release Notes: New features and improvements

# 4. Update PR
gh pr edit 1 --title "feat: ..." --body-file pr-body.md
```

---

## Document Version

- **Created**: 2024
- **Last Updated**: 2024
- **Version**: 1.0.0
- **Status**: Active
