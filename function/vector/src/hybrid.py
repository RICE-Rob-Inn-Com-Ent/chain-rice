"""Dense + sparse — RRF i łączenie rankingów."""

from __future__ import annotations

from collections import defaultdict

# TODO:
# [ ] implement hybrid search: dense + sparse (BM25S) fusion
# [ ]     alpha from RICE_HYBRID_ALPHA env var (default: 0.5)
# [ ]     alpha=1.0: pure dense, alpha=0.0: pure lexical
# [ ] implement Reciprocal Rank Fusion (RRF):
# [ ]     k from RICE_RRF_K env var (default: 60)
# [ ]     merge dense and sparse result lists via RRF scoring
# [ ] implement Qdrant native sparse vector search:
# [ ]     upload sparse vectors alongside dense vectors
# [ ]     Query API with sparse vector + dense vector fusion
# [ ] implement result deduplication by point_id


def reciprocal_rank_fusion(
    rankings: list[list[tuple[str, float]]],
    *,
    k: int = 60,
) -> list[tuple[str, float]]:
    """RRF: `score(d) = sum_i 1/(k + rank_i(d))` dla list posortowanych malejąco po score."""
    acc: dict[str, float] = defaultdict(float)
    for ranked in rankings:
        for rank, (doc_id, _score) in enumerate(ranked, start=1):
            acc[doc_id] += 1.0 / (k + rank)
    return sorted(acc.items(), key=lambda x: -x[1])


def fuse_dense_sparse_ids(
    dense_ranked: list[tuple[str, float]],
    sparse_ranked: list[tuple[str, float]],
    *,
    rrf_k: int = 60,
) -> list[tuple[str, float]]:
    """Łączy wyniki wyszukiwania gęstego (np. Qdrant) i BM25."""
    return reciprocal_rank_fusion([dense_ranked, sparse_ranked], k=rrf_k)


def align_by_id(
    ordered_ids: list[str],
    payloads: dict[str, dict],
) -> list[dict]:
    """Układa payload wg kolejności ID (np. po fuzji)."""
    return [payloads[i] for i in ordered_ids if i in payloads]
