"""Pydantic models for extraction/validation (instructor, crew, outlines) and embeddings (torch).

Used by model/extract, model/constrain, model/embeddings, model/scheduler. English only.
"""

from enum import Enum
from pydantic import BaseModel, Field


class DeviceType(str, Enum):
    """Device type for compute (CPU, CUDA, MPS for Apple Metal)."""

    CPU = "cpu"
    CUDA = "cuda"
    MPS = "mps"  # Apple Metal


class EmbeddingModelConfig(BaseModel):
    """Embedding model configuration (PyTorch): name, dim, max_seq_length, batch_size, device."""

    name: str = Field(default="default")
    dim: int = Field(default=384, ge=1)
    max_seq_length: int = Field(default=512, ge=1)
    batch_size: int = Field(default=32, ge=1)
    device: str = Field(default="cpu")


class CheckpointMeta(BaseModel):
    """Checkpoint metadata: path, step, epoch, metrics."""

    path: str = ""
    step: int = 0
    epoch: int = 0
    metrics: dict[str, float] = Field(default_factory=dict)


# -----------------------------------------------------------------------------
# Extraction / validation (instructor, outlines)
# -----------------------------------------------------------------------------


class ExtractionResult(BaseModel):
    """Example schema for structured extraction from LLM (summary, entities)."""

    summary: str = Field(description="Short summary")
    entities: list[str] = Field(default_factory=list, description="Extracted entities")


class ValidatedOutput(BaseModel):
    """Example schema for validated output (JSON/regex constrained generation)."""

    ok: bool = True
    message: str = ""
