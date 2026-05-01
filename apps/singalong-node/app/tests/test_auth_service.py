"""Tests for Node auth service with Master GraphQL integration"""

import pytest
from unittest.mock import AsyncMock, patch
from app.services.auth_service import AuthService, GraphQLError
from app.services.graphql_client import HTTPException
from app.models.db_models import UserRole, User


class TestAuthServiceControllerAuth:
    """Test controller authentication via Master GraphQL"""

    @pytest.mark.asyncio
    async def test_authenticate_controller_success(self, db, auth_service, mock_graphql_responses):
        """Controller auth should call Master GraphQL and create local user cache"""
        auth_service.graphql_client.authenticate_controller = AsyncMock(
            return_value=mock_graphql_responses["authenticate_controller_success"]
        )

        # Authenticate
        access_token, refresh_token, role, access_expires, refresh_expires = (
            await auth_service.authenticate_controller(
                nickname="testuser",
                session_id="1234",
                node_id="node-uuid",
                db=db,
            )
        )

        # Verify tokens were generated
        assert access_token is not None
        assert refresh_token is not None
        assert role == UserRole.CONTROLLER
        assert access_expires == 3600
        assert refresh_expires == 604800

        # Verify GraphQL client was called
        auth_service.graphql_client.authenticate_controller.assert_called_once_with(
            nickname="testuser",
            session_id="1234",
            node_id="node-uuid",
        )

        # Verify user was cached locally
        user = db.query(User).filter(User.nickname_or_username == "testuser").first()
        assert user is not None
        assert user.role == UserRole.CONTROLLER

    @pytest.mark.asyncio
    async def test_authenticate_controller_graphql_failure(self, db, auth_service):
        """Controller auth should raise ValueError if Master GraphQL fails"""
        auth_service.graphql_client.authenticate_controller = AsyncMock(
            side_effect=GraphQLError("Invalid nickname")
        )

        with pytest.raises(ValueError, match="Failed to authenticate controller"):
            await auth_service.authenticate_controller(
                nickname="testuser",
                session_id="1234",
                node_id="node-uuid",
                db=db,
            )


class TestAuthServiceAdminAuth:
    """Test admin authentication via Master GraphQL"""

    @pytest.mark.asyncio
    async def test_authenticate_admin_success(self, db, auth_service, mock_graphql_responses):
        """Admin auth should call Master GraphQL and create local user cache"""
        auth_service.graphql_client.authenticate_admin = AsyncMock(
            return_value=mock_graphql_responses["authenticate_admin_success"]
        )

        # Authenticate
        access_token, refresh_token, role, access_expires, refresh_expires = (
            await auth_service.authenticate_admin(
                username="testadmin",
                password="adminpass",
                node_id="node-uuid",
                db=db,
            )
        )

        # Verify tokens were generated
        assert access_token is not None
        assert refresh_token is not None
        assert role == UserRole.ADMIN
        assert access_expires == 3600
        assert refresh_expires == 604800

        # Verify GraphQL client was called
        auth_service.graphql_client.authenticate_admin.assert_called_once_with(
            username="testadmin",
            password="adminpass",
            node_id="node-uuid",
        )

        # Verify user was cached locally
        user = db.query(User).filter(User.nickname_or_username == "testadmin").first()
        assert user is not None
        assert user.role == UserRole.ADMIN

    @pytest.mark.asyncio
    async def test_authenticate_admin_invalid_credentials(self, db, auth_service):
        """Admin auth should raise ValueError if Master GraphQL rejects credentials"""
        auth_service.graphql_client.authenticate_admin = AsyncMock(
            side_effect=GraphQLError("Invalid credentials")
        )

        with pytest.raises(ValueError, match="Failed to authenticate admin"):
            await auth_service.authenticate_admin(
                username="testadmin",
                password="wrongpass",
                node_id="node-uuid",
                db=db,
            )


class TestAuthServicePlayerAuth:
    """Test player authentication via Master GraphQL"""

    @pytest.mark.asyncio
    async def test_authenticate_player_success(self, db, auth_service, mock_graphql_responses):
        """Player auth should call Master GraphQL and create local user cache"""
        auth_service.graphql_client.authenticate_player = AsyncMock(
            return_value=mock_graphql_responses["authenticate_player_success"]
        )

        # Authenticate
        access_token, refresh_token, role, access_expires, refresh_expires = (
            await auth_service.authenticate_player(
                session_id="1234",
                node_id="node-uuid",
                db=db,
            )
        )

        # Verify tokens were generated
        assert access_token is not None
        assert refresh_token is not None
        assert role == UserRole.PLAYER
        assert access_expires == 3600
        assert refresh_expires == 604800

        # Verify GraphQL client was called
        auth_service.graphql_client.authenticate_player.assert_called_once_with(
            session_id="1234",
            node_id="node-uuid",
        )

    @pytest.mark.asyncio
    async def test_authenticate_player_already_connected(self, db, auth_service, mock_graphql_responses):
        """Player auth should fail if another player is already connected (local rule)"""
        from app.models.db_models import PlayerConnection
        import uuid
        
        # Create existing player connection with valid UUID
        existing_connection = PlayerConnection(
            player_id=uuid.uuid4()
        )
        db.add(existing_connection)
        db.commit()

        with pytest.raises(ValueError, match="Another player is already connected"):
            await auth_service.authenticate_player(
                session_id="1234",
                node_id="node-uuid",
                db=db,
            )

        # GraphQL should NOT have been called
        auth_service.graphql_client.authenticate_player.assert_not_called()


class TestAuthServiceTokenRefresh:
    """Test token refresh functionality"""

    def test_refresh_token_success(self, db, auth_service):
        """Refresh token should generate new tokens with same role"""
        # Generate initial token
        initial_token = auth_service._generate_token(
            user_id="user-123",
            role=UserRole.CONTROLLER,
            token_type="refresh",
            expires_in_seconds=604800,
        )

        # Refresh
        access_token, refresh_token, role, access_expires, refresh_expires = (
            auth_service.refresh_token(initial_token, db)
        )

        # Verify new tokens
        assert access_token is not None
        assert refresh_token is not None
        assert role == UserRole.CONTROLLER
        assert access_expires == 3600
        assert refresh_expires == 604800

    def test_refresh_token_invalid(self, db, auth_service):
        """Refresh token should reject invalid tokens"""
        import jwt

        with pytest.raises(jwt.InvalidTokenError):
            auth_service.refresh_token("invalid-token", db)


class TestAuthServiceTokenValidation:
    """Test token validation"""

    def test_validate_token_success(self, auth_service):
        """Valid token should pass validation"""
        # Generate token
        token = auth_service._generate_token(
            user_id="user-123",
            role=UserRole.CONTROLLER,
            token_type="access",
            expires_in_seconds=3600,
        )

        # Validate
        payload = auth_service.validate_token(token)
        assert payload["sub"] == "user-123"
        assert payload["role"] == UserRole.CONTROLLER
        assert payload["expires_in"] > 0

    def test_validate_token_invalid(self, auth_service):
        """Invalid token should raise error"""
        import jwt

        with pytest.raises(jwt.InvalidTokenError):
            auth_service.validate_token("invalid-token")
