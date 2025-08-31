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

    db.init_app(app)

    from app.routes import data_routes

    app.register_blueprint(data_routes)

    with app.app_context():
        from app.models import Data  # noqa: F401

        db.create_all()

    return app
