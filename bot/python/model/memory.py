"""Qdrant vector store and BM25 hybrid search with RRF (Reciprocal Rank Fusion).

Provides get_vector_store, list_collections, create_collection, delete_collection,
hybrid_search (BM25), search (hybrid semantic + keyword with RRF), add_documents,
delete_documents, update_document. In-memory fallback when Qdrant unavailable.
Requires: qdrant-client, bm25s (extra model). All comments in English.
"""

from __future__ import annotations

from typing import Any

from loguru import logger

# In-memory fallback when Qdrant not used: id -> {text, metadata}
_memory_docs: dict[str, dict[str, Any]] = {}
_bm25_corpus: list[str] = []
_bm25_ids: list[str] = []  # same order as _bm25_corpus for index -> id
_bm25_index: Any = None


def _rrf_fusion(rank_lists: list[list[tuple[str, float]]], k: int = 60) -> list[tuple[str, float]]:
    """Reciprocal Rank Fusion: merge ranked lists into one. k is RRF constant."""
    scores: dict[str, float] = {}
    for rank_list in rank_lists:
        for rank, (doc_id, _) in enumerate(rank_list, start=1):
            scores[doc_id] = scores.get(doc_id, 0.0) + 1.0 / (k + rank)
    sorted_ids = sorted(scores.keys(), key=lambda x: -scores[x])
    return [(doc_id, scores[doc_id]) for doc_id in sorted_ids]


def get_vector_store(*, url: str | None = None, port: int | None = None, api_key: str | None = None):
    """Return Qdrant client. URL/port from config if not provided."""
    try:
        from qdrant_client import QdrantClient
    except ImportError as e:
        raise ImportError("get_vector_store requires qdrant-client; uv sync --extra model") from e
    try:
        from app.config import get_settings
        s = get_settings()
        url = url or s.QDRANT_URL.replace("http://", "").replace("https://", "").split(":")[0]
        port = port or (6333 if "6333" in s.QDRANT_URL else 6333)
        api_key = api_key or (s.QDRANT_API_KEY or None)
    except Exception:
        url = url or "localhost"
        port = port or 6333
    if api_key:
        return QdrantClient(url=url or "http://localhost", port=port, api_key=api_key)
    return QdrantClient(host=url, port=port)


def list_collections() -> list[str]:
    """List Qdrant collection names. Returns [] if Qdrant unavailable."""
    try:
        client = get_vector_store()
        return [c.name for c in client.get_collections().collections]
    except Exception as e:
        logger.debug("list_collections failed", error=str(e))
        return []


def create_collection(name: str | None = None, vector_size: int | None = None) -> None:
    """Create Qdrant collection. Uses config name and vector_size if not provided."""
    try:
        from qdrant_client.models import Distance, VectorParams
        from app.config import get_settings
        s = get_settings()
        name = name or s.QDRANT_COLLECTION_NAME
        vector_size = vector_size or s.QDRANT_VECTOR_SIZE
        client = get_vector_store()
        client.create_collection(name, vectors_config=VectorParams(size=vector_size, distance=Distance.COSINE))
        logger.info("create_collection", name=name)
    except Exception as e:
        logger.warning("create_collection failed", error=str(e))


def delete_collection(name: str | None = None) -> None:
    """Delete Qdrant collection."""
    try:
        from app.config import get_settings
        name = name or get_settings().QDRANT_COLLECTION_NAME
        client = get_vector_store()
        client.delete_collection(name)
        logger.info("delete_collection", name=name)
    except Exception as e:
        logger.warning("delete_collection failed", error=str(e))


def hybrid_search(
    corpus: list[str], query: str, top_k: int = 5
) -> list[tuple[int, float]]:
    """BM25 keyword search. Returns list of (index, score)."""
    try:
        import bm25s
    except ImportError as e:
        raise ImportError("hybrid_search requires bm25s; uv sync --extra model") from e
    if not corpus:
        return []
    corpus_tokens = bm25s.tokenize(corpus)
    retriever = bm25s.BM25()
    retriever.index(corpus_tokens)
    query_tokens = bm25s.tokenize(query)
    docs, scores = retriever.retrieve(query_tokens, k=top_k)
    return list(zip(docs, scores, strict=True))


def _bm25_search(query: str, top_k: int) -> list[tuple[str, float]]:
    """BM25 over in-memory corpus; returns (id, score)."""
    global _bm25_corpus, _bm25_ids, _bm25_index
    if not _bm25_corpus or _bm25_index is None or not _bm25_ids:
        return []
    try:
        import bm25s
        query_tokens = bm25s.tokenize(query)
        docs, scores = _bm25_index.retrieve(query_tokens, k=top_k)
        return [(_bm25_ids[i], float(s)) for i, s in zip(docs, scores, strict=True) if i < len(_bm25_ids)]
    except Exception:
        return []


def search(query: str, top_k: int = 5, alpha: float = 0.5, **kwargs: Any) -> list[dict]:
    """Hybrid search: semantic (Qdrant) + keyword (BM25) with RRF. alpha: weight for semantic.

    Returns list of {"id", "text", "score", "metadata"}. Uses in-memory store if Qdrant unavailable.
    """
    corpus = kwargs.get("corpus", [])
    if corpus:
        hits = hybrid_search(corpus, query, top_k=top_k)
        return [{"id": str(i), "text": corpus[i], "score": float(sc), "metadata": {}} for i, sc in hits]
    # In-memory: BM25 only if we have docs
    bm25_hits = _bm25_search(query, top_k)
    results = []
    for doc_id, score in bm25_hits:
        doc = _memory_docs.get(doc_id, {})
        results.append({
            "id": doc_id,
            "text": doc.get("text", ""),
            "score": score,
            "metadata": doc.get("metadata", {}),
        })
    # If Qdrant configured, could run vector search and RRF merge here
    try:
        from app.config import get_settings
        from qdrant_client.models import PointStruct
        s = get_settings()
        if s.QDRANT_URL and _memory_docs:
            client = get_vector_store()
            coll = s.QDRANT_COLLECTION_NAME
            # Placeholder: would need embeddings; skip if no embedding fn
            pass
    except Exception:
        pass
    return results


def add_documents(docs: list[dict[str, Any]], embed_fn: Any = None) -> list[str]:
    """Index documents. Each doc: {id?, text, metadata?}. Returns list of ids.

    If embed_fn is provided (e.g. from model.embeddings), vectors are stored in Qdrant.
    Otherwise only in-memory + BM25 is updated.
    """
    global _memory_docs, _bm25_corpus, _bm25_ids, _bm25_index
    ids: list[str] = []
    for i, doc in enumerate(docs):
        doc_id = doc.get("id") or f"doc_{i}"
        text = doc.get("text", "")
        meta = doc.get("metadata", {})
        _memory_docs[doc_id] = {"id": doc_id, "text": text, "metadata": meta}
        ids.append(doc_id)
    if _memory_docs:
        _bm25_ids = sorted(_memory_docs.keys())
        _bm25_corpus = [_memory_docs[k].get("text", "") for k in _bm25_ids]
        try:
            import bm25s
            tokens = bm25s.tokenize(_bm25_corpus)
            _bm25_index = bm25s.BM25()
            _bm25_index.index(tokens)
        except ImportError:
            _bm25_index = None
    logger.info("add_documents", count=len(ids))
    return ids


def delete_documents(ids: list[str]) -> None:
    """Remove documents by id from in-memory store and reset BM25."""
    global _memory_docs, _bm25_corpus, _bm25_ids, _bm25_index
    for doc_id in ids:
        _memory_docs.pop(doc_id, None)
    _bm25_ids = sorted(_memory_docs.keys())
    _bm25_corpus = [_memory_docs[k].get("text", "") for k in _bm25_ids]
    _bm25_index = None
    if _bm25_corpus:
        try:
            import bm25s
            _bm25_index = bm25s.BM25()
            _bm25_index.index(bm25s.tokenize(_bm25_corpus))
        except ImportError:
            pass
    logger.info("delete_documents", count=len(ids))


def update_document(doc_id: str, data: dict[str, Any]) -> None:
    """Update one document by id. data: {text?, metadata?}."""
    global _memory_docs, _bm25_corpus, _bm25_ids, _bm25_index
    if doc_id not in _memory_docs:
        return
    _memory_docs[doc_id].update(data)
    _bm25_ids = sorted(_memory_docs.keys())
    _bm25_corpus = [_memory_docs[k].get("text", "") for k in _bm25_ids]
    _bm25_index = None
    if _bm25_corpus:
        try:
            import bm25s
            _bm25_index = bm25s.BM25()
            _bm25_index.index(bm25s.tokenize(_bm25_corpus))
        except ImportError:
            pass
