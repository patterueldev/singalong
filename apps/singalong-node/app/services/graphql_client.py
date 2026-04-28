"""GraphQL client for communicating with Master server"""

import logging
from typing import Optional

import httpx

logger = logging.getLogger(__name__)


class MasterGraphQLClient:
    """GraphQL client for Master authentication mutations"""

    AUTHENTICATE_CONTROLLER_MUTATION = """
    mutation AuthenticateController($nickname: String!, $sessionId: String!, $nodeId: String!) {
      authenticateController(nickname: $nickname, sessionId: $sessionId, nodeId: $nodeId) {
        token
        refreshToken
        user {
          id
          username
          role
          nickname
        }
      }
    }
    """

    AUTHENTICATE_ADMIN_MUTATION = """
    mutation AuthenticateAdmin($username: String!, $password: String!, $nodeId: String!) {
      authenticateAdmin(username: $username, password: $password, nodeId: $nodeId) {
        token
        refreshToken
        user {
          id
          username
          role
          nickname
        }
      }
    }
    """

    AUTHENTICATE_PLAYER_MUTATION = """
    mutation AuthenticatePlayer($sessionId: String!, $nodeId: String!) {
      authenticatePlayer(sessionId: $sessionId, nodeId: $nodeId) {
        token
        refreshToken
        user {
          id
          username
          role
          nickname
        }
      }
    }
    """

    def __init__(self, graphql_url: str, timeout: int = 30):
        """
        Initialize GraphQL client

        Args:
            graphql_url: Master GraphQL endpoint URL
            timeout: Request timeout in seconds
        """
        self.graphql_url = graphql_url
        self.timeout = timeout
        self._bearer_token: Optional[str] = None

    async def authenticate_controller(
        self, nickname: str, session_id: str, node_id: str
    ) -> dict:
        """
        Authenticate a controller user via Master GraphQL

        Args:
            nickname: Controller nickname
            session_id: 4-digit session ID
            node_id: Node UUID

        Returns:
            Response with token, refreshToken, and user info

        Raises:
            GraphQLError: If authentication fails
            HTTPException: If network error occurs
        """
        variables = {
            "nickname": nickname,
            "sessionId": session_id,
            "nodeId": node_id,
        }
        return await self._execute_mutation(
            self.AUTHENTICATE_CONTROLLER_MUTATION, variables
        )

    async def authenticate_admin(
        self, username: str, password: str, node_id: str
    ) -> dict:
        """
        Authenticate an admin user via Master GraphQL

        Args:
            username: Admin username
            password: Admin password
            node_id: Node UUID

        Returns:
            Response with token, refreshToken, and user info

        Raises:
            GraphQLError: If authentication fails
            HTTPException: If network error occurs
        """
        variables = {
            "username": username,
            "password": password,
            "nodeId": node_id,
        }
        return await self._execute_mutation(
            self.AUTHENTICATE_ADMIN_MUTATION, variables
        )

    async def authenticate_player(self, session_id: str, node_id: str) -> dict:
        """
        Authenticate a player user via Master GraphQL

        Args:
            session_id: 4-digit session ID
            node_id: Node UUID

        Returns:
            Response with token, refreshToken, and user info

        Raises:
            GraphQLError: If authentication fails
            HTTPException: If network error occurs
        """
        variables = {
            "sessionId": session_id,
            "nodeId": node_id,
        }
        return await self._execute_mutation(
            self.AUTHENTICATE_PLAYER_MUTATION, variables
        )

    async def _execute_mutation(self, query: str, variables: dict) -> dict:
        """
        Execute a GraphQL mutation

        Args:
            query: GraphQL query string
            variables: Variables for the query

        Returns:
            GraphQL response data

        Raises:
            GraphQLError: If GraphQL response contains errors
            HTTPException: If network error occurs
        """
        # Get fresh bearer token if needed
        await self._ensure_bearer_token()

        headers = {
            "Authorization": f"Bearer {self._bearer_token}",
            "Content-Type": "application/json",
        }

        payload = {
            "query": query,
            "variables": variables,
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout, follow_redirects=False) as client:
                response = await client.post(
                    self.graphql_url,
                    json=payload,
                    headers=headers,
                )
                response.raise_for_status()

                data = response.json()

                # Check for GraphQL errors
                if "errors" in data:
                    errors = data.get("errors", [])
                    error_msg = errors[0].get("message", "Unknown error") if errors else "Unknown error"
                    logger.error(f"GraphQL error: {error_msg}")
                    raise GraphQLError(error_msg)

                return data.get("data", {})

        except httpx.HTTPError as e:
            logger.error(f"HTTP error: {str(e)}")
            raise HTTPException(f"Failed to connect to Master: {str(e)}")

    async def _ensure_bearer_token(self):
        """
        Get the current bearer token from the MasterAuthManager

        The token is obtained during Node startup via initialize_master_auth().
        This method may refresh the token if it's about to expire.
        """
        from app.services.master_auth_manager import get_master_auth_manager
        
        auth_manager = get_master_auth_manager()
        self._bearer_token = await auth_manager.get_access_token()


class GraphQLError(Exception):
    """Raised when GraphQL mutation fails"""
    pass


class HTTPException(Exception):
    """Raised when HTTP request fails"""
    pass
