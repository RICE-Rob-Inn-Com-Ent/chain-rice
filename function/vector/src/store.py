"""Async Qdrant vector store — collections, typed upserts, dense query, maintenance."""

from __future__ import annotations

import asyncio
import hashlib
import time
from typing import Any, Self, cast

import numpy as np
from helper import get_settings
from pydantic import BaseModel, ConfigDict, Field, model_validator
from qdrant_client import AsyncQdrantClient
from qdrant_client.http.exceptions import UnexpectedResponse
from qdrant_client.http.models.models import QueryResponse, ScoredPoint
from qdrant_client.models import (
    Distance,
    FieldCondition,
    Filter,
    HnswConfigDiff,
    MatchValue,
    OptimizersConfig,
    PointIdsList,
    PointStruct,
    VectorParams,
)

from .chunk import DocumentChunk
from .const import (
    QDRANT_DEFAULT_COLLECTION,
    QDRANT_DISTANCE_METRIC,
    QDRANT_HNSW_EF_CONSTRUCT,
    QDRANT_HNSW_FULL_SCAN_THRESHOLD,
    QDRANT_HNSW_M,
    QDRANT_HNSW_ON_DISK,
    QDRANT_ON_DISK_PAYLOAD,
    QDRANT_OPTIMIZER_DEFAULT_SEGMENT_NUMBER,
    QDRANT_OPTIMIZER_DELETED_THRESHOLD,
    QDRANT_OPTIMIZER_FLUSH_INTERVAL_SEC,
    QDRANT_OPTIMIZER_INDEXING_THRESHOLD,
    QDRANT_OPTIMIZER_MEMMAP_THRESHOLD,
    QDRANT_OPTIMIZER_VACUUM_MIN_VECTORS,
    QDRANT_PAYLOAD_KEY_CHUNK_ID,
    QDRANT_PAYLOAD_KEY_CONTENT,
    QDRANT_PAYLOAD_KEY_DOC_ID,
    QDRANT_PAYLOAD_KEY_METADATA,
    QDRANT_PAYLOAD_KEY_SOURCE,
    VECTOR_SIZE,
)
from .error import StorageError
from .log import store_logger


def stable_point_id(doc_id: str, chunk_index: int) -> int:
    """Deterministic Qdrant point id from document id and chunk index (positive int63)."""
    h = hashlib.sha256(f"{doc_id}:{chunk_index}".encode()).digest()
    return int.from_bytes(h[:8], "big") & 0x7FFFFFFFFFFFFFFF


def _distance_from_const() -> Distance:
    metric = QDRANT_DISTANCE_METRIC.strip().lower()
    if metric == "cosine":
        return Distance.COSINE
    if metric == "dot":
        return Distance.DOT
    if metric in ("euclid", "euclidean"):
        return Distance.EUCLID
    msg = f"unsupported QDRANT_DISTANCE_METRIC: {QDRANT_DISTANCE_METRIC!r}"
    raise ValueError(msg)


def _vector_params(*, vector_size: int) -> VectorParams:
    return VectorParams(
        size=vector_size,
        distance=_distance_from_const(),
        on_disk=False,
        hnsw_config=HnswConfigDiff(
            m=QDRANT_HNSW_M,
            ef_construct=QDRANT_HNSW_EF_CONSTRUCT,
            full_scan_threshold=QDRANT_HNSW_FULL_SCAN_THRESHOLD,
            on_disk=QDRANT_HNSW_ON_DISK,
        ),
    )


def _optimizers_config() -> OptimizersConfig:
    return OptimizersConfig(
        deleted_threshold=QDRANT_OPTIMIZER_DELETED_THRESHOLD,
        vacuum_min_vector_number=QDRANT_OPTIMIZER_VACUUM_MIN_VECTORS,
        default_segment_number=QDRANT_OPTIMIZER_DEFAULT_SEGMENT_NUMBER,
        indexing_threshold=QDRANT_OPTIMIZER_INDEXING_THRESHOLD,
        memmap_threshold=QDRANT_OPTIMIZER_MEMMAP_THRESHOLD,
        flush_interval_sec=QDRANT_OPTIMIZER_FLUSH_INTERVAL_SEC,
    )


def _filters_dict_to_filter(filters: dict[str, Any] | None) -> Filter | None:
    if not filters:
        return None
    must: list[FieldCondition] = []
    for key, value in filters.items():
        must.append(FieldCondition(key=str(key), match=MatchValue(value=value)))
    return Filter(must=must)


def normalize_query_filter(filters: dict[str, Any] | Filter | None) -> Filter | None:
    """Accept a plain dict (equality) or an explicit :class:`Filter`."""
    if filters is None:
        return None
    if isinstance(filters, Filter):
        return filters
    return _filters_dict_to_filter(filters)


def _numpy_vector_to_list(vec: Any) -> list[float]:
    arr = np.asarray(vec, dtype=np.float32).reshape(-1)
    return cast(list[float], arr.astype(np.float64).tolist())


def wrap_storage_error(op: str, details: dict[str, Any] | None, exc: BaseException) -> StorageError:
    if isinstance(exc, StorageError):
        return exc
    if isinstance(exc, asyncio.TimeoutError):
        err = StorageError(
            f"Qdrant operation timed out: {op}",
            error_code="STORAGE_TIMEOUT",
            details={**(details or {}), "operation": op},
        )
        err.__cause__ = exc
        return err
    if isinstance(exc, UnexpectedResponse):
        err = StorageError(
            f"Qdrant HTTP error during {op}: {exc!r}",
            error_code="STORAGE_HTTP_ERROR",
            details={
                **(details or {}),
                "operation": op,
                "status_code": getattr(exc, "status_code", None),
            },
        )
        err.__cause__ = exc
        return err
    err = StorageError(
        f"Qdrant failure during {op}: {exc!r}",
        error_code="STORAGE_ERROR",
        details={**(details or {}), "operation": op, "type": type(exc).__name__},
    )
    err.__cause__ = exc
    return err


class ChunkPayload(BaseModel):
    """Payload schema for a point — filterable fields aligned with ``const`` Qdrant keys."""

    model_config = ConfigDict(str_strip_whitespace=True, extra="ignore", populate_by_name=True)

    content: str = Field(min_length=1, description="Chunk text body.")
    doc_id: str = Field(min_length=1)
    chunk_index: int = Field(ge=0, default=0)
    metadata: dict[str, Any] = Field(default_factory=dict)
    chunk_id: str | None = None
    source: str | None = None

    @model_validator(mode="before")
    @classmethod
    def _legacy_text_key(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data
        d = dict(data)
        if "text" in d and "content" not in d:
            d["content"] = d.pop("text")
        if "meta" in d and "metadata" not in d:
            d["metadata"] = d.pop("meta")
        return d

    @property
    def text(self) -> str:
        return self.content

    @property
    def meta(self) -> dict[str, Any]:
        return self.metadata

    def to_payload(self) -> dict[str, Any]:
        """Flat dict for Qdrant with canonical keys plus legacy ``text`` / ``meta`` aliases."""
        cid = self.chunk_id or ""
        out: dict[str, Any] = {
            QDRANT_PAYLOAD_KEY_CONTENT: self.content,
            QDRANT_PAYLOAD_KEY_DOC_ID: self.doc_id,
            QDRANT_PAYLOAD_KEY_CHUNK_ID: cid,
            QDRANT_PAYLOAD_KEY_METADATA: dict(self.metadata),
            QDRANT_PAYLOAD_KEY_SOURCE: self.source or "",
            "text": self.content,
            "doc_id": self.doc_id,
            "chunk_index": self.chunk_index,
            "meta": dict(self.metadata),
        }
        return out


def qdrant_payload_from_chunk(
    chunk: DocumentChunk,
    *,
    source: str | None = None,
    chunk_id: str | None = None,
) -> dict[str, Any]:
    """Build a Qdrant payload dict from a :class:`.chunk.DocumentChunk` (metadata for filtering)."""
    cid = chunk_id or f"{chunk.parent_id}:{chunk.chunk_index}"
    return ChunkPayload(
        content=chunk.content,
        doc_id=chunk.parent_id,
        chunk_index=chunk.chunk_index,
        metadata=dict(chunk.metadata),
        chunk_id=cid,
        source=source,
    ).to_payload()


class VectorStore:
    """Async Qdrant façade — owns or borrows an :class:`AsyncQdrantClient`."""

    __slots__ = ("_client", "_collection", "_owns_client", "_vector_size")

    def __init__(
        self,
        client: AsyncQdrantClient,
        *,
        collection: str,
        vector_size: int,
        owns_client: bool = False,
    ) -> None:
        self._client = client
        self._collection = collection
        self._vector_size = vector_size
        self._owns_client = owns_client

    @property
    def client(self) -> AsyncQdrantClient:
        return self._client

    @property
    def collection(self) -> str:
        return self._collection

    @property
    def vector_size(self) -> int:
        return self._vector_size

    @classmethod
    async def connect(
        cls,
        *,
        collection: str | None = None,
        vector_size: int | None = None,
        url: str | None = None,
        api_key: str | None = None,
    ) -> Self:
        """Create a store with a new async client from ``helper.get_settings()`` (or overrides)."""
        settings = get_settings()
        uri = url or settings.qdrant_url
        key = settings.qdrant_api_key if api_key is None else api_key
        timeout_s = max(1, int(settings.http_read_timeout_s))
        kwargs: dict[str, Any] = {"url": uri, "timeout": timeout_s}
        if key:
            kwargs["api_key"] = key
        try:
            client = AsyncQdrantClient(**kwargs)
        except Exception as exc:
            raise wrap_storage_error(
                "connect",
                {"url": uri},
                exc,
            ) from exc
        return cls(
            client,
            collection=collection or QDRANT_DEFAULT_COLLECTION,
            vector_size=int(vector_size or VECTOR_SIZE),
            owns_client=True,
        )

    async def aclose(self) -> None:
        if self._owns_client:
            await self._client.close()

    async def __aenter__(self) -> Self:
        return self

    async def __aexit__(self, *args: object) -> None:
        await self.aclose()

    async def ensure_collection(
        self,
        *,
        on_disk_payload: bool | None = None,
    ) -> None:
        await ensure_collection(
            self._client,
            self._collection,
            vector_size=self._vector_size,
            on_disk_payload=on_disk_payload if on_disk_payload is not None else QDRANT_ON_DISK_PAYLOAD,
        )

    async def upsert_batch(
        self,
        chunks: list[DocumentChunk],
        vectors: list[Any],
        *,
        wait: bool = True,
        source: str | None = None,
    ) -> None:
        if len(chunks) != len(vectors):
            msg = "chunks and vectors must have the same length"
            raise ValueError(msg)
        if not chunks:
            return
        t0 = time.perf_counter()
        ids = [stable_point_id(c.parent_id, c.chunk_index) for c in chunks]
        points: list[PointStruct] = []
        for pid, chunk, vec in zip(ids, chunks, vectors, strict=True):
            vec_list = _numpy_vector_to_list(vec)
            if len(vec_list) != self._vector_size:
                msg = f"vector dim {len(vec_list)} != expected {self._vector_size}"
                raise ValueError(msg)
            payload = qdrant_payload_from_chunk(chunk, source=source)
            points.append(PointStruct(id=pid, vector=vec_list, payload=payload))
        try:
            await self._client.upsert(collection_name=self._collection, points=points, wait=wait)
        except Exception as exc:
            raise wrap_storage_error(
                "upsert_batch",
                {"collection": self._collection, "n_points": len(points)},
                exc,
            ) from exc
        elapsed_ms = (time.perf_counter() - t0) * 1000.0
        store_logger.info(
            "qdrant upsert_batch | collection={} | points={} | latency_ms={:.2f}",
            self._collection,
            len(points),
            elapsed_ms,
        )

    async def query(
        self,
        vector: list[float],
        top_k: int,
        filters: dict[str, Any] | Filter | None = None,
        *,
        offset: int | None = None,
        score_threshold: float | None = None,
        with_vectors: bool = False,
    ) -> list[ScoredPoint]:
        if len(vector) != self._vector_size:
            msg = f"query vector dim {len(vector)} != expected {self._vector_size}"
            raise ValueError(msg)
        flt = normalize_query_filter(filters)
        try:
            resp: QueryResponse = await self._client.query_points(
                collection_name=self._collection,
                query=vector,
                limit=top_k,
                offset=offset,
                score_threshold=score_threshold,
                query_filter=flt,
                with_payload=True,
                with_vectors=with_vectors,
            )
        except Exception as exc:
            raise wrap_storage_error(
                "query",
                {"collection": self._collection, "top_k": top_k},
                exc,
            ) from exc
        return list(resp.points)

    async def delete_collection(self) -> None:
        await delete_collection(self._client, self._collection)

    async def clear_collection(self) -> None:
        await clear_collection(self._client, self._collection)


# --- Optional process-wide singleton (explicit opt-in) -----------------------------------------

_store_singleton: VectorStore | None = None
_store_singleton_lock = asyncio.Lock()


async def get_vector_store_singleton(
    *,
    collection: str | None = None,
    vector_size: int | None = None,
    reset: bool = False,
) -> VectorStore:
    """Return a shared :class:`VectorStore` (lazy). Use ``reset=True`` in tests."""
    global _store_singleton
    async with _store_singleton_lock:
        if reset:
            if _store_singleton is not None:
                await _store_singleton.aclose()
            _store_singleton = None
        if _store_singleton is None:
            _store_singleton = await VectorStore.connect(collection=collection, vector_size=vector_size)
        return _store_singleton


# --- Module-level async API (pass-through ``AsyncQdrantClient``) -------------------------------


async def ensure_collection(
    client: AsyncQdrantClient,
    name: str,
    *,
    vector_size: int,
    distance: Distance | None = None,
    on_disk_payload: bool | None = None,
) -> None:
    """Create the collection if missing, with HNSW + optimizer defaults from ``const``."""
    _ = distance  # reserved — metric driven by ``QDRANT_DISTANCE_METRIC``
    on_disk = QDRANT_ON_DISK_PAYLOAD if on_disk_payload is None else on_disk_payload
    try:
        await client.get_collection(name)
        return
    except UnexpectedResponse as exc:
        if getattr(exc, "status_code", None) != 404:
            raise wrap_storage_error("ensure_collection", {"collection": name}, exc) from exc
    except Exception as exc:
        raise wrap_storage_error("ensure_collection", {"collection": name}, exc) from exc
    try:
        await client.create_collection(
            collection_name=name,
            vectors_config=_vector_params(vector_size=vector_size),
            optimizers_config=_optimizers_config(),
            on_disk_payload=on_disk,
        )
    except Exception as exc:
        raise wrap_storage_error(
            "ensure_collection",
            {"collection": name, "vector_size": vector_size},
            exc,
        ) from exc
    store_logger.info("created qdrant collection {} | vector_size={}", name, vector_size)


async def upsert_points(
    client: AsyncQdrantClient,
    collection: str,
    ids: list[int],
    vectors: list[list[float]] | list[Any],
    payloads: list[dict[str, Any]],
    *,
    wait: bool = True,
) -> None:
    """Upsert numeric-id points using :class:`PointStruct` (async)."""
    if not (len(ids) == len(vectors) == len(payloads)):
        msg = "ids, vectors, and payloads must have equal length"
        raise ValueError(msg)
    if not ids:
        return
    t0 = time.perf_counter()
    points: list[PointStruct] = []
    for i, v, p in zip(ids, vectors, payloads, strict=True):
        vec_list = v if isinstance(v, list) and not isinstance(v, (bytes, bytearray)) else _numpy_vector_to_list(v)
        points.append(PointStruct(id=i, vector=vec_list, payload=p))
    try:
        await client.upsert(collection_name=collection, points=points, wait=wait)
    except Exception as exc:
        raise wrap_storage_error(
            "upsert_points",
            {"collection": collection, "n_points": len(points)},
            exc,
        ) from exc
    elapsed_ms = (time.perf_counter() - t0) * 1000.0
    store_logger.info(
        "qdrant upsert_points | collection={} | points={} | latency_ms={:.2f}",
        collection,
        len(points),
        elapsed_ms,
    )


async def delete_collection(client: AsyncQdrantClient, name: str) -> None:
    try:
        await client.delete_collection(collection_name=name)
    except Exception as exc:
        raise wrap_storage_error("delete_collection", {"collection": name}, exc) from exc


async def clear_collection(client: AsyncQdrantClient, name: str, *, batch_size: int = 512) -> None:
    """Remove all points from a collection (keeps collection and vector config)."""
    offset: Any = None
    total = 0
    t0 = time.perf_counter()
    try:
        while True:
            points, next_offset = await client.scroll(
                collection_name=name,
                limit=batch_size,
                offset=offset,
                with_payload=False,
                with_vectors=False,
            )
            if not points:
                break
            ids_batch = [p.id for p in points]
            await client.delete(collection_name=name, points_selector=PointIdsList(points=ids_batch), wait=True)
            total += len(ids_batch)
            if next_offset is None:
                break
            offset = next_offset
    except Exception as exc:
        raise wrap_storage_error("clear_collection", {"collection": name}, exc) from exc
    elapsed_ms = (time.perf_counter() - t0) * 1000.0
    store_logger.info(
        "qdrant clear_collection | collection={} | deleted_points={} | latency_ms={:.2f}",
        name,
        total,
        elapsed_ms,
    )


async def create_snapshot(client: AsyncQdrantClient, collection: str) -> str | None:
    try:
        snap = await client.create_snapshot(collection_name=collection)
        return getattr(snap, "name", None) or str(snap)
    except Exception as exc:
        store_logger.warning("qdrant snapshot failed | collection={} | err={}", collection, exc)
        return None


async def list_collections(client: AsyncQdrantClient) -> list[str]:
    try:
        cols = await client.get_collections()
    except Exception as exc:
        raise wrap_storage_error("list_collections", {}, exc) from exc
    return [c.name for c in cols.collections]
