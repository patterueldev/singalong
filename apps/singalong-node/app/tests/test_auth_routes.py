"""Tests for authentication routes"""

import jwt
import pytest

from app.models.db_models import AdminCredentials, PlayerCredentials
from app.services.auth_service import AuthService


class TestAuthRoutes:
    """Test suite for authentication routes"""

    def test_health_check(self, client):
        """Test health check endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"
        assert response.json()["service"] == "singalong-node"

    def test_root_endpoint(self, client):
        """Test root endpoint"""
        response = client.get("/")
        assert response.status_code == 200
        assert response.json()["message"] == "Singalong Node API"

    # Controller authentication tests
    def test_authenticate_controller_success(self, client, db):
        """Test successful controller authentication"""
        response = client.post(
            "/api/auth/controller",
            json={"nickname": "attendee1"},
        )

        assert response.status_code == 201
        data = response.json()
        assert data["access_token"]
        assert data["refresh_token"]
        assert data["role"] == "controller"
        assert data["expires_in"] > 0
        assert data["refresh_expires_in"] > 0
        assert data["token_type"] == "bearer"

    def test_authenticate_controller_duplicate(self, client, db):
        """Test controller authentication with duplicate nickname"""
        # First request succeeds
        response1 = client.post(
            "/api/auth/controller",
            json={"nickname": "attendee1"},
        )
        assert response1.status_code == 201

        # Second request with same nickname fails
        response2 = client.post(
            "/api/auth/controller",
            json={"nickname": "attendee1"},
        )
        assert response2.status_code == 409
        assert "already taken" in response2.json()["detail"]

    def test_authenticate_controller_invalid_request(self, client):
        """Test controller authentication with invalid request"""
        response = client.post(
            "/api/auth/controller",
            json={"nickname": ""},
        )
        assert response.status_code == 422

    def test_authenticate_controller_no_nickname(self, client):
        """Test controller authentication without nickname"""
        response = client.post(
            "/api/auth/controller",
            json={},
        )
        assert response.status_code == 422

    # Admin authentication tests
    def test_authenticate_admin_success(self, client, db):
        """Test successful admin authentication"""
        response = client.post(
            "/api/auth/admin",
            json={"username": "testadmin", "password": "adminpass123"},
        )

        assert response.status_code == 201
        data = response.json()
        assert data["access_token"]
        assert data["refresh_token"]
        assert data["role"] == "admin"
        assert data["expires_in"] > 0
        assert data["refresh_expires_in"] > 0

    def test_authenticate_admin_invalid_username(self, client, db):
        """Test admin authentication with invalid username"""
        response = client.post(
            "/api/auth/admin",
            json={"username": "invaliduser", "password": "anypassword"},
        )

        assert response.status_code == 401
        assert "Invalid admin credentials" in response.json()["detail"]

    def test_authenticate_admin_invalid_password(self, client, db):
        """Test admin authentication with invalid password"""
        response = client.post(
            "/api/auth/admin",
            json={"username": "testadmin", "password": "wrongpassword"},
        )

        assert response.status_code == 401
        assert "Invalid admin credentials" in response.json()["detail"]

    def test_authenticate_admin_no_credentials(self, client):
        """Test admin authentication without credentials"""
        response = client.post(
            "/api/auth/admin",
            json={},
        )
        assert response.status_code == 422

    # Player authentication tests
    def test_authenticate_player_success(self, client, db):
        """Test successful player authentication"""
        response = client.post(
            "/api/auth/player",
            json={"username": "testplayer", "password": "playerpass123"},
        )

        assert response.status_code == 201
        data = response.json()
        assert data["access_token"]
        assert data["refresh_token"]
        assert data["role"] == "player"
        assert data["expires_in"] > 0
        assert data["refresh_expires_in"] > 0

    def test_authenticate_player_invalid_username(self, client, db):
        """Test player authentication with invalid username"""
        response = client.post(
            "/api/auth/player",
            json={"username": "invaliduser", "password": "anypassword"},
        )

        assert response.status_code == 401
        assert "Invalid player credentials" in response.json()["detail"]

    def test_authenticate_player_invalid_password(self, client, db):
        """Test player authentication with invalid password"""
        response = client.post(
            "/api/auth/player",
            json={"username": "testplayer", "password": "wrongpassword"},
        )

        assert response.status_code == 401
        assert "Invalid player credentials" in response.json()["detail"]

    def test_authenticate_player_already_connected(self, client, db):
        """Test player authentication when another player is connected"""
        # First player connects
        response1 = client.post(
            "/api/auth/player",
            json={"username": "testplayer", "password": "playerpass123"},
        )
        assert response1.status_code == 201

        # Add second player credentials
        player_creds2 = PlayerCredentials(
            username="testplayer2",
            password_hash=AuthService.hash_password("playerpass456"),
        )
        db.add(player_creds2)
        db.commit()

        # Second player fails
        response2 = client.post(
            "/api/auth/player",
            json={"username": "testplayer2", "password": "playerpass456"},
        )
        assert response2.status_code == 409
        assert "already connected" in response2.json()["detail"]

    def test_authenticate_player_no_credentials(self, client):
        """Test player authentication without credentials"""
        response = client.post(
            "/api/auth/player",
            json={},
        )
        assert response.status_code == 422

    # Token refresh tests
    def test_refresh_token_success(self, client, db):
        """Test successful token refresh"""
        # First, authenticate to get tokens
        auth_response = client.post(
            "/api/auth/controller",
            json={"nickname": "attendee1"},
        )
        refresh_token = auth_response.json()["refresh_token"]

        # Refresh the token
        response = client.post(
            "/api/auth/refresh",
            json={"refresh_token": refresh_token},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["access_token"]
        assert data["refresh_token"]
        assert data["role"] == "controller"

    def test_refresh_token_invalid(self, client):
        """Test refresh with invalid refresh token"""
        response = client.post(
            "/api/auth/refresh",
            json={"refresh_token": "invalid.token.here"},
        )

        assert response.status_code == 401
        assert "Invalid refresh token" in response.json()["detail"]

    def test_refresh_token_with_access_token(self, client, db):
        """Test refresh with access token instead of refresh token"""
        # Get an access token
        auth_response = client.post(
            "/api/auth/controller",
            json={"nickname": "attendee1"},
        )
        access_token = auth_response.json()["access_token"]

        # Try to refresh with access token
        response = client.post(
            "/api/auth/refresh",
            json={"refresh_token": access_token},
        )

        assert response.status_code == 401
        assert "Invalid token type" in response.json()["detail"]

    def test_refresh_token_no_token(self, client):
        """Test refresh without refresh token"""
        response = client.post(
            "/api/auth/refresh",
            json={},
        )
        assert response.status_code == 422

    # Token structure tests
    def test_controller_token_structure(self, client, db):
        """Test that controller token has correct structure"""
        auth_response = client.post(
            "/api/auth/controller",
            json={"nickname": "attendee1"},
        )
        access_token = auth_response.json()["access_token"]

        # Decode the token (without verification for this test)
        payload = jwt.decode(access_token, options={"verify_signature": False})
        assert payload["role"] == "controller"
        assert payload["service_name"] == "singalong-node"
        assert payload["token_type"] == "access"
        assert "sub" in payload
        assert "exp" in payload
        assert "iat" in payload

    def test_admin_token_structure(self, client, db):
        """Test that admin token has correct structure"""
        auth_response = client.post(
            "/api/auth/admin",
            json={"username": "testadmin", "password": "adminpass123"},
        )
        access_token = auth_response.json()["access_token"]

        payload = jwt.decode(access_token, options={"verify_signature": False})
        assert payload["role"] == "admin"
        assert payload["service_name"] == "singalong-node"
        assert payload["token_type"] == "access"

    def test_player_token_structure(self, client, db):
        """Test that player token has correct structure"""
        auth_response = client.post(
            "/api/auth/player",
            json={"username": "testplayer", "password": "playerpass123"},
        )
        access_token = auth_response.json()["access_token"]

        payload = jwt.decode(access_token, options={"verify_signature": False})
        assert payload["role"] == "player"
        assert payload["service_name"] == "singalong-node"
        assert payload["token_type"] == "access"
