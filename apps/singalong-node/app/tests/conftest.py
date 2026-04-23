"""Test configuration and fixtures"""

import pytest
import tempfile
import os
from pathlib import Path
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Import models BEFORE creating engine
from app.models.db_models import (
    AdminCredentials,
    PlayerCredentials,
)
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

    # Create test admin and player credentials
    admin_creds = AdminCredentials(
        username="testadmin",
        password_hash=AuthService.hash_password("adminpass123"),
    )
    player_creds = PlayerCredentials(
        username="testplayer",
        password_hash=AuthService.hash_password("playerpass123"),
    )
    db.add(admin_creds)
    db.add(player_creds)
    db.commit()

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
    """Auth service with test configuration"""
    return AuthService(
        api_key="test-secret-key",
        algorithm="HS256",
        access_token_expire_seconds=3600,
        refresh_token_expire_seconds=604800,
    )











