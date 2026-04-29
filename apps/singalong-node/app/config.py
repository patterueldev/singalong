"""Application configuration"""

import os
from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # Server configuration
    host: str = Field(default="0.0.0.0", validation_alias="HOST")
    port: int = Field(default=5002, validation_alias="PORT")
    debug: bool = Field(default=False, validation_alias="DEBUG")

    # Master server configuration
    master_url: str = Field(
        default="http://localhost:5001", validation_alias="MASTER_URL"
    )
    master_graphql_url: str = Field(
        default="http://localhost:5001/graphql",
        validation_alias="MASTER_GRAPHQL_URL",
    )
    # Node's API key for authenticating with Master
    master_api_key: str = Field(
        default="your-master-api-key", validation_alias="NODE_MASTER_API_KEY"
    )
    master_timeout: int = Field(default=30, validation_alias="MASTER_TIMEOUT")

    # JWT Configuration
    jwt_secret_key: str = Field(
        default="your-secret-key-change-in-production",
        validation_alias="JWT_SECRET_KEY",
    )
    jwt_algorithm: str = Field(default="HS256", validation_alias="JWT_ALGORITHM")
    jwt_access_token_expire_seconds: int = Field(
        default=10800, validation_alias="JWT_ACCESS_TOKEN_EXPIRE_SECONDS"
    )
    jwt_refresh_token_expire_seconds: int = Field(
        default=604800, validation_alias="JWT_REFRESH_TOKEN_EXPIRE_SECONDS"
    )

    # Database configuration
    database_url: str = Field(
        default="sqlite:///./singalong_node.db", validation_alias="DATABASE_URL"
    )

    # Player API Keys for registration validation (comma-separated)
    node_player_api_keys: str = Field(default="", validation_alias="NODE_PLAYER_API_KEYS")

    # OpenAI Configuration
    openai_api_key: str = Field(default="", validation_alias="OPENAI_API_KEY")

    # Service configuration
    service_name: str = "singalong-node"
    api_version: str = "v1"
    node_id: str = Field(
        default="550e8400-e29b-41d4-a716-446655440000", validation_alias="NODE_ID"
    )

    model_config = {"env_file": ".env", "case_sensitive": False, "extra": "ignore"}

    def get_valid_player_api_keys(self) -> list[str]:
        """Parse comma-separated player API keys from NODE_PLAYER_API_KEYS env var"""
        if not self.node_player_api_keys:
            return []
        return [key.strip() for key in self.node_player_api_keys.split(",") if key.strip()]


settings = Settings()


