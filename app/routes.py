"""API routes for the application."""

from __future__ import annotations

from typing import Any

from flask import Blueprint, jsonify, request
from sqlalchemy import text

from app import db
from app.models import Data

data_routes = Blueprint("data_routes", __name__)


@data_routes.route("/data", methods=["POST"])
def insert_data() -> tuple[dict[str, str], int]:
    """Insert new data into the database."""
    data: dict[str, Any] = request.json or {}
    name = data.get("name")

    if not name:
        return {"message": "Name is required"}, 400

    # Check if data already exists
    current_data = Data.query.filter_by(name=name).first()
    if current_data:
        return {"message": "Data already exists"}, 409

    # Create new data entry
    new_data = Data(name=name)
    db.session.add(new_data)
    db.session.commit()

    return {"message": "Data inserted successfully"}, 201


@data_routes.route("/data", methods=["GET"])
def get_all_data() -> Any:
    """Get all data from the database."""
    data_list = [data.to_dict() for data in Data.query.all()]
    return jsonify(data_list)


@data_routes.route("/data/<int:data_id>", methods=["DELETE"])
def delete_data(data_id: int) -> tuple[dict[str, str], int]:
    """Delete data by ID."""
    element_to_delete = Data.query.get(data_id)
    if not element_to_delete:
        return {"message": "Data not found"}, 404

    db.session.delete(element_to_delete)
    db.session.commit()
    return {"message": "Data deleted successfully"}, 200


@data_routes.route("/health", methods=["GET"])
def health_check() -> tuple[dict[str, str], int]:
    """Health check endpoint for Docker containers."""
    try:
        # Test database connection
        db.session.execute(text("SELECT 1"))
        return (
            {
                "status": "healthy",
                "database": "connected",
                "service": "reto_final_python",
            },
            200,
        )
    except Exception as e:
        return (
            {
                "status": "unhealthy",
                "database": "disconnected",
                "service": "reto_final_python",
                "error": str(e),
            },
            503,
        )
