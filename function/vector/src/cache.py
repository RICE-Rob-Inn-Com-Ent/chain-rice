"""Async LRU+TTL caches for embeddings and search; uses helper (get_settings, logger, RiceError)."""

from __future__ import annotations  # noqa: I001

import asyncio
import hashlib
import threading
import inspect
import json
import struct
import time
from collections import OrderedDict
from collections.abc import Awaitable, Callable, Mapping, Sequence
from dataclasses import dataclass
from functools import wraps
from typing import Any, cast

import numpy as np
import torch

from helper import RiceError, get_settings, logger  # type: ignore[import-untyped]

from .const import (
    DEFAULT_EMBEDDING_MODEL,
    EMBEDDING_CACHE_MAX_ENTRIES,
    EMBEDDING_CACHE_TTL_S,
    SEARCH_CACHE_MAX_ENTRIES,
    SEARCH_CACHE_TTL_S,
    SEMANTIC_CACHE_SIMILARITY_THRESHOLD,
    VECTOR_SIZE,
    VECTOR_TEXT_ENCODING,
)


def _sha256_hex(*parts: str) -> str:
    h = hashlib.sha256()
    for p in parts:
        h.update(p.encode(VECTOR_TEXT_ENCODING))
        h.update(b"\0")
    return h.hexdigest()


def embedding_cache_key(text: str, model_name: str) -> str:
    """Deterministic cache key: SHA-256 of normalized model id + text."""
    return _sha256_hex(model_name, text)


def search_cache_key(
    *,
    query: str,
    collection: str,
    top_k: int,
    extra: Mapping[str, Any] | None = None,
) -> str:
    """Deterministic key for a search request fingerprint."""
    payload = {
        "collection": collection,
        "extra": dict(extra) if extra else {},
        "query": query,
        "top_k": top_k,
    }
    raw = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode(VECTOR_TEXT_ENCODING)).hexdigest()


def _embedding_wire_bytes(vec: torch.Tensor | np.ndarray) -> bytes:
    if isinstance(vec, torch.Tensor):
        arr = vec.detach().float().cpu().contiguous().numpy()
    else:
        arr = np.asarray(vec, dtype=np.float32)
    if arr.ndim != 1:
        arr = arr.reshape(-1)
    dim = int(arr.shape[0])
    header = struct.pack("!I", dim)
    return header + arr.astype(np.float32, copy=False).tobytes()


def _embedding_from_wire(data: bytes) -> np.ndarray | None:
    if len(data) < 4:
        return None
    (dim,) = struct.unpack("!I", data[:4])
    body = data[4:]
    need = dim * 4
    if len(body) != need:
        return None
    return np.frombuffer(body, dtype=np.float32, count=dim).copy()


@dataclass(slots=True)
class _TTLRUEntry:
    expires_mono: float
    payload: bytes


class _AsyncTTLRUByteCache:
    """Process-local LRU with TTL; bounded size; async-safe."""

    def __init__(self, *, max_entries: int, ttl_s: int, name: str) -> None:
        self._max_entries = max(1, int(max_entries))
        self._ttl_s = max(1, int(ttl_s))
        self._name = name
        self._data: OrderedDict[str, _TTLRUEntry] = OrderedDict()
        self._lock = asyncio.Lock()

    async def get_bytes(self, key: str) -> bytes | None:
        async with self._lock:
            try:
                entry = self._data[key]
            except KeyError:
                return None
            if entry.expires_mono <= time.monotonic():
                del self._data[key]
                return None
            self._data.move_to_end(key)
            return entry.payload

    async def set_bytes(self, key: str, value: bytes) -> None:
        async with self._lock:
            self._data.pop(key, None)
            while len(self._data) >= self._max_entries:
                try:
                    self._data.popitem(last=False)
                except KeyError:
                    break
            self._data[key] = _TTLRUEntry(
                expires_mono=time.monotonic() + float(self._ttl_s),
                payload=value,
            )
            self._data.move_to_end(key)

    async def clear(self) -> None:
        async with self._lock:
            self._data.clear()


def _resolve_cache_limits(
    *,
    default_ttl: int,
    default_max: int,
    ttl_setting: str,
    max_setting: str,
) -> tuple[int, int]:
    """Read optional overrides from helper settings; never raises."""
    try:
        settings = get_settings()
        ttl = int(getattr(settings, ttl_setting, default_ttl))
        max_e = int(getattr(settings, max_setting, default_max))
    except Exception as exc:
        logger.warning("cache: get_settings failed, using const defaults: {}", exc)
        return max(1, default_ttl), max(1, default_max)
    return max(1, ttl), max(1, max_e)


class EmbeddingCache:
    """LRU + TTL cache for dense embedding vectors (float32, flattened)."""

    def __init__(
        self,
        *,
        max_entries: int | None = None,
        ttl_s: int | None = None,
    ) -> None:
        ttl, max_e = _resolve_cache_limits(
            default_ttl=EMBEDDING_CACHE_TTL_S,
            default_max=EMBEDDING_CACHE_MAX_ENTRIES,
            ttl_setting="vector_embedding_cache_ttl_s",
            max_setting="vector_embedding_cache_max_entries",
        )
        self._backend = _AsyncTTLRUByteCache(
            max_entries=max_entries if max_entries is not None else max_e,
            ttl_s=ttl_s if ttl_s is not None else ttl,
            name="EmbeddingCache",
        )

    @staticmethod
    def make_key(text: str, model_name: str) -> str:
        return embedding_cache_key(text, model_name)

    async def get_vector(self, text: str, model_name: str) -> np.ndarray | None:
        key = self.make_key(text, model_name)
        try:
            raw = await self._backend.get_bytes(key)
            if raw is None:
                return None
            vec = _embedding_from_wire(raw)
            if vec is None:
                logger.warning("EmbeddingCache: corrupt payload for key prefix {}", key[:12])
            return vec
        except Exception as exc:
            logger.warning("EmbeddingCache.get_vector degraded: {}", exc)
            return None

    async def set_vector(
        self,
        text: str,
        model_name: str,
        vector: torch.Tensor | np.ndarray,
    ) -> None:
        key = self.make_key(text, model_name)
        try:
            await self._backend.set_bytes(key, _embedding_wire_bytes(vector))
        except Exception as exc:
            logger.warning("EmbeddingCache.set_vector degraded: {}", exc)

    async def clear(self) -> None:
        await self._backend.clear()


_default_embedding_cache: EmbeddingCache | None = None
_embedding_cache_singleton_lock = threading.Lock()


def get_embedding_cache() -> EmbeddingCache:
    """Process-wide default embedding vector cache (LRU + TTL)."""
    global _default_embedding_cache
    with _embedding_cache_singleton_lock:
        if _default_embedding_cache is None:
            _default_embedding_cache = EmbeddingCache()
        return _default_embedding_cache


class SearchResultCache:
    """LRU + TTL cache for serialized dense/sparse search hit lists (JSON bytes)."""

    def __init__(
        self,
        *,
        max_entries: int | None = None,
        ttl_s: int | None = None,
    ) -> None:
        ttl, max_e = _resolve_cache_limits(
            default_ttl=SEARCH_CACHE_TTL_S,
            default_max=SEARCH_CACHE_MAX_ENTRIES,
            ttl_setting="vector_search_cache_ttl_s",
            max_setting="vector_search_cache_max_entries",
        )
        self._backend = _AsyncTTLRUByteCache(
            max_entries=max_entries if max_entries is not None else max_e,
            ttl_s=ttl_s if ttl_s is not None else ttl,
            name="SearchResultCache",
        )

    async def get_results(self, cache_key: str) -> Any | None:
        try:
            raw = await self._backend.get_bytes(cache_key)
            if raw is None:
                return None
            return json.loads(raw.decode(VECTOR_TEXT_ENCODING))
        except Exception as exc:
            logger.warning("SearchResultCache.get_results degraded: {}", exc)
            return None

    async def set_results(self, cache_key: str, value: Any) -> None:
        try:
            raw = json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode(
                VECTOR_TEXT_ENCODING
            )
            await self._backend.set_bytes(cache_key, raw)
        except Exception as exc:
            logger.warning("SearchResultCache.set_results degraded: {}", exc)

    async def clear(self) -> None:
        await self._backend.clear()


class SemanticCache:
    """Placeholder for similarity-based answer cache (vector threshold)."""

    def __init__(
        self,
        *,
        similarity_threshold: float = SEMANTIC_CACHE_SIMILARITY_THRESHOLD,
    ) -> None:
        self.similarity_threshold = float(similarity_threshold)

    async def find_similar(
        self,
        _query_vector: torch.Tensor | np.ndarray,
        *,
        top_k: int = 1,
    ) -> list[tuple[str, float]] | None:
        """Reserved for ANN / Qdrant-backed semantic hit lookup; not implemented."""
        logger.debug(
            "SemanticCache.find_similar is a stub (threshold={}, top_k={})",
            self.similarity_threshold,
            top_k,
        )
        return None

    async def remember(self, *_args: Any, **_kwargs: Any) -> None:
        """Reserved for storing query/answer pairs with vectors."""
        logger.debug("SemanticCache.remember is a stub")


async def _maybe_await(value: Any) -> Any:
    if inspect.isawaitable(value):
        return await value
    return value


def cached_embedding(
    cache: EmbeddingCache,
    *,
    model_name: str | None = None,
    model_kw: str = "model_name",
) -> Callable[[Callable[..., Any]], Callable[..., Awaitable[torch.Tensor]]]:
    """Decorate an embed function/method so repeated texts hit ``EmbeddingCache``.

    The wrapped callable must accept ``texts: Sequence[str]`` as its first positional argument
    and return ``torch.Tensor`` of shape ``[N, D]`` (either sync or async). For instance methods,
    wrap ``lambda texts, **kw: self.encode(texts, **kw)`` so ``texts`` stays first.
    """

    def decorator(fn: Callable[..., Any]) -> Callable[..., Awaitable[torch.Tensor]]:
        @wraps(fn)
        async def wrapper(*args: Any, **kwargs: Any) -> torch.Tensor:
            if not args:
                raise RiceError("cached_embedding: missing texts argument")
            texts = cast(Sequence[str], args[0])
            tail_args = args[1:]
            resolved_model = cast(str | None, kwargs.get(model_kw)) or model_name
            if resolved_model is None:
                resolved_model = DEFAULT_EMBEDDING_MODEL

            texts_list = list(texts)
            if not texts_list:
                return torch.empty(0, VECTOR_SIZE, dtype=torch.float32)

            hits: list[np.ndarray | None] = [None] * len(texts_list)
            missing_idx: list[int] = []
            try:
                for i, t in enumerate(texts_list):
                    vec = await cache.get_vector(t, resolved_model)
                    hits[i] = vec
                    if vec is None:
                        missing_idx.append(i)
            except Exception as exc:
                logger.warning("cached_embedding: cache read degraded, recomputing all: {}", exc)
                missing_idx = list(range(len(texts_list)))
                hits = [None] * len(texts_list)

            if missing_idx:
                subset = [texts_list[i] for i in missing_idx]
                try:
                    raw_out = cast(Callable[..., Any], fn)(subset, *tail_args, **kwargs)
                    batch = await _maybe_await(raw_out)
                    if not isinstance(batch, torch.Tensor):
                        batch = torch.as_tensor(batch, dtype=torch.float32)
                except Exception as exc:
                    logger.warning("cached_embedding: embed fn failed: {}", exc)
                    raise

                for row, idx in enumerate(missing_idx):
                    row_vec = batch[row]
                    hits[idx] = row_vec.detach().float().cpu().numpy().reshape(-1)
                    try:
                        await cache.set_vector(texts_list[idx], resolved_model, row_vec)
                    except Exception as cache_exc:
                        logger.warning("cached_embedding: cache write degraded: {}", cache_exc)

            dim = next((int(h.shape[0]) for h in hits if h is not None), VECTOR_SIZE)
            if any(h is None for h in hits):
                logger.warning("cached_embedding: incomplete hits after embed; padding with zeros")
            stacked = np.stack(
                [h if h is not None else np.zeros(dim, dtype=np.float32) for h in hits],
                axis=0,
            )
            return torch.from_numpy(stacked.copy())

        return wrapper

    return decorator


__all__ = [
    "EmbeddingCache",
    "SearchResultCache",
    "SemanticCache",
    "cached_embedding",
    "embedding_cache_key",
    "get_embedding_cache",
    "search_cache_key",
]
