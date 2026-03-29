"""Guardrails AI — walidacja treści, polityki bezpieczeństwa, akcje on_fail."""

from __future__ import annotations

from typing import Any

from loguru import logger

# TODO:
# [ ] implement output schema validation via guardrails-ai:
# [ ]     define Guard from Pydantic model → validate LLM output
# [ ]     validators: ValidLength, ValidChoices, RegexMatch, DetectPII
# [ ]     PII detection enabled when RICE_PII_DETECTION=true
# [ ] implement content policy filter:
# [ ]     block output matching RICE_BLOCKED_PATTERNS (regex list from env)
# [ ]     block output with toxicity score > RICE_TOXICITY_THRESHOLD
# [ ] implement hallucination detection:
# [ ]     cross-reference output claims against retrieved Qdrant context
# [ ]     flag when claim not grounded in context — log to OTel
# [ ] implement output audit trail:
# [ ]     every validated output → append to NATS subject audit.sage.outputs
# [ ]     CLERK subscribes and stores in immutable audit log
# [ ] implement retry on guard failure:
# [ ]     on validation fail → reask LLM with failure reason injected into prompt
# [ ]     max reasks from RICE_GUARD_MAX_REASKS env var


def build_default_guard() -> Any:
    """Pusty `Guard` — import guardrails leniwy (unika konfliktów z wersją `openai`)."""
    from guardrails import Guard

    return Guard()


def apply_guard(guard: Any, text: str) -> Any:
    """Wywołuje dostępną metodę walidacji (`__call__`, `validate`, `parse`)."""
    if hasattr(guard, "validate"):
        return guard.validate(text)  # type: ignore[no-any-return, operator]
    if callable(guard):
        return guard(text)  # type: ignore[operator]
    return guard.parse(text)  # type: ignore[no-any-return]


def validate_output(text: str, guard: Any | None = None) -> tuple[bool, Any]:
    """Zwraca (sukces, wynik lub wyjątek)."""
    g = guard or build_default_guard()
    try:
        out = apply_guard(g, text)
        return True, out
    except Exception as exc:  # noqa: BLE001
        logger.warning("guard blocked or failed: {}", exc)
        return False, exc
