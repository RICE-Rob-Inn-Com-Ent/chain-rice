"""Vector — embeddingi, Qdrant, BM25, hybryda RRF, chunking, RAG pipeline."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from .chunk import TextChunk, chunk_document, split_fixed_windows, split_paragraphs_then_windows, strip_html
from .embed import (
    HashProjectionEmbedder,
    SentenceTransformerEmbedder,
    TextEmbedder,
    encode_image_batch_dummy,
    encode_text_batches,
    pick_device,
    to_device,
)
from .hybrid import align_by_id, fuse_dense_sparse_ids, reciprocal_rank_fusion
from .lexical import LexicalIndex, default_stopwords_lang
from .pipeline import RagPipeline, RagPipelineConfig
from .rerank import (
    cross_encoder_rerank_stub,
    dedupe_by_doc_id,
    maximal_marginal_relevance,
    numpy_cosine_matrix,
)
from .search import dense_search, filter_match, filter_must, scroll_all_ids
from .store import ChunkPayload, create_snapshot, delete_collection, ensure_collection, list_collections, upsert_points

__all__ = [
    "ChunkPayload",
    "HashProjectionEmbedder",
    "LexicalIndex",
    "RagPipeline",
    "RagPipelineConfig",
    "SentenceTransformerEmbedder",
    "TextChunk",
    "TextEmbedder",
    "align_by_id",
    "chunk_document",
    "create_snapshot",
    "dedupe_by_doc_id",
    "default_stopwords_lang",
    "delete_collection",
    "dense_search",
    "encode_image_batch_dummy",
    "encode_text_batches",
    "ensure_collection",
    "filter_match",
    "filter_must",
    "fuse_dense_sparse_ids",
    "list_collections",
    "maximal_marginal_relevance",
    "numpy_cosine_matrix",
    "pick_device",
    "reciprocal_rank_fusion",
    "scroll_all_ids",
    "split_fixed_windows",
    "split_paragraphs_then_windows",
    "strip_html",
    "to_device",
    "upsert_points",
    "cross_encoder_rerank_stub",
]
