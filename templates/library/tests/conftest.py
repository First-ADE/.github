"""Shared test fixtures."""

import pytest


@pytest.fixture
def example_fixture():
    """Example fixture for testing."""
    return {"key": "value"}
