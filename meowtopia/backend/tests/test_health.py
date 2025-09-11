import os
import time
import httpx

BASE_URL = os.environ.get("BACKEND_URL", "http://localhost:8000")


def test_health_endpoint():
    # simple retry for CI/dev flakiness on low-memory machines
    for _ in range(10):
        try:
            r = httpx.get(f"{BASE_URL}/health", timeout=2.0)
            if r.status_code == 200:
                body = r.json()
                assert body.get("status") == "healthy"
                return
        except Exception:
            time.sleep(1)
    raise AssertionError("/health not healthy after retries")
