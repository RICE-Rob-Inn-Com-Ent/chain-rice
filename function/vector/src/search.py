"""Qdrant — async dense search, filters, scroll, and high-level :class:`VectorSearcher`."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import asyncio
import time
from datetime import date, datetime
from typing import Any, cast

import numpy as np
from helper import Page, SchemaBase, logger
from pydantic import ConfigDict, Field
from qdrant_client import AsyncQdrantClient
from qdrant_client.http.models.models import QueryResponse, ScoredPoint
from qdrant_client.models import (
    DatetimeRange,
    FieldCondition,
    Filter,
    MatchValue,
    Range,
)

from .const import (
    QDRANT_PAYLOAD_KEY_CHUNK_ID,
    QDRANT_PAYLOAD_KEY_CONTENT,
    QDRANT_PAYLOAD_KEY_METADATA,
    SCORE_THRESHOLD,
)
from .embed import EmbeddingEngine
from .error import StorageError
from .store import VectorStore, wrap_storage_error


class SearchResult(SchemaBase):
    """One dense hit ready for APIs or downstream reranking."""

    model_config = ConfigDict(str_strip_whitespace=True, extra="ignore")

    chunk_id: str = Field(min_length=1)
    content: str = ""
    metadata: dict[str, Any] = Field(default_factory=dict)
    score: float = Field(default=0.0)
    point_id: str | int | None = Field(
        default=None,
        description="Qdrant point id when available (int hash or UUID string).",
    )

    def to_api_dict(self) -> dict[str, Any]:
        """JSON-friendly dict for HTTP responses."""
        return self.model_dump(mode="json")


def scored_point_to_search_result(point: ScoredPoint) -> SearchResult:
    """Map a Qdrant :class:`ScoredPoint` into :class:`SearchResult` using canonical payload keys."""
    pl = point.payload or {}
    cid = str(pl.get(QDRANT_PAYLOAD_KEY_CHUNK_ID) or "").strip()
    if not cid and point.id is not None:
        cid = str(point.id)
    if not cid:
        cid = "unknown"
    content = str(pl.get(QDRANT_PAYLOAD_KEY_CONTENT) or pl.get("text") or "")
    raw_meta = pl.get(QDRANT_PAYLOAD_KEY_METADATA, pl.get("meta", {}))
    metadata = dict(raw_meta) if isinstance(raw_meta, dict) else {}
    score = float(point.score or 0.0)
    return SearchResult(
        chunk_id=cid,
        content=content,
        metadata=metadata,
        score=score,
        point_id=point.id,
    )


def build_filter(spec: dict[str, Any] | None) -> Filter | None:
    """Build a Qdrant :class:`Filter` from a small declarative dict.

    * Scalar → equality (:class:`MatchValue`) under ``must``.
    * ``{"field": {"$in": [v1, v2, ...]}}`` → ``should`` (match any value) for that field.
    * ``{"field": {"$range": {"gte": 1.0, "lte": 2.0}}}`` → numeric :class:`Range` (float endpoints).
    * ``{"field": {"$datetime_range": {"gte": "2024-01-01", "lte": "..."}}}`` → :class:`DatetimeRange`
      (ISO-8601 strings or ``datetime`` / ``date``).
    """
    if not spec:
        return None

    def _parse_dt(val: Any) -> datetime | date | None:
        if val is None:
            return None
        if isinstance(val, datetime):
            return val
        if isinstance(val, date) and not isinstance(val, datetime):
            return val
        s = str(val).strip().replace("Z", "+00:00")
        try:
            return datetime.fromisoformat(s)
        except ValueError:
            head = s.split("T", maxsplit=1)[0]
            return date.fromisoformat(head)

    must: list[Any] = []

    for key, raw in spec.items():
        k = str(key)
        if isinstance(raw, dict):
            if "$in" in raw:
                vals = raw["$in"]
                if not isinstance(vals, list) or not vals:
                    msg = f"$in for {k!r} must be a non-empty list"
                    raise ValueError(msg)
                should_fc = [FieldCondition(key=k, match=MatchValue(value=v)) for v in vals]
                must.append(Filter(should=should_fc))
            elif "$range" in raw:
                r = raw["$range"]
                if not isinstance(r, dict):
                    msg = f"$range for {k!r} must be a dict"
                    raise ValueError(msg)

                def _f(name: str) -> float | None:
                    x = r.get(name)
                    return float(x) if x is not None else None

                must.append(
                    FieldCondition(
                        key=k,
                        range=Range(gt=_f("gt"), gte=_f("gte"), lt=_f("lt"), lte=_f("lte")),
                    ),
                )
            elif "$datetime_range" in raw:
                dr = raw["$datetime_range"]
                if not isinstance(dr, dict):
                    msg = f"$datetime_range for {k!r} must be a dict"
                    raise ValueError(msg)
                must.append(
                    FieldCondition(
                        key=k,
                        range=DatetimeRange(
                            gt=_parse_dt(dr.get("gt")),
                            gte=_parse_dt(dr.get("gte")),
                            lt=_parse_dt(dr.get("lt")),
                            lte=_parse_dt(dr.get("lte")),
                        ),
                    ),
                )
            else:
                msg = f"unsupported filter operator on field {k!r}: {set(raw)!r}"
                raise ValueError(msg)
        elif isinstance(raw, list):
            if not raw:
                msg = f"list filter for {k!r} must be non-empty (use $in explicitly otherwise)"
                raise ValueError(msg)
            must.append(
                Filter(should=[FieldCondition(key=k, match=MatchValue(value=v)) for v in raw]),
            )
        else:
            must.append(FieldCondition(key=k, match=MatchValue(value=raw)))

    return Filter(must=must) if must else None


class VectorSearcher:
    """Orchestrates query embedding, Qdrant dense retrieval, thresholds, and :class:`SearchResult` rows."""

    __slots__ = ("_embed", "_score_threshold", "_store")

    def __init__(
        self,
        store: VectorStore,
        embed: EmbeddingEngine,
        *,
        score_threshold: float | None = None,
    ) -> None:
        self._store = store
        self._embed = embed
        self._score_threshold = float(SCORE_THRESHOLD if score_threshold is None else score_threshold)

    @property
    def store(self) -> VectorStore:
        return self._store

    @property
    def embed(self) -> EmbeddingEngine:
        return self._embed

    def _effective_threshold(self, override: float | None) -> float:
        return self._score_threshold if override is None else float(override)

    def _apply_score_floor(self, results: list[SearchResult], floor: float) -> list[SearchResult]:
        if floor <= 0.0:
            return results
        return [r for r in results if r.score >= floor]

    @staticmethod
    def _query_filter(filters: dict[str, Any] | Filter | None) -> Filter | None:
        if filters is None:
            return None
        if isinstance(filters, Filter):
            return filters
        return build_filter(filters)

    async def search_dense(
        self,
        query_text: str,
        top_k: int,
        *,
        filters: dict[str, Any] | Filter | None = None,
        score_threshold: float | None = None,
    ) -> list[SearchResult]:
        """Encode ``query_text``, query Qdrant, return thresholded :class:`SearchResult` rows."""
        t0 = time.perf_counter()
        vec_np = await asyncio.to_thread(self._embed.embed_query, query_text)
        vec = cast(list[float], vec_np.astype(np.float64, copy=False).tolist())
        floor = self._effective_threshold(score_threshold)
        q_thr = floor if floor > 0.0 else None
        flt = self._query_filter(filters)

        points = await self._store.query(
            vec,
            top_k,
            filters=flt,
            score_threshold=q_thr,
        )
        out = [scored_point_to_search_result(p) for p in points]
        out = self._apply_score_floor(out, floor)
        elapsed_ms = (time.perf_counter() - t0) * 1000.0
        logger.info(
            "vector search_dense | top_k={} | results={} | latency_ms={:.2f}",
            top_k,
            len(out),
            elapsed_ms,
        )
        return out

    async def search_dense_page(
        self,
        query_text: str,
        *,
        offset: int,
        limit: int,
        filters: dict[str, Any] | Filter | None = None,
        score_threshold: float | None = None,
    ) -> Page[SearchResult]:
        """Dense search with Qdrant ``offset`` / ``limit``; wraps rows in :class:`helper.Page`."""
        t0 = time.perf_counter()
        vec_np = await asyncio.to_thread(self._embed.embed_query, query_text)
        vec = cast(list[float], vec_np.astype(np.float64, copy=False).tolist())
        floor = self._effective_threshold(score_threshold)
        q_thr = floor if floor > 0.0 else None
        flt = self._query_filter(filters)

        points = await self._store.query(
            vec,
            limit,
            filters=flt,
            offset=offset,
            score_threshold=q_thr,
        )
        rows = self._apply_score_floor([scored_point_to_search_result(p) for p in points], floor)
        has_next = len(rows) == limit
        elapsed_ms = (time.perf_counter() - t0) * 1000.0
        logger.info(
            "vector search_dense_page | offset={} | limit={} | results={} | latency_ms={:.2f}",
            offset,
            limit,
            len(rows),
            elapsed_ms,
        )
        return Page[SearchResult](items=rows, offset=offset, limit=limit, total=None, has_next=has_next)

    async def search_by_vector(
        self,
        vector: list[float],
        top_k: int,
        *,
        filters: dict[str, Any] | Filter | None = None,
        score_threshold: float | None = None,
    ) -> list[SearchResult]:
        """Dense search when the query vector is already computed."""
        t0 = time.perf_counter()
        floor = self._effective_threshold(score_threshold)
        q_thr = floor if floor > 0.0 else None
        flt = self._query_filter(filters)

        points = await self._store.query(
            vector,
            top_k,
            filters=flt,
            score_threshold=q_thr,
        )
        out = self._apply_score_floor([scored_point_to_search_result(p) for p in points], floor)
        elapsed_ms = (time.perf_counter() - t0) * 1000.0
        logger.info(
            "vector search_by_vector | top_k={} | results={} | latency_ms={:.2f}",
            top_k,
            len(out),
            elapsed_ms,
        )
        return out

    async def get_by_id(self, point_id: str | int) -> SearchResult | None:
        """Retrieve a single point by Qdrant id (int hash or UUID string). If missing, try ``chunk_id`` payload."""
        t0 = time.perf_counter()
        try:
            batch = await self._store.client.retrieve(
                collection_name=self._store.collection,
                ids=[point_id],
                with_payload=True,
                with_vectors=False,
            )
        except Exception as exc:
            raise wrap_storage_error(
                "get_by_id",
                {"collection": self._store.collection, "id": point_id},
                exc,
            ) from exc
        if batch:
            p = batch[0]
            ver = int(getattr(p, "version", 0) or 0)
            sp = ScoredPoint(id=p.id, score=1.0, version=ver, payload=p.payload, vector=None)
            elapsed_ms = (time.perf_counter() - t0) * 1000.0
            logger.info("vector get_by_id | hit=1 | latency_ms={:.2f}", elapsed_ms)
            return scored_point_to_search_result(sp)

        flt = build_filter({QDRANT_PAYLOAD_KEY_CHUNK_ID: str(point_id)})
        try:
            pts, _ = await self._store.client.scroll(
                collection_name=self._store.collection,
                limit=1,
                offset=None,
                with_payload=True,
                with_vectors=False,
                scroll_filter=flt,
            )
        except Exception as exc:
            raise wrap_storage_error(
                "get_by_id_scroll",
                {"collection": self._store.collection, "chunk_id": str(point_id)},
                exc,
            ) from exc
        if not pts:
            logger.info("vector get_by_id | hit=0 | latency_ms={:.2f}", (time.perf_counter() - t0) * 1000.0)
            return None
        p0 = pts[0]
        ver0 = int(getattr(p0, "version", 0) or 0)
        sp = ScoredPoint(id=p0.id, score=1.0, version=ver0, payload=p0.payload, vector=None)
        logger.info("vector get_by_id | hit=1(chunk_id) | latency_ms={:.2f}", (time.perf_counter() - t0) * 1000.0)
        return scored_point_to_search_result(sp)


async def dense_search(
    client: AsyncQdrantClient,
    collection: str,
    query_vector: list[float],
    *,
    limit: int = 10,
    score_threshold: float | None = None,
    query_filter: Filter | None = None,
    with_payload: bool = True,
    offset: int | None = None,
    using: str | None = None,
) -> list[ScoredPoint]:
    """Nearest-neighbor vector search (async ``query_points``)."""
    try:
        resp: QueryResponse = await client.query_points(
            collection_name=collection,
            query=query_vector,
            using=using,
            limit=limit,
            offset=offset,
            score_threshold=score_threshold,
            query_filter=query_filter,
            with_payload=with_payload,
        )
    except Exception as exc:
        raise wrap_storage_error(
            "dense_search",
            {"collection": collection, "limit": limit},
            exc,
        ) from exc
    return list(resp.points)


def filter_match(field: str, value: str | int | bool) -> Filter:
    """Filter: payload field equals ``value``."""
    return Filter(must=[FieldCondition(key=field, match=MatchValue(value=value))])


def filter_must(conditions: list[FieldCondition]) -> Filter:
    return Filter(must=conditions)


async def scroll_all_ids(
    client: AsyncQdrantClient,
    collection: str,
    *,
    batch_size: int = 256,
    query_filter: Filter | None = None,
) -> list[Any]:
    """All point ids in a collection (reindexing, audit)."""
    ids: list[Any] = []
    offset: Any = None
    try:
        while True:
            points, next_offset = await client.scroll(
                collection_name=collection,
                limit=batch_size,
                offset=offset,
                with_payload=False,
                with_vectors=False,
                scroll_filter=query_filter,
            )
            ids.extend(p.id for p in points)
            if next_offset is None:
                break
            offset = next_offset
    except Exception as exc:
        raise StorageError(
            f"Qdrant scroll failed: {exc!r}",
            error_code="STORAGE_SCROLL_ERROR",
            details={"collection": collection},
        ) from exc
    return ids
