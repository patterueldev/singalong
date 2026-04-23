"""Application configuration"""

import os
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # Server configuration
    host: str = os.getenv("HOST", "0.0.0.0")
    port: int = int(os.getenv("PORT", "5002"))
    debug: bool = os.getenv("DEBUG", "False").lower() == "true"

    # Master server configuration
    master_url: str = os.getenv("MASTER_URL", "http://localhost:5001")
    master_graphql_url: str = os.getenv(
        "MASTER_GRAPHQL_URL", "http://localhost:5001/graphql"
    )
    master_api_key: str = os.getenv("MASTER_API_KEY", "your-master-api-key")
    master_timeout: int = int(os.getenv("MASTER_TIMEOUT", "30"))

    # JWT Configuration
    jwt_secret_key: str = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
    jwt_algorithm: str = os.getenv("JWT_ALGORITHM", "HS256")
    jwt_access_token_expire_seconds: int = int(
        os.getenv("JWT_ACCESS_TOKEN_EXPIRE_SECONDS", 10800)  # 3 hours
    )
    jwt_refresh_token_expire_seconds: int = int(
        os.getenv("JWT_REFRESH_TOKEN_EXPIRE_SECONDS", 604800)  # 7 days
    )

    # Database configuration
    database_url: str = os.getenv("DATABASE_URL", "sqlite:///./singalong_node.db")

    # Service configuration
    service_name: str = "singalong-node"
    api_version: str = "v1"

    model_config = {"env_file": ".env", "case_sensitive": False}


settings = Settings()

