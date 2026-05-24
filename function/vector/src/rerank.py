"""Reranking — cross-encoder, MMR, deduplication, cosine utilities."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import threading
import time
from collections.abc import Sequence
from typing import Any, ClassVar, Literal

import numpy as np
import torch
import torch.nn.functional as F
from helper import RiceError, logger

from .const import DEVICE, RERANK_BATCH_SIZE, RERANK_MAX_LENGTH, RERANK_MODEL_NAME
from .search import SearchResult


def score_normalization(
    raw: np.ndarray | Sequence[float],
    *,
    method: Literal["sigmoid", "minmax"] = "sigmoid",
) -> np.ndarray:
    """Map cross-encoder logits to ``[0, 1]`` (sigmoid) or per-batch min–max."""
    arr = np.asarray(raw, dtype=np.float64).reshape(-1)
    if arr.size == 0:
        return arr.astype(np.float32, copy=False)
    if method == "sigmoid":
        clipped = np.clip(arr, -60.0, 60.0)
        out = 1.0 / (1.0 + np.exp(-clipped))
    else:
        lo = float(arr.min())
        hi = float(arr.max())
        out = (arr - lo) / (hi - lo + 1e-9) if hi > lo else np.full_like(arr, 0.5)
    return out.astype(np.float32, copy=False)


def maximal_marginal_relevance(
    query_vec: torch.Tensor,
    doc_vecs: torch.Tensor,
    *,
    k: int = 5,
    lambda_mult: float = 0.5,
) -> list[int]:
    """MMR po kosinusie: `argmax lambda*sim(q,d) - (1-lambda)*max sim(d,S)`."""
    if doc_vecs.numel() == 0:
        return []
    docs = F.normalize(doc_vecs.float(), p=2, dim=-1)
    q = F.normalize(query_vec.float().unsqueeze(0), p=2, dim=-1)
    sim_q = (docs @ q.T).squeeze(-1)
    sim_d = docs @ docs.T
    n = docs.shape[0]
    selected: list[int] = []
    candidates = set(range(n))
    while len(selected) < min(k, n) and candidates:
        best_i = None
        best_s = -1e9
        for i in list(candidates):
            if not selected:
                score = float(sim_q[i])
            else:
                red = max(float(sim_d[i, j]) for j in selected)
                score = float(lambda_mult * sim_q[i] - (1.0 - lambda_mult) * red)
            if score > best_s:
                best_s = score
                best_i = i
        if best_i is None:
            break
        selected.append(best_i)
        candidates.discard(best_i)
    return selected


def dedupe_by_doc_id(
    items: list[tuple[str, float, dict[str, Any]]],
    *,
    keep_highest_score: bool = True,
) -> list[tuple[str, float, dict[str, Any]]]:
    """Usuwa duplikaty `doc_id`, zostawiając najlepszy score."""
    best: dict[str, tuple[float, dict[str, Any]]] = {}
    for doc_id, score, payload in items:
        if doc_id not in best:
            best[doc_id] = (score, payload)
        else:
            cur, pl = best[doc_id]
            if (keep_highest_score and score > cur) or (not keep_highest_score and score < cur):
                best[doc_id] = (score, pl)
    return [(did, sc, pl) for did, (sc, pl) in best.items()]


def numpy_cosine_matrix(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Macierz podobieństwa kosinusowego (wiersze znormalizowane L2)."""
    a_n = a / (np.linalg.norm(a, axis=1, keepdims=True) + 1e-9)
    b_n = b / (np.linalg.norm(b, axis=1, keepdims=True) + 1e-9)
    return a_n @ b_n.T


class Reranker:
    """Singleton cross-encoder (sentence-transformers). Bypass when model name is empty or load fails."""

    _instance: ClassVar[Reranker | None] = None
    _singleton_lock = threading.Lock()

    def __new__(cls) -> Reranker:
        if cls._instance is None:
            with cls._singleton_lock:
                if cls._instance is None:
                    inst = super().__new__(cls)
                    inst._initialized = False
                    cls._instance = inst
        assert cls._instance is not None
        return cls._instance

    def __init__(self) -> None:
        with Reranker._singleton_lock:
            if getattr(self, "_initialized", False):
                return
            self._model_name = str(RERANK_MODEL_NAME).strip()
            self._batch_size = int(RERANK_BATCH_SIZE)
            self._max_length = int(RERANK_MAX_LENGTH)
            self._device = str(DEVICE)
            self._model = None
            self._bypass = not bool(self._model_name)
            self._bypass_reason: str | None = "RERANK_MODEL_NAME is empty" if self._bypass else None
            self._initialized = True

    @property
    def bypass(self) -> bool:
        return self._bypass

    @property
    def bypass_reason(self) -> str | None:
        return self._bypass_reason

    def _ensure_model(self) -> None:
        if self._bypass or self._model is not None:
            return
        with Reranker._singleton_lock:
            if self._bypass or self._model is not None:
                return
            try:
                from sentence_transformers import CrossEncoder
            except ImportError:
                self._bypass = True
                self._bypass_reason = "sentence-transformers not installed"
                logger.warning("Reranker bypass | {}", self._bypass_reason)
                return
            t0 = time.perf_counter()
            try:
                self._model = CrossEncoder(
                    self._model_name,
                    device=self._device,
                    max_length=self._max_length,
                )
            except RuntimeError as exc:
                msg = str(exc).lower()
                if "out of memory" in msg or "cuda" in msg:
                    self._bypass = True
                    self._bypass_reason = "GPU OOM during reranker load"
                else:
                    self._bypass = True
                    self._bypass_reason = str(exc)
                logger.warning("Reranker bypass | {} | err={!r}", self._bypass_reason, exc)
                return
            except Exception as exc:
                self._bypass = True
                self._bypass_reason = str(exc)
                logger.warning("Reranker bypass | load failed | err={!r}", exc)
                return
            dt = time.perf_counter() - t0
            logger.info(
                "Reranker ready | model={} device={} max_length={} load_s={:.2f}",
                self._model_name,
                self._device,
                self._max_length,
                dt,
            )

    def rerank(
        self,
        query: str,
        results: list[SearchResult],
        top_n: int,
        *,
        normalize: Literal["sigmoid", "minmax"] = "sigmoid",
    ) -> list[SearchResult]:
        """Score ``(query, result.content)`` pairs with the cross-encoder; return top ``top_n`` by normalized score."""
        if not results:
            return []
        n_take = max(1, int(top_n))
        if self._bypass:
            return list(results)[:n_take]

        self._ensure_model()
        if self._bypass or self._model is None:
            return list(results)[:n_take]

        q = (query or "").strip()[: self._max_length * 4]
        pairs: list[tuple[str, str]] = [(q, (r.content or "")[: self._max_length * 4]) for r in results]

        t0 = time.perf_counter()
        try:
            with torch.inference_mode():
                raw_scores = self._model.predict(
                    pairs,
                    batch_size=self._batch_size,
                    show_progress_bar=False,
                )
        except RuntimeError as exc:
            msg = str(exc).lower()
            if "out of memory" in msg:
                raise RiceError(
                    "cross-encoder inference OOM",
                    error_code="RERANK_OOM",
                    details={"batch_size": self._batch_size, "n_pairs": len(pairs)},
                ) from exc
            raise RiceError(
                "cross-encoder inference failed",
                error_code="RERANK_INFERENCE",
                details={"reason": str(exc)},
            ) from exc
        except RiceError:
            raise
        except Exception as exc:
            raise RiceError(
                "cross-encoder inference failed",
                error_code="RERANK_INFERENCE",
                details={"reason": str(exc)},
            ) from exc

        raw_arr = np.asarray(raw_scores, dtype=np.float64).reshape(-1)
        norm = score_normalization(raw_arr, method=normalize)
        elapsed_ms = (time.perf_counter() - t0) * 1000.0
        logger.info(
            "rerank | pairs={} | top_n={} | latency_ms={:.2f}",
            len(pairs),
            n_take,
            elapsed_ms,
        )

        enriched: list[tuple[float, SearchResult]] = []
        for r, raw, n in zip(results, raw_arr.tolist(), norm.tolist(), strict=True):
            meta = {
                **r.metadata,
                "rerank_raw": float(raw),
                "rerank_normalized": float(n),
            }
            enriched.append(
                (float(n), r.model_copy(update={"score": float(n), "metadata": meta})),
            )
        enriched.sort(key=lambda x: -x[0])
        return [r for _, r in enriched[:n_take]]


def get_reranker() -> Reranker:
    """Singleton :class:`Reranker`."""
    return Reranker()


def cross_encoder_rerank_stub(
    query: str,
    documents: list[str],
    *,
    top_k: int = 10,
) -> list[tuple[int, float]]:
    """Backward-compatible index + score pairs; uses :class:`Reranker` when active, else identity order."""
    if not documents:
        return []
    rr = get_reranker()
    if rr.bypass:
        logger.debug("cross_encoder_rerank_stub: reranker bypass | reason={}", rr.bypass_reason)
        return [(i, 0.0) for i in range(min(int(top_k), len(documents)))]
    sr = [
        SearchResult(
            chunk_id=str(i),
            content=text,
            metadata={"_stub_index": i},
            score=0.0,
            point_id=None,
        )
        for i, text in enumerate(documents)
    ]
    ranked = rr.rerank(query, sr, top_n=min(int(top_k), len(sr)))
    out: list[tuple[int, float]] = []
    for r in ranked:
        idx = r.metadata.get("_stub_index")
        if isinstance(idx, int):
            out.append((idx, float(r.score)))
    return out if out else [(i, 0.0) for i in range(min(int(top_k), len(documents)))]


__all__ = [
    "Reranker",
    "cross_encoder_rerank_stub",
    "dedupe_by_doc_id",
    "get_reranker",
    "maximal_marginal_relevance",
    "numpy_cosine_matrix",
    "score_normalization",
]
