"""Torch — embeddingi: singleton ``EmbeddingEngine``, Sentence-Transformers, cache, batching."""

from __future__ import annotations

import asyncio
import hashlib
import threading
import time
from collections.abc import Callable, Sequence
from typing import Any, ClassVar, Literal, Protocol, cast, runtime_checkable

import numpy as np
import torch
import torch.nn.functional as F
from helper import RiceError, logger  # type: ignore[import-untyped]

from .cache import EmbeddingCache, get_embedding_cache
from .const import DEVICE, EMBED_BATCH_SIZE, EMBEDDING_MODEL_NAME


def pick_device(prefer_cuda: bool = True) -> torch.device:
    """Pick CUDA, MPS, or CPU (may differ from ``const.DEVICE`` string snapshot)."""
    if prefer_cuda and torch.cuda.is_available():
        return torch.device("cuda")
    if getattr(torch.backends, "mps", None) and torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def to_device(batch: torch.Tensor, device: torch.device | None) -> torch.Tensor:
    if device is None:
        return batch
    return batch.to(device=device, non_blocking=device.type == "cuda")


def _l2_normalize_numpy(rows: np.ndarray) -> np.ndarray:
    norms = np.linalg.norm(rows, axis=1, keepdims=True)
    norms = np.maximum(norms, 1e-12)
    return (rows / norms).astype(np.float32, copy=False)


def _running_asyncio_loop() -> bool:
    try:
        asyncio.get_running_loop()
    except RuntimeError:
        return False
    return True


@runtime_checkable
class TextEmbedder(Protocol):
    """Protokół enkodera tekstu → wektory znormalizowane L2 (np. do ``RagPipeline``)."""

    embedding_dim: int

    def encode(
        self,
        texts: Sequence[str],
        *,
        batch_size: int = 32,
        normalize: bool = True,
    ) -> torch.Tensor:
        """Zwraca tensor float32 [N, D]."""


class EmbeddingEngine:
    """Singleton: ``sentence-transformers`` na ``const.DEVICE``, cache, wejście/wyjście numpy."""

    _instance: ClassVar[EmbeddingEngine | None] = None
    _singleton_lock = threading.Lock()

    def __new__(cls) -> EmbeddingEngine:
        if cls._instance is None:
            with cls._singleton_lock:
                if cls._instance is None:
                    inst = super().__new__(cls)
                    inst._initialized = False
                    cls._instance = inst
        assert cls._instance is not None
        return cls._instance

    def __init__(
        self,
        *,
        cache: EmbeddingCache | None = None,
        pooling: Literal["default", "mean", "cls"] = "default",
    ) -> None:
        with EmbeddingEngine._singleton_lock:
            if getattr(self, "_initialized", False):
                return
            self._pooling = pooling
            if pooling != "default":
                logger.warning(
                    "EmbeddingEngine: pooling={!r} is reserved; SentenceTransformer uses its own pooling",
                    pooling,
                )
            self._device = torch.device(DEVICE)
            self._cache = cache if cache is not None else get_embedding_cache()
            self._model_name = EMBEDDING_MODEL_NAME

            try:
                from sentence_transformers import SentenceTransformer
            except ImportError as exc:
                raise RiceError(
                    "sentence-transformers is not installed",
                    error_code="EMBED_IMPORT",
                    details={"hint": "uv add sentence-transformers"},
                ) from exc

            t0 = time.perf_counter()
            try:
                self._model = SentenceTransformer(self._model_name, device=str(self._device))
            except RuntimeError as exc:
                msg = str(exc).lower()
                if "out of memory" in msg or "cuda" in msg:
                    raise RiceError(
                        "model load failed (likely GPU OOM)",
                        error_code="EMBED_OOM",
                        details={"model": self._model_name, "device": str(self._device)},
                    ) from exc
                raise RiceError(
                    "failed to load SentenceTransformer model",
                    error_code="EMBED_LOAD",
                    details={"model": self._model_name, "reason": str(exc)},
                ) from exc
            except Exception as exc:
                raise RiceError(
                    "failed to load SentenceTransformer model",
                    error_code="EMBED_LOAD",
                    details={"model": self._model_name, "reason": str(exc)},
                ) from exc

            self.embedding_dim = int(self._model.get_sentence_embedding_dimension())
            load_s = time.perf_counter() - t0
            logger.info(
                "EmbeddingEngine ready | model={} device={} dim={} load_s={:.2f}",
                self._model_name,
                str(self._device),
                self.embedding_dim,
                load_s,
            )
            self._initialized = True

    def _encode_batch_tensor(self, texts: list[str], *, batch_size: int) -> torch.Tensor:
        with torch.inference_mode():
            try:
                emb = self._model.encode(
                    texts,
                    batch_size=batch_size,
                    convert_to_tensor=True,
                    normalize_embeddings=True,
                    show_progress_bar=False,
                )
            except RuntimeError as exc:
                msg = str(exc).lower()
                if "out of memory" in msg:
                    raise RiceError(
                        "embedding batch failed (GPU OOM)",
                        error_code="EMBED_OOM",
                        details={"batch_size": batch_size, "n": len(texts)},
                    ) from exc
                raise RiceError(
                    "embedding encode failed",
                    error_code="EMBED_ENCODE",
                    details={"reason": str(exc)},
                ) from exc
        if not isinstance(emb, torch.Tensor):
            emb = torch.tensor(emb, dtype=torch.float32, device=self._device)
        return emb

    def _cache_reads_sync(self, texts: list[str]) -> list[np.ndarray | None]:
        if _running_asyncio_loop():
            logger.warning("EmbeddingEngine: skipping embedding cache (asyncio loop is running)")
            return [None] * len(texts)

        async def _reads() -> list[np.ndarray | None]:
            return list(await asyncio.gather(*[self._cache.get_vector(t, self._model_name) for t in texts]))

        return asyncio.run(_reads())

    def _cache_writes_sync(self, writes: list[tuple[str, np.ndarray]]) -> None:
        if not writes or _running_asyncio_loop():
            return

        async def _sets() -> None:
            await asyncio.gather(
                *[self._cache.set_vector(text, self._model_name, vec) for text, vec in writes],
            )

        asyncio.run(_sets())

    def embed_documents(
        self,
        texts: list[str],
        *,
        batch_size: int | None = None,
        use_cache: bool = True,
    ) -> np.ndarray:
        """Zwraca ``float32`` macierz ``(N, D)`` L2 — pod Qdrant / numpy."""
        if not texts:
            return np.zeros((0, self.embedding_dim), dtype=np.float32)
        bs = int(batch_size or EMBED_BATCH_SIZE)
        n = len(texts)
        rows: list[np.ndarray | None] = [None] * n

        if use_cache:
            try:
                cached = self._cache_reads_sync(texts)
                for i, v in enumerate(cached):
                    rows[i] = v.copy() if v is not None else None
            except Exception as exc:
                logger.warning("EmbeddingEngine: cache read failed, recomputing all | {}", exc)
                rows = [None] * n

        missing = [i for i, r in enumerate(rows) if r is None]
        to_write: list[tuple[str, np.ndarray]] = []

        if missing:
            subset = [texts[i] for i in missing]
            for start in range(0, len(subset), bs):
                batch = subset[start : start + bs]
                batch_missing_idx = missing[start : start + bs]
                tens = self._encode_batch_tensor(batch, batch_size=bs)
                tens_cpu = tens.detach().float().cpu().numpy()
                tens_np = _l2_normalize_numpy(tens_cpu)
                for j, row_idx in enumerate(batch_missing_idx):
                    vec = tens_np[j].astype(np.float32, copy=False)
                    rows[row_idx] = vec
                    if use_cache:
                        to_write.append((texts[row_idx], vec))

            if use_cache and to_write:
                try:
                    self._cache_writes_sync(to_write)
                except Exception as exc:
                    logger.warning("EmbeddingEngine: cache write failed | {}", exc)

        if any(r is None for r in rows):
            raise RiceError(
                "internal embedding error: missing rows after encode",
                error_code="EMBED_INTERNAL",
                details={"n": n},
            )
        return np.ascontiguousarray(np.stack(cast(list[np.ndarray], rows), axis=0), dtype=np.float32)

    def embed_query(self, text: str, *, use_cache: bool = False) -> np.ndarray:
        """Pojedynczy wektor zapytań ``(D,)`` float32 L2 (domyślnie bez cache)."""
        if not text.strip():
            raise RiceError(
                "query text must be non-empty",
                error_code="EMBED_EMPTY_QUERY",
                details={},
            )
        return self.embed_documents([text], batch_size=1, use_cache=use_cache)[0].copy()

    def encode(
        self,
        texts: Sequence[str],
        *,
        batch_size: int = 32,
        normalize: bool = True,
    ) -> torch.Tensor:
        """Kompatybilność z :class:`TextEmbedder` — zwraca tensor na CPU."""
        arr = self.embed_documents(list(texts), batch_size=batch_size, use_cache=True)
        t = torch.from_numpy(np.ascontiguousarray(arr))
        if normalize:
            t = F.normalize(t, p=2, dim=-1)
        return t


def get_embedding_engine() -> EmbeddingEngine:
    """Zwraca singleton ``EmbeddingEngine`` (cache: ``get_embedding_cache()`` przy pierwszym init)."""
    return EmbeddingEngine()


class HashProjectionEmbedder:
    """Deterministyczne wektory (dev/test) — bez pobierania modeli; nie do produkcji."""

    def __init__(self, dim: int = 384, seed: bytes = b"rice-vector") -> None:
        self.embedding_dim = dim
        self._seed = seed

    def encode(
        self,
        texts: Sequence[str],
        *,
        batch_size: int = 32,
        normalize: bool = True,
    ) -> torch.Tensor:
        device = pick_device(prefer_cuda=False)
        out: list[torch.Tensor] = []
        for i in range(0, len(texts), batch_size):
            chunk = texts[i : i + batch_size]
            vecs = []
            for t in chunk:
                h = hashlib.blake2b(
                    self._seed + t.encode("utf-8"),
                    digest_size=64,
                ).digest()
                buf = (h * (self.embedding_dim // len(h) + 1))[: self.embedding_dim]
                arr = np.frombuffer(buf, dtype=np.uint8).astype(np.float32)
                arr = arr / 255.0 * 2.0 - 1.0
                vecs.append(arr)
            batch = torch.tensor(np.stack(vecs), dtype=torch.float32, device=device)
            if normalize:
                batch = F.normalize(batch, p=2, dim=-1)
            out.append(batch)
        return torch.cat(out, dim=0)


class SentenceTransformerEmbedder:
    """Lekki wrapper na ``sentence_transformers`` (osobna instancja od singletonu)."""

    def __init__(self, model_name: str, device: torch.device | None = None) -> None:
        try:
            from sentence_transformers import SentenceTransformer
        except ImportError as e:
            msg = "Zainstaluj: sentence-transformers"
            raise ImportError(msg) from e
        self._device = device or pick_device()
        self._model = SentenceTransformer(model_name, device=str(self._device))
        self.embedding_dim = self._model.get_sentence_embedding_dimension()

    def encode(
        self,
        texts: Sequence[str],
        *,
        batch_size: int = 32,
        normalize: bool = True,
    ) -> torch.Tensor:
        with torch.inference_mode():
            emb = self._model.encode(
                list(texts),
                batch_size=batch_size,
                convert_to_tensor=True,
                normalize_embeddings=normalize,
                show_progress_bar=False,
            )
        if not isinstance(emb, torch.Tensor):
            emb = torch.tensor(emb, dtype=torch.float32, device=self._device)
        return emb


def encode_text_batches(
    texts: Sequence[str],
    forward: Callable[[torch.Tensor], torch.Tensor],
    tokenizer: Callable[[Sequence[str]], dict[str, torch.Tensor]],
    *,
    batch_size: int = 16,
    device: torch.device | None = None,
) -> torch.Tensor:
    """Batchowanie dla własnego ``nn.Module`` + tokenizera HuggingFace."""
    device = device or pick_device()
    outs: list[torch.Tensor] = []
    texts_list = list(texts)
    for i in range(0, len(texts_list), batch_size):
        batch = texts_list[i : i + batch_size]
        toks = tokenizer(batch)
        toks = {k: v.to(device) for k, v in toks.items()}
        with torch.inference_mode():
            vec = forward(**toks)
        outs.append(vec.detach().float().cpu())
    return torch.cat(outs, dim=0)


def encode_image_batch_dummy(images: Sequence[Any], *, dim: int = 512) -> torch.Tensor:
    """Placeholder na potok wizualny."""
    logger.warning("encode_image_batch_dummy: zwraca zera — podłącz model obrazów.")
    return torch.zeros(len(images), dim, dtype=torch.float32)
