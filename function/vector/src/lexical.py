"""BM25S — indeks leksykalny, tokenizacja, korpus, scoring."""

from __future__ import annotations

from dataclasses import dataclass

import bm25s
from loguru import logger

# TODO:
# [ ] implement BM25S index builder:
# [ ]     tokenize corpus, build inverted index
# [ ]     k1 from RICE_BM25_K1 env var (default: 1.5)
# [ ]     b from RICE_BM25_B env var (default: 0.75)
# [ ] implement BM25S query:
# [ ]     tokenize query, score documents, return top-k
# [ ] implement index persistence: save/load BM25S index to disk
# [ ]     index path from RICE_BM25_INDEX_PATH env var
# [ ] implement incremental index update: add new documents without full rebuild
# [ ] implement sparse vector export:
# [ ]     convert BM25S scores → sparse vector for Qdrant sparse index


@dataclass
class LexicalIndex:
    """Korpus + BM25S — `doc_ids[i]` odpowiada `documents[i]`."""

    corpus_ids: list[str]
    retriever: bm25s.BM25

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
        corpus_tokens = bm25s.tokenize(
            documents,
            stopwords=stopwords,
            show_progress=show_progress,
            leave=False,
        )
        retriever = bm25s.BM25()
        retriever.index(
            corpus_tokens,
            show_progress=show_progress,
            leave_progress=False,
        )
        return cls(corpus_ids=list(doc_ids), retriever=retriever)

    def search(self, query: str, k: int = 20, *, show_progress: bool = False) -> list[tuple[str, float]]:
        """Zwraca (doc_id, score) wg rankingu BM25."""
        q_tokens = bm25s.tokenize([query], show_progress=show_progress)
        k_eff = min(k, max(1, len(self.corpus_ids)))
        res = self.retriever.retrieve(
            q_tokens,
            k=k_eff,
            show_progress=show_progress,
            leave_progress=False,
        )
        indices = res.documents[0]
        scores = res.scores[0]
        out: list[tuple[str, float]] = []
        for idx, sc in zip(indices, scores, strict=True):
            i = int(idx)
            if not (0 <= i < len(self.corpus_ids)):
                logger.debug("bm25 index out of range: {}", i)
                continue
            out.append((self.corpus_ids[i], float(sc)))
        return out


def default_stopwords_lang(lang: str) -> str:
    """Krótki kod języka → moduł stopwords BM25S (domyślnie angielski)."""
    return lang if lang in {"english", "german", "french", "spanish", "italian", "dutch"} else "english"
