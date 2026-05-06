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
    discovery_manager = PlayerDiscoveryManager.get_instance()
    print("✓ Player discovery manager initialized")
    
    # Restore player assignments from DB on startup
    # Players who were assigned at shutdown will be marked as "offline_but_assigned"
    from app.models.db_models import Session
    db_session = SessionLocal()
    try:
        assigned_sessions = db_session.query(Session).filter(
            Session.player_id.isnot(None),
            Session.status == "active"
        ).all()
        
        if assigned_sessions:
            node_logger = logging.getLogger(__name__)
            node_logger.info(
                f"[Startup] restoring_player_assignments | count={len(assigned_sessions)}"
            )
            for session in assigned_sessions:
                # Create placeholder PlayerInfo for restored assignment
                # Player will reconnect later via WebSocket or HTTP reconnect endpoint
                node_logger.info(
                    f"[Startup] restore_assignment | session={session.code} | "
                    f"player_id={session.player_id[:8]}...{session.player_id[-4:]} | "
                    f"name={session.player_name} | status=offline_but_assigned"
                )
                # Note: Don't create PlayerInfo objects here—just log
                # Player will register via WebSocket when it connects
    finally:
        db_session.close()
    
    # Initialize session cleanup job (removes stale player assignments)
    from app.services.session_cleanup_job import start_session_cleanup_job
    await start_session_cleanup_job()
    print("✓ Session cleanup job started (30s interval, 60s timeout)")
    
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

# CORS middleware using Starlette's built-in (much more reliable)
cors_origins = settings.get_cors_origins()
logging.info(f"CORS origins configured: {cors_origins}")
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static admin UI files
import os
from pathlib import Path
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

admin_static_path = Path(__file__).parent / "static" / "admin"
if admin_static_path.exists():
    @app.get("/admin", include_in_schema=False)
    async def admin_root():
        """Redirect /admin to /admin/"""
        from fastapi.responses import RedirectResponse
        return RedirectResponse(url="/admin/", status_code=301)
    
    @app.get("/admin/", include_in_schema=False)
    async def admin_index():
        """Serve admin UI"""
        return FileResponse(admin_static_path / "index.html", media_type="text/html")
    
    @app.get("/admin/{full_path:path}", include_in_schema=False)
    async def admin_static(full_path: str):
        """Serve static assets and handle SPA routing"""
        file_path = admin_static_path / full_path
        
        # Check if exact file exists
        if file_path.exists() and file_path.is_file():
            return FileResponse(file_path)
        
        # For any non-existent path (e.g., React routes), serve index.html for SPA
        return FileResponse(admin_static_path / "index.html", media_type="text/html")

# Include routers with /api prefix
from app.api.routes import auth, sessions, songs, players, websocket

app.include_router(auth.router, prefix="/api")
app.include_router(sessions.router, prefix="/api")
app.include_router(songs.router, prefix="/api")
app.include_router(players.router, prefix="/api")
# WebSocket routes are served at root level (/ws/*), not under /api
app.include_router(websocket.router)


@app.get("/health", tags=["Health"])
@app.get("/api/health", tags=["Health"])
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


