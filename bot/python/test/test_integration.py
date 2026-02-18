"""End-to-end integration tests."""

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.mark.integration
def test_app_startup_and_health() -> None:
    """App starts and health endpoint responds."""
    client = TestClient(app)
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


@pytest.mark.integration
def test_app_openapi_available() -> None:
    """OpenAPI schema is exposed."""
    client = TestClient(app)
    r = client.get("/openapi.json")
    assert r.status_code == 200
    data = r.json()
    assert "openapi" in data
    assert "paths" in data
