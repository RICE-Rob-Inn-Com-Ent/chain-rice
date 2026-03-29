"""Fixtures bezpieczeństwa: zmockowany env, brak sekretów w logach."""

from __future__ import annotations

import pytest

# TODO:
# [ ] fixture: malicious_prompt — list of prompt injection attempts
# [ ]     loaded from test/security/prompts.json — not hardcoded in code
# [ ] fixture: pii_samples — list of strings containing PII
# [ ]     names, emails, phone numbers, SSNs — synthetic only
# [ ] fixture: oversized_payload — payload exceeding RICE_MAX_PAYLOAD_BYTES
# [ ] fixture: invalid_schema_payload — dict missing required fields
# [ ] fixture: sql_injection_samples — SQL injection strings for NATS payload tests
# [ ] fixture: xss_samples — XSS strings for output validation tests


@pytest.fixture
def sanitized_env(monkeypatch: pytest.MonkeyPatch) -> None:
    """Czyści zmienne typowo wrażliwe na czas testu."""
    for key in (
        "AWS_SECRET_ACCESS_KEY",
        "OPENAI_API_KEY",
        "LITELLM_API_KEY",
        "POSTGRES_PASSWORD",
    ):
        monkeypatch.delenv(key, raising=False)
    monkeypatch.setenv("ENVIRONMENT", "test")


@pytest.fixture
def no_network(monkeypatch: pytest.MonkeyPatch) -> None:
    """Placeholder — rozszerz o mock socket/httpx w testach wymagających izolacji."""
    return None
