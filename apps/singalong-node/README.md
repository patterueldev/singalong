# Singalong Node

A local FastAPI-based karaoke server for the Singalong system. This service acts as a bridge between the master server and admin/controller applications, fetching karaoke files and data while managing local operations.

## Features

- **Local Server**: Runs on port 5002 (configurable)
- **Master Communication**: Connects to the Singalong Master server for data synchronization
- **Admin Integration**: Communicates with admin applications for content management
- **Controller Support**: Interfaces with controller apps for real-time karaoke control
- **Hot-Reload Development**: Configured for rapid development iteration
- **Production Ready**: Includes proper error handling and configuration management

## Prerequisites

- Python 3.10 or higher
- Poetry (for dependency management)

## Installation

1. Install dependencies:

```bash
poetry install
```

2. Create a `.env` file from the example:

```bash
cp .env.example .env
```

3. Configure environment variables in `.env`:

```env
# Server Configuration
HOST=0.0.0.0
PORT=5002
DEBUG=False

# Master Server Configuration
MASTER_URL=http://localhost:5000
MASTER_TIMEOUT=30
```

## Development

Start the development server with hot-reload:

```bash
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 5002
```

The API will be available at `http://localhost:5002`

- API documentation: `http://localhost:5002/docs`
- Alternative documentation: `http://localhost:5002/redoc`

## API Endpoints

### Health & Status

- `GET /` - Root endpoint with service information
- `GET /health` - Health check endpoint

## Project Structure

```
singalong-node/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI application entry point
│   ├── config.py               # Configuration and settings
│   ├── api/                    # Route organization
│   │   └── __init__.py
│   ├── models/                 # Data models (Pydantic)
│   │   └── __init__.py
│   └── services/               # Business logic
│       └── __init__.py
├── .env.example                # Environment variables template
├── .gitignore                  # Git ignore rules
├── pyproject.toml              # Poetry configuration
├── poetry.lock                 # Locked dependency versions
└── README.md                   # This file
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | `0.0.0.0` | Server bind address |
| `PORT` | `5002` | Server port |
| `DEBUG` | `False` | Enable debug mode |
| `MASTER_URL` | `http://localhost:5000` | Master server URL |
| `MASTER_TIMEOUT` | `30` | Master server request timeout (seconds) |

## Development Commands

### Run development server

```bash
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 5002
```

### Run with custom configuration

```bash
PORT=5003 MASTER_URL=http://example.com:5000 poetry run uvicorn app.main:app --reload
```

### Install new dependencies

```bash
poetry add <package-name>
```

### Update dependencies

```bash
poetry update
```

### View available scripts

```bash
poetry run --help
```

## Production Deployment

For production, use a production-grade ASGI server:

```bash
poetry run gunicorn app.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:5002
```

Or use the Uvicorn worker directly:

```bash
poetry run uvicorn app.main:app --host 0.0.0.0 --port 5002 --workers 4
```

## Architecture

### Communication Flows

1. **Master Sync**: Node ↔ Master (fetch karaoke data, sync state)
2. **Admin Control**: Admin App → Node (content management)
3. **Controller Interface**: Controller App ↔ Node (real-time karaoke control)

### Future Modules

- `app/services/master.py` - Master server communication client
- `app/services/karaoke.py` - Karaoke file management
- `app/models/karaoke.py` - Karaoke data models
- `app/api/karaoke.py` - Karaoke routes
- `app/api/admin.py` - Admin routes
- `app/api/controller.py` - Controller routes

## Contributing

1. Follow the existing code structure
2. Use type hints for all functions
3. Add docstrings to public functions
4. Keep dependencies minimal

## License

Part of the Singalong project
