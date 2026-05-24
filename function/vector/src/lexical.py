"""BM25S lexical retrieval — ``LexicalEngine``, persistence, preprocessing, chunk-aware hits."""

from __future__ import annotations

import json
import re
import time
from pathlib import Path
from typing import Any, Final, NamedTuple

import bm25s
from helper import logger  # type: ignore[import-untyped]

from .chunk import DocumentChunk
from .const import (
    BM25S_DEFAULT_B,
    BM25S_DEFAULT_K1,
    LEXICAL_INDEX_BASENAME,
    LEXICAL_INDEX_DIR,
)

Chunk = DocumentChunk

_PUNCT_RE = re.compile(r"[^\w\s]", re.UNICODE)
_MANIFEST_SUFFIX: Final[str] = "_manifest.json"


class LexicalHit(NamedTuple):
    """Single BM25 hit for fusion (``doc_id`` aligns with dense Qdrant payloads)."""

    chunk_id: str
    doc_id: str
    score: float


def preprocess_lexical_text(
    text: str,
    *,
    lowercase: bool = True,
    strip_punctuation: bool = True,
) -> str:
    """Lowercase, strip punctuation to spaces, collapse whitespace."""
    s = (text or "").strip()
    if not s:
        return ""
    if lowercase:
        s = s.casefold()
    if strip_punctuation:
        s = _PUNCT_RE.sub(" ", s)
    return re.sub(r"\s+", " ", s).strip()


def default_stopwords_lang(lang: str) -> str:
    """ISO-style hint → BM25S stopword module name (default English)."""
    return lang if lang in {"english", "german", "french", "spanish", "italian", "dutch"} else "english"


def aggregate_lexical_hits_by_doc(hits: list[LexicalHit]) -> list[tuple[str, float]]:
    """Collapse chunk-level BM25 hits to one score per ``doc_id`` (max)."""
    best: dict[str, float] = {}
    for h in hits:
        prev = best.get(h.doc_id)
        if prev is None or h.score > prev:
            best[h.doc_id] = float(h.score)
    return sorted(best.items(), key=lambda x: -x[1])


def _chunk_id_for(chunk: DocumentChunk) -> str:
    mid = chunk.metadata.get("chunk_id") if isinstance(chunk.metadata, dict) else None
    if isinstance(mid, str) and mid.strip():
        return mid.strip()
    return f"{chunk.parent_id}:{chunk.chunk_index}"


class LexicalEngine:
    """BM25S-backed sparse index with disk persistence and full rebuild on updates."""

    def __init__(
        self,
        *,
        k1: float = BM25S_DEFAULT_K1,
        b: float = BM25S_DEFAULT_B,
        stopwords: str | None = "english",
        use_stopwords: bool = True,
    ) -> None:
        self._k1 = float(k1)
        self._b = float(b)
        self._stopwords = stopwords if use_stopwords else None
        self._use_stopwords = use_stopwords
        self._retriever: bm25s.BM25 | None = None
        self._chunk_ids: list[str] = []
        self._doc_ids: list[str] = []
        self._contents: list[str] = []

    @property
    def size(self) -> int:
        return len(self._chunk_ids)

    def clear(self) -> None:
        """Remove all indexed chunks and reset the BM25 retriever (in-memory only)."""
        self._chunk_ids.clear()
        self._doc_ids.clear()
        self._contents.clear()
        self._retriever = None

    def index_documents(
        self,
        chunks: list[DocumentChunk],
        *,
        replace: bool = True,
        show_progress: bool = False,
    ) -> None:
        """Tokenize ``DocumentChunk`` ``content`` and build or extend the BM25 index."""
        rows: list[tuple[str, str, str]] = []
        for ch in chunks:
            if not isinstance(ch, DocumentChunk):
                msg = f"index_documents expects DocumentChunk, got {type(ch).__name__}"
                raise TypeError(msg)
            raw = preprocess_lexical_text(ch.content)
            if not raw:
                continue
            cid = _chunk_id_for(ch)
            rows.append((cid, ch.parent_id, raw))

        if not rows:
            logger.warning("LexicalEngine.index_documents: no non-empty chunks after preprocessing")
            return

        if replace:
            self._chunk_ids.clear()
            self._doc_ids.clear()
            self._contents.clear()
            self._retriever = None

        self._chunk_ids.extend(cid for cid, _, _ in rows)
        self._doc_ids.extend(did for _, did, _ in rows)
        self._contents.extend(txt for _, _, txt in rows)

        t0 = time.perf_counter()
        self._fit_retriever(show_progress=show_progress)
        dt = time.perf_counter() - t0
        logger.info(
            "LexicalEngine indexed | chunks={} index_s={:.3f}",
            len(self._chunk_ids),
            dt,
        )

    def _fit_retriever(self, *, show_progress: bool) -> None:
        if not self._contents:
            return
        sw = self._stopwords if self._use_stopwords else None
        corpus_tokens = bm25s.tokenize(
            self._contents,
            stopwords=sw,
            show_progress=show_progress,
            leave=False,
        )
        self._retriever = bm25s.BM25(k1=self._k1, b=self._b)
        self._retriever.index(
            corpus_tokens,
            show_progress=show_progress,
            leave_progress=False,
        )

    def add_documents(self, chunks: list[DocumentChunk], *, show_progress: bool = False) -> None:
        """Append chunks and rebuild the index (full NumPy rebuild; suitable for moderate corpora)."""
        self.index_documents(chunks, replace=False, show_progress=show_progress)

    def search(
        self,
        query: str,
        top_k: int = 20,
        *,
        k: int | None = None,
        show_progress: bool = False,
    ) -> list[LexicalHit]:
        """BM25 retrieval: ``chunk_id``, ``doc_id`` (``parent_id``), and raw lexical score."""
        if self._retriever is None or not self._contents:
            return []
        n = int(k if k is not None else top_k)
        n = max(1, min(n, len(self._chunk_ids)))
        q_prep = preprocess_lexical_text(query)
        if not q_prep:
            return []
        q_tokens = bm25s.tokenize(
            [q_prep],
            stopwords=self._stopwords if self._use_stopwords else None,
            show_progress=show_progress,
        )
        res = self._retriever.retrieve(
            q_tokens,
            k=n,
            show_progress=show_progress,
            leave_progress=False,
        )
        indices = res.documents[0]
        scores = res.scores[0]
        out: list[LexicalHit] = []
        for idx, sc in zip(indices, scores, strict=True):
            i = int(idx)
            if not (0 <= i < len(self._chunk_ids)):
                logger.debug("LexicalEngine.search: bm25 index out of range | i={}", i)
                continue
            out.append(
                LexicalHit(
                    chunk_id=self._chunk_ids[i],
                    doc_id=self._doc_ids[i],
                    score=float(sc),
                ),
            )
        return out

    def default_save_base(self) -> Path:
        return Path(LEXICAL_INDEX_DIR) / LEXICAL_INDEX_BASENAME

    def save(self, base_path: Path | str | None = None) -> Path:
        """Persist BM25 index + manifest (chunk / doc ids, raw texts, hyperparameters)."""
        if self._retriever is None:
            msg = "cannot save LexicalEngine: index is empty"
            raise ValueError(msg)
        base = Path(base_path) if base_path is not None else self.default_save_base()
        base.parent.mkdir(parents=True, exist_ok=True)
        manifest = {
            "chunk_ids": self._chunk_ids,
            "doc_ids": self._doc_ids,
            "contents": self._contents,
            "k1": self._k1,
            "b": self._b,
            "stopwords": self._stopwords,
            "use_stopwords": self._use_stopwords,
        }
        man_path = base.parent / f"{base.name}{_MANIFEST_SUFFIX}"
        man_path.write_text(json.dumps(manifest, ensure_ascii=False), encoding="utf-8")
        self._retriever.save(str(base))
        logger.info("LexicalEngine saved | path={} chunks={}", base, len(self._chunk_ids))
        return base

    @classmethod
    def load(cls, base_path: Path | str | None = None) -> LexicalEngine:
        """Load BM25 index + manifest written by :meth:`save`."""
        base = Path(base_path) if base_path is not None else Path(LEXICAL_INDEX_DIR) / LEXICAL_INDEX_BASENAME
        man_path = base.parent / f"{base.name}{_MANIFEST_SUFFIX}"
        manifest = json.loads(man_path.read_text(encoding="utf-8"))
        eng = cls(
            k1=float(manifest.get("k1", BM25S_DEFAULT_K1)),
            b=float(manifest.get("b", BM25S_DEFAULT_B)),
            stopwords=manifest.get("stopwords", "english"),
            use_stopwords=bool(manifest.get("use_stopwords", True)),
        )
        eng._chunk_ids = list(manifest.get("chunk_ids", []))
        eng._doc_ids = list(manifest.get("doc_ids", []))
        eng._contents = list(manifest.get("contents", []))
        eng._retriever = bm25s.BM25.load(str(base), load_corpus=True)
        logger.info("LexicalEngine loaded | path={} chunks={}", base, len(eng._chunk_ids))
        return eng


class LexicalIndex(LexicalEngine):
    """Backward-compatible API: flat ``documents`` / ``doc_ids`` corpus."""

    @classmethod
    def build(
        cls,
        documents: list[str],
        doc_ids: list[str],
        *,
        stopwords: str = "english",
        show_progress: bool = False,
    ) -> LexicalIndex:
        if len(documents) != len(doc_ids):
            msg = "documents and doc_ids length mismatch"
            raise ValueError(msg)
        chunks = [
            DocumentChunk(content=documents[i], parent_id=doc_ids[i], chunk_index=0, metadata={})
            for i in range(len(documents))
        ]
        inst = cls(stopwords=stopwords, use_stopwords=True)
        inst.index_documents(chunks, replace=True, show_progress=show_progress)
        return inst

    def search(
        self,
        query: str,
        k: int = 20,
        *,
        top_k: int | None = None,
        show_progress: bool = False,
    ) -> list[LexicalHit]:
        n = int(top_k if top_k is not None else k)
        return super().search(query, top_k=n, show_progress=show_progress)


__all__ = [
    "Chunk",
    "LexicalEngine",
    "LexicalHit",
    "LexicalIndex",
    "aggregate_lexical_hits_by_doc",
    "default_stopwords_lang",
    "preprocess_lexical_text",
]
