"""Unit tests for API routes."""

from __future__ import annotations

import json
from unittest.mock import patch

from flask import Flask
from flask.testing import FlaskClient

from app.models import Data


class TestHealthEndpoint:
    """Test cases for the health check endpoint."""

    def test_health_check_success(self, client: FlaskClient) -> None:
        """Test successful health check."""
        response = client.get("/health")

        assert response.status_code == 200

        data = response.get_json()
        assert data["status"] == "healthy"
        assert data["database"] == "connected"
        assert data["service"] == "reto_final_python"

    def test_health_check_database_error(self, client: FlaskClient, app: Flask) -> None:
        """Test health check when database is not available."""
        with app.app_context():
            # Mock database session to raise an exception
            with patch("app.routes.db.session.execute") as mock_execute:
                mock_execute.side_effect = Exception("Database connection failed")

                response = client.get("/health")

                assert response.status_code == 503

                data = response.get_json()
                assert data["status"] == "unhealthy"
                assert data["database"] == "disconnected"
                assert data["service"] == "reto_final_python"
                assert "Database connection failed" in data["error"]


class TestDataEndpoints:
    """Test cases for data CRUD endpoints."""

    def test_get_all_data_empty(self, client: FlaskClient) -> None:
        """Test getting all data when database is empty."""
        response = client.get("/data")

        assert response.status_code == 200

        data = response.get_json()
        assert data == []

    def test_get_all_data_with_entries(
        self, client: FlaskClient, multiple_data: list[Data]
    ) -> None:
        """Test getting all data when database has entries."""
        response = client.get("/data")

        assert response.status_code == 200

        data = response.get_json()
        assert len(data) == 3

        # Verify structure of returned data
        for item in data:
            assert "id" in item
            assert "name" in item
            assert isinstance(item["id"], int)
            assert isinstance(item["name"], str)

    def test_insert_data_success(self, client: FlaskClient) -> None:
        """Test successful data insertion."""
        payload = {"name": "New User"}

        response = client.post(
            "/data", data=json.dumps(payload), content_type="application/json"
        )

        assert response.status_code == 201

        data = response.get_json()
        assert data["message"] == "Data inserted successfully"

        # Verify data was actually inserted
        get_response = client.get("/data")
        get_data = get_response.get_json()
        assert len(get_data) == 1
        assert get_data[0]["name"] == "New User"

    def test_insert_data_no_name(self, client: FlaskClient) -> None:
        """Test data insertion without name field."""
        payload = {}

        response = client.post(
            "/data", data=json.dumps(payload), content_type="application/json"
        )

        assert response.status_code == 400

        data = response.get_json()
        assert data["message"] == "Name is required"

    def test_insert_data_empty_name(self, client: FlaskClient) -> None:
        """Test data insertion with empty name."""
        payload = {"name": ""}

        response = client.post(
            "/data", data=json.dumps(payload), content_type="application/json"
        )

        assert response.status_code == 400

        data = response.get_json()
        assert data["message"] == "Name is required"

    def test_insert_data_none_name(self, client: FlaskClient) -> None:
        """Test data insertion with None name."""
        payload = {"name": None}

        response = client.post(
            "/data", data=json.dumps(payload), content_type="application/json"
        )

        assert response.status_code == 400

        data = response.get_json()
        assert data["message"] == "Name is required"

    def test_insert_data_duplicate_name(
        self, client: FlaskClient, sample_data: Data
    ) -> None:
        """Test inserting data with duplicate name."""
        payload = {"name": sample_data.name}

        response = client.post(
            "/data", data=json.dumps(payload), content_type="application/json"
        )

        assert response.status_code == 409

        data = response.get_json()
        assert data["message"] == "Data already exists"

    def test_insert_data_invalid_json(self, client: FlaskClient) -> None:
        """Test data insertion with invalid JSON."""
        response = client.post(
            "/data", data="invalid json", content_type="application/json"
        )

        assert response.status_code == 400

    def test_delete_data_success(self, client: FlaskClient, sample_data: Data) -> None:
        """Test successful data deletion."""
        response = client.delete(f"/data/{sample_data.id}")

        assert response.status_code == 200

        data = response.get_json()
        assert data["message"] == "Data deleted successfully"

        # Verify data was actually deleted
        get_response = client.get("/data")
        get_data = get_response.get_json()
        assert len(get_data) == 0

    def test_delete_data_not_found(self, client: FlaskClient) -> None:
        """Test deleting non-existent data."""
        response = client.delete("/data/999")

        assert response.status_code == 404

        data = response.get_json()
        assert data["message"] == "Data not found"

    def test_delete_data_invalid_id(self, client: FlaskClient) -> None:
        """Test deleting data with invalid ID format."""
        response = client.delete("/data/invalid")

        assert (
            response.status_code == 404
        )  # Flask returns 404 for invalid route parameters


class TestEdgeCases:
    """Test edge cases and error scenarios."""

    def test_post_data_without_content_type(self, client: FlaskClient) -> None:
        """Test POST request without content-type header."""
        payload = '{"name": "Test User"}'

        response = client.post("/data", data=payload)

        # Should handle gracefully
        assert response.status_code in [
            400,
            415,
        ]  # Bad Request or Unsupported Media Type

    def test_get_data_with_query_parameters(self, client: FlaskClient) -> None:
        """Test GET request with query parameters (should be ignored)."""
        response = client.get("/data?param=value")

        assert response.status_code == 200
        # Should work normally and ignore query parameters

    def test_unsupported_http_methods(self, client: FlaskClient) -> None:
        """Test unsupported HTTP methods on endpoints."""
        # PUT method on /data
        response = client.put("/data")
        assert response.status_code == 405  # Method Not Allowed

        # PATCH method on /data
        response = client.patch("/data")
        assert response.status_code == 405  # Method Not Allowed
