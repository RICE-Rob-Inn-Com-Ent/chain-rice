"""Tests for model layer (CrewAI agents, extract, memory, constrain): Pydantic models."""

from model.models import ExtractionResult, ValidatedOutput


def test_models_load() -> None:
    """Pydantic models from model are importable."""
    r = ExtractionResult(summary="x", entities=[])
    assert r.summary == "x"
    v = ValidatedOutput(ok=True)
    assert v.ok is True
