"""Integration tests for the Flask application."""

from __future__ import annotations

import json

from flask.testing import FlaskClient


class TestIntegrationWorkflows:
    """Integration tests for complete workflows."""

    def test_complete_crud_workflow(self, client: FlaskClient) -> None:
        """Test complete CRUD workflow: Create, Read, Update (via recreate), Delete."""
        # 1. Verify empty state
        response = client.get("/data")
        assert response.status_code == 200
        assert response.get_json() == []

        # 2. Create new data
        create_payload = {"name": "Integration Test User"}
        response = client.post(
            "/data", data=json.dumps(create_payload), content_type="application/json"
        )
        assert response.status_code == 201
        assert response.get_json()["message"] == "Data inserted successfully"

        # 3. Read the created data
        response = client.get("/data")
        assert response.status_code == 200
        data_list = response.get_json()
        assert len(data_list) == 1
        assert data_list[0]["name"] == "Integration Test User"
        created_id = data_list[0]["id"]

        # 4. Try to create duplicate (should fail)
        response = client.post(
            "/data", data=json.dumps(create_payload), content_type="application/json"
        )
        assert response.status_code == 409
        assert response.get_json()["message"] == "Data already exists"

        # 5. Delete the data
        response = client.delete(f"/data/{created_id}")
        assert response.status_code == 200
        assert response.get_json()["message"] == "Data deleted successfully"

        # 6. Verify deletion
        response = client.get("/data")
        assert response.status_code == 200
        assert response.get_json() == []

    def test_multiple_users_workflow(self, client: FlaskClient) -> None:
        """Test workflow with multiple users."""
        users = ["Alice", "Bob", "Charlie"]
        created_ids = []

        # Create multiple users
        for user in users:
            payload = {"name": user}
            response = client.post(
                "/data", data=json.dumps(payload), content_type="application/json"
            )
            assert response.status_code == 201

        # Verify all users exist
        response = client.get("/data")
        assert response.status_code == 200
        data_list = response.get_json()
        assert len(data_list) == 3

        # Collect IDs and verify names
        names = [item["name"] for item in data_list]
        created_ids = [item["id"] for item in data_list]

        for user in users:
            assert user in names

        # Delete users one by one
        for user_id in created_ids:
            response = client.delete(f"/data/{user_id}")
            assert response.status_code == 200

        # Verify all deleted
        response = client.get("/data")
        assert response.status_code == 200
        assert response.get_json() == []

    def test_health_check_integration(self, client: FlaskClient) -> None:
        """Test health check integration with database operations."""
        # Health check should work initially
        response = client.get("/health")
        assert response.status_code == 200
        assert response.get_json()["status"] == "healthy"

        # Perform database operations
        payload = {"name": "Health Test User"}
        response = client.post(
            "/data", data=json.dumps(payload), content_type="application/json"
        )
        assert response.status_code == 201

        # Health check should still work after operations
        response = client.get("/health")
        assert response.status_code == 200
        assert response.get_json()["status"] == "healthy"

        # Clean up
        response = client.get("/data")
        data_list = response.get_json()
        if data_list:
            client.delete(f"/data/{data_list[0]['id']}")

    def test_error_recovery_workflow(self, client: FlaskClient) -> None:
        """Test system recovery after various error conditions."""
        # 1. Try invalid operations
        response = client.post("/data", data="{invalid json}")
        assert response.status_code == 415  # Unsupported Media Type (no content-type)

        response = client.delete("/data/999")
        assert response.status_code == 404

        response = client.post(
            "/data", data=json.dumps({}), content_type="application/json"
        )
        assert response.status_code == 400

        # 2. System should still work normally after errors
        payload = {"name": "Recovery Test User"}
        response = client.post(
            "/data", data=json.dumps(payload), content_type="application/json"
        )
        assert response.status_code == 201

        # 3. Health check should still be healthy
        response = client.get("/health")
        assert response.status_code == 200
        assert response.get_json()["status"] == "healthy"


class TestConcurrentOperations:
    """Test scenarios that simulate concurrent operations."""

    def test_rapid_sequential_operations(self, client: FlaskClient) -> None:
        """Test rapid sequential create and delete operations."""
        # Rapidly create multiple entries
        for i in range(10):
            payload = {"name": f"Rapid User {i}"}
            response = client.post(
                "/data", data=json.dumps(payload), content_type="application/json"
            )
            assert response.status_code == 201

        # Verify all created
        response = client.get("/data")
        assert response.status_code == 200
        data_list = response.get_json()
        assert len(data_list) == 10

        # Rapidly delete all
        for item in data_list:
            response = client.delete(f"/data/{item['id']}")
            assert response.status_code == 200

        # Verify all deleted
        response = client.get("/data")
        assert response.status_code == 200
        assert response.get_json() == []

    def test_mixed_operations_sequence(self, client: FlaskClient) -> None:
        """Test mixed operations in sequence."""
        operations = []

        # Create some data
        for i in range(3):
            payload = {"name": f"Mixed User {i}"}
            response = client.post(
                "/data", data=json.dumps(payload), content_type="application/json"
            )
            assert response.status_code == 201
            operations.append(f"Created user {i}")

        # Get current state
        response = client.get("/data")
        data_list = response.get_json()
        operations.append(f"Retrieved {len(data_list)} users")

        # Delete some data
        if data_list:
            response = client.delete(f"/data/{data_list[0]['id']}")
            assert response.status_code == 200
            operations.append(f"Deleted user {data_list[0]['id']}")

        # Health check
        response = client.get("/health")
        assert response.status_code == 200
        operations.append("Health check passed")

        # Final verification
        response = client.get("/data")
        final_data = response.get_json()
        operations.append(f"Final count: {len(final_data)}")

        # Ensure we performed all expected operations
        assert len(operations) >= 6  # At least 6 operations (may have extras)


class TestApplicationConfiguration:
    """Test application configuration and setup."""

    def test_application_factory_pattern(self, app) -> None:
        """Test that application factory pattern works correctly."""
        assert app.name == "app"
        assert app.config["TESTING"] is True
        assert app.config["SQLALCHEMY_DATABASE_URI"] == "sqlite:///:memory:"

    def test_database_initialization(self, app) -> None:
        """Test that database is properly initialized."""
        from app import db

        with app.app_context():
            # Database should be created and accessible
            result = db.session.execute(
                db.text("SELECT name FROM sqlite_master WHERE type='table'")
            )
            tables = [row[0] for row in result]
            assert "data" in tables

    def test_blueprints_registration(self, app) -> None:
        """Test that blueprints are properly registered."""
        blueprints = [bp.name for bp in app.iter_blueprints()]
        assert "data_routes" in blueprints
