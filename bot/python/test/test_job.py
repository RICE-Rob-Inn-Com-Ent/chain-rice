"""Tests for former job layer: embeddings/scheduler (model), compute (sim)."""

from model.models import EmbeddingModelConfig
from model.scheduler import Priority


def test_job_models() -> None:
    """Embedding/scheduler models are importable (model layer)."""
    c = EmbeddingModelConfig(name="test", dim=384)
    assert c.dim == 384
    assert Priority.HIGH > Priority.NORMAL


def test_cuda_available() -> None:
    """cuda_available runs without error (torch optional, model.scheduler)."""
    try:
        from model.scheduler import cuda_available

        _ = cuda_available()
    except ImportError:
        pass
