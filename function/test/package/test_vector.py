"""Unit + integration: `function/vector` — embed, hybrid, lexical; Qdrant (opt-in)."""

from __future__ import annotations

import os

import pytest

from function.vector.embed import HashProjectionEmbedder
from function.vector.hybrid import reciprocal_rank_fusion
from function.vector.lexical import LexicalIndex

# TODO:
# [ ] test chunk: text split into chunks of correct size with overlap
# [ ] test embed: embedding has correct dimension (RICE_EMBEDDING_DIM)
# [ ] test embed normalization: L2 norm ≈ 1.0
# [ ] test bm25 index: query returns relevant document above threshold
# [ ] test hybrid search: results from both dense and sparse combined
# [ ] test rerank: reranked results differ from original order
# [ ] test rag pipeline: end-to-end chunk→embed→search→rerank returns result
# [ ] qdrant: collection created, point upserted, searched, result matches


def test_hash_embedder_shape() -> None:
    e = HashProjectionEmbedder(dim=16)
    t = e.encode(["a", "b"], batch_size=2)
    assert t.shape == (2, 16)


def test_rrf_fusion() -> None:
    r = reciprocal_rank_fusion([[("a", 1.0), ("b", 0.5)], [("b", 2.0)]], k=60)
    assert r[0][0] in {"a", "b"}


def test_lexical_index_bm25() -> None:
    idx = LexicalIndex.build(["hello world", "other doc"], ["d0", "d1"], show_progress=False)
    hits = idx.search("hello", k=2, show_progress=False)
    assert len(hits) >= 1
    assert hits[0][0] == "d0"


@pytest.fixture
def qdrant_url() -> str:
    return os.getenv("QDRANT_URL", "http://127.0.0.1:6333")


@pytest.mark.integration
@pytest.mark.qdrant
@pytest.mark.asyncio
async def test_qdrant_health(qdrant_url: str, integration_enabled: bool) -> None:
    if not integration_enabled:
        pytest.skip("set RUN_INTEGRATION=1")
    from qdrant_client import QdrantClient

    c = QdrantClient(url=qdrant_url, timeout=5)
    collections = c.get_collections()
    assert collections is not None
