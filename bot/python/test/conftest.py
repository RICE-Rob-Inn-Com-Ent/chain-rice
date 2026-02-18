"""Shared fixtures for all tests. Mock settings, LLM, sample data, temp dirs."""

from __future__ import annotations

import os
import tempfile
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client() -> TestClient:
    """FastAPI test client."""
    return TestClient(app)


@pytest.fixture
def mock_settings(monkeypatch):
    """Override get_settings to return test env (no real API keys)."""
    monkeypatch.setenv("LITELLM_API_KEY", "")
    monkeypatch.setenv("ENABLE_AGENTS", "false")
    monkeypatch.setenv("ENABLE_QUANTUM", "false")
    monkeypatch.setenv("ENABLE_DATA", "true")
    monkeypatch.setenv("ENABLE_GPU", "false")
    yield
    try:
        from app.config import get_settings

        get_settings.cache_clear()
    except Exception:
        pass


@pytest.fixture
def sample_query_request() -> dict:
    """Sample query request body."""
    return {"query": "SELECT 1 AS n", "params": None}


@pytest.fixture
def sample_chat_request() -> dict:
    """Sample chat request body."""
    return {"message": "Hello", "context": None, "options": None}


@pytest.fixture
def sample_simulation_request() -> dict:
    """Sample simulation request body."""
    return {"circuit_type": "bell", "params": {"shots": 100}}


@pytest.fixture
def temp_dir():
    """Temporary directory for test files."""
    with tempfile.TemporaryDirectory() as d:
        yield Path(d)


@pytest.fixture
def sample_table_data() -> list[dict]:
    """Sample list of dicts for table/parquet tests."""
    return [{"a": 1, "b": 2.0}, {"a": 3, "b": 4.0}]
