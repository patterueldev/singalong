"""Tests for authentication service"""

import time

import jwt
import pytest

from app.main import settings
from app.services.auth_service import AuthService


@pytest.fixture
def auth_service():
    """Auth service instance for testing"""
    return AuthService(
        api_key=settings.master_api_key,
        algorithm=settings.jwt_algorithm,
        access_token_expire_seconds=3600,
        refresh_token_expire_seconds=604800,
    )


class TestAuthService:
    """Tests for AuthService"""

    def test_exchange_api_key(self, auth_service):
        """Test exchanging API key for tokens"""
        access_token, refresh_token, access_expires, refresh_expires = (
            auth_service.exchange_api_key()
        )

        # Verify tokens are strings
        assert isinstance(access_token, str)
        assert isinstance(refresh_token, str)

        # Verify expiry times
        assert access_expires == 3600
        assert refresh_expires == 604800

        # Verify tokens are valid JWT
        access_payload = jwt.decode(
            access_token, settings.master_api_key, algorithms=["HS256"]
        )
        refresh_payload = jwt.decode(
            refresh_token, settings.master_api_key, algorithms=["HS256"]
        )

        # Verify token types
        assert access_payload["token_type"] == "access"
        assert refresh_payload["token_type"] == "refresh"

    def test_token_has_correct_claims(self, auth_service):
        """Test that tokens have correct claims"""
        access_token, _, _, _ = auth_service.exchange_api_key()

        payload = jwt.decode(
            access_token, settings.master_api_key, algorithms=["HS256"]
        )

        assert payload["sub"] == "singalong-master"
        assert payload["service_name"] == "singalong-master"
        assert payload["token_type"] == "access"
        assert "iat" in payload
        assert "exp" in payload

    def test_validate_token(self, auth_service):
        """Test token validation"""
        access_token, _, _, _ = auth_service.exchange_api_key()

        payload = auth_service.validate_token(access_token)

        assert payload["sub"] == "singalong-master"
        assert payload["token_type"] == "access"
        assert "expires_in" in payload
        assert payload["expires_in"] > 0

    def test_validate_expired_token(self, auth_service):
        """Test validation of expired token"""
        # Create a token that expires immediately
        short_lived_service = AuthService(
            api_key=settings.master_api_key,
            access_token_expire_seconds=0,  # Expires immediately
        )
        expired_token, _, _, _ = short_lived_service.exchange_api_key()

        # Wait a moment to ensure expiry
        time.sleep(0.1)

        # Validation should fail
        with pytest.raises(jwt.ExpiredSignatureError):
            auth_service.validate_token(expired_token)

    def test_refresh_valid_token(self, auth_service):
        """Test refreshing a valid refresh token"""
        _, refresh_token, _, _ = auth_service.exchange_api_key()

        new_access, new_refresh, access_exp, refresh_exp = (
            auth_service.refresh_access_token(refresh_token)
        )

        # Verify new tokens are generated
        assert isinstance(new_access, str)
        assert isinstance(new_refresh, str)

        # Verify new tokens are different from old (at least access is different)
        assert new_access != refresh_token

        # Verify new tokens are valid
        access_payload = auth_service.validate_token(new_access)
        refresh_payload = jwt.decode(
            new_refresh, settings.master_api_key, algorithms=["HS256"]
        )

        assert access_payload["token_type"] == "access"
        assert refresh_payload["token_type"] == "refresh"

    def test_refresh_expired_token(self, auth_service):
        """Test refreshing with expired refresh token"""
        # Create a token that expires immediately
        short_lived_service = AuthService(
            api_key=settings.master_api_key,
            refresh_token_expire_seconds=0,
        )
        _, expired_refresh, _, _ = short_lived_service.exchange_api_key()

        # Wait for expiry
        time.sleep(0.1)

        # Refresh should fail
        with pytest.raises(jwt.ExpiredSignatureError):
            auth_service.refresh_access_token(expired_refresh)

    def test_refresh_invalid_token_type(self, auth_service):
        """Test refreshing with access token instead of refresh token"""
        access_token, _, _, _ = auth_service.exchange_api_key()

        # Try to refresh with access token (wrong type)
        with pytest.raises(jwt.InvalidTokenError):
            auth_service.refresh_access_token(access_token)

    def test_validate_wrong_service_name(self, auth_service):
        """Test validation fails with wrong service name in token"""
        from app.services.auth_service import AuthService

        # Create token with different service
        other_service = AuthService(
            api_key=settings.master_api_key,
        )
        other_service.service_name = "different-service"
        token, _, _, _ = other_service.exchange_api_key()

        # Create a fresh auth service that validates with correct service name
        # When validating with original auth_service, it should fail due to service name mismatch
        with pytest.raises(jwt.InvalidTokenError):
            auth_service.validate_token(token)
