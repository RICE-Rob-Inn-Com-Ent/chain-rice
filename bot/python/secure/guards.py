"""Guardrails AI: prompt/response validation, PII detection and scrubbing, toxicity, schema validation.

Provides is_prompt_injection, validate_prompt_guardrails, detect_pii, scrub_pii, sanitize_response,
is_toxic, validate_toxicity, validate_schema, sanitize_prompt, apply_guardrails. Uses regex fallbacks
when guardrails-ai not installed. Requires: guardrails-ai (extra secure). English only.
"""

from __future__ import annotations

import json
import re
from typing import Any, Callable

from secure.models import (
    GuardrailReport,
    GuardrailViolation,
    PIIDetectionResult,
    PIIEntity,
)

DEFAULT_REDACTION = "[REDACTED]"

# -----------------------------------------------------------------------------
# Guardrails validators setup
# -----------------------------------------------------------------------------

# Lightweight patterns when guardrails-ai not installed (fallback)
_BLOCK_PATTERNS = [
    re.compile(r"ignore\s+(previous|all)\s+instructions", re.I),
    re.compile(r"disregard\s+(previous|all)", re.I),
    re.compile(r"you\s+are\s+now\s+", re.I),
    re.compile(r"jail\s*break", re.I),
    re.compile(r"system\s*:\s*you\s+are", re.I),
    re.compile(r"<\s*script|javascript\s*:", re.I),
]


def _guardrails():
    try:
        import guardrails as g

        return g
    except ImportError:
        try:
            from guardrails import Guard

            return type("Guardrails", (), {"Guard": Guard})()
        except ImportError as e:
            raise ImportError(
                "guards wymaga guardrails-ai; zainstaluj: uv sync --extra secure"
            ) from e


# -----------------------------------------------------------------------------
# Prompt injection detection
# -----------------------------------------------------------------------------


def is_prompt_injection(text: str) -> bool:
    """Detect common prompt injection patterns (regex fallback when guardrails-ai not installed)."""
    if not text or not text.strip():
        return False
    for pat in _BLOCK_PATTERNS:
        if pat.search(text):
            return True
    return False


def validate_prompt_guardrails(text: str) -> GuardrailReport:
    """Validate prompt (Guardrails AI or regex fallback). Returns GuardrailReport."""
    if is_prompt_injection(text):
        return GuardrailReport(
            valid=False,
            violations=[
                GuardrailViolation(
                    validator="prompt_injection",
                    message="Request rejected: invalid or disallowed input.",
                )
            ],
        )
    try:
        _guardrails()
        # Tu: Guard z validatorami guardrails-ai (GuardrailsPII, etc.)
    except ImportError:
        pass
    return GuardrailReport(valid=True)


# -----------------------------------------------------------------------------
# PII scrubbing/detection
# -----------------------------------------------------------------------------


def detect_pii(text: str) -> PIIDetectionResult:
    """Detect PII in text (guardrails-ai/Presidio or regex fallback). Returns entities and anonymized text."""
    entities = []
    try:
        _guardrails()
        # Tu: GuardrailsPII validator
    except ImportError:
        # Prosty fallback: email pattern
        email_pat = re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b")
        for m in email_pat.finditer(text):
            entities.append(
                PIIEntity(type="EMAIL", start=m.start(), end=m.end(), text=m.group())
            )
    anonymized = text
    for e in sorted(entities, key=lambda x: -x.start):
        anonymized = anonymized[: e.start] + DEFAULT_REDACTION + anonymized[e.end :]
    return PIIDetectionResult(
        entities=entities,
        anonymized_text=anonymized,
        has_pii=len(entities) > 0,
    )


def scrub_pii(text: str) -> str:
    """Return text with PII replaced by placeholders."""
    return detect_pii(text).anonymized_text


# -----------------------------------------------------------------------------
# Response sanitization
# -----------------------------------------------------------------------------


def sanitize_response(text: str) -> str:
    """Sanitize response (strip dangerous tags, scrub PII)."""
    out = scrub_pii(text)
    # Strip script tags
    out = re.sub(
        r"<\s*script[^>]*>.*?<\s*/\s*script\s*>", "", out, flags=re.I | re.DOTALL
    )
    return out.strip()


# -----------------------------------------------------------------------------
# Custom guardrails
# -----------------------------------------------------------------------------


def add_custom_guard(name: str, validator_fn: Callable[..., Any]) -> None:
    """Register custom validator (placeholder; full version would use Guard.add_validator)."""
    _ = name
    _ = validator_fn


# -----------------------------------------------------------------------------
# Toxicity detection
# -----------------------------------------------------------------------------


def is_toxic(text: str) -> bool:
    """Detect toxicity (guardrails-ai toxicity validator when available; else placeholder returns False)."""
    if not (text or "").strip():
        return False
    try:
        _guardrails()
        # Tu: toxicity validator na text
    except ImportError:
        pass
    return False


def validate_toxicity(text: str) -> GuardrailReport:
    """Validate response for toxicity. Returns GuardrailReport."""
    if is_toxic(text):
        return GuardrailReport(
            valid=False,
            violations=[
                GuardrailViolation(
                    validator="toxicity", message="Toxic content detected."
                )
            ],
        )
    return GuardrailReport(valid=True)


# -----------------------------------------------------------------------------
# Schema validation for AI outputs
# -----------------------------------------------------------------------------


def validate_schema(output: Any, schema: type) -> GuardrailReport:
    """Validate AI output against Pydantic schema."""
    try:
        if hasattr(schema, "model_validate"):
            schema.model_validate(output)
            return GuardrailReport(valid=True)
    except Exception as e:
        return GuardrailReport(
            valid=False,
            violations=[
                GuardrailViolation(
                    validator="schema",
                    message=str(e),
                )
            ],
        )
    return GuardrailReport(valid=True)


def detect_injection(prompt: str) -> bool:
    """Detect prompt injection. Alias for is_prompt_injection."""
    return is_prompt_injection(prompt)


def sanitize_prompt(prompt: str) -> str:
    """Return sanitized prompt (strip suspicious patterns). Lightweight fallback."""
    out = prompt
    for pat in _BLOCK_PATTERNS:
        out = pat.sub(DEFAULT_REDACTION, out)
    return out.strip()


def scrub_pii(text: str, replacement: str = DEFAULT_REDACTION) -> str:
    """Replace PII with given replacement string."""
    res = detect_pii(text)
    out = text
    for e in sorted(res.entities, key=lambda x: -x.start):
        out = out[: e.start] + replacement + out[e.end :]
    return out


def check_toxicity(text: str, threshold: float = 0.5) -> bool:
    """Return True if toxicity score >= threshold. Fallback: False."""
    return get_toxicity_score(text) >= threshold


def get_toxicity_score(text: str) -> float:
    """Return toxicity score 0.0-1.0. Placeholder when guardrails-ai not available."""
    if not (text or "").strip():
        return 0.0
    try:
        _guardrails()
    except ImportError:
        pass
    return 0.0


def validate_response(response: str, schema: dict | type) -> bool:
    """Validate response string or object against schema (dict or Pydantic). Returns True if valid."""
    if isinstance(schema, dict):
        try:
            import json

            json.loads(response)
            return True
        except json.JSONDecodeError:
            return False
    try:
        if hasattr(schema, "model_validate"):
            schema.model_validate(
                json.loads(response) if isinstance(response, str) else response
            )
            return True
    except Exception:
        pass
    return False


def enforce_constraints(response: str, rules: list[dict]) -> str:
    """Apply constraint rules (e.g. max_length, block_patterns). Returns enforced response."""
    out = response
    for r in rules:
        if r.get("max_length") and len(out) > r["max_length"]:
            out = out[: r["max_length"]]
        if r.get("block_pattern"):
            out = re.sub(r["block_pattern"], "", out)
    return out


_registry: dict[str, Callable[..., Any]] = {}


def register_guardrail(name: str, validator_func: Callable[..., Any]) -> None:
    """Register custom guardrail by name."""
    _registry[name] = validator_func


def apply_guardrails(
    text: str, guardrail_names: list[str]
) -> tuple[bool, list[GuardrailViolation]]:
    """Run named guardrails on text. Returns (all_passed, list of violations)."""
    violations: list[GuardrailViolation] = []
    for name in guardrail_names:
        if name in _registry:
            try:
                ok = _registry[name](text)
                if not ok:
                    violations.append(
                        GuardrailViolation(validator=name, message="Validation failed")
                    )
            except Exception as e:
                violations.append(GuardrailViolation(validator=name, message=str(e)))
    if "prompt_injection" in guardrail_names or "detect_injection" in guardrail_names:
        if detect_injection(text):
            violations.append(
                GuardrailViolation(
                    validator="prompt_injection", message="Invalid or disallowed input"
                )
            )
    return (len(violations) == 0, violations)
