"""Flask application factory and configuration."""

from __future__ import annotations

from flask import Flask
from flask_sqlalchemy import SQLAlchemy

from app.config import config_dict

db = SQLAlchemy()


def create_app(config_name: str) -> Flask:
    """Create and configure the Flask application."""
    app = Flask(__name__)
    app.config.from_object(config_dict[config_name])

    # Initialize the database
    db.init_app(app)

    # Import blueprints/routes
    from app.routes import data_routes

    # Register blueprints
    app.register_blueprint(data_routes)

    # Create tables if they don't exist
    with app.app_context():
        # Import models to ensure they're registered
        from app.models import Data  # noqa: F401

        db.create_all()

    return app
