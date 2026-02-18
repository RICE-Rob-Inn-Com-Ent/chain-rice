"""Structured data extraction from text via LLM (instructor). Requires: instructor (extra model).

Provides extract (LLM + Pydantic schema), extract_structured (parse JSON only), extract_batch,
extract_with_validation. Schema is always passed in (never hardcoded). English only.
"""

from __future__ import annotations

from typing import Any, Callable, TypeVar

from pydantic import BaseModel

T = TypeVar("T", bound=BaseModel)


def extract_structured(response_text: str, model: type[T]) -> T:
    """Parse JSON string into Pydantic model (no LLM call)."""
    if not issubclass(model, BaseModel):
        raise TypeError("model must be a Pydantic BaseModel class")
    return model.model_validate_json(response_text)


def _get_llm_config() -> tuple[str, str]:
    """Return (model_name, api_key)."""
    try:
        from app.config import get_settings
        s = get_settings()
        return s.LITELLM_MODEL, s.LITELLM_API_KEY or ""
    except Exception:
        return "gpt-4o-mini", ""


def extract(text: str, schema: type[T], allow_partial: bool = False) -> T:
    """Extract structured data from raw text using LLM + instructor.

    Args:
        text: Raw text to extract from.
        schema: Pydantic model class for output.
        allow_partial: If True, missing fields may be omitted (schema with defaults).

    Returns:
        Instance of schema with extracted fields.

    Raises:
        ImportError: If instructor or litellm not installed.
    """
    try:
        import instructor
        import litellm
    except ImportError as e:
        raise ImportError(
            "extract requires instructor and litellm; uv sync --extra model"
        ) from e
    if not issubclass(schema, BaseModel):
        raise TypeError("schema must be a Pydantic BaseModel class")
    model_name, api_key = _get_llm_config()
    client = instructor.patch(litellm.completion, mode=instructor.Mode.JSON)
    resp = client(
        model=model_name,
        messages=[{"role": "user", "content": f"Extract structured information from this text:\n\n{text}"}],
        response_model=schema,
        api_key=api_key or None,
    )
    return resp if isinstance(resp, schema) else schema.model_validate(resp)


def extract_batch(texts: list[str], schema: type[T], allow_partial: bool = False) -> list[T]:
    """Batch extraction. Returns list of schema instances. One LLM call per text."""
    return [extract(t, schema, allow_partial=allow_partial) for t in texts]


def extract_with_validation(
    text: str,
    schema: type[T],
    validators: list[Callable[[T], bool]] | None = None,
    allow_partial: bool = False,
) -> T:
    """Extract then run custom validation. Retries once on validation failure (no retry loop by default)."""
    validators = validators or []
    result = extract(text, schema, allow_partial=allow_partial)
    for v in validators:
        if not v(result):
            from app.utils import ValidationError
            raise ValidationError("Custom validation failed")
    return result
