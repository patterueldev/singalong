"""
FastAPI application factory and configuration
"""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings"""

    app_name: str = "singalong-master"
    app_version: str = "0.1.0"
    debug: bool = os.getenv("DEBUG", "False").lower() == "true"
    port: int = int(os.getenv("PORT", 5001))
    host: str = os.getenv("HOST", "0.0.0.0")

    # API Key for service authentication
    master_api_key: str = os.getenv("MASTER_API_KEY", "")

    # JWT Configuration
    jwt_algorithm: str = os.getenv("JWT_ALGORITHM", "HS256")
    jwt_access_token_expire_seconds: int = int(
        os.getenv("JWT_ACCESS_TOKEN_EXPIRE_SECONDS", 3600)
    )
    jwt_refresh_token_expire_seconds: int = int(
        os.getenv("JWT_REFRESH_TOKEN_EXPIRE_SECONDS", 604800)
    )
    
    # User JWT Secret (for user tokens, separate from API key)
    user_jwt_secret: str = os.getenv("USER_JWT_SECRET", "dev-user-secret")

    class Config:
        env_file = ".env"


settings = Settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle"""
    # Startup
    print(f"Starting {settings.app_name} v{settings.app_version}")
    from app.database import init_db
    init_db()
    yield
    # Shutdown
    print(f"Shutting down {settings.app_name}")


def create_app() -> FastAPI:
    """Create and configure FastAPI application"""
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        debug=settings.debug,
        lifespan=lifespan,
    )

    # Add middleware
    from app.middleware.graphql_auth import GraphQLAuthMiddleware

    app.add_middleware(GraphQLAuthMiddleware)

    # Register routes
    from app.api.routes import router as auth_router

    app.include_router(auth_router)

    # GraphQL endpoint
    from app.graphql.schema import schema
    from ariadne.asgi import GraphQL

    graphql_app = GraphQL(schema)
    app.mount("/graphql", graphql_app)

    @app.get("/health", tags=["health"])
    async def health_check():
        """Health check endpoint"""
        return {
            "status": "healthy",
            "service": settings.app_name,
            "version": settings.app_version,
        }

    @app.get("/", tags=["root"])
    async def root():
        """Root endpoint"""
        return {
            "message": f"Welcome to {settings.app_name}",
            "version": settings.app_version,
        }

    return app


app = create_app()
