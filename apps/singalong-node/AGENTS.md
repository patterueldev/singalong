# Singalong Node - Developer Guide

Backend service that acts as a gateway and middleware between frontend applications and the master server. Provides local coordination, caching, search, and session management.

## Quick Links

- **[Root AGENTS.md](../../AGENTS.md)** - Main codebase documentation
- **[Architecture](../../docs/PROJECT_OVERVIEW.md)** - System design
- **[Backend Phases](../../docs/BACKEND_PHASES.md)** - Implementation roadmap
- **[API Authentication Contract](../../docs/API_CONTRACT_AUTHENTICATION.md)** - JWT + API key flow

---

## 1. Project Overview

**Service**: singalong-node  
**Role**: Local gateway, middleware, coordinator  
**Type**: Backend REST API  
**Technology**: FastAPI, Python 3.10+, PostgreSQL, httpx, yt-dlp  
**Port**: 5002 (default)

### Key Responsibilities

1. **API Gateway for Frontends**
   - Accept requests from Admin and Controller apps
   - Route requests to Master or process locally
   - Transparent caching and fallback handling

2. **Session Management**
   - Create and manage karaoke sessions
   - Track connected users
   - Manage song reservations per session

3. **Search & Discovery**
   - YouTube search using yt-dlp
   - Song identification from URLs
   - Metadata enhancement using OpenAI

4. **Authentication & Users**
   - User session tokens (nickname-based)
   - Per-session user tracking

5. **Master Communication**
   - Authenticate with Master using API key
   - Sync song catalog from Master
   - Request downloads for new songs
   - Handle offline scenarios

---

## 2. Architecture

### 2.1 Folder Structure

```
singalong-node/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app factory & initialization
│   ├── config.py               # Settings (Pydantic)
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/             # API endpoints (organized by feature)
│   │   │   ├── __init__.py
│   │   │   ├── auth.py         # User auth (nickname join) - B3
│   │   │   ├── search.py       # Song search - B4
│   │   │   ├── identify.py     # URL identification - B5
│   │   │   ├── enhance.py      # Metadata enhancement - B6
│   │   │   ├── suggest.py      # Song suggestion - B7
│   │   │   ├── sessions.py     # Session management - B8
│   │   │   ├── songs.py        # Song listing & discovery
│   │   │   └── health.py       # Health checks
│   │   └── dependencies.py     # FastAPI dependency injection
│   ├── models/
│   │   ├── __init__.py
│   │   ├── schemas.py          # Pydantic request/response models
│   │   ├── domain.py           # Domain objects (User, Session, etc.)
│   │   └── database.py         # SQLAlchemy ORM models
│   ├── services/
│   │   ├── __init__.py
│   │   ├── master_client.py    # Communication with Master (auth, tokens)
│   │   ├── session_service.py  # Session management & coordination
│   │   ├── user_service.py     # User authentication (nickname)
│   │   ├── search_service.py   # YouTube search via yt-dlp
│   │   ├── identify_service.py # URL metadata extraction
│   │   ├── enhance_service.py  # OpenAI metadata enhancement
│   │   ├── suggest_service.py  # Song suggestion to Master
│   │   ├── cache_service.py    # Local caching
│   │   └── youtube_service.py  # yt-dlp wrapper
│   ├── repositories/
│   │   ├── __init__.py
│   │   ├── base.py             # Base repository class
│   │   ├── user_repository.py
│   │   ├── session_repository.py
│   │   ├── song_repository.py  # Local song cache
│   │   └── reservation_repository.py
│   ├── middleware/
│   │   ├── __init__.py
│   │   └── session_auth.py     # Session token validation
│   └── tests/
│       ├── __init__.py
│       ├── conftest.py         # pytest fixtures
│       ├── test_api.py
│       ├── test_services.py
│       ├── test_master_client.py
│       └── test_repositories.py
├── migrations/                 # Alembic database migrations
├── .env.example                # Environment variables template
├── pyproject.toml              # Poetry dependencies
├── poetry.lock
├── Dockerfile                  # Production container
├── run.sh                       # Startup script
└── README.md                   # Service documentation
```

### 2.2 Code Organization Principles

**Routes → Services → Repositories → Database / Master**

```
HTTP Request from Frontend
    ↓
[api/routes/sessions.py]        ← Handle HTTP (parse params, return response)
    ↓ calls
[services/session_service.py]   ← Business logic (orchestration, validation)
    ↓ calls
[repositories/...]              ← Data access (local queries only)
└─ or ─→ [services/master_client.py]  ← Master communication (async)
    ↓
Local Database / Master Server
```

---

## 3. Design Patterns

### 3.1 SOLID Principles (Required)

Every file must follow SOLID:

1. **Single Responsibility**: Routes handle HTTP. Services handle logic. Repos query local data. MasterClient handles network.
2. **Open/Closed**: Use interfaces for search providers (YouTubeSearch, etc.).
3. **Liskov Substitution**: All search implementations work identically.
4. **Interface Segregation**: Services inject only what they need.
5. **Dependency Inversion**: Services depend on repository interfaces and MasterClient interface.

### 3.2 MVC Pattern (Required)

```
Model (Pydantic + Domain)
 ↑
Service (Business Logic + Orchestration)
 ↑
Route/Controller (HTTP)
```

**Key Difference from Master**: Node services often orchestrate between local repos AND Master communication.

---

## 4. Core Modules

### 4.1 Master Client (B1 dependency)

**File**: `app/services/master_client.py`

**Responsibilities**:
- Authenticate with Master (exchange API key)
- Maintain token cache with auto-refresh
- Make authenticated requests to Master
- Handle Master unavailability (circuit breaker)

**Implementation**:
```python
class MasterClient:
    def __init__(self, config: Settings, cache: CacheService):
        self.config = config
        self.cache = cache
        self.client = httpx.AsyncClient()
        self._token_cache = None
    
    async def authenticate(self):
        """Exchange API key for tokens on startup"""
        response = await self.client.post(
            f"{self.config.master_url}/api/auth/exchange",
            json={"api_key": self.config.master_api_key}
        )
        tokens = response.json()
        self.cache.set("access_token", tokens["access_token"])
        self.cache.set("refresh_token", tokens["refresh_token"])
    
    async def get_songs(self, limit: int = 100, offset: int = 0):
        """Fetch songs from Master"""
        token = await self._get_valid_token()
        response = await self.client.get(
            f"{self.config.master_url}/api/songs",
            headers={"Authorization": f"Bearer {token}"},
            params={"limit": limit, "offset": offset}
        )
        return response.json()
    
    async def _get_valid_token(self) -> str:
        """Ensure token is valid, refresh if needed"""
        token = self.cache.get("access_token")
        if self._token_expires_soon(token):
            await self._refresh_token()
            token = self.cache.get("access_token")
        return token
```

**Key Features**:
- Loads API key from `.env` at startup
- Caches tokens in memory
- Auto-refreshes tokens before expiry
- Handles Master unavailability gracefully
- No direct token exposure (always in cache)

### 4.2 User Authentication (B3)

**Files**: `app/api/routes/auth.py`, `app/services/user_service.py`

**Endpoints**:
- `POST /api/auth` - Join session with nickname

**Workflow**:
1. User (from Controller) sends nickname + optional password
2. Node validates nickname (unique per session)
3. Node creates user session record
4. Node returns session token
5. User includes token in subsequent requests

**Implementation Notes**:
- Session tokens are Node-specific (not Master tokens)
- Sessions are tied to a specific Node karaoke session
- Passwords optional (for session access control)

### 4.3 Song Search (B4)

**Files**: `app/api/routes/search.py`, `app/services/search_service.py`

**Endpoints**:
- `POST /api/search` - Search YouTube for songs

**Implementation**:
- Use yt-dlp to query YouTube
- Parse results into Song objects
- Return paginated results
- Cache search results (TTL: 1 hour)

### 4.4 Song Identification (B5)

**Files**: `app/api/routes/identify.py`, `app/services/identify_service.py`

**Endpoints**:
- `POST /api/identify` - Extract metadata from YouTube URL

**Implementation**:
- Accept YouTube URL
- Use yt-dlp to extract metadata
- Return title, artist, duration, thumbnail
- Handle various URL formats (youtube.com, youtu.be, etc.)

### 4.5 Song Enhancement (B6)

**Files**: `app/api/routes/enhance.py`, `app/services/enhance_service.py`

**Endpoints**:
- `POST /api/enhance` - Improve song metadata using OpenAI

**Implementation**:
- Accepts raw metadata from identify step
- Calls OpenAI API to correct/infer data
- Returns confidence scores
- Cache by (title, artist) tuple

### 4.6 Song Suggestion (B7)

**Files**: `app/api/routes/suggest.py`, `app/services/suggest_service.py`

**Endpoints**:
- `POST /api/suggest` - Submit song to Master for download

**Implementation**:
- Accept enhanced song details
- Send to Master via `/api/songs/download-request`
- Wait for download completion (webhook/polling)
- Sync local cache on completion
- Optionally reserve for user

### 4.7 Session Management (B8)

**Files**: `app/api/routes/sessions.py`, `app/services/session_service.py`

**Endpoints**:
- `POST /api/sessions` - Create new session
- `GET /api/sessions/{code}` - Join existing session
- `GET /api/sessions/{code}/details` - Get session info
- `GET /api/sessions/{code}/reservations` - Get reserved songs

**Key Models**:
```python
class Session:
    id: str  # UUID
    code: str  # "ABC123" - user-friendly code
    title: str  # "Alice's Birthday"
    vibes: List[str]  # ["energetic", "80s"] for recommendations
    owner_id: str  # User who created
    users: List[User]
    reservations: List[Reservation]
    created_at: datetime
    status: str  # "active", "closed"

class User:
    id: str
    nickname: str
    session_id: str
    joined_at: datetime

class Reservation:
    id: str
    session_id: str
    song_id: str  # From local cache or Master
    reserved_by: str  # User ID
    order: int  # Priority/queue position
    status: str  # "pending", "playing", "completed"
    reserved_at: datetime
```

### 4.8 Config Management

**File**: `app/config.py`

```python
class Settings(BaseSettings):
    app_name: str = "singalong-node"
    debug: bool = False
    host: str = "0.0.0.0"
    port: int = 5002
    
    # Master service
    master_url: str = "http://singalong-master:5001"
    master_api_key: str  # Required, from .env
    
    # Database
    database_url: str = "postgresql://localhost/singalong_node"
    
    # YouTube / Search
    ytdlp_path: str = "/usr/local/bin/yt-dlp"
    search_cache_ttl: int = 3600  # 1 hour
    
    # OpenAI (for enhancement)
    openai_api_key: str = ""
    openai_model: str = "gpt-3.5-turbo"
    
    # Offline mode
    allow_offline: bool = True  # Fall back to local cache if Master unavailable
```

---

## 5. Development Workflow

### 5.1 Setup

```bash
cd apps/singalong-node

# Create .env from template
cp .env.example .env

# Install dependencies
poetry install

# Run migrations
poetry run alembic upgrade head

# Start dev server
poetry run uvicorn app.main:app --reload --port 5002
```

### 5.2 API Documentation

Once running, visit: http://localhost:5002/docs (Swagger UI)

### 5.3 Testing Master Communication

```bash
# Test token exchange
curl -X POST http://localhost:5002/api/master/auth \
  -H "Content-Type: application/json" \
  -d '{"api_key":"test-key"}'

# List songs (requires valid token)
curl http://localhost:5002/api/songs \
  -H "Authorization: Bearer <token>"
```

---

## 6. Communication Patterns

### 6.1 Node → Master (via MasterClient)

```python
# In any service
class SomeService:
    def __init__(self, master: MasterClient):
        self.master = master
    
    async def fetch_songs(self):
        # MasterClient handles auth internally
        songs = await self.master.get_songs(limit=100)
        return songs
```

### 6.2 Frontend → Node → Master (Transparent)

```
Controller App
    ↓ HTTP request
Node (/api/search)
    ↓ if search → use local yt-dlp
    ↓ if fetch → call Master
    ↓ HTTP response
Controller App
```

Frontend never sees Master - all communication through Node.

---

## 7. Testing

### 7.1 Unit Tests

```python
# test_services.py
@pytest.mark.asyncio
async def test_search_songs(search_service):
    results = await search_service.search("karaoke song")
    assert len(results) > 0
    assert results[0].title is not None

# test_master_client.py
@pytest.mark.asyncio
async def test_master_auth(master_client, mocker):
    mock_response = {"access_token": "token", "refresh_token": "refresh"}
    mocker.patch.object(master_client.client, 'post', 
                       return_value=AsyncMock(json=lambda: mock_response))
    await master_client.authenticate()
    assert master_client.cache.get("access_token") == "token"
```

### 7.2 Run Tests

```bash
poetry run pytest
poetry run pytest --cov=app
poetry run pytest app/tests/test_search_service.py -v
```

---

## 8. Dependency Versions

Key dependencies (see `pyproject.toml`):

- **fastapi**: ^0.136.0
- **uvicorn**: ^0.45.0
- **pydantic**: ^2.13.3
- **sqlalchemy**: ^2.0.0
- **alembic**: ^1.12.0
- **httpx**: ^0.28.1 (async HTTP client)
- **yt-dlp**: ^2024.01.0
- **openai**: ^1.0.0 (for enhancement)
- **pytest**: ^7.4.0
- **pytest-asyncio**: ^0.21.0

---

## 9. Common Tasks

### Check API Documentation
```bash
open http://localhost:5002/docs
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

### Test Master Connectivity
```bash
# Create .env with real Master URL and API key
# Then check:
curl http://localhost:5002/api/health
```

### Enable Debug Logging
```bash
# In .env
DEBUG=true

# Restart service with reload
poetry run uvicorn app.main:app --reload
```

---

## 10. Key Files Reference

| File | Purpose |
|------|---------|
| `app/main.py` | FastAPI app initialization, startup hooks |
| `app/config.py` | Settings and environment variables |
| `app/services/master_client.py` | Master authentication and communication |
| `app/api/routes/*.py` | HTTP endpoint handlers |
| `app/services/*.py` | Business logic and external API calls |
| `app/repositories/*.py` | Local data access layer |
| `app/models/*.py` | Pydantic and domain models |
| `pyproject.toml` | Dependencies and project config |
| `.env.example` | Template for environment variables |

---

## 11. Implementation Phases (from BACKEND_PHASES.md)

Recommended order:

1. **B1**: Master authentication (dependency)
2. **B3**: User auth (nickname join)
3. **B8**: Session management
4. **B4**: Search (YouTube)
5. **B5**: Identify (URL metadata)
6. **B6**: Enhance (OpenAI)
7. **B7**: Suggest (to Master)

Each phase documented in [BACKEND_PHASES.md](../../docs/BACKEND_PHASES.md)

---

## 12. Error Handling Pattern

All endpoints follow consistent error response format:

```python
@router.post("/search")
async def search(
    request: SearchRequest,
    service: SearchService = Depends()
):
    try:
        results = await service.search(request.keywords)
        return SearchResponse(results=results)
    except YouTubeError as e:
        logger.error(f"YouTube search failed: {e}")
        raise HTTPException(status_code=503, detail="Search service unavailable")
    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")
```

---

## Document Version

- **Created**: 2026-04
- **Version**: 1.0.0
- **Status**: Active
