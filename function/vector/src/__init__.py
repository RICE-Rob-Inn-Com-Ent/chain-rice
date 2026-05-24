"""SAGE vector memory — dense retrieval, lexical index, and orchestrated ingest/search."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

__version__ = "0.1.0"

# --- Chunk models & strategies -------------------------------------------------
from .chunk import DocumentChunk, RecursiveCharacterChunker, SlidingWindowChunker

type Chunk = DocumentChunk

# --- Configuration (tunable defaults) -----------------------------------------
from .const import (
    DEVICE,
    EMBEDDING_MODEL_NAME,
    QDRANT_DEFAULT_COLLECTION,
    VECTOR_SIZE,
)

# --- Embedding engine -----------------------------------------------------------
from .embed import EmbeddingEngine

# --- Orchestration -------------------------------------------------------------
from .pipeline import VectorPipeline, VectorPipelineConfig

# --- Retrieval ----------------------------------------------------------------
from .search import SearchResult, VectorSearcher

# --- Persistence ---------------------------------------------------------------
from .store import VectorStore

__all__ = [
    "__version__",
    "Chunk",
    "DEVICE",
    "EMBEDDING_MODEL_NAME",
    "DocumentChunk",
    "EmbeddingEngine",
    "QDRANT_DEFAULT_COLLECTION",
    "RecursiveCharacterChunker",
    "SearchResult",
    "SlidingWindowChunker",
    "VECTOR_SIZE",
    "VectorPipeline",
    "VectorPipelineConfig",
    "VectorSearcher",
    "VectorStore",
]
