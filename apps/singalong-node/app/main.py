"""FastAPI application entry point"""

from fastapi import FastAPI
from fastapi.responses import JSONResponse

from app.config import settings

app = FastAPI(
    title=settings.service_name,
    description="Local karaoke server for singalong system",
    version="0.1.0",
)


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


@app.on_event("startup")
async def startup_event():
    """Application startup event"""
    print(f"Starting {settings.service_name} on {settings.host}:{settings.port}")
    print(f"Master server: {settings.master_url}")


@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown event"""
    print(f"Shutting down {settings.service_name}")
