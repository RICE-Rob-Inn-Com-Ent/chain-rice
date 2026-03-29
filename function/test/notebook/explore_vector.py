"""Marimo: RAG / vector — `marimo edit function/test/notebook/explore_vector.py`."""

from __future__ import annotations

from typing import Any

import marimo

# TODO:
# [ ] marimo cell: embed sample texts — show embedding heatmap
# [ ] marimo cell: interactive RAG query — type query → show retrieved chunks
# [ ] marimo cell: hybrid search alpha slider — see dense vs lexical tradeoff
# [ ] marimo cell: Qdrant collection stats — point count, vector size, index status
# [ ] marimo cell: reranking comparison — before/after rerank order

__generated_with = "0.10.0"
app = marimo.App()


@app.cell
def intro() -> Any:
    import marimo as mo

    return mo.md("# Vector / RAG smoke")


@app.cell
def run_vector_smoke() -> Any:
    from function.vector.embed import HashProjectionEmbedder
    from function.vector.hybrid import reciprocal_rank_fusion

    e = HashProjectionEmbedder(dim=8)
    _emb = e.encode(["hello"], batch_size=1)
    _rrf = reciprocal_rank_fusion([[("a", 1.0)], [("a", 0.5)]])
    return _emb, _rrf
