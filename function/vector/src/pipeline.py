"""Vector orchestration — :class:`VectorPipeline` (ingest / search / context) and legacy :class:`RagPipeline`."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import asyncio
import time
import uuid
from dataclasses import dataclass, field
from typing import Any

import torch
from helper import RiceError, logger  # type: ignore[import-untyped]
from qdrant_client import AsyncQdrantClient

from .chunk import DocumentChunk, RecursiveCharacterChunker, chunk_document, prepare_plaintext
from .const import (
    CHUNK_OVERLAP,
    CHUNK_SIZE,
    EMBED_BATCH_SIZE,
    HYBRID_RRF_K,
    INITIAL_SEARCH_TOP_K,
    QDRANT_DEFAULT_COLLECTION,
    QDRANT_PAYLOAD_KEY_CONTENT,
    QDRANT_PAYLOAD_KEY_DOC_ID,
)
from .embed import EmbeddingEngine, TextEmbedder
from .hybrid import HybridSearcher, fuse_dense_sparse_ids
from .lexical import LexicalEngine, aggregate_lexical_hits_by_doc
from .rerank import get_reranker, maximal_marginal_relevance
from .search import SearchResult, VectorSearcher, dense_search
from .settings import get_settings
from .store import ChunkPayload, VectorStore, ensure_collection, stable_point_id, upsert_points

# --- VectorPipeline (primary orchestrator) -------------------------------------------------------


def _resolve_doc_id(metadata: dict[str, Any]) -> str:
    raw = metadata.get("doc_id") or metadata.get("parent_id")
    if raw is not None and str(raw).strip():
        return str(raw).strip()
    return uuid.uuid4().hex


def _rerank_enabled_from_settings() -> bool:
    try:
        return bool(get_settings().use_reranker)
    except Exception as exc:
        logger.warning("VectorPipeline: get_settings failed; rerank disabled | err={!r}", exc)
        return False


@dataclass
class VectorPipelineConfig:
    """Tuning knobs for chunking, embedding batching, hybrid pool size, and rerank."""

    chunk_size: int = CHUNK_SIZE
    chunk_overlap: int = CHUNK_OVERLAP
    embed_batch_size: int = EMBED_BATCH_SIZE
    hybrid_rrf_k: int = HYBRID_RRF_K
    """Minimum hybrid candidate count before optional rerank (``max(top_k * factor, const)``)."""

    rerank_pool_factor: int = 4


@dataclass
class IngestOutcome:
    """Per-document result from :meth:`VectorPipeline.ingest_batch`."""

    doc_id: str
    chunks_written: int
    ok: bool
    error: str | None = None


@dataclass
class VectorPipeline:
    """Chunk → embed → Qdrant + BM25; query → hybrid (dense + lexical) → optional rerank."""

    store: VectorStore
    embed: EmbeddingEngine
    lexical: LexicalEngine
    hybrid: HybridSearcher
    config: VectorPipelineConfig = field(default_factory=VectorPipelineConfig)

    def __post_init__(self) -> None:
        if self.store.vector_size != self.embed.embedding_dim:
            msg = (
                f"VectorStore.vector_size ({self.store.vector_size}) "
                f"!= EmbeddingEngine.embedding_dim ({self.embed.embedding_dim})"
            )
            raise ValueError(msg)

    @classmethod
    async def connect(
        cls,
        *,
        collection: str | None = None,
        lexical: LexicalEngine | None = None,
        config: VectorPipelineConfig | None = None,
    ) -> VectorPipeline:
        """Build a pipeline from ``helper`` settings (Qdrant URL, timeouts) and shared singletons."""
        cfg = config or VectorPipelineConfig()
        store = await VectorStore.connect(collection=collection)
        embed = EmbeddingEngine()
        lex = lexical if lexical is not None else LexicalEngine()
        dense = VectorSearcher(store, embed)
        hybrid = HybridSearcher(dense, lex, rrf_k=cfg.hybrid_rrf_k)
        return cls(store=store, embed=embed, lexical=lex, hybrid=hybrid, config=cfg)

    def _chunk_with_recursive_splitter(self, text: str, doc_id: str, metadata: dict[str, Any]) -> list[DocumentChunk]:
        prepared = prepare_plaintext(text)
        if not prepared.strip():
            return []
        chunker = RecursiveCharacterChunker(
            chunk_size=self.config.chunk_size,
            chunk_overlap=self.config.chunk_overlap,
        )
        base_meta = {k: v for k, v in metadata.items() if k not in {"doc_id", "parent_id"}}
        out: list[DocumentChunk] = []
        idx = 0
        for fragment in chunker.iter_chunks(prepared):
            frag = fragment.strip()
            if not frag:
                continue
            cid = f"{doc_id}:{idx}"
            meta = {
                **base_meta,
                "doc_id": doc_id,
                "chunk_id": cid,
            }
            out.append(
                DocumentChunk(
                    content=frag,
                    parent_id=doc_id,
                    chunk_index=idx,
                    metadata=meta,
                ),
            )
            idx += 1
        return out

    async def ingest_text(self, text: str, metadata: dict[str, Any]) -> int:
        """Chunk with :class:`~.chunk.RecursiveCharacterChunker`, embed, upsert Qdrant, extend BM25."""
        outcome = (await self.ingest_batch([(text, metadata)]))[0]
        if not outcome.ok:
            msg = outcome.error or "ingest failed"
            raise RiceError(
                msg,
                error_code="PIPELINE_INGEST_FAILED",
                details={"doc_id": outcome.doc_id},
            )
        return outcome.chunks_written

    async def ingest_batch(self, documents: list[tuple[str, dict[str, Any]]]) -> list[IngestOutcome]:
        """Ingest many ``(text, metadata)`` tuples; failures are isolated and logged per document."""
        outcomes: list[IngestOutcome] = []
        t0 = time.perf_counter()
        for body, meta in documents:
            doc_id = _resolve_doc_id(meta)
            try:
                n = await self._ingest_one(body, meta, doc_id)
                outcomes.append(IngestOutcome(doc_id=doc_id, chunks_written=n, ok=True, error=None))
            except Exception as exc:
                logger.error(
                    "VectorPipeline.ingest_batch: doc failed (Qdrant unchanged for this doc) | doc_id={} | err={!r}",
                    doc_id,
                    exc,
                )
                outcomes.append(
                    IngestOutcome(
                        doc_id=doc_id,
                        chunks_written=0,
                        ok=False,
                        error=f"{type(exc).__name__}: {exc}",
                    ),
                )
        elapsed_ms = (time.perf_counter() - t0) * 1000.0
        ok_n = sum(1 for o in outcomes if o.ok)
        logger.info(
            "VectorPipeline.ingest_batch | docs={} ok={} | latency_ms={:.2f}",
            len(outcomes),
            ok_n,
            elapsed_ms,
        )
        return outcomes

    async def _ingest_one(self, text: str, metadata: dict[str, Any], doc_id: str) -> int:
        chunks = self._chunk_with_recursive_splitter(text, doc_id, metadata)
        if not chunks:
            logger.warning("VectorPipeline.ingest: no chunks after split | doc_id={}", doc_id)
            return 0

        await self.store.ensure_collection()
        texts = [c.content for c in chunks]

        def _encode() -> Any:
            return self.embed.embed_documents(texts, batch_size=self.config.embed_batch_size, use_cache=False)

        try:
            vectors = await asyncio.to_thread(_encode)
        except Exception as exc:
            logger.error("VectorPipeline.ingest: embedding failed | doc_id={} | err={!r}", doc_id, exc)
            raise

        try:
            await self.store.upsert_batch(chunks, list(vectors), wait=True, source=None)
        except Exception as exc:
            logger.error(
                "VectorPipeline.ingest: Qdrant upsert failed (lexical not updated for this doc) | doc_id={} | err={!r}",
                doc_id,
                exc,
            )
            raise

        def _lexical_add() -> None:
            try:
                self.lexical.add_documents(chunks, show_progress=False)
            except Exception as lex_exc:
                logger.error(
                    "VectorPipeline.ingest: lexical index failed after successful Qdrant upsert | doc_id={} | err={!r}",
                    doc_id,
                    lex_exc,
                )

        await asyncio.to_thread(_lexical_add)
        return len(chunks)

    def _hybrid_pool_size(self, top_k: int) -> int:
        base = max(1, int(top_k)) * max(1, int(self.config.rerank_pool_factor))
        return max(base, int(INITIAL_SEARCH_TOP_K))

    async def search(
        self,
        query: str,
        top_k: int,
        *,
        weight_factor: float | None = None,
        force_rerank: bool | None = None,
    ) -> list[SearchResult]:
        """Hybrid search, optional cross-encoder rerank (``RICE_USE_RERANKER``), sorted by score."""
        t0 = time.perf_counter()
        k_out = max(1, int(top_k))
        use_rr = bool(force_rerank) if force_rerank is not None else _rerank_enabled_from_settings()
        pool = self._hybrid_pool_size(k_out) if use_rr else k_out

        hybrid_results = await self.hybrid.search(query, pool, weight_factor=weight_factor)
        if not hybrid_results:
            logger.info("VectorPipeline.search | hits=0 | latency_ms={:.2f}", (time.perf_counter() - t0) * 1000.0)
            return []

        if use_rr:
            rr = get_reranker()
            if not rr.bypass:

                def _rerank() -> list[SearchResult]:
                    return rr.rerank(query, hybrid_results, top_n=k_out)

                try:
                    hybrid_results = await asyncio.to_thread(_rerank)
                except RiceError as exc:
                    logger.warning(
                        "VectorPipeline.search: rerank failed, returning hybrid order | err={!r}",
                        exc,
                    )
                    hybrid_results = hybrid_results[:k_out]
            else:
                hybrid_results = hybrid_results[:k_out]
        else:
            hybrid_results = hybrid_results[:k_out]

        hybrid_results.sort(key=lambda r: float(r.score), reverse=True)
        elapsed_ms = (time.perf_counter() - t0) * 1000.0
        logger.info(
            "VectorPipeline.search | top_k={} | rerank={} | results={} | latency_ms={:.2f}",
            k_out,
            use_rr,
            len(hybrid_results),
            elapsed_ms,
        )
        return hybrid_results

    async def get_context(self, query: str, top_k: int) -> str:
        """Format ranked hits as a single context block for LLM prompts."""
        rows = await self.search(query, top_k)
        if not rows:
            return ""
        parts: list[str] = []
        for i, r in enumerate(rows, start=1):
            did = str(r.metadata.get("doc_id") or "")
            head = f"[{i}] chunk_id={r.chunk_id} score={float(r.score):.4f}"
            if did:
                head += f" doc_id={did}"
            parts.append(f"{head}\n{r.content.strip()}")
        return "\n\n---\n\n".join(parts)

    async def clear_all(self) -> None:
        """Wipe Qdrant points in the pipeline collection and reset the in-memory lexical index."""
        t0 = time.perf_counter()

        def _lex() -> None:
            self.lexical.clear()

        results = await asyncio.gather(
            self.store.clear_collection(),
            asyncio.to_thread(_lex),
            return_exceptions=True,
        )
        errors = [x for x in results if isinstance(x, BaseException)]
        for label, item in zip(("qdrant", "lexical"), results, strict=True):
            if isinstance(item, BaseException):
                logger.error("VectorPipeline.clear_all: {} failed | err={!r}", label, item)
        elapsed_ms = (time.perf_counter() - t0) * 1000.0
        logger.warning(
            "VectorPipeline.clear_all | collection={} | errors={} | latency_ms={:.2f}",
            self.store.collection,
            len(errors),
            elapsed_ms,
        )
        if errors:
            raise errors[0]


# --- Legacy RagPipeline (AsyncQdrantClient + TextEmbedder protocol) ------------------------------


@dataclass
class RagPipelineConfig:
    collection: str = QDRANT_DEFAULT_COLLECTION
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
        client: AsyncQdrantClient,
        embedder: TextEmbedder,
        *,
        lexical: LexicalEngine | None = None,
        config: RagPipelineConfig | None = None,
    ) -> None:
        self.client = client
        self.embedder = embedder
        self.lexical = lexical
        self.config = config or RagPipelineConfig()
        self._collection_ready = False

    async def _ensure_collection(self) -> None:
        if self._collection_ready:
            return
        await ensure_collection(
            self.client,
            self.config.collection,
            vector_size=self.embedder.embedding_dim,
        )
        self._collection_ready = True

    async def index_document(self, doc_id: str, text: str, *, meta: dict[str, Any] | None = None) -> int:
        await self._ensure_collection()
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
        ids = [stable_point_id(doc_id, c.index) for c in chunks]
        payloads = [
            ChunkPayload(
                content=c.text,
                doc_id=c.doc_id,
                chunk_index=c.index,
                metadata={**c.meta, **(meta or {})},
            ).to_payload()
            for c in chunks
        ]
        await upsert_points(self.client, self.config.collection, ids, vecs_list, payloads)
        return len(chunks)

    async def query(
        self,
        query_text: str,
        *,
        query_filter: Any | None = None,
    ) -> list[tuple[str, float, dict[str, Any]]]:
        """Zwraca listę `(doc_id, score, payload)` po MMR; score z fuzji lub dense."""
        await self._ensure_collection()
        cfg = self.config
        qv = self.embedder.encode([query_text], batch_size=1)[0]
        q_list = qv.cpu().float().tolist()

        dense_hits = await dense_search(
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
            did = str(pl.get(QDRANT_PAYLOAD_KEY_DOC_ID) or pl.get("doc_id", ""))
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
            sparse_hits = self.lexical.search(
                query_text,
                k=cfg.top_k_sparse,
                show_progress=False,
            )
            sparse_ranked = aggregate_lexical_hits_by_doc(sparse_hits)
            fused = fuse_dense_sparse_ids(dense_ranked, sparse_ranked)[: cfg.top_k_fused]

        if not fused:
            return []

        texts: list[str] = []
        scores: list[float] = []
        metas: list[dict[str, Any]] = []
        doc_ids: list[str] = []
        for did, sc in fused:
            pl = best_payload.get(did, {})
            t = str(pl.get(QDRANT_PAYLOAD_KEY_CONTENT) or pl.get("text", ""))
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


__all__ = [
    "IngestOutcome",
    "RagPipeline",
    "RagPipelineConfig",
    "VectorPipeline",
    "VectorPipelineConfig",
]
