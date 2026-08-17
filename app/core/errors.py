"""Small domain errors shared by service and HTTP layers."""

from __future__ import annotations


class ConflictError(ValueError):
    """The resource changed state since the caller last read it."""
