"""FastAPI application entry point"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import JSONResponse

from app.config import settings
from app.database import init_db
from app.services.player_manager import PlayerManager


# Configure logging to output to console
logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)

# Ensure root logger outputs to console
root_logger = logging.getLogger()
if not root_logger.handlers:
    handler = logging.StreamHandler()
    handler.setFormatter(
        logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    )
    root_logger.addHandler(handler)
    root_logger.setLevel(logging.DEBUG if settings.debug else logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle"""
    # Startup
    print(f"Starting {settings.service_name}")
    print(f"Master server: {settings.master_url}")
    from app.database import init_db, SessionLocal
    from app.services.session_init import ensure_admin_session_exists
    from app.services.master_auth_manager import initialize_master_auth
    
    init_db()  # Initialize database
    
    # Exchange API key for JWT tokens with Master
    try:
        await initialize_master_auth(settings.master_url, settings.master_api_key)
    except Exception as e:
        print(f"WARNING: Failed to authenticate with Master: {str(e)}")
        print("NOTE: Continuing startup without Master connection (local testing mode)")
    
    # Initialize admin session 9999
    db = SessionLocal()
    try:
        ensure_admin_session_exists(db)
    finally:
        db.close()
    
    # Initialize player manager with valid API keys
    valid_keys = settings.get_valid_player_api_keys()
    PlayerManager.create_singleton(valid_keys)
    print(f"Player manager initialized with {len(valid_keys)} valid API key(s)")
    
    yield
    # Shutdown
    print(f"Shutting down {settings.service_name}")


app = FastAPI(
    title=settings.service_name,
    description="Local karaoke server for singalong system",
    version="0.1.0",
    lifespan=lifespan,
)

# Include routers
from app.api.routes import auth, sessions, songs, players

app.include_router(auth.router)
app.include_router(sessions.router)
app.include_router(songs.router)
app.include_router(players.router)


@app.get("/health", tags=["Health"])
async def health_check() -> JSONResponse:
    """Health check endpoint"""
    return JSONResponse(
        status_code=200,
        content={
            "status": "healthy",
            "service": settings.service_name,
            "master_url": settings.master_url,
        },
    )


@app.get("/", tags=["Root"])
async def root() -> JSONResponse:
    """Root endpoint"""
    return JSONResponse(
        status_code=200,
        content={
            "message": "Singalong Node API",
            "version": "0.1.0",
            "docs": "/docs",
        },
    )


