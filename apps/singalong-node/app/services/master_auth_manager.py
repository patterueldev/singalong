"""Manager for Node-to-Master authentication tokens"""

import logging
import httpx
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)


class MasterAuthManager:
    """Manages authentication tokens for Node-to-Master communication"""

    def __init__(self, master_url: str, api_key: str, timeout: int = 30):
        """
        Initialize the auth manager

        Args:
            master_url: Master service base URL
            api_key: API key to exchange for tokens
            timeout: Request timeout in seconds
        """
        self.master_url = master_url
        self.api_key = api_key
        self.timeout = timeout
        self.access_token: str | None = None
        self.refresh_token: str | None = None
        self.token_expires_at: datetime | None = None

    async def initialize(self) -> None:
        """
        Exchange API key for JWT tokens during Node startup

        This is called once when the Node starts up and should succeed before
        the Node begins serving requests.

        Raises:
            Exception: If token exchange fails
        """
        logger.info(f"Exchanging API key for JWT tokens with Master")
        logger.debug(f"Using API key: '{self.api_key}'")
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.master_url}/api/auth/exchange",
                    json={"api_key": self.api_key},
                )
                response.raise_for_status()

                data = response.json()
                self.access_token = data.get("access_token")
                self.refresh_token = data.get("refresh_token")
                expires_in = data.get("expires_in", 3600)

                if not self.access_token:
                    raise ValueError("Master returned no access_token")

                # Calculate when token expires
                self.token_expires_at = datetime.utcnow() + timedelta(seconds=expires_in)

                logger.info(
                    f"Successfully obtained JWT tokens from Master. Token expires at {self.token_expires_at}"
                )

        except httpx.HTTPError as e:
            logger.error(f"Failed to obtain tokens from Master: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Error during token exchange: {str(e)}")
            raise

    async def get_access_token(self) -> str:
        """
        Get the current access token, refreshing if necessary

        Returns:
            Valid JWT access token

        Raises:
            ValueError: If no token is available
            Exception: If token refresh fails
        """
        if not self.access_token:
            raise ValueError("No access token available. Did you call initialize()?")

        # Check if token is about to expire (refresh 5 minutes before expiry)
        if self.token_expires_at:
            time_until_expiry = self.token_expires_at - datetime.utcnow()
            if time_until_expiry < timedelta(minutes=5):
                logger.info("Access token expiring soon, refreshing...")
                await self._refresh_access_token()

        return self.access_token

    async def _refresh_access_token(self) -> None:
        """Refresh the access token using the refresh token"""
        if not self.refresh_token:
            raise ValueError("No refresh token available")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.master_url}/api/auth/refresh",
                    json={"refresh_token": self.refresh_token},
                )
                response.raise_for_status()

                data = response.json()
                self.access_token = data.get("access_token")
                self.refresh_token = data.get("refresh_token")
                expires_in = data.get("expires_in", 3600)

                if not self.access_token:
                    raise ValueError("Master returned no access_token during refresh")

                self.token_expires_at = datetime.utcnow() + timedelta(seconds=expires_in)

                logger.info(f"Successfully refreshed JWT tokens. New expiry: {self.token_expires_at}")

        except httpx.HTTPError as e:
            logger.error(f"Failed to refresh tokens: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Error during token refresh: {str(e)}")
            raise


# Global instance
_master_auth_manager: MasterAuthManager | None = None


def get_master_auth_manager() -> MasterAuthManager:
    """Get the global MasterAuthManager instance"""
    global _master_auth_manager
    if _master_auth_manager is None:
        raise RuntimeError("MasterAuthManager not initialized. Did you call initialize_master_auth()?")
    return _master_auth_manager


async def initialize_master_auth(master_url: str, api_key: str) -> MasterAuthManager:
    """Initialize the global MasterAuthManager"""
    global _master_auth_manager
    _master_auth_manager = MasterAuthManager(master_url, api_key)
    await _master_auth_manager.initialize()
    return _master_auth_manager
