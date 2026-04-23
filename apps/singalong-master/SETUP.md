# Singalong Master Service - Setup Complete ✅

## What's Been Created

A production-ready FastAPI backend boilerplate for the **Singalong Master Service** - the central server for video file storage and data management.

## Directory Structure

```
singalong-master/
├── app/                          # Application package
│   ├── __init__.py              # Package initialization (v0.1.0)
│   ├── main.py                  # FastAPI app factory with settings & endpoints
│   ├── api/                     # API route handlers (organize by feature)
│   ├── models/                  # Pydantic data models & schemas
│   └── services/                # Business logic layer
├── pyproject.toml               # Poetry configuration
├── poetry.lock                  # Locked dependency versions
├── README.md                    # Full documentation
├── .env.example                 # Environment template
├── .gitignore                   # Python-standard ignore rules
├── run.sh                       # Startup script (executable)
└── SETUP.md                     # This file
```

## Dependencies

**Production:**
- `fastapi` (0.104.1) - Modern Python web framework
- `uvicorn` (0.24.0) - ASGI server with hot reload
- `pydantic` (2.5.0) - Data validation
- `pydantic-settings` (2.1.0) - Settings management
- `python-dotenv` (1.0.0) - Environment variables

**Development:**
- `pytest` - Unit testing
- `pytest-asyncio` - Async test support
- `httpx` - HTTP client for testing
- `black` - Code formatter
- `ruff` - Linter

## Getting Started

### 1. Install Dependencies
Dependencies are already installed via Poetry:
```bash
cd /Users/pat/Projects/PAT/singalong/apps/singalong-master
poetry install
```

### 2. Create .env File (Optional)
Copy the example and customize:
```bash
cp .env.example .env
```

### 3. Start Development Server

**Option A - Using run.sh (Recommended):**
```bash
./run.sh
```

**Option B - Using poetry directly:**
```bash
poetry run uvicorn app.main:app --reload
```

The server will start on `http://localhost:5001` with hot reload enabled.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Welcome message |
| GET | `/health` | Service health status |
| GET | `/docs` | Swagger UI documentation |
| GET | `/redoc` | ReDoc documentation |

Test the health endpoint:
```bash
curl http://localhost:5001/health
```

## Environment Configuration

Set these variables in `.env` or as environment variables:

| Variable | Default | Notes |
|----------|---------|-------|
| `DEBUG` | `False` | Enable debug mode |
| `PORT` | `5001` | Server port |
| `HOST` | `0.0.0.0` | Bind address |

Example:
```bash
PORT=8000 poetry run uvicorn app.main:app --reload
```

## Development Workflow

### Code Formatting
```bash
# Format with Black
poetry run black app/

# Lint and auto-fix with Ruff
poetry run ruff check --fix app/
```

### Testing
```bash
# Run all tests
poetry run pytest

# Run with coverage
poetry run pytest --cov=app
```

### Project Layout Guide

#### Adding API Routes
Create `app/api/videos.py`:
```python
from fastapi import APIRouter

router = APIRouter(prefix="/videos", tags=["videos"])

@router.get("/")
async def list_videos():
    return {"videos": []}
```

Register in `app/main.py`:
```python
from app.api import videos
app.include_router(videos.router)
```

#### Adding Data Models
Create `app/models/video.py`:
```python
from pydantic import BaseModel

class VideoResponse(BaseModel):
    id: str
    title: str
    duration: int
```

#### Adding Business Logic
Create `app/services/video_service.py`:
```python
class VideoService:
    async def get_video(self, video_id: str):
        # Implement business logic
        pass
```

## Production Deployment

### Using Gunicorn
```bash
poetry add gunicorn
poetry run gunicorn app.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker
```

### Using Docker
The project is ready for containerization. Add to Dockerfile:
```dockerfile
FROM python:3.10-slim
WORKDIR /app
RUN pip install poetry
COPY . .
RUN poetry install --no-dev
CMD ["poetry", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "5001"]
```

## Next Steps

1. **Add video management routes** → `app/api/videos.py`
2. **Define data models** → `app/models/`
3. **Implement business logic** → `app/services/`
4. **Add database integration** → Update `pyproject.toml` with SQLAlchemy, etc.
5. **Add authentication** → Integrate with auth service
6. **Add tests** → Create `tests/` directory with test cases

## Key Features

✅ Hot reload enabled for development
✅ Auto-generated API documentation (Swagger + ReDoc)
✅ Settings management with environment variables
✅ Health check endpoint
✅ Production-ready async architecture
✅ Code quality tools pre-configured
✅ Testing setup ready to use
✅ Python 3.10+ compatible

## Troubleshooting

**Port already in use:**
```bash
PORT=5002 ./run.sh
```

**Dependencies won't install:**
```bash
poetry cache clear . --all
poetry install --no-cache
```

**Hot reload not working:**
Ensure you're using `--reload` flag:
```bash
poetry run uvicorn app.main:app --reload
```

## Resources

- FastAPI Docs: https://fastapi.tiangolo.com/
- Pydantic Docs: https://docs.pydantic.dev/
- Poetry Docs: https://python-poetry.org/docs/
- Uvicorn Docs: https://www.uvicorn.org/

---

**Project Ready** 🎉
