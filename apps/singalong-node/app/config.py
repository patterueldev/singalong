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
    master_url: str = os.getenv("MASTER_URL", "http://localhost:5000")
    master_timeout: int = int(os.getenv("MASTER_TIMEOUT", "30"))

    # Service configuration
    service_name: str = "singalong-node"
    api_version: str = "v1"

    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
