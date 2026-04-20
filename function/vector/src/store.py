"""Qdrant — kolekcje, upsert, payload, snapshoty."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import Any

from loguru import logger
from pydantic import BaseModel, Field
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, PointStruct, VectorParams

# TODO:
# [ ] implement Qdrant collection manager:
# [ ]     create_collection with VectorParams(size=RICE_EMBEDDING_DIM, distance=RICE_DISTANCE)
# [ ]     distance: Cosine|Dot|Euclid — from RICE_QDRANT_DISTANCE env var
# [ ]     on_disk_payload=True for large payloads
# [ ] implement scalar quantization config:
# [ ]     ScalarQuantizationConfig(type=INT8, quantile=0.99)
# [ ]     enabled when RICE_QDRANT_QUANTIZATION=scalar
# [ ] implement HNSW config:
# [ ]     m from RICE_QDRANT_HNSW_M, ef_construct from RICE_QDRANT_EF_CONSTRUCT
# [ ] implement collection aliases for zero-downtime updates:
# [ ]     create new collection → populate → switch alias → delete old
# [ ] implement multi-vector support: named vectors per role
# [ ]     dense: main embedding, sparse: BM25S weights
# [ ] implement payload indexing:
# [ ]     create_payload_index for filterable fields
# [ ]     indexed fields from RICE_QDRANT_INDEX_FIELDS env var
# [ ] implement snapshots: create_snapshot before bulk operations
# [ ]     snapshot path from RICE_QDRANT_SNAPSHOT_DIR


class ChunkPayload(BaseModel):
    """Schemat payloadu punktu — rozszerzaj w projekcie, nie zmieniaj nazw pól w locie."""

    text: str
    doc_id: str
    chunk_index: int = 0
    meta: dict[str, Any] = Field(default_factory=dict)


def ensure_collection(
    client: QdrantClient,
    name: str,
    *,
    vector_size: int,
    distance: Distance = Distance.COSINE,
    on_disk_payload: bool = False,
) -> None:
    """Tworzy kolekcję jeśli nie istnieje."""
    exists = False
    try:
        client.get_collection(name)
        exists = True
    except Exception:
        exists = False
    if exists:
        return
    client.create_collection(
        collection_name=name,
        vectors_config=VectorParams(size=vector_size, distance=distance, on_disk=False),
        on_disk_payload=on_disk_payload,
    )
    logger.info("created qdrant collection {}", name)


def upsert_points(
    client: QdrantClient,
    collection: str,
    ids: list[int],
    vectors: list[list[float]],
    payloads: list[dict[str, Any]],
    *,
    wait: bool = True,
) -> None:
    """Upsert punktów (identyfikatory numeryczne)."""
    points = [
        PointStruct(id=i, vector=v, payload=p) for i, v, p in zip(ids, vectors, payloads, strict=True)
    ]
    client.upsert(collection_name=collection, points=points, wait=wait)


def delete_collection(client: QdrantClient, name: str) -> None:
    client.delete_collection(collection_name=name)


def create_snapshot(client: QdrantClient, collection: str) -> str | None:
    """Snapshot kolekcji (serwer Qdrant musi wspierać snapshots). Zwraca nazwę lub None."""
    try:
        snap = client.create_snapshot(collection_name=collection)
        return getattr(snap, "name", None) or str(snap)
    except Exception as exc:  # noqa: BLE001
        logger.warning("snapshot failed: {}", exc)
        return None


def list_collections(client: QdrantClient) -> list[str]:
    cols = client.get_collections()
    return [c.name for c in cols.collections]
