"""Tests for authentication service"""

import time

import jwt
import pytest

from app.models.db_models import AdminCredentials, PlayerCredentials, User, UserRole
from app.services.auth_service import AuthService


class TestAuthService:
    """Test suite for AuthService"""

    def test_hash_password(self, auth_service):
        """Test password hashing"""
        password = "testpassword123"
        hashed = AuthService.hash_password(password, rounds=4)

        assert hashed != password
        assert AuthService._verify_password(password, hashed)

    def test_hash_password_different_each_time(self):
        """Test that hashing produces different hashes each time"""
        password = "testpassword123"
        hash1 = AuthService.hash_password(password, rounds=4)
        hash2 = AuthService.hash_password(password, rounds=4)

        assert hash1 != hash2
        assert AuthService._verify_password(password, hash1)
        assert AuthService._verify_password(password, hash2)

    def test_verify_password_invalid(self, auth_service):
        """Test password verification with wrong password"""
        password = "testpassword123"
        hashed = AuthService.hash_password(password, rounds=4)

        assert not AuthService._verify_password("wrongpassword", hashed)

    def test_authenticate_controller_success(self, auth_service, db):
        """Test successful controller authentication"""
        access_token, refresh_token, role, access_expires, refresh_expires = (
            auth_service.authenticate_controller("testnickname", db)
        )

        assert access_token
        assert refresh_token
        assert role == UserRole.CONTROLLER
        assert access_expires == auth_service.access_token_expire_seconds
        assert refresh_expires == auth_service.refresh_token_expire_seconds

        # Verify user was created
        user = db.query(User).filter(User.nickname_or_username == "testnickname").first()
        assert user
        assert user.role == UserRole.CONTROLLER

    def test_authenticate_controller_duplicate_nickname(self, auth_service, db):
        """Test controller authentication with duplicate nickname"""
        auth_service.authenticate_controller("testnickname", db)

        with pytest.raises(ValueError, match="already taken"):
            auth_service.authenticate_controller("testnickname", db)

    def test_authenticate_admin_success(self, auth_service, db):
        """Test successful admin authentication"""
        admin_creds = AdminCredentials(
            username="admin_success_test",
            password_hash=AuthService.hash_password("adminpass123"),
        )
        db.add(admin_creds)
        db.commit()

        access_token, refresh_token, role, access_expires, refresh_expires = (
            auth_service.authenticate_admin("admin_success_test", "adminpass123", db)
        )

        assert access_token
        assert refresh_token
        assert role == UserRole.ADMIN
        assert access_expires == auth_service.access_token_expire_seconds
        assert refresh_expires == auth_service.refresh_token_expire_seconds

        # Verify user was created
        user = db.query(User).filter(User.nickname_or_username == "admin_success_test").first()
        assert user
        assert user.role == UserRole.ADMIN

    def test_authenticate_admin_invalid_username(self, auth_service, db):
        """Test admin authentication with invalid username"""
        with pytest.raises(ValueError, match="Invalid admin credentials"):
            auth_service.authenticate_admin("invaliduser", "anypassword", db)

    def test_authenticate_admin_invalid_password(self, auth_service, db):
        """Test admin authentication with invalid password"""
        admin_creds = AdminCredentials(
            username="admin_invalid_pwd",
            password_hash=AuthService.hash_password("adminpass123"),
        )
        db.add(admin_creds)
        db.commit()

        with pytest.raises(ValueError, match="Invalid admin credentials"):
            auth_service.authenticate_admin("admin_invalid_pwd", "wrongpassword", db)

    def test_authenticate_player_success(self, auth_service, db):
        """Test successful player authentication"""
        player_creds = PlayerCredentials(
            username="player_success_test",
            password_hash=AuthService.hash_password("playerpass123"),
        )
        db.add(player_creds)
        db.commit()

        access_token, refresh_token, role, access_expires, refresh_expires = (
            auth_service.authenticate_player("player_success_test", "playerpass123", db)
        )

        assert access_token
        assert refresh_token
        assert role == UserRole.PLAYER
        assert access_expires == auth_service.access_token_expire_seconds
        assert refresh_expires == auth_service.refresh_token_expire_seconds

        # Verify user was created
        user = db.query(User).filter(User.nickname_or_username == "player_success_test").first()
        assert user
        assert user.role == UserRole.PLAYER

    def test_authenticate_player_invalid_username(self, auth_service, db):
        """Test player authentication with invalid username"""
        with pytest.raises(ValueError, match="Invalid player credentials"):
            auth_service.authenticate_player("invaliduser", "anypassword", db)

    def test_authenticate_player_invalid_password(self, auth_service, db):
        """Test player authentication with invalid password"""
        player_creds = PlayerCredentials(
            username="player_invalid_pwd",
            password_hash=AuthService.hash_password("playerpass123"),
        )
        db.add(player_creds)
        db.commit()

        with pytest.raises(ValueError, match="Invalid player credentials"):
            auth_service.authenticate_player("player_invalid_pwd", "wrongpassword", db)

    def test_authenticate_player_already_connected(self, auth_service, db):
        """Test player authentication when another player is connected"""
        player_creds = PlayerCredentials(
            username="player_first",
            password_hash=AuthService.hash_password("playerpass123"),
        )
        db.add(player_creds)
        db.commit()

        # First player connects successfully
        auth_service.authenticate_player("player_first", "playerpass123", db)

        # Create second player credentials
        player_creds2 = PlayerCredentials(
            username="player_second",
            password_hash=AuthService.hash_password("playerpass456"),
        )
        db.add(player_creds2)
        db.commit()

        # Second player should fail
        with pytest.raises(ValueError, match="already connected"):
            auth_service.authenticate_player("player_second", "playerpass456", db)

    def test_validate_token_success(self, auth_service):
        """Test successful token validation"""
        access_token = auth_service._generate_token(
            user_id="test-user-id",
            role=UserRole.CONTROLLER,
            token_type="access",
            expires_in_seconds=3600,
        )

        payload = auth_service.validate_token(access_token)

        assert payload["sub"] == "test-user-id"
        assert payload["role"] == UserRole.CONTROLLER
        assert payload["service_name"] == "singalong-node"
        assert payload["token_type"] == "access"
        assert "expires_in" in payload

    def test_validate_token_expired(self, auth_service):
        """Test token validation with expired token"""
        access_token = auth_service._generate_token(
            user_id="test-user-id",
            role=UserRole.CONTROLLER,
            token_type="access",
            expires_in_seconds=-1,  # Already expired
        )

        with pytest.raises(jwt.ExpiredSignatureError):
            auth_service.validate_token(access_token)

    def test_validate_token_invalid(self, auth_service):
        """Test token validation with invalid token"""
        with pytest.raises(jwt.InvalidTokenError):
            auth_service.validate_token("invalid.token.here")

    def test_validate_token_wrong_service(self, auth_service):
        """Test token validation with wrong service name"""
        payload = {
            "sub": "test-user-id",
            "role": UserRole.CONTROLLER,
            "service_name": "wrong-service",
            "iat": int(time.time()),
            "exp": int(time.time()) + 3600,
            "token_type": "access",
        }
        token = jwt.encode(payload, auth_service.api_key, algorithm=auth_service.algorithm)

        with pytest.raises(jwt.InvalidTokenError, match="Invalid service name"):
            auth_service.validate_token(token)

    def test_refresh_token_success(self, auth_service, db):
        """Test successful token refresh"""
        refresh_token = auth_service._generate_token(
            user_id="test-user-id",
            role=UserRole.CONTROLLER,
            token_type="refresh",
            expires_in_seconds=604800,
        )

        new_access, new_refresh, role, access_expires, refresh_expires = (
            auth_service.refresh_token(refresh_token, db)
        )

        assert new_access
        assert new_refresh
        assert role == UserRole.CONTROLLER

    def test_refresh_token_expired(self, auth_service, db):
        """Test refresh with expired refresh token"""
        refresh_token = auth_service._generate_token(
            user_id="test-user-id",
            role=UserRole.CONTROLLER,
            token_type="refresh",
            expires_in_seconds=-1,  # Already expired
        )

        with pytest.raises(jwt.ExpiredSignatureError):
            auth_service.refresh_token(refresh_token, db)

    def test_refresh_token_wrong_type(self, auth_service, db):
        """Test refresh with access token instead of refresh token"""
        access_token = auth_service._generate_token(
            user_id="test-user-id",
            role=UserRole.CONTROLLER,
            token_type="access",
            expires_in_seconds=3600,
        )

        with pytest.raises(jwt.InvalidTokenError, match="Invalid token type"):
            auth_service.refresh_token(access_token, db)

    def test_generate_token_controller(self, auth_service):
        """Test token generation for controller role"""
        token = auth_service._generate_token(
            user_id="test-user-id",
            role=UserRole.CONTROLLER,
            token_type="access",
            expires_in_seconds=3600,
        )

        assert token
        payload = jwt.decode(token, auth_service.api_key, algorithms=[auth_service.algorithm])
        assert payload["role"] == UserRole.CONTROLLER

    def test_generate_token_admin(self, auth_service):
        """Test token generation for admin role"""
        token = auth_service._generate_token(
            user_id="test-user-id",
            role=UserRole.ADMIN,
            token_type="access",
            expires_in_seconds=3600,
        )

        assert token
        payload = jwt.decode(token, auth_service.api_key, algorithms=[auth_service.algorithm])
        assert payload["role"] == UserRole.ADMIN

    def test_generate_token_player(self, auth_service):
        """Test token generation for player role"""
        token = auth_service._generate_token(
            user_id="test-user-id",
            role=UserRole.PLAYER,
            token_type="access",
            expires_in_seconds=3600,
        )

        assert token
        payload = jwt.decode(token, auth_service.api_key, algorithms=[auth_service.algorithm])
        assert payload["role"] == UserRole.PLAYER
