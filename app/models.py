"""Database models for the application."""

from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy.orm import Mapped, mapped_column

if TYPE_CHECKING:
    pass

from app import db


class Data(db.Model):  # type: ignore
    """Data model for storing application data."""

    __tablename__ = "data"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(db.String(100), nullable=False)

    def __repr__(self) -> str:
        """Return a string representation of the Data object."""
        return f"<Data id={self.id} name={self.name}>"

    def to_dict(self) -> dict[str, int | str]:
        """Convert the Data object to a dictionary."""
        return {"id": self.id, "name": self.name}
