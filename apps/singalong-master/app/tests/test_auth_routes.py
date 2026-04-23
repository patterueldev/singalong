"""Tests for authentication API routes"""

import json

import jwt
import pytest

from app.main import settings


class TestAuthRoutes:
    """Tests for /api/auth endpoints"""

    def test_exchange_valid_api_key(self, client, valid_api_key):
        """Test exchanging valid API key for tokens"""
        response = client.post(
            "/api/auth/exchange",
            json={"api_key": valid_api_key},
        )

        assert response.status_code == 200
        data = response.json()

        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "Bearer"
        assert data["expires_in"] == 3600
        assert data["refresh_expires_in"] == 604800

    def test_exchange_invalid_api_key(self, client):
        """Test exchanging invalid API key"""
        # Use a valid length key but wrong value
        wrong_key = "a" * 32
        response = client.post(
            "/api/auth/exchange",
            json={"api_key": wrong_key},
        )

        assert response.status_code == 401
        assert "Invalid API key" in response.json()["detail"]

    def test_exchange_missing_api_key(self, client):
        """Test exchanging with missing API key"""
        response = client.post(
            "/api/auth/exchange",
            json={},
        )

        assert response.status_code == 422  # Validation error

    def test_exchange_short_api_key(self, client):
        """Test exchanging with too-short API key"""
        response = client.post(
            "/api/auth/exchange",
            json={"api_key": "short"},
        )

        assert response.status_code == 422  # Validation error

    def test_refresh_valid_token(self, client, valid_api_key):
        """Test refreshing with valid refresh token"""
        # First, exchange for tokens
        exchange_response = client.post(
            "/api/auth/exchange",
            json={"api_key": valid_api_key},
        )
        refresh_token = exchange_response.json()["refresh_token"]

        # Now refresh
        response = client.post(
            "/api/auth/refresh",
            json={"refresh_token": refresh_token},
        )

        assert response.status_code == 200
        data = response.json()

        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "Bearer"

    def test_refresh_invalid_token(self, client):
        """Test refreshing with invalid token"""
        response = client.post(
            "/api/auth/refresh",
            json={"refresh_token": "invalid-token"},
        )

        assert response.status_code == 401
        assert "Invalid refresh token" in response.json()["detail"]

    def test_refresh_access_token(self, client, valid_api_key):
        """Test refreshing with access token (should fail)"""
        # Get access token
        exchange_response = client.post(
            "/api/auth/exchange",
            json={"api_key": valid_api_key},
        )
        access_token = exchange_response.json()["access_token"]

        # Try to refresh with access token
        response = client.post(
            "/api/auth/refresh",
            json={"refresh_token": access_token},
        )

        assert response.status_code == 401
        assert "Invalid refresh token" in response.json()["detail"]

    def test_validate_valid_token(self, client, valid_api_key):
        """Test validating a valid access token"""
        # Get access token
        exchange_response = client.post(
            "/api/auth/exchange",
            json={"api_key": valid_api_key},
        )
        access_token = exchange_response.json()["access_token"]

        # Validate token
        response = client.get(
            "/api/auth/validate",
            headers={"Authorization": f"Bearer {access_token}"},
        )

        assert response.status_code == 200
        data = response.json()

        assert data["status"] == "valid"
        assert data["sub"] == "singalong-master"
        assert "iat" in data
        assert "exp" in data
        assert "expires_in" in data
        assert data["expires_in"] > 0

    def test_validate_missing_header(self, client):
        """Test validation without Authorization header"""
        response = client.get("/api/auth/validate")

        assert response.status_code == 401
        assert "Missing Authorization header" in response.json()["detail"]

    def test_validate_invalid_token(self, client):
        """Test validating invalid token"""
        response = client.get(
            "/api/auth/validate",
            headers={"Authorization": "Bearer invalid-token"},
        )

        assert response.status_code == 401
        assert "Invalid token" in response.json()["detail"]

    def test_validate_expired_token(self, client):
        """Test validating expired token"""
        # Create a short-lived token
        from app.services.auth_service import AuthService

        auth_service = AuthService(
            api_key=settings.master_api_key,
            access_token_expire_seconds=0,
        )
        expired_token, _, _, _ = auth_service.exchange_api_key()

        # Validate (should fail)
        response = client.get(
            "/api/auth/validate",
            headers={"Authorization": f"Bearer {expired_token}"},
        )

        assert response.status_code == 401
        assert "Invalid token" in response.json()["detail"]

    def test_validate_with_malformed_header(self, client):
        """Test validation with malformed Authorization header"""
        response = client.get(
            "/api/auth/validate",
            headers={"Authorization": "NotBearer token"},
        )

        assert response.status_code == 401

    def test_token_contains_correct_service_name(self, client, valid_api_key):
        """Test that tokens contain correct service name"""
        response = client.post(
            "/api/auth/exchange",
            json={"api_key": valid_api_key},
        )
        access_token = response.json()["access_token"]

        # Decode token manually
        payload = jwt.decode(
            access_token, settings.master_api_key, algorithms=["HS256"]
        )

        assert payload["service_name"] == "singalong-master"
        assert payload["sub"] == "singalong-master"

    def test_multiple_token_exchanges(self, client, valid_api_key):
        """Test that multiple exchanges generate different tokens with different iat timestamps"""
        import time

        response1 = client.post(
            "/api/auth/exchange",
            json={"api_key": valid_api_key},
        )
        token1 = response1.json()["access_token"]

        # Wait at least 1 second to ensure different iat
        time.sleep(1.01)

        response2 = client.post(
            "/api/auth/exchange",
            json={"api_key": valid_api_key},
        )
        token2 = response2.json()["access_token"]

        # Tokens should be different (different iat timestamps)
        assert token1 != token2

        # Both should be valid
        assert client.get(
            "/api/auth/validate",
            headers={"Authorization": f"Bearer {token1}"},
        ).status_code == 200

        assert client.get(
            "/api/auth/validate",
            headers={"Authorization": f"Bearer {token2}"},
        ).status_code == 200

    def test_refresh_generates_new_refresh_token(self, client, valid_api_key):
        """Test that refreshing generates a new refresh token"""
        import time

        # Get initial tokens
        response1 = client.post(
            "/api/auth/exchange",
            json={"api_key": valid_api_key},
        )
        refresh_token_1 = response1.json()["refresh_token"]

        # Wait to ensure different iat
        time.sleep(1.01)

        # Refresh
        response2 = client.post(
            "/api/auth/refresh",
            json={"refresh_token": refresh_token_1},
        )
        refresh_token_2 = response2.json()["refresh_token"]

        # Tokens should be different
        assert refresh_token_1 != refresh_token_2

        # New refresh token should be valid
        response3 = client.post(
            "/api/auth/refresh",
            json={"refresh_token": refresh_token_2},
        )
        assert response3.status_code == 200
