"""Reranking — MMR, deduplikacja, opcjonalny cross-encoder."""

from __future__ import annotations

import numpy as np
import torch
import torch.nn.functional as F
from loguru import logger

# TODO:
# [ ] implement cross-encoder reranking:
# [ ]     model from RICE_RERANK_MODEL env var
# [ ]     top_k candidates from RICE_RERANK_TOP_K env var
# [ ]     score threshold from RICE_RERANK_THRESHOLD env var
# [ ] implement Cohere Rerank API when RICE_COHERE_KEY is set
# [ ]     fallback to local cross-encoder when key not set
# [ ] implement LLM-based reranking:
# [ ]     ask LLM to rank retrieved chunks by relevance
# [ ]     prompt template from RICE_RERANK_PROMPT env var
# [ ] implement diversity reranking: MMR (Maximal Marginal Relevance)
# [ ]     lambda from RICE_MMR_LAMBDA env var


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
    items: list[tuple[str, float, dict]],
    *,
    keep_highest_score: bool = True,
) -> list[tuple[str, float, dict]]:
    """Usuwa duplikaty `doc_id`, zostawiając najlepszy score."""
    best: dict[str, tuple[float, dict]] = {}
    for doc_id, score, payload in items:
        if doc_id not in best:
            best[doc_id] = (score, payload)
        else:
            cur, pl = best[doc_id]
            if (keep_highest_score and score > cur) or (not keep_highest_score and score < cur):
                best[doc_id] = (score, pl)
    return [(did, sc, pl) for did, (sc, pl) in best.items()]


def cross_encoder_rerank_stub(
    _query: str,
    documents: list[str],
    *,
    top_k: int = 10,
) -> list[tuple[int, float]]:
    """Placeholder — podłącz `CrossEncoder` z sentence-transformers w deploymencie."""
    logger.warning("cross_encoder_rerank_stub: zwraca kolejność identyczną — podłącz model CE.")
    return [(i, 0.0) for i in range(min(top_k, len(documents)))]


def numpy_cosine_matrix(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Macierz podobieństwa kosinusowego (wiersze znormalizowane L2)."""
    a_n = a / (np.linalg.norm(a, axis=1, keepdims=True) + 1e-9)
    b_n = b / (np.linalg.norm(b, axis=1, keepdims=True) + 1e-9)
    return a_n @ b_n.T
