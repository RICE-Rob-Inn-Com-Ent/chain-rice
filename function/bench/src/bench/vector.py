"""Benchmarks for the ``vector`` package (chunking; no network / Qdrant)."""

from __future__ import annotations

import importlib

from ._resolve import vector_module
from ._timing import TimingSample, bench_call

_v = vector_module()
_chunk = importlib.import_module(f"{_v.__name__}.chunk")
chunk_document = _chunk.chunk_document


def run_vector_benchmarks(*, repeat: int = 5, warmup: int = 1) -> list[TimingSample]:
    text = ("Paragraph one. " * 40 + "\n\n") * 30

    def chunk_text() -> None:
        chunk_document(text, "bench-doc", chunk_size=400, overlap=40)

    return [
        bench_call(
            "vector.chunk_document (recursive)",
            chunk_text,
            repeat=repeat,
            warmup=warmup,
            note=f"chars={len(text)}",
        ),
    ]
