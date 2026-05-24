"""Pydantic — modele bazowe, typy pól, serializery."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import json
from datetime import UTC, datetime
from typing import Annotated, Any, Generic, TypeVar

from pydantic import BaseModel, BeforeValidator, ConfigDict, Field, computed_field

T = TypeVar("T")

# TODO:
# [ ] define base Pydantic config: ConfigDict(strict=True, frozen=False, extra="forbid")
# [ ] define RiceBaseModel: all SAGE models inherit from this
# [ ]     adds: created_at, updated_at auto-fields
# [ ]     adds: model_dump_json() with ISO8601 datetime serialization
# [ ] define pagination schema: Page(items, total, page, page_size, has_next)
# [ ]     page_size default from RICE_PAGE_SIZE env var
# [ ] define error schema: RiceError(code, message, detail, trace_id)
# [ ]     codes: soft-coded enum — not hardcoded integers
# [ ] define NATS message schema: NatsMessage(subject, payload, headers, timestamp)
# [ ]     all SAGE NATS messages validated against this schema
# [ ] define OTel span schema: SpanContext(trace_id, span_id, role, model, latency_ms)
# [ ] export all schemas as JSON Schema to infra/schemas/sage/
# [ ]     called by MASON on rice pour to generate Proto contracts


def _utc_now() -> datetime:
    return datetime.now(tz=UTC)


def _strip_nonempty(v: Any) -> str:
    if isinstance(v, str):
        s = v.strip()
        if not s:
            msg = "value must be non-empty after strip"
            raise ValueError(msg)
        return s
    msg = "expected string"
    raise TypeError(msg)


NonEmptyStr = Annotated[str, BeforeValidator(_strip_nonempty)]


class SchemaBase(BaseModel):
    """Bazowy model — strict gdzie ma sens."""

    model_config = ConfigDict(
        str_strip_whitespace=True,
        validate_assignment=True,
        extra="forbid",
    )


class TimestampedSchema(SchemaBase):
    """Encja z czasem utworzenia (UTC)."""

    created_at: datetime = Field(default_factory=_utc_now)

    @computed_field  # type: ignore[prop-decorator]
    @property
    def created_at_iso(self) -> str:
        return self.created_at.isoformat()


class Page(SchemaBase, Generic[T]):
    """Offset/limit window over ``items`` (search, list APIs). ``total`` optional when unknown."""

    items: list[T] = Field(default_factory=list)
    offset: int = Field(ge=0, default=0)
    limit: int = Field(ge=1, default=20)
    total: int | None = Field(
        default=None,
        description="Total matching rows when the store reports it; omit when unknown.",
    )
    has_next: bool = Field(
        default=False,
        description="True when another page likely exists (e.g. ``len(items) == limit``).",
    )


def dumps_json_value(v: Any) -> str:
    """Dowolny obiekt → string JSON (np. do własnych serializerów)."""
    return json.dumps(v, default=str)
