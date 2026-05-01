# Singalong Master - Developer Guide

Backend service that serves as the central repository and authoritative source of truth for all karaoke content, metadata, and downloads.

## Quick Links

- **[Root AGENTS.md](../../AGENTS.md)** - Main codebase documentation
- **[Architecture](../../docs/PROJECT_OVERVIEW.md)** - System design
- **[Backend Phases](../../docs/BACKEND_PHASES.md)** - Implementation roadmap
- **[API Authentication Contract](../../docs/API_CONTRACT_AUTHENTICATION.md)** - JWT + API key flow

---

## 1. Project Overview

**Service**: singalong-master  
**Role**: Central data repository, download manager, source of truth  
**Type**: Backend REST API  
**Technology**: FastAPI, Python 3.10+, PostgreSQL, yt-dlp  
**Port**: 5001 (default)

### Key Responsibilities

1. **Song Storage & Management**
   - Centralized database of all karaoke videos
   - Metadata (title, artist, duration, genre, etc.)
   - File storage (local or S3)

2. **Download Management**
   - Accept download requests from Node services
   - Use yt-dlp to download from YouTube
   - Track download progress
   - Store metadata

3. **API Gateway for Nodes**
   - Provide REST API for Node queries
   - Authenticate Node via JWT tokens
   - Support search, filtering, sync operations

4. **WebSocket Notifications** (future)
   - Notify Nodes of download completion
   - Broadcast metadata updates

---

## 2. Architecture

### 2.1 Folder Structure

```
singalong-master/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app factory & initialization
│   ├── config.py               # Settings (Pydantic)
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/             # API endpoints (organized by feature)
│   │   │   ├── __init__.py
│   │   │   ├── auth.py         # Authentication endpoints (B1)
│   │   │   ├── songs.py        # Song queries (B2, B8)
│   │   │   ├── downloads.py    # Download requests (B2)
│   │   │   └── health.py       # Health checks
│   │   └── dependencies.py     # FastAPI dependency injection
│   ├── models/
│   │   ├── __init__.py
│   │   ├── schemas.py          # Pydantic request/response models
│   │   ├── domain.py           # Domain objects (Song, Download, etc.)
│   │   └── database.py         # SQLAlchemy ORM models
│   ├── services/
│   │   ├── __init__.py
│   │   ├── auth_service.py     # JWT token management
│   │   ├── song_service.py     # Song business logic
│   │   ├── download_service.py # Download orchestration
│   │   └── youtube_service.py  # YT-DLP integration
│   ├── repositories/
│   │   ├── __init__.py
│   │   ├── base.py             # Base repository class
│   │   ├── song_repository.py  # Song persistence
│   │   └── download_repository.py
│   ├── middleware/
│   │   ├── __init__.py
│   │   └── auth.py             # JWT validation middleware
│   └── tests/
│       ├── __init__.py
│       ├── conftest.py         # pytest fixtures
│       ├── test_api.py
│       ├── test_services.py
│       ├── test_repositories.py
│       └── test_auth.py
├── migrations/                 # Alembic database migrations
│   ├── versions/
│   ├── env.py
│   ├── script.py.mako
│   └── alembic.ini
├── .env.example                # Environment variables template
├── pyproject.toml              # Poetry dependencies
├── poetry.lock
├── Dockerfile                  # Production container
├── run.sh                       # Startup script
└── README.md                   # Service documentation
```

### 2.2 Code Organization Principles

**Routes → Services → Repositories → Database**

```
HTTP Request
    ↓
[api/routes/songs.py]          ← Handle HTTP (parse params, return response)
    ↓ calls
[services/song_service.py]      ← Business logic (validation, rules)
    ↓ calls
[repositories/song_repo.py]     ← Data access (queries only)
    ↓ uses
[models/database.py]            ← ORM models
    ↓
Database
```

---

## 3. Design Patterns

### 3.1 SOLID Principles (Target Architecture)

⚠️ **TECHNICAL DEBT NOTICE**: Current implementation has violations (documented below). These are flagged for future refactoring during UI development phase.

**Target SOLID compliance**:

1. **Single Responsibility**: Routes handle HTTP only. Services handle logic only. Repos handle queries only.
2. **Open/Closed**: Use interfaces for repositories (BaseRepository) and auth strategies. Should not modify existing code to add features.
3. **Liskov Substitution**: All implementations of an interface should be interchangeable.
4. **Interface Segregation**: Services should inject only what they need, not full database sessions.
5. **Dependency Inversion**: Services should depend on repository abstractions, NOT direct database access.

**Current Violations** (see Section 12: Technical Debt):
- Routes contain database queries (violates SRP, DIP)
- Services lack repository abstraction layer (violates DIP)
- Services receive full SQLAlchemy session instead of specific repositories (violates ISP)
- No repository interfaces exist (violates OCP, DIP)

### 3.2 MVC Pattern (Target Architecture)

```
Model (Pydantic + Domain)
 ↑
Service (Business Logic)
 ↑
Route/Controller (HTTP)
```

**Correct pattern**:
- Routes: Parse HTTP params, call service, format response
- Services: Implement business logic, call repositories
- Repositories: Query database only
- Models: Data structures only (no logic)

⚠️ **CURRENT STATE**: Implementation does NOT fully match this pattern. See Technical Debt section for violations and refactoring plan.

---

## 4. Core Modules

### 4.1 Authentication (B1)

**Files**: `app/api/routes/auth.py`, `app/services/auth_service.py`

**Endpoints**:
- `POST /api/auth/exchange` - Exchange API key for tokens
- `POST /api/auth/refresh` - Refresh access token
- `GET /api/auth/validate` - Validate token

**Contract**: See [API_CONTRACT_AUTHENTICATION.md](../../docs/API_CONTRACT_AUTHENTICATION.md)

**Implementation Notes**:
- Load `MASTER_API_KEY` from `.env` at startup
- Use PyJWT library for token generation/validation
- HS256 algorithm with API key as secret
- Access token: 1 hour expiry
- Refresh token: 7 days expiry
- Middleware validates Bearer token on protected routes

### 4.2 Song Management (B2, B8)

**Files**: `app/models/schemas.py`, `app/services/song_service.py`, `app/repositories/song_repository.py`

**Key Models**:
```python
class Song(BaseModel):
    id: str
    title: str
    artist: str
    duration: int
    genre: str
    year: int
    status: str  # "draft", "ready", "deleted"
    youtube_url: str
    file_path: str  # or S3 URL
    created_at: datetime
    updated_at: datetime
```

**Database Schema**:
```sql
CREATE TABLE songs (
    id UUID PRIMARY KEY,
    title VARCHAR NOT NULL,
    artist VARCHAR,
    duration INTEGER,
    genre VARCHAR,
    year INTEGER,
    status VARCHAR,
    youtube_url VARCHAR,
    file_path VARCHAR,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    UNIQUE(youtube_url)
);
```

### 4.3 Download Management (B2)

**Files**: `app/api/routes/downloads.py`, `app/services/download_service.py`

**Endpoints**:
- `POST /api/songs/download-request` - Request song download
- `GET /api/downloads/{id}` - Get download status

**Workflow**:
1. Node sends download request with YouTube URL + metadata
2. Master creates draft song record
3. Master queues YT-DLP download task
4. Master sends back status (queued)
5. Node continues with async notification (WebSocket/webhook)

### 4.4 Config Management

**File**: `app/config.py`

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "singalong-master"
    debug: bool = False
    host: str = "0.0.0.0"
    port: int = 5001
    
    # API Key for Node authentication
    master_api_key: str  # Required, from .env
    
    # Database
    database_url: str = "postgresql://localhost/singalong"
    
    # YT-DLP
    ytdlp_path: str = "/usr/local/bin/yt-dlp"
    download_dir: str = "/data/downloads"
    
    class Config:
        env_file = ".env"
        case_sensitive = False
```

---

## 5. Development Workflow

### 5.1 Setup

```bash
cd apps/singalong-master

# Create .env from template
cp .env.example .env

# Install dependencies
poetry install

# Run migrations
poetry run alembic upgrade head

# Start dev server
poetry run uvicorn app.main:app --reload --port 5001
```

### 5.2 API Documentation

Once running, visit: http://localhost:5001/docs (Swagger UI)

### 5.3 Adding a New Endpoint

1. **Create route** in `app/api/routes/feature.py`:
```python
from fastapi import APIRouter, Depends

router = APIRouter(prefix="/songs", tags=["Songs"])

@router.get("/")
async def list_songs(
    service: SongService = Depends()
) -> SongsResponse:
    songs = await service.list_songs()
    return SongsResponse.from_domain(songs)
```

2. **Create service** in `app/services/song_service.py`:
```python
class SongService:
    def __init__(self, repo: SongRepository = Depends()):
        self.repo = repo
    
    async def list_songs(self) -> List[Song]:
        return await self.repo.find_all()
```

3. **Create repository** in `app/repositories/song_repository.py`:
```python
class SongRepository(BaseRepository[Song]):
    async def find_all(self) -> List[Song]:
        query = select(SongModel)
        result = await self.session.execute(query)
        return [Song.from_model(row) for row in result.scalars().all()]
```

4. **Register route** in `app/main.py`:
```python
from app.api.routes import songs

app.include_router(songs.router)
```

5. **Add tests** in `app/tests/test_songs.py`

---

## 6. Testing

### 6.1 Test Structure

```python
# conftest.py - Fixtures
@pytest.fixture
async def song_service():
    repo = MagicMock(spec=SongRepository)
    return SongService(repo=repo)

# test_services.py
@pytest.mark.asyncio
async def test_create_song(song_service):
    request = CreateSongRequest(title="Song", artist="Artist")
    song = await song_service.create_song(request)
    assert song.title == "Song"
```

### 6.2 Run Tests

```bash
# All tests
poetry run pytest

# With coverage
poetry run pytest --cov=app

# Specific test
poetry run pytest app/tests/test_auth.py::test_token_exchange
```

---

## 7. Dependency Versions

Key dependencies (see `pyproject.toml`):

- **fastapi**: ^0.104.0
- **uvicorn**: ^0.24.0
- **pydantic**: ^2.5.0
- **pydantic-settings**: ^2.0.0
- **sqlalchemy**: ^2.0.0
- **alembic**: ^1.12.0
- **PyJWT**: ^2.8.0
- **yt-dlp**: ^2024.01.0
- **httpx**: ^0.25.0
- **python-dotenv**: ^1.0.0
- **pytest**: ^7.4.0
- **pytest-asyncio**: ^0.21.0

---

## 8. Common Tasks

### Check API Documentation
```bash
open http://localhost:5001/docs
```

### Run Linters
```bash
poetry run black --check .
poetry run ruff check .
```

### Format Code
```bash
poetry run black .
poetry run ruff check --fix .
```

### Database Migrations
```bash
# Create new migration
poetry run alembic revision --autogenerate -m "description"

# Apply migrations
poetry run alembic upgrade head

# Rollback
poetry run alembic downgrade -1
```

### Debug a Service
```bash
poetry run python -m pdb -m uvicorn app.main:app
```

---

## 9. Key Files Reference

| File | Purpose |
|------|---------|
| `app/main.py` | FastAPI app initialization, middleware setup |
| `app/config.py` | Settings and environment variables |
| `app/api/routes/*.py` | HTTP endpoint handlers |
| `app/services/*.py` | Business logic implementation |
| `app/repositories/*.py` | Data access layer |
| `app/models/*.py` | Pydantic and domain models |
| `app/middleware/auth.py` | JWT validation middleware |
| `pyproject.toml` | Dependencies and project config |
| `.env.example` | Template for environment variables |

---

## 10. Technical Debt: SOLID/MVC Architecture Violations

⚠️ **CURRENT STATE (As of latest checkpoint)**: Implementation deviates from documented SOLID principles and MVC pattern. This section documents known violations and recommended refactoring.

### 10.1 Known Violations

#### Issue 1: Routes Access Database Directly (CRITICAL)
- **Files**: `app/api/routes/downloads.py`, `app/api/routes/songs.py`
- **Problem**: Route handlers contain direct database queries instead of calling services
- **Impact**: Violates SRP, makes routes untestable without database, couples API layer to schema
- **Impact**: HIGH (affects testing, maintainability, schema changes break routes)

#### Issue 2: Missing Repository Pattern (CRITICAL)
- **Problem**: No `app/repositories/` layer exists despite being documented in section 5.3
- **Should exist**: `SongRepository`, `DownloadRepository` interfaces + concrete implementations
- **Current**: Routes and services mix data access code with business logic
- **Impact**: Services cannot be tested in isolation, tight coupling to database
- **Impact**: HIGH (blocks unit testing, prevents future schema migrations)

#### Issue 3: Services Lack Dependency Inversion (HIGH)
- **Files**: `app/services/download_service.py`, `app/services/song_service.py`
- **Problem**: Services receive `db: SQLSession` and query directly instead of receiving repository instances
- **Should be**: `SongService(song_repo: SongRepository, download_repo: DownloadRepository)`
- **Current**: `SongService(db: SQLSession)` with direct database queries
- **Impact**: Violates DIP and ISP, makes services database-dependent
- **Impact**: HIGH (blocks service layer unit testing)

#### Issue 4: Routes Depend on Concrete Models (HIGH)
- **Files**: `app/api/routes/downloads.py`, `app/api/routes/songs.py`
- **Problem**: Routes import concrete database models and use directly
- **Should be**: Routes only use Pydantic response schemas, not database models
- **Example**: Routes instantiate `db_models.Song(...)` directly
- **Impact**: Routes tightly coupled to database schema, testing requires database

### 10.2 Refactoring Plan (Future Sprint)

**Recommended order**:

1. **Implement Repository Pattern** (2-3 hours)
   ```python
   # Create app/repositories/base_repository.py
   class BaseRepository(ABC, Generic[T]):
       @abstractmethod
       async def get_by_id(self, id: str) -> Optional[T]: pass
       @abstractmethod
       async def save(self, entity: T) -> T: pass
   
   # Create concrete repositories
   class SongRepository(BaseRepository[Song]):
       def __init__(self, db: SQLSession):
           self.db = db
       async def find_all(self, limit: int = 100) -> List[Song]:
           query = select(Song).limit(limit)
           return await self.db.execute(query)
   ```

2. **Move Database Queries to Services** (1-2 hours)
   - Extract routes database queries → service methods
   - Routes now only parse request, call service, format response
   - Example:
     ```python
     # BEFORE (Route has logic):
     @router.get("/songs")
     async def list_songs(...):
         songs = db.query(Song).limit(100).all()
         return [SongResponse.from_model(s) for s in songs]
     
     # AFTER (Route calls service):
     @router.get("/songs")
     async def list_songs(..., service: SongService = Depends()):
         songs = await service.list_songs()
         return [SongResponse.from_domain(s) for s in songs]
     ```

3. **Inject Repositories into Services** (1-2 hours)
   - Services receive repository instances via constructor
   - Remove direct db.query() calls from service layer
   - Update FastAPI dependency injection in dependencies.py

4. **Remove db_models imports from routes** (30 mins)
   - All database model conversions → service layer
   - Routes only work with Pydantic response schemas

5. **Add Unit Tests** (2-3 hours)
   - Mock repositories, test services in isolation
   - Mock services, test routes only handle HTTP concerns
   - Achieve 80%+ coverage

**Estimated total**: 8-12 hours of focused refactoring work

### 10.3 Why This Debt Exists

- **MVP Priority**: Initial implementation prioritized speed/features over architecture (pragmatic choice)
- **Working System**: Despite violations, system is functionally correct (issues are architectural, not bugs)
- **No Active Regression**: System works correctly; violations are design-level concerns

### 10.4 Impact Assessment

**Current** (MVP phase):
- ✅ Features work
- ✅ Endpoints respond correctly
- ❌ Hard to test services in isolation
- ❌ Hard to modify database schema
- ❌ Coupling makes future features slower

**After Refactoring**:
- ✅ Same features
- ✅ Can test without database
- ✅ Easy schema changes
- ✅ Can reuse services across routes
- ✅ Faster future feature development

---

## 11. Implementation Phases

Current implementation focus (from BACKEND_PHASES.md):

- **B1**: JWT authentication ← START HERE
- **B2**: Download request endpoint
- **B8**: Song management endpoints

Each phase in [BACKEND_PHASES.md](../../docs/BACKEND_PHASES.md) includes:
- API specifications
- Database schema
- Implementation checklist
- Acceptance criteria

---

## Document Version

- **Created**: 2026-04
- **Version**: 1.1.0
- **Status**: Active
- **Last Audit**: Current session (SOLID/MVC violations documented)
