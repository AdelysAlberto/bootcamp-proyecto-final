"""Unit tests for database models."""

from __future__ import annotations

from app.models import Data


class TestDataModel:
    """Test cases for the Data model."""

    def test_data_creation(self, app) -> None:
        """Test creating a new Data instance."""
        with app.app_context():
            data = Data(name="Test Name")
            assert data.name == "Test Name"
            assert data.id is None  # ID is not set until saved to database

    def test_data_repr(self, app) -> None:
        """Test the string representation of Data model."""
        with app.app_context():
            data = Data(name="Test Name")
            data.id = 1  # Simulate database ID
            assert repr(data) == "<Data id=1 name=Test Name>"

    def test_data_to_dict(self, app) -> None:
        """Test converting Data model to dictionary."""
        with app.app_context():
            data = Data(name="Test Name")
            data.id = 1  # Simulate database ID

            result = data.to_dict()
            expected = {"id": 1, "name": "Test Name"}

            assert result == expected
            assert isinstance(result, dict)
            assert isinstance(result["id"], int)
            assert isinstance(result["name"], str)

    def test_data_persistence(self, app) -> None:
        """Test saving and retrieving Data from database."""
        from app import db

        with app.app_context():
            # Create and save data
            data = Data(name="Persistent Data")
            db.session.add(data)
            db.session.commit()

            # Verify data was saved
            assert data.id is not None

            # Retrieve data from database
            retrieved_data = Data.query.filter_by(name="Persistent Data").first()
            assert retrieved_data is not None
            assert retrieved_data.name == "Persistent Data"
            assert retrieved_data.id == data.id

    def test_data_unique_names_allowed(self, app) -> None:
        """Test that multiple entries with different names can be created."""
        from app import db

        with app.app_context():
            data1 = Data(name="Name 1")
            data2 = Data(name="Name 2")

            db.session.add(data1)
            db.session.add(data2)
            db.session.commit()

            assert data1.id != data2.id
            assert Data.query.count() == 2

    def test_data_duplicate_names_allowed(self, app) -> None:
        """Test that duplicate names are allowed in the model (business logic handles duplicates)."""
        from app import db

        with app.app_context():
            data1 = Data(name="Same Name")
            data2 = Data(name="Same Name")

            db.session.add(data1)
            db.session.add(data2)
            db.session.commit()

            # Both should be saved successfully at model level
            assert data1.id != data2.id
            assert Data.query.filter_by(name="Same Name").count() == 2


# Test comment
