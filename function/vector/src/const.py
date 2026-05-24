"""Vector constants for embeddings, Qdrant, lexical indexing, and hybrid retrieval."""

from __future__ import annotations

import importlib
from typing import Final

import torch

# ---------------------------------------------------------------------------
# [MODELS] — embedding model defaults and runtime device selection
# ---------------------------------------------------------------------------

EMBEDDING_MODEL_NAME: Final[str] = "sentence-transformers/all-MiniLM-L6-v2"
DEFAULT_EMBEDDING_MODEL: Final[str] = EMBEDDING_MODEL_NAME
EMBED_BATCH_SIZE: Final[int] = 32
VECTOR_SIZE: Final[int] = 384


def _detect_device() -> str:
    """Pick the most capable runtime accelerator available."""
    if torch.cuda.is_available():
        return "cuda"
    mps_backend = getattr(torch.backends, "mps", None)
    if mps_backend and mps_backend.is_available():
        return "mps"
    return "cpu"


DEVICE: Final[str] = _detect_device()

# Keep text processing and I/O aligned with global helper standards.
_helper_module = importlib.import_module("helper")
_helper_encoding = getattr(_helper_module, "ENCODING", "utf-8")
VECTOR_TEXT_ENCODING: Final[str] = str(_helper_encoding)

# ---------------------------------------------------------------------------
# [QDRANT] — collection names, vector metric, payload key contracts
# ---------------------------------------------------------------------------

QDRANT_DEFAULT_COLLECTION: Final[str] = "sage_vectors"
QDRANT_DEFAULT_ALIAS: Final[str] = "sage_vectors_current"
QDRANT_DISTANCE_METRIC: Final[str] = "Cosine"

# HNSW / optimizers — tuned for low-latency ANN under typical RAG corpora (SAGE default).
QDRANT_HNSW_M: Final[int] = 32
QDRANT_HNSW_EF_CONSTRUCT: Final[int] = 256
QDRANT_HNSW_FULL_SCAN_THRESHOLD: Final[int] = 10_000
QDRANT_HNSW_ON_DISK: Final[bool] = False
QDRANT_OPTIMIZER_DEFAULT_SEGMENT_NUMBER: Final[int] = 2
QDRANT_OPTIMIZER_INDEXING_THRESHOLD: Final[int] = 20_000
QDRANT_OPTIMIZER_MEMMAP_THRESHOLD: Final[int] = 200_000
QDRANT_OPTIMIZER_FLUSH_INTERVAL_SEC: Final[int] = 5
QDRANT_OPTIMIZER_DELETED_THRESHOLD: Final[float] = 0.2
QDRANT_OPTIMIZER_VACUUM_MIN_VECTORS: Final[int] = 1000
QDRANT_ON_DISK_PAYLOAD: Final[bool] = True

QDRANT_PAYLOAD_KEY_CONTENT: Final[str] = "content"
QDRANT_PAYLOAD_KEY_METADATA: Final[str] = "metadata"
QDRANT_PAYLOAD_KEY_CHUNK_ID: Final[str] = "chunk_id"
QDRANT_PAYLOAD_KEY_DOC_ID: Final[str] = "doc_id"
QDRANT_PAYLOAD_KEY_SOURCE: Final[str] = "source"

# ---------------------------------------------------------------------------
# [CHUNK_STRATEGY] — defaults for text chunking in RAG ingest
# ---------------------------------------------------------------------------

CHUNK_SIZE: Final[int] = 800
CHUNK_OVERLAP: Final[int] = 120
DEFAULT_CHUNK_SIZE: Final[int] = CHUNK_SIZE
DEFAULT_CHUNK_OVERLAP: Final[int] = CHUNK_OVERLAP
CHUNK_PIPELINE_MAX_INPUT_CHARS: Final[int] = 5_000_000

# ---------------------------------------------------------------------------
# [LEXICAL] — BM25S baseline hyperparameters
# ---------------------------------------------------------------------------

BM25S_DEFAULT_K1: Final[float] = 1.2
BM25S_DEFAULT_B: Final[float] = 0.75
LEXICAL_INDEX_DIR: Final[str] = ".rice/vector/lexical_index"
LEXICAL_INDEX_BASENAME: Final[str] = "bm25s_corpus"

# ---------------------------------------------------------------------------
# [RERANK] — candidate limits for retrieval and final ranking
# ---------------------------------------------------------------------------

INITIAL_SEARCH_TOP_K: Final[int] = 50
FINAL_RERANK_TOP_K: Final[int] = 10
# Cross-encoder reranker: empty ``RERANK_MODEL_NAME`` skips load (bypass).
# ``RERANK_MAX_LENGTH`` is passed to the CE tokenizer.
RERANK_MODEL_NAME: Final[str] = "cross-encoder/ms-marco-MiniLM-L-6-v2"
RERANK_BATCH_SIZE: Final[int] = 16
RERANK_MAX_LENGTH: Final[int] = 512

# Minimum dense similarity score (e.g. cosine) after retrieval; 0 disables post-filtering.
SCORE_THRESHOLD: Final[float] = 0.0

# ---------------------------------------------------------------------------
# [CACHE] — embedding / search result caches (LRU + TTL)
# ---------------------------------------------------------------------------

EMBEDDING_CACHE_MAX_ENTRIES: Final[int] = 50_000
EMBEDDING_CACHE_TTL_S: Final[int] = 3600
SEARCH_CACHE_MAX_ENTRIES: Final[int] = 10_000
SEARCH_CACHE_TTL_S: Final[int] = 300
SEMANTIC_CACHE_SIMILARITY_THRESHOLD: Final[float] = 0.92

# ---------------------------------------------------------------------------
# [HYBRID] — dense + sparse score blending
# ---------------------------------------------------------------------------

HYBRID_DENSE_ALPHA: Final[float] = 0.60
HYBRID_SPARSE_WEIGHT: Final[float] = 1.0 - HYBRID_DENSE_ALPHA
HYBRID_RRF_K: Final[int] = 60

__all__ = [
    "BM25S_DEFAULT_B",
    "BM25S_DEFAULT_K1",
    "CHUNK_OVERLAP",
    "CHUNK_PIPELINE_MAX_INPUT_CHARS",
    "CHUNK_SIZE",
    "DEFAULT_CHUNK_OVERLAP",
    "DEFAULT_CHUNK_SIZE",
    "DEFAULT_EMBEDDING_MODEL",
    "DEVICE",
    "EMBEDDING_CACHE_MAX_ENTRIES",
    "EMBEDDING_CACHE_TTL_S",
    "EMBEDDING_MODEL_NAME",
    "EMBED_BATCH_SIZE",
    "FINAL_RERANK_TOP_K",
    "HYBRID_DENSE_ALPHA",
    "HYBRID_RRF_K",
    "HYBRID_SPARSE_WEIGHT",
    "INITIAL_SEARCH_TOP_K",
    "LEXICAL_INDEX_BASENAME",
    "LEXICAL_INDEX_DIR",
    "QDRANT_DEFAULT_ALIAS",
    "QDRANT_DEFAULT_COLLECTION",
    "QDRANT_DISTANCE_METRIC",
    "QDRANT_HNSW_EF_CONSTRUCT",
    "QDRANT_HNSW_FULL_SCAN_THRESHOLD",
    "QDRANT_HNSW_M",
    "QDRANT_HNSW_ON_DISK",
    "QDRANT_ON_DISK_PAYLOAD",
    "QDRANT_OPTIMIZER_DEFAULT_SEGMENT_NUMBER",
    "QDRANT_OPTIMIZER_DELETED_THRESHOLD",
    "QDRANT_OPTIMIZER_FLUSH_INTERVAL_SEC",
    "QDRANT_OPTIMIZER_INDEXING_THRESHOLD",
    "QDRANT_OPTIMIZER_MEMMAP_THRESHOLD",
    "QDRANT_OPTIMIZER_VACUUM_MIN_VECTORS",
    "QDRANT_PAYLOAD_KEY_CHUNK_ID",
    "QDRANT_PAYLOAD_KEY_CONTENT",
    "QDRANT_PAYLOAD_KEY_DOC_ID",
    "QDRANT_PAYLOAD_KEY_METADATA",
    "QDRANT_PAYLOAD_KEY_SOURCE",
    "RERANK_BATCH_SIZE",
    "RERANK_MAX_LENGTH",
    "RERANK_MODEL_NAME",
    "SCORE_THRESHOLD",
    "SEARCH_CACHE_MAX_ENTRIES",
    "SEARCH_CACHE_TTL_S",
    "SEMANTIC_CACHE_SIMILARITY_THRESHOLD",
    "VECTOR_SIZE",
    "VECTOR_TEXT_ENCODING",
]
