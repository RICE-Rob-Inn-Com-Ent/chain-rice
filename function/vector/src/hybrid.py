"""Dense + sparse — RRF, weighted fusion, and :class:`HybridSearcher` orchestration."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import asyncio
from collections import defaultdict
from collections.abc import Sequence
from typing import Any

from helper import logger

from .const import HYBRID_RRF_K, INITIAL_SEARCH_TOP_K
from .lexical import LexicalEngine, LexicalHit
from .search import SearchResult, VectorSearcher


def _rrf_from_doc_rankings(
    rankings: list[list[tuple[str, float]]],
    *,
    k: int,
    weights: Sequence[float] | None = None,
) -> list[tuple[str, float]]:
    """RRF over doc-id rankings: ``score(d) = sum_i w_i / (k + rank_i(d))``."""
    acc: dict[str, float] = defaultdict(float)
    ws = list(weights) if weights is not None else [1.0] * len(rankings)
    if len(ws) != len(rankings):
        msg = "weights length must match rankings length"
        raise ValueError(msg)
    for w, ranked in zip(ws, rankings, strict=True):
        for rank, (doc_id, _s) in enumerate(ranked, start=1):
            acc[doc_id] += float(w) * (1.0 / (float(k) + float(rank)))
    return sorted(acc.items(), key=lambda x: -x[1])


def fuse_dense_sparse_ids(
    dense_ranked: list[tuple[str, float]],
    sparse_ranked: list[tuple[str, float]],
    *,
    rrf_k: int = HYBRID_RRF_K,
    weight_factor: float | None = None,
) -> list[tuple[str, float]]:
    """Fuse dense + sparse **doc-level** scores (legacy pipeline)."""
    if weight_factor is None:
        weights = None
    else:
        a = float(weight_factor)
        weights = [a, 1.0 - a]
    return _rrf_from_doc_rankings([dense_ranked, sparse_ranked], k=rrf_k, weights=weights)


def _rank_of(results: list[SearchResult], chunk_id: str) -> int | None:
    for i, r in enumerate(results, start=1):
        if r.chunk_id == chunk_id:
            return i
    return None


def reciprocal_rank_fusion(
    dense_results: list[SearchResult],
    sparse_results: list[SearchResult],
    *,
    k: int = HYBRID_RRF_K,
    weight_factor: float | None = None,
) -> list[SearchResult]:
    """Fuse **chunk-level** :class:`SearchResult` lists with RRF (key = ``chunk_id``).

    When ``weight_factor`` (α) is set in ``[0, 1]``, dense uses weight α and sparse ``1-α``.
    When ``None``, both lists use weight ``1.0`` (standard RRF).
    """
    if weight_factor is None:
        w_dense, w_sparse = 1.0, 1.0
    else:
        a = max(0.0, min(1.0, float(weight_factor)))
        w_dense, w_sparse = a, 1.0 - a

    acc: dict[str, float] = defaultdict(float)
    for rank, r in enumerate(dense_results, start=1):
        acc[r.chunk_id] += w_dense * (1.0 / (float(k) + float(rank)))
    for rank, r in enumerate(sparse_results, start=1):
        acc[r.chunk_id] += w_sparse * (1.0 / (float(k) + float(rank)))

    dense_by = {r.chunk_id: r for r in dense_results}
    sparse_by = {r.chunk_id: r for r in sparse_results}
    order = sorted(acc.keys(), key=lambda cid: -acc[cid])

    out: list[SearchResult] = []
    for cid in order:
        d, s = dense_by.get(cid), sparse_by.get(cid)
        meta: dict[str, Any] = {}
        content = ""
        point_id: str | int | None = None
        if s is not None:
            meta.update(s.metadata)
            content = s.content or content
        if d is not None:
            meta.update(d.metadata)
            content = d.content or content
            point_id = d.point_id
        meta["rrf_score"] = float(acc[cid])
        meta["hybrid_dense_rank"] = _rank_of(dense_results, cid)
        meta["hybrid_sparse_rank"] = _rank_of(sparse_results, cid)
        out.append(
            SearchResult(
                chunk_id=cid,
                content=content,
                metadata=meta,
                score=float(acc[cid]),
                point_id=point_id,
            ),
        )
    return out


def align_by_id(
    ordered_ids: list[str],
    payloads: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    """Order payloads by id (e.g. after doc-level fusion)."""
    return [payloads[i] for i in ordered_ids if i in payloads]


def _lexical_hits_to_search_results(lex: LexicalEngine, hits: list[LexicalHit]) -> list[SearchResult]:
    """Materialize lexical rows into :class:`SearchResult` (content from the BM25 corpus)."""
    if not hits:
        return []
    index = {cid: i for i, cid in enumerate(lex._chunk_ids)}
    out: list[SearchResult] = []
    for h in hits:
        i = index.get(h.chunk_id)
        if i is None or not (0 <= i < len(lex._contents)):
            out.append(
                SearchResult(
                    chunk_id=h.chunk_id,
                    content="",
                    metadata={"doc_id": h.doc_id, "source": "lexical"},
                    score=float(h.score),
                    point_id=None,
                ),
            )
            continue
        out.append(
            SearchResult(
                chunk_id=h.chunk_id,
                content=lex._contents[i],
                metadata={"doc_id": lex._doc_ids[i], "source": "lexical"},
                score=float(h.score),
                point_id=None,
            ),
        )
    return out


class HybridSearcher:
    """Runs dense (Qdrant) and lexical (BM25S) in parallel, then fuses with RRF into :class:`SearchResult`."""

    __slots__ = ("_dense", "_lexical", "_rrf_k")

    def __init__(
        self,
        dense: VectorSearcher,
        lexical: LexicalEngine,
        *,
        rrf_k: int | None = None,
    ) -> None:
        self._dense = dense
        self._lexical = lexical
        self._rrf_k = int(rrf_k if rrf_k is not None else HYBRID_RRF_K)

    @property
    def dense(self) -> VectorSearcher:
        return self._dense

    @property
    def lexical(self) -> LexicalEngine:
        return self._lexical

    def _candidate_fetch_size(self, top_k: int) -> int:
        return max(int(top_k) * 2, min(int(INITIAL_SEARCH_TOP_K), max(int(top_k), 50)))

    async def search(
        self,
        query: str,
        top_k: int,
        *,
        weight_factor: float | None = None,
    ) -> list[SearchResult]:
        """Parallel dense + lexical search, RRF fusion, top-``top_k`` chunk results.

        ``weight_factor`` (α): ``None`` → standard RRF (weight 1 on each list). Set α in ``[0, 1]`` for
        weighted RRF (dense × α + sparse × (1−α)). If one engine fails, the other list still ranks.
        """
        fetch = self._candidate_fetch_size(top_k)

        async def _dense_task() -> list[SearchResult]:
            try:
                return await self._dense.search_dense(query, fetch)
            except Exception as exc:
                logger.warning("hybrid: dense search failed, sparse-only | err={!r}", exc)
                return []

        def _lexical_task() -> list[LexicalHit]:
            try:
                return self._lexical.search(query, top_k=fetch, show_progress=False)
            except Exception as exc:
                logger.warning("hybrid: lexical search failed, dense-only | err={!r}", exc)
                return []

        dense_hits, lexical_hits = await asyncio.gather(_dense_task(), asyncio.to_thread(_lexical_task))
        sparse_results = _lexical_hits_to_search_results(self._lexical, lexical_hits)

        dense_ids = {r.chunk_id for r in dense_hits}
        sparse_ids = {r.chunk_id for r in sparse_results}
        logger.info(
            "hybrid: overlap | dense={} sparse={} intersection={}",
            len(dense_ids),
            len(sparse_ids),
            len(dense_ids & sparse_ids),
        )

        if not dense_hits and not sparse_results:
            return []

        fused = reciprocal_rank_fusion(
            dense_hits,
            sparse_results,
            k=self._rrf_k,
            weight_factor=weight_factor,
        )
        return fused[: max(1, int(top_k))]


__all__ = [
    "HybridSearcher",
    "align_by_id",
    "fuse_dense_sparse_ids",
    "reciprocal_rank_fusion",
]
