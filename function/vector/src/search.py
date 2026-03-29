"""Qdrant — wyszukiwanie gęste, filtry, próg score."""

from __future__ import annotations

from typing import Any

from qdrant_client import QdrantClient
from qdrant_client.http.models.models import QueryResponse, ScoredPoint
from qdrant_client.models import FieldCondition, Filter, MatchValue

# TODO:
# [ ] implement dense vector search:
# [ ]     qdrant_client.search(collection, query_vector, limit=RICE_SEARCH_TOP_K)
# [ ]     with_payload=True, with_vectors=False (payload only)
# [ ] implement filtered search:
# [ ]     Filter(must=[FieldCondition(key, match)]) — fields from config
# [ ] implement batch search: qdrant_client.search_batch()
# [ ] implement recommend API: find similar to positive/negative examples
# [ ] implement scroll API: paginate all points in collection
# [ ]     offset, limit from RICE_SCROLL_* env vars
# [ ] implement group search: qdrant_client.search_groups()
# [ ]     group_by field from config — e.g., group by source document


def dense_search(
    client: QdrantClient,
    collection: str,
    query_vector: list[float],
    *,
    limit: int = 10,
    score_threshold: float | None = None,
    query_filter: Filter | None = None,
    with_payload: bool = True,
    offset: int | None = None,
    using: str | None = None,
) -> list[ScoredPoint]:
    """Najbliższe sąsiedztwo wektorowe (API `query_points`)."""
    resp: QueryResponse = client.query_points(
        collection_name=collection,
        query=query_vector,
        using=using,
        limit=limit,
        score_threshold=score_threshold,
        query_filter=query_filter,
        with_payload=with_payload,
        offset=offset,
    )
    return list(resp.points)


def filter_match(field: str, value: str | int | bool) -> Filter:
    """Filtr: pole payload == value."""
    return Filter(must=[FieldCondition(key=field, match=MatchValue(value=value))])


def filter_must(conditions: list[FieldCondition]) -> Filter:
    return Filter(must=conditions)


def scroll_all_ids(
    client: QdrantClient,
    collection: str,
    *,
    batch_size: int = 256,
    query_filter: Filter | None = None,
) -> list[Any]:
    """Lista ID punktów (przeindeksowanie, audyt)."""
    ids: list[Any] = []
    offset = None
    while True:
        points, next_offset = client.scroll(
            collection_name=collection,
            limit=batch_size,
            offset=offset,
            with_payload=False,
            with_vectors=False,
            scroll_filter=query_filter,
        )
        ids.extend(p.id for p in points)
        if next_offset is None:
            break
        offset = next_offset
    return ids
