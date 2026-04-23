# Singalong Master Service

The central "master" server for the Singalong application. This service handles video file storage, metadata management, and serves as the central data hub for the platform.

## Overview

**Singalong Master** is a FastAPI-based backend service that provides:
- Video file storage and management
- Metadata management and retrieval
- RESTful API for client applications
- Health monitoring and service status

## Architecture

```
app/
├── main.py          # FastAPI application factory and configuration
├── api/             # API route handlers (organize by feature)
├── models/          # Pydantic data models and schemas
├── services/        # Business logic and service layer
└── __init__.py
```

## Requirements

- Python 3.10+
- Poetry (for dependency management)

## Setup

### 1. Install Dependencies

```bash
poetry install
```

### 2. Create Environment File (Optional)

```bash
cat > .env << EOF
DEBUG=True
PORT=5001
HOST=0.0.0.0
EOF
```

### 3. Run the Development Server

```bash
poetry run uvicorn app.main:app --host 0.0.0.0 --port 5001 --reload
```

The server will be available at `http://localhost:5001`

## API Endpoints

### Health Check
- **GET** `/health` - Service health status
  ```bash
  curl http://localhost:5001/health
  ```

### Root
- **GET** `/` - Service welcome message
  ```bash
  curl http://localhost:5001/
  ```

## Development

### Hot Reload

The development server includes hot reload (file watch mode) by default with the `--reload` flag:

```bash
poetry run uvicorn app.main:app --reload
```

Any changes to Python files will trigger a server restart.

### Code Quality

Format code with Black:
```bash
poetry run black app/
```

Lint with Ruff:
```bash
poetry run ruff check app/
```

### Testing

Run tests with pytest:
```bash
poetry run pytest
```

Run with coverage:
```bash
poetry run pytest --cov=app
```

## Configuration

Configure the service using environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `DEBUG` | `False` | Enable debug mode |
| `PORT` | `5001` | Server port |
| `HOST` | `0.0.0.0` | Server host |

Or define them in a `.env` file in the project root.

## Project Structure

### `app/main.py`
FastAPI application factory with:
- Settings management via Pydantic
- Lifespan management (startup/shutdown)
- Health check endpoint
- Root endpoint

### `app/api/`
API route handlers organized by feature:
```python
# Example: app/api/videos.py
from fastapi import APIRouter

router = APIRouter(prefix="/videos", tags=["videos"])

@router.get("/")
async def list_videos():
    return []
```

Register routers in `main.py`:
```python
from app.api import videos
app.include_router(videos.router)
```

### `app/models/`
Pydantic data models for:
- Request/response schemas
- Database models
- Data validation

```python
# Example: app/models/video.py
from pydantic import BaseModel

class VideoResponse(BaseModel):
    id: str
    title: str
    duration: int
```

### `app/services/`
Business logic and service layer:
```python
# Example: app/services/video_service.py
class VideoService:
    async def get_video(self, video_id: str):
        # Business logic here
        pass
```

## Running in Production

For production deployments:

```bash
poetry run uvicorn app.main:app --host 0.0.0.0 --port 5001 --workers 4
```

Or use a production ASGI server like Gunicorn:

```bash
poetry add gunicorn
poetry run gunicorn app.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker
```

## Contributing

1. Follow PEP 8 style guide
2. Run formatters before committing:
   ```bash
   poetry run black app/
   poetry run ruff check --fix app/
   ```
3. Ensure tests pass
4. Add tests for new features

## License

See LICENSE in the root repository
