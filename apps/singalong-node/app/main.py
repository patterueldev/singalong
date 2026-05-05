"""FastAPI application entry point"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from starlette.middleware.cors import CORSMiddleware

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
    from app.services.master_websocket_client import get_master_websocket_client
    from app.services.master_event_handlers import MasterEventHandlers
    import asyncio
    
    init_db()  # Initialize database
    
    # Exchange API key for JWT tokens with Master
    try:
        await initialize_master_auth(settings.master_url, settings.master_api_key)
    except Exception as e:
        print(f"FATAL: Failed to authenticate with Master: {str(e)}")
        raise
    
    # Initialize admin session 9999 and cleanup extra sessions
    db = SessionLocal()
    try:
        ensure_admin_session_exists(db)
        # Deactivate old sessions (>24h) except whitelisted ones
        from app.services.session_init import cleanup_node_sessions
        cleanup_node_sessions(db, allowed_codes=["9999"])
    finally:
        db.close()
    

    # Initialize player discovery manager
    from app.services.player_discovery_manager import PlayerDiscoveryManager
    PlayerDiscoveryManager.get_instance()
    print("✓ Player discovery manager initialized")
    
    # Initialize WebSocket services (Event Bus, Connection Manager, etc.)
    from app.services.websocket_service_container import init_websocket_services
    service_container = init_websocket_services()
    print("✓ WebSocket services initialized (EventBus, ConnectionManager, BroadcastService)")
    
    # Initialize WebSocket client for Master communication
    ws_client = get_master_websocket_client()
    ws_client.register_handler("download:progress", MasterEventHandlers.handle_download_progress)
    ws_client.register_handler("download:complete", MasterEventHandlers.handle_download_complete)
    ws_client.register_handler("catalog:updated", MasterEventHandlers.handle_catalog_updated)
    ws_client.register_handler("system:health", MasterEventHandlers.handle_system_health)
    
    # Connect to Master WebSocket and start listening
    if await ws_client.connect():
        # Start listening task in background
        listen_task = asyncio.create_task(ws_client.listen())
        print("✓ Master WebSocket client initialized and listening")
    else:
        print("⚠ Failed to connect to Master WebSocket (will retry)")
        listen_task = None
    
    yield
    # Shutdown
    print(f"Shutting down {settings.service_name}")
    
    # Stop mDNS broadcasting
    if mdns_bridge_service:
        try:
            mdns_bridge_service.stop()
        except Exception as e:
            print(f"⚠ Error stopping mDNS broadcasting: {e}")
    
    if ws_client:
        await ws_client.disconnect()
    if listen_task and not listen_task.done():
        listen_task.cancel()
        try:
            await listen_task
        except asyncio.CancelledError:
            pass


app = FastAPI(
    title=settings.service_name,
    description="Local karaoke server for singalong system",
    version="0.1.0",
    lifespan=lifespan,
)

# Mount static admin UI files
import os
from pathlib import Path
from fastapi.staticfiles import StaticFiles

admin_static_path = Path(__file__).parent / "static" / "admin"
if admin_static_path.exists():
    from fastapi.responses import FileResponse
    
    @app.get("/admin", include_in_schema=False)
    async def admin_root():
        """Redirect /admin to /admin/"""
        return FileResponse(admin_static_path / "index.html", media_type="text/html")
    
    @app.get("/admin/", include_in_schema=False)
    async def admin_index():
        """Serve admin UI"""
        return FileResponse(admin_static_path / "index.html", media_type="text/html")
    
    # Mount static files (assets, etc.)
    app.mount("/admin", StaticFiles(directory=str(admin_static_path)), name="admin")

# Include routers
from app.api.routes import auth, sessions, songs, players, websocket

app.include_router(auth.router)
app.include_router(sessions.router)
app.include_router(songs.router)
app.include_router(players.router)
app.include_router(websocket.router)


# CORS middleware
@app.middleware("http")
async def cors_middleware(request, call_next):
    """Handle CORS for requests"""
    origin = request.headers.get("origin")
    
    # List of allowed origins
    allowed_origins = [
        "http://localhost:3001",
        "http://localhost:3002",
        "https://singalongadmin-dev.nicenature.space",
        "https://singalongcontroller-dev.nicenature.space",
    ]
    
    # Check if origin is allowed
    if origin in allowed_origins or origin and any(origin.startswith(ao) for ao in allowed_origins):
        # Handle preflight OPTIONS request
        if request.method == "OPTIONS":
            from fastapi.responses import Response
            return Response(
                headers={
                    "Access-Control-Allow-Origin": origin,
                    "Access-Control-Allow-Credentials": "true",
                    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type, Authorization",
                }
            )
        
        # Handle actual request
        response = await call_next(request)
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Access-Control-Allow-Credentials"] = "true"
        return response
    
    # If origin not allowed, process normally
    return await call_next(request)


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


