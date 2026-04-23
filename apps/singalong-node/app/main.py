"""FastAPI application entry point"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import JSONResponse

from app.config import settings
from app.database import init_db
from app.api.routes import auth


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle"""
    # Startup
    print(f"Starting {settings.service_name}")
    print(f"Master server: {settings.master_url}")
    init_db()  # Initialize database
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
app.include_router(auth.router)


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

