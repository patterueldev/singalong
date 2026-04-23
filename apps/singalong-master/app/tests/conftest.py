"""Pytest configuration and fixtures"""

import os

import pytest
from fastapi.testclient import TestClient

# Set test environment variables before importing app
os.environ["MASTER_API_KEY"] = "test-key"
os.environ["DEBUG"] = "True"


@pytest.fixture
def client():
    """FastAPI test client"""
    from app.main import app

    return TestClient(app)


@pytest.fixture
def valid_api_key():
    """Valid API key from environment"""
    return os.environ.get("MASTER_API_KEY")
