"""Configuration settings for the Flask application."""

from __future__ import annotations

import os


class Config:
    """Base configuration class."""

    SECRET_KEY: str = os.environ.get("SECRET_KEY", "your_secret_key")

    SQLALCHEMY_DATABASE_URI: str | None = os.environ.get("DATABASE_URI")
    SQLALCHEMY_TRACK_MODIFICATIONS: bool = False


class DevelopmentConfig(Config):
    """Development configuration."""

    DEBUG: bool = True


class ProductionConfig(Config):
    """Production configuration."""

    DEBUG: bool = False


# Dictionary to map environment names to configuration classes
config_dict: dict[str, type[Config]] = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
}
