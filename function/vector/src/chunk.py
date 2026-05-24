"""Text chunking for embeddings and lexical indexing — recursive, sliding, and ingest helpers."""

from __future__ import annotations

import json
import re
from collections.abc import Iterator, Sequence
from typing import Any, Literal

from helper import RiceError, logger
from helper.schema import SchemaBase
from helper.validate import validate_payload
from pydantic import ConfigDict, Field, field_validator, model_validator

from .const import (
    CHUNK_OVERLAP,
    CHUNK_PIPELINE_MAX_INPUT_CHARS,
    CHUNK_SIZE,
    VECTOR_TEXT_ENCODING,
)

_STRIP_HTML = re.compile(r"<[^>]+>")
class ChunkingNormalizedText(SchemaBase):
    """Validated body passed through `validate_payload` before chunking."""

    text: str

    @field_validator("text", mode="after")
    @classmethod
    def _normalize_whitespace(cls, v: str) -> str:
        v = v.replace("\r\n", "\n").replace("\r", "\n")
        v = re.sub(r"[ \t\f\v]+", " ", v)
        v = re.sub(r"\n{3,}", "\n\n", v)
        return v.strip()


class DocumentChunk(SchemaBase):
    """One fragment ready for embedding / Qdrant with preserved metadata."""

    content: str = Field(min_length=1)
    metadata: dict[str, Any] = Field(default_factory=dict)
    chunk_index: int = Field(ge=0)
    parent_id: str = Field(min_length=1)

    model_config = ConfigDict(
        str_strip_whitespace=True,
        validate_assignment=True,
        extra="forbid",
        populate_by_name=True,
    )

    @model_validator(mode="before")
    @classmethod
    def _legacy_field_names(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data
        d = dict(data)
        if "text" in d and "content" not in d:
            d["content"] = d.pop("text")
        if "doc_id" in d and "parent_id" not in d:
            d["parent_id"] = d.pop("doc_id")
        if "index" in d and "chunk_index" not in d:
            d["chunk_index"] = d.pop("index")
        if "meta" in d and "metadata" not in d:
            d["metadata"] = d.pop("meta")
        return d

    @property
    def text(self) -> str:
        return self.content

    @property
    def doc_id(self) -> str:
        return self.parent_id

    @property
    def index(self) -> int:
        return self.chunk_index

    @property
    def meta(self) -> dict[str, Any]:
        return self.metadata


TextChunk = DocumentChunk


def strip_html(text: str) -> str:
    """Remove simple HTML/XML tags (not a full parser)."""
    return _STRIP_HTML.sub(" ", text)


def estimate_token_count(text: str, *, method: Literal["chars", "words", "hybrid"] = "hybrid") -> int:
    """Rough token budget for chunking / rate limits (no tokenizer dependency)."""
    if not text.strip():
        return 0
    n_chars = len(text)
    n_words = len(text.split())
    if method == "chars":
        return max(1, n_chars // 4)
    if method == "words":
        return max(1, int(n_words * 1.3))
    return max(1, int(min(n_chars // 4, n_words * 1.3)))


def prepare_plaintext(raw: str) -> str:
    """Normalize plain text (no structural assumptions)."""
    return _ingest_and_normalize(raw)


def prepare_markdown(raw: str) -> str:
    """Normalize Markdown: strip HTML if present, keep headings and blocks."""
    t = strip_html(raw)
    return _ingest_and_normalize(t)


def prepare_json_string(raw: str) -> str:
    """If `raw` is JSON, extract a primary text field; otherwise treat as plain string."""
    s = raw.strip()
    if not s:
        return ""
    if not (s.startswith("{") or s.startswith("[")):
        return _ingest_and_normalize(s)
    try:
        data = json.loads(s)
    except json.JSONDecodeError as exc:
        raise RiceError(
            "invalid JSON string for chunking",
            error_code="CHUNK_JSON_DECODE",
            details={"reason": str(exc)},
        ) from exc
    if isinstance(data, str):
        return _ingest_and_normalize(data)
    if isinstance(data, dict):
        for key in ("text", "content", "body", "markdown", "message"):
            val = data.get(key)
            if isinstance(val, str) and val.strip():
                return _ingest_and_normalize(val)
        return _ingest_and_normalize(json.dumps(data, ensure_ascii=False))
    if isinstance(data, list):
        parts = [json.dumps(item, ensure_ascii=False) if not isinstance(item, str) else item for item in data]
        return _ingest_and_normalize("\n\n".join(parts))
    return _ingest_and_normalize(str(data))


def _ingest_and_normalize(raw: str) -> str:
    if not isinstance(raw, str):
        msg = "document text must be str"
        raise TypeError(msg)
    try:
        raw.encode(VECTOR_TEXT_ENCODING, errors="strict")
    except UnicodeError as exc:
        raise RiceError(
            "text encoding is not valid for chunking pipeline",
            error_code="CHUNK_ENCODING",
            details={"encoding": VECTOR_TEXT_ENCODING},
        ) from exc
    if len(raw) > CHUNK_PIPELINE_MAX_INPUT_CHARS:
        raise RiceError(
            "document exceeds maximum size for chunking",
            error_code="CHUNK_TEXT_TOO_LARGE",
            details={"length": len(raw), "max": CHUNK_PIPELINE_MAX_INPUT_CHARS},
        )
    if not raw.strip():
        return ""
    return validate_payload(ChunkingNormalizedText, {"text": raw}).text


def _recursive_char_chunks(
    text: str,
    *,
    chunk_size: int,
    separators: Sequence[str],
) -> Iterator[str]:
    """Split by decreasing structural priority; yields non-empty trimmed fragments."""
    text_stripped = text.strip()
    if not text_stripped:
        return
    if len(text_stripped) <= chunk_size:
        yield text_stripped
        return

    if not separators:
        for i in range(0, len(text_stripped), chunk_size):
            frag = text_stripped[i : i + chunk_size].strip()
            if frag:
                yield frag
        return

    for idx, separator in enumerate(separators):
        if separator != "" and separator not in text_stripped:
            continue
        splits = [text_stripped] if separator == "" else text_stripped.split(separator)
        next_seps = separators[idx + 1 :]
        merged: list[str] = []
        for piece in splits:
            if not piece:
                continue
            if len(piece) <= chunk_size:
                merged.append(piece)
            else:
                if merged:
                    joined = separator.join(merged).strip()
                    if joined:
                        yield from _recursive_char_chunks(joined, chunk_size=chunk_size, separators=next_seps)
                    merged = []
                yield from _recursive_char_chunks(piece, chunk_size=chunk_size, separators=next_seps)
        if merged:
            joined = separator.join(merged).strip()
            if joined:
                yield from _recursive_char_chunks(joined, chunk_size=chunk_size, separators=next_seps)
        return

    for i in range(0, len(text_stripped), chunk_size):
        frag = text_stripped[i : i + chunk_size].strip()
        if frag:
            yield frag


class RecursiveCharacterChunker:
    """Hierarchical splits: Markdown-ish headers, paragraphs, lines, sentences, then words."""

    def __init__(
        self,
        *,
        chunk_size: int | None = None,
        chunk_overlap: int | None = None,
        separators: Sequence[str] | None = None,
    ) -> None:
        self.chunk_size = int(chunk_size or CHUNK_SIZE)
        self.chunk_overlap = int(chunk_overlap or CHUNK_OVERLAP)
        self._separators: tuple[str, ...] = tuple(separators) if separators is not None else (
            "\n## ",
            "\n### ",
            "\n#### ",
            "\n##### ",
            "\n###### ",
            "\n\n",
            "\n",
            ". ",
            "! ",
            "? ",
            "; ",
            ", ",
            " ",
            "",
        )
        if self.chunk_size <= 0:
            msg = "chunk_size must be positive"
            raise ValueError(msg)
        if self.chunk_overlap < 0 or self.chunk_overlap >= self.chunk_size:
            msg = "chunk_overlap must be in [0, chunk_size)"
            raise ValueError(msg)

    def iter_chunks(self, text: str) -> Iterator[str]:
        yield from _recursive_char_chunks(text, chunk_size=self.chunk_size, separators=self._separators)


class SlidingWindowChunker:
    """Fixed-size overlapping windows over normalized text."""

    def __init__(
        self,
        *,
        chunk_size: int | None = None,
        chunk_overlap: int | None = None,
    ) -> None:
        self.chunk_size = int(chunk_size or CHUNK_SIZE)
        self.chunk_overlap = int(chunk_overlap or CHUNK_OVERLAP)
        if self.chunk_size <= 0:
            msg = "chunk_size must be positive"
            raise ValueError(msg)
        if self.chunk_overlap < 0 or self.chunk_overlap >= self.chunk_size:
            msg = "chunk_overlap must be in [0, chunk_size)"
            raise ValueError(msg)

    def iter_chunks(self, text: str) -> Iterator[str]:
        t = text.strip()
        if not t:
            return
        step = max(1, self.chunk_size - self.chunk_overlap)
        start = 0
        n = len(t)
        while start < n:
            end = min(start + self.chunk_size, n)
            frag = t[start:end].strip()
            if frag:
                yield frag
            if end == n:
                break
            start += step


class SemanticChunker:
    """Placeholder for model-based boundary detection (embedding / NER)."""

    def __init__(
        self,
        *,
        chunk_size: int | None = None,
        chunk_overlap: int | None = None,
    ) -> None:
        self.chunk_size = chunk_size or CHUNK_SIZE
        self.chunk_overlap = chunk_overlap or CHUNK_OVERLAP

    def iter_chunks(self, text: str) -> Iterator[str]:
        logger.debug(
            "SemanticChunker is a stub; using RecursiveCharacterChunker | size={} overlap={}",
            self.chunk_size,
            self.chunk_overlap,
        )
        yield from RecursiveCharacterChunker(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
        ).iter_chunks(text)


def split_fixed_windows(
    text: str,
    *,
    chunk_size: int | None = None,
    overlap: int | None = None,
) -> list[str]:
    """Backward-compatible list API over :class:`SlidingWindowChunker`."""
    cw = SlidingWindowChunker(chunk_size=chunk_size or CHUNK_SIZE, chunk_overlap=overlap or CHUNK_OVERLAP)
    return list(cw.iter_chunks(text))


def split_paragraphs_then_windows(
    text: str,
    *,
    chunk_size: int | None = None,
    overlap: int | None = None,
) -> list[str]:
    """Paragraphs first; long blocks passed through sliding windows."""
    cs = chunk_size or CHUNK_SIZE
    ov = overlap or CHUNK_OVERLAP
    out: list[str] = []
    for block in text.split("\n\n"):
        b = block.strip()
        if not b:
            continue
        if len(b) <= cs:
            out.append(b)
        else:
            out.extend(split_fixed_windows(b, chunk_size=cs, overlap=ov))
    return out


def iter_chunk_document(
    text: str,
    parent_id: str,
    *,
    strategy: str = "recursive",
    chunk_size: int | None = None,
    overlap: int | None = None,
    extra_meta: dict[str, Any] | None = None,
    source_type: Literal["markdown", "plain", "json"] = "plain",
) -> Iterator[DocumentChunk]:
    """Yield chunks without materializing the full list (large documents)."""
    cs = chunk_size or CHUNK_SIZE
    ov = overlap or CHUNK_OVERLAP
    extra = dict(extra_meta or {})

    if source_type == "markdown":
        prepared = prepare_markdown(text)
    elif source_type == "json":
        prepared = prepare_json_string(text)
    else:
        prepared = prepare_plaintext(text)

    if not prepared.strip():
        return

    if strategy == "recursive":
        iterator = RecursiveCharacterChunker(chunk_size=cs, chunk_overlap=ov).iter_chunks(prepared)
    elif strategy == "sliding":
        iterator = SlidingWindowChunker(chunk_size=cs, chunk_overlap=ov).iter_chunks(prepared)
    elif strategy == "semantic":
        iterator = SemanticChunker(chunk_size=cs, chunk_overlap=ov).iter_chunks(prepared)
    elif strategy == "paragraphs":
        iterator = (p for p in split_paragraphs_then_windows(prepared, chunk_size=cs, overlap=ov) if p.strip())
    elif strategy == "fixed":
        iterator = (p for p in split_fixed_windows(prepared, chunk_size=cs, overlap=ov) if p.strip())
    else:
        msg = f"unknown strategy: {strategy}"
        raise ValueError(msg)

    idx = 0
    for fragment in iterator:
        frag = fragment.strip()
        if not frag:
            continue
        meta = {
            **extra,
            "strategy": strategy,
            "source_type": source_type,
            "token_estimate": estimate_token_count(frag),
        }
        yield DocumentChunk(
            content=frag,
            parent_id=parent_id,
            chunk_index=idx,
            metadata=meta,
        )
        idx += 1


def chunk_document(
    text: str,
    doc_id: str,
    *,
    strategy: str = "recursive",
    chunk_size: int | None = None,
    overlap: int | None = None,
    extra_meta: dict[str, Any] | None = None,
    source_type: Literal["markdown", "plain", "json"] = "plain",
) -> list[DocumentChunk]:
    """Materialize ``iter_chunk_document`` as a list (small / medium corpora)."""
    return list(
        iter_chunk_document(
            text,
            doc_id,
            strategy=strategy,
            chunk_size=chunk_size,
            overlap=overlap,
            extra_meta=extra_meta,
            source_type=source_type,
        ),
    )


__all__ = [
    "DocumentChunk",
    "RecursiveCharacterChunker",
    "SemanticChunker",
    "SlidingWindowChunker",
    "TextChunk",
    "chunk_document",
    "estimate_token_count",
    "iter_chunk_document",
    "prepare_json_string",
    "prepare_markdown",
    "prepare_plaintext",
    "split_fixed_windows",
    "split_paragraphs_then_windows",
    "strip_html",
]
