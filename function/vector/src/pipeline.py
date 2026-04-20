"""Pełny potok RAG: chunk → embed → upsert → zapytanie → hybryda → rerank."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import hashlib
from dataclasses import dataclass
from typing import Any

import torch
from qdrant_client import QdrantClient

from .chunk import chunk_document
from .embed import TextEmbedder
from .hybrid import fuse_dense_sparse_ids
from .lexical import LexicalIndex
from .rerank import maximal_marginal_relevance
from .search import dense_search
from .store import ChunkPayload, ensure_collection, upsert_points

# TODO:
# [ ] implement full RAG pipeline:
# [ ]     chunk → embed → store (index time)
# [ ]     query → embed → hybrid_search → rerank → return (query time)
# [ ] implement async pipeline: all steps via asyncio
# [ ] implement pipeline monitoring:
# [ ]     OTel spans per step: chunk_count, embed_latency, search_latency, rerank_latency
# [ ] implement multi-collection RAG:
# [ ]     search across multiple Qdrant collections simultaneously
# [ ]     collections from RICE_RAG_COLLECTIONS env var (comma-separated)
# [ ] implement citation tracking:
# [ ]     return source metadata with each retrieved chunk
# [ ]     enable hallucination detection in agent/guard.py
# [ ] implement Temporal activity wrapping for indexing pipeline:
# [ ]     large corpus indexing as long-running Temporal workflow


def _stable_point_id(doc_id: str, chunk_index: int) -> int:
    h = hashlib.sha256(f"{doc_id}:{chunk_index}".encode()).digest()
    return int.from_bytes(h[:8], "big") & 0x7FFFFFFFFFFFFFFF


@dataclass
class RagPipelineConfig:
    collection: str = "rice_rag"
    chunk_strategy: str = "paragraphs"
    chunk_size: int = 1200
    chunk_overlap: int = 120
    top_k_dense: int = 20
    top_k_sparse: int = 20
    top_k_fused: int = 15
    mmr_k: int = 5


class RagPipeline:
    """Chunk → embed → Qdrant; zapytanie: dense (+ opcjonalnie BM25 RRF) → MMR na fragmentach."""

    def __init__(
        self,
        client: QdrantClient,
        embedder: TextEmbedder,
        *,
        lexical: LexicalIndex | None = None,
        config: RagPipelineConfig | None = None,
    ) -> None:
        self.client = client
        self.embedder = embedder
        self.lexical = lexical
        self.config = config or RagPipelineConfig()
        ensure_collection(
            self.client,
            self.config.collection,
            vector_size=embedder.embedding_dim,
        )

    def index_document(self, doc_id: str, text: str, *, meta: dict[str, Any] | None = None) -> int:
        chunks = chunk_document(
            text,
            doc_id,
            strategy=self.config.chunk_strategy,
            chunk_size=self.config.chunk_size,
            overlap=self.config.chunk_overlap,
            extra_meta=meta,
        )
        if not chunks:
            return 0
        texts = [c.text for c in chunks]
        vecs = self.embedder.encode(texts, batch_size=32)
        vecs_list = vecs.cpu().float().tolist()
        ids = [_stable_point_id(doc_id, c.index) for c in chunks]
        payloads = [
            ChunkPayload(
                text=c.text,
                doc_id=c.doc_id,
                chunk_index=c.index,
                meta={**c.meta, **(meta or {})},
            ).model_dump()
            for c in chunks
        ]
        upsert_points(self.client, self.config.collection, ids, vecs_list, payloads)
        return len(chunks)

    def query(
        self,
        query_text: str,
        *,
        query_filter: Any | None = None,
    ) -> list[tuple[str, float, dict[str, Any]]]:
        """Zwraca listę `(doc_id, score, payload)` po MMR; score z fuzji lub dense."""
        cfg = self.config
        qv = self.embedder.encode([query_text], batch_size=1)[0]
        q_list = qv.cpu().float().tolist()

        dense_hits = dense_search(
            self.client,
            cfg.collection,
            q_list,
            limit=cfg.top_k_dense,
            query_filter=query_filter,
        )
        dense_by_doc: dict[str, float] = {}
        best_payload: dict[str, dict[str, Any]] = {}
        for p in dense_hits:
            pl = p.payload or {}
            did = str(pl.get("doc_id", ""))
            if not did:
                continue
            sc = float(p.score or 0.0)
            if did not in dense_by_doc or sc > dense_by_doc[did]:
                dense_by_doc[did] = sc
                best_payload[did] = pl

        dense_ranked = sorted(dense_by_doc.items(), key=lambda x: -x[1])

        if self.lexical is None:
            fused = dense_ranked[: cfg.top_k_fused]
        else:
            sparse_ranked = self.lexical.search(query_text, k=cfg.top_k_sparse, show_progress=False)
            fused = fuse_dense_sparse_ids(dense_ranked, sparse_ranked)[: cfg.top_k_fused]

        if not fused:
            return []

        texts: list[str] = []
        scores: list[float] = []
        metas: list[dict[str, Any]] = []
        doc_ids: list[str] = []
        for did, sc in fused:
            pl = best_payload.get(did, {})
            t = str(pl.get("text", ""))
            if not t:
                continue
            texts.append(t)
            scores.append(sc)
            metas.append(pl)
            doc_ids.append(did)

        if not texts:
            return []

        doc_vecs = self.embedder.encode(texts, batch_size=16)
        order = maximal_marginal_relevance(
            qv,
            doc_vecs,
            k=min(cfg.mmr_k, doc_vecs.shape[0]),
        )
        return [
            (doc_ids[i], scores[i], metas[i])
            for i in order
            if i < len(doc_ids)
        ]
