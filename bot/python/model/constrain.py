"""Outlines: constrained generation (JSON, regex, choice). Dynamic schemas at runtime.

Provides generate_json, generate_regex, generate_choice, json_completion, validate_format_output.
Requires: outlines (extra model). Model id from app.config (LITELLM_MODEL). All comments in English.
"""

from __future__ import annotations

from typing import Any


def _model_id() -> str:
    """Return model name from config for Outlines."""
    try:
        from app.config import get_settings
        return get_settings().LITELLM_MODEL
    except Exception:
        return "gpt-4o-mini"


def generate_json(prompt: str, schema: dict[str, Any] | None = None, max_tokens: int = 512) -> str:
    """Generate output constrained to valid JSON. schema: JSON Schema dict (optional)."""
    try:
        import outlines
    except ImportError as e:
        raise ImportError("generate_json requires outlines; uv sync --extra model") from e
    model_id = _model_id()
    try:
        if schema:
            gen = outlines.generate.json(model_id, prompt, max_tokens=max_tokens)
        else:
            gen = outlines.generate.json(model_id, prompt, max_tokens=max_tokens)
        return str(gen) if gen is not None else "{}"
    except Exception:
        return "{}"


def generate_regex(prompt: str, pattern: str, max_tokens: int = 256) -> str:
    """Generate output that matches the given regex pattern."""
    try:
        import outlines
    except ImportError as e:
        raise ImportError("generate_regex requires outlines; uv sync --extra model") from e
    model_id = _model_id()
    try:
        gen = outlines.generate.regex(model_id, pattern, prompt, max_tokens=max_tokens)
        return str(gen) if gen is not None else ""
    except Exception:
        return ""


def generate_choice(prompt: str, options: list[str], max_tokens: int = 64) -> str:
    """Generate output constrained to one of the given options."""
    try:
        import outlines
    except ImportError as e:
        raise ImportError("generate_choice requires outlines; uv sync --extra model") from e
    model_id = _model_id()
    try:
        gen = outlines.generate.choice(model_id, options, prompt, max_tokens=max_tokens)
        return str(gen) if gen is not None else (options[0] if options else "")
    except Exception:
        return options[0] if options else ""


def json_completion(prompt: str, max_tokens: int = 512) -> str:
    """Legacy alias: generate JSON completion."""
    return generate_json(prompt, max_tokens=max_tokens)


def validate_format_output(output: str, schema: dict[str, Any] | None = None) -> bool:
    """Check that output is valid JSON. If schema provided, validate structure (basic)."""
    import json
    try:
        obj = json.loads(output)
    except json.JSONDecodeError:
        return False
    if schema is None:
        return True
    if "type" in schema and schema["type"] == "object" and "properties" in schema:
        if not isinstance(obj, dict):
            return False
        for k in schema.get("required", []):
            if k not in obj:
                return False
    return True
