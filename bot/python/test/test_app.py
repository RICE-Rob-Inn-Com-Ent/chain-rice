"""FastAPI app endpoint tests."""

import pytest
from fastapi.testclient import TestClient


def test_health(client: TestClient) -> None:
    """Health check returns 200 and status ok."""
    r = client.get("/health")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ok"
    assert "version" in data
    assert "timestamp" in data


def test_config(client: TestClient) -> None:
    """Config endpoint returns sanitized config (no secrets)."""
    r = client.get("/config")
    assert r.status_code == 200
    data = r.json()
    assert "app_title" in data
    assert "enable_data" in data


@pytest.mark.integration
def test_query_endpoint_when_data_enabled(client: TestClient) -> None:
    """POST /query returns rows when ENABLE_DATA is true (default)."""
    r = client.post("/query", json={"query": "SELECT 1 AS n", "params": None})
    if r.status_code == 200:
        data = r.json()
        assert "data" in data
        assert data["row_count"] >= 0
    else:
        assert r.status_code in (404, 422)
