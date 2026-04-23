"""Test configuration and fixtures"""

import pytest
import tempfile
import os
from pathlib import Path
from unittest.mock import AsyncMock, patch
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Import models BEFORE creating engine
from app.database import Base, get_db
from app.main import app
from app.services.auth_service import AuthService


# Create a temporary directory for test databases
test_db_dir = tempfile.mkdtemp()


@pytest.fixture(scope="function")
def test_db_path():
    """Create a temporary database file for each test"""
    db_file = os.path.join(test_db_dir, f"test_{id(pytest)}.db")
    yield db_file
    # Clean up
    if os.path.exists(db_file):
        os.remove(db_file)


def create_test_engine_and_session(db_path):
    """Create test engine and session for a specific database file"""
    SQLALCHEMY_DATABASE_URL = f"sqlite:///{db_path}"

    test_engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        connect_args={"check_same_thread": False},
    )

    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)
    
    # Create all tables
    Base.metadata.create_all(bind=test_engine)

    return test_engine, TestingSessionLocal


@pytest.fixture(scope="function")
def db(test_db_path):
    """Get database session for tests"""
    test_engine, TestingSessionLocal = create_test_engine_and_session(test_db_path)

    # Override get_db to use test session
    def override_get_db_local():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    # Save the original override so we can restore it
    original_override = app.dependency_overrides.get(get_db)
    app.dependency_overrides[get_db] = override_get_db_local

    db = TestingSessionLocal()

    yield db

    db.close()

    # Restore the original override
    if original_override:
        app.dependency_overrides[get_db] = original_override
    else:
        del app.dependency_overrides[get_db]


@pytest.fixture
def client(db):
    """FastAPI test client with db setup"""
    return TestClient(app)


@pytest.fixture
def auth_service():
    """Auth service with test configuration and mocked GraphQL client"""
    with patch("app.services.auth_service.MasterGraphQLClient") as mock_client_class:
        mock_graphql_client = AsyncMock()
        mock_client_class.return_value = mock_graphql_client
        
        service = AuthService(
            api_key="test-secret-key",
            algorithm="HS256",
            access_token_expire_seconds=3600,
            refresh_token_expire_seconds=604800,
        )
        service.graphql_client = mock_graphql_client
        return service


@pytest.fixture
def mock_graphql_responses():
    """Mock GraphQL responses for different auth scenarios"""
    return {
        "authenticate_controller_success": {
            "authenticateController": {
                "token": "mock-user-token",
                "refreshToken": "mock-refresh-token",
                "user": {
                    "id": "550e8400-e29b-41d4-a716-446655440000",
                    "username": None,
                    "role": "controller",
                    "nickname": "testuser"
                }
            }
        },
        "authenticate_admin_success": {
            "authenticateAdmin": {
                "token": "mock-admin-token",
                "refreshToken": "mock-refresh-token",
                "user": {
                    "id": "550e8400-e29b-41d4-a716-446655440001",
                    "username": "testadmin",
                    "role": "admin",
                    "nickname": None
                }
            }
        },
        "authenticate_player_success": {
            "authenticatePlayer": {
                "token": "mock-player-token",
                "refreshToken": "mock-refresh-token",
                "user": {
                    "id": "550e8400-e29b-41d4-a716-446655440002",
                    "username": None,
                    "role": "player",
                    "nickname": None
                }
            }
        }
    }







