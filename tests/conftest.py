"""Test configuration and fixtures for the Flask application."""

from __future__ import annotations

import tempfile
from collections.abc import Generator
from pathlib import Path

import pytest
from flask import Flask
from flask.testing import FlaskClient

from app import create_app, db
from app.config import Config
from app.models import Data


class TestConfig(Config):
    """Test configuration class."""

    TESTING: bool = True
    DEBUG: bool = True
    WTF_CSRF_ENABLED: bool = False

    # Use in-memory SQLite database for tests
    SQLALCHEMY_DATABASE_URI: str = "sqlite:///:memory:"
    SQLALCHEMY_TRACK_MODIFICATIONS: bool = False

    # Create a temporary directory for test files
    TEMP_DIR: Path = Path(tempfile.mkdtemp())

    # Test-specific settings
    SECRET_KEY: str = "test-secret-key"
    SERVER_NAME: str = "localhost"


@pytest.fixture(scope="function")
def app() -> Generator[Flask, None, None]:
    """Create and configure a test Flask application."""
    # Temporarily add TestConfig to config_dict
    from app.config import config_dict

    config_dict["testing"] = TestConfig

    # Create app with test configuration
    test_app = create_app("testing")

    # Create application context
    with test_app.app_context():
        # Create all database tables
        db.create_all()
        yield test_app
        # Clean up database
        db.session.remove()
        db.drop_all()


@pytest.fixture(scope="function")
def client(app: Flask) -> FlaskClient:
    """Create a test client for the Flask application."""
    return app.test_client()


@pytest.fixture(scope="function")
def sample_data(app: Flask) -> Generator[Data, None, None]:
    """Create sample data for testing."""
    with app.app_context():
        data = Data(name="Test User")
        db.session.add(data)
        db.session.commit()

        # Refresh to get the ID
        db.session.refresh(data)
        yield data

        # Clean up is handled by the app fixture


@pytest.fixture(scope="function")
def multiple_data(app: Flask) -> Generator[list[Data], None, None]:
    """Create multiple sample data entries for testing."""
    with app.app_context():
        data_list = [
            Data(name="User 1"),
            Data(name="User 2"),
            Data(name="User 3"),
        ]

        for data in data_list:
            db.session.add(data)
        db.session.commit()

        # Refresh to get the IDs
        for data in data_list:
            db.session.refresh(data)

        yield data_list
