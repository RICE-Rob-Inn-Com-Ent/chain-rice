"""Dzielenie tekstu, nakładanie okien, metadane, proste parsowanie dokumentów."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any

# TODO:
# [ ] implement recursive character text splitter:
# [ ]     chunk_size from RICE_CHUNK_SIZE env var (default: 512)
# [ ]     chunk_overlap from RICE_CHUNK_OVERLAP env var (default: 64)
# [ ]     separators: ["\n\n", "\n", ". ", " "] — configurable
# [ ] implement semantic chunking:
# [ ]     split on embedding similarity drops
# [ ]     threshold from RICE_SEMANTIC_CHUNK_THRESHOLD env var
# [ ] implement code-aware chunking:
# [ ]     detect language (Python/Go/Rust/TS) → split on function/class boundaries
# [ ]     language detection via file extension or content analysis
# [ ] implement .rice manifest chunking:
# [ ]     parse .rice syntax → chunk per section (domain/service/agent)
# [ ] implement chunk metadata:
# [ ]     source, position, total_chunks, language, project
# [ ]     all metadata as Qdrant payload


@dataclass
class TextChunk:
    """Fragment dokumentu z metadanymi."""

    text: str
    doc_id: str
    index: int
    meta: dict[str, Any] = field(default_factory=dict)


def split_fixed_windows(
    text: str,
    *,
    chunk_size: int = 512,
    overlap: int = 64,
) -> list[str]:
    """Nakładające się okna znaków."""
    if chunk_size <= 0:
        msg = "chunk_size must be positive"
        raise ValueError(msg)
    if overlap < 0 or overlap >= chunk_size:
        msg = "overlap must be in [0, chunk_size)"
        raise ValueError(msg)
    chunks: list[str] = []
    start = 0
    n = len(text)
    while start < n:
        end = min(start + chunk_size, n)
        chunks.append(text[start:end])
        if end == n:
            break
        start = end - overlap
    return chunks


def split_paragraphs_then_windows(
    text: str,
    *,
    chunk_size: int = 1200,
    overlap: int = 120,
) -> list[str]:
    """Najpierw akapity (`\\n\\n`), potem okna dla długich fragmentów."""
    parts: list[str] = []
    for block in text.split("\n\n"):
        b = block.strip()
        if not b:
            continue
        if len(b) <= chunk_size:
            parts.append(b)
        else:
            parts.extend(split_fixed_windows(b, chunk_size=chunk_size, overlap=overlap))
    return parts


def chunk_document(
    text: str,
    doc_id: str,
    *,
    strategy: str = "paragraphs",
    chunk_size: int = 1200,
    overlap: int = 120,
    extra_meta: dict[str, Any] | None = None,
) -> list[TextChunk]:
    """Dokument → lista `TextChunk` z indeksami."""
    extra_meta = extra_meta or {}
    if strategy == "fixed":
        parts = split_fixed_windows(text, chunk_size=chunk_size, overlap=overlap)
    elif strategy == "paragraphs":
        parts = split_paragraphs_then_windows(text, chunk_size=chunk_size, overlap=overlap)
    else:
        msg = f"unknown strategy: {strategy}"
        raise ValueError(msg)
    out: list[TextChunk] = []
    for i, p in enumerate(parts):
        if not p.strip():
            continue
        meta = {**extra_meta, "strategy": strategy}
        out.append(TextChunk(text=p.strip(), doc_id=doc_id, index=i, meta=meta))
    return out


_STRIP_HTML = re.compile(r"<[^>]+>")


def strip_html(text: str) -> str:
    """Proste usunięcie tagów HTML (bez pełnego parsera)."""
    return _STRIP_HTML.sub(" ", text)
