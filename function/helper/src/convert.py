"""Pydantic — dump, validate, JSON/dict, prosta koercja typów."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import json
from typing import Any, TypeVar

from pydantic import BaseModel, TypeAdapter

T = TypeVar("T", bound=BaseModel)

# TODO:
# [ ] implement dict → Pydantic model conversion with error wrapping
# [ ] implement Pydantic model → JSON string (ISO8601 dates, no None fields)
# [ ] implement Polars DataFrame → list[dict] → Pydantic model list
# [ ] implement numpy array → Python list (handles all dtypes including float16)
# [ ] implement msgpack encode/decode for NATS payloads (faster than JSON)
# [ ]     RICE_NATS_SERIALIZER=msgpack|json env var controls format
# [ ] implement Arrow → Polars → numpy conversion chain
# [ ]     used by job/bridge.py for Mojo kernel data exchange
# [ ] implement base64 encode/decode for binary payloads in NATS messages


def model_to_dict(model: BaseModel, *, mode: str = "python", exclude_none: bool = False) -> dict[str, Any]:
    """`model_dump` z ustalonym trybem serializacji."""
    return model.model_dump(mode=mode, exclude_none=exclude_none)


def model_to_json(model: BaseModel, *, indent: int | None = None) -> str:
    """JSON string (UTF-8)."""
    return model.model_dump_json(indent=indent)


def parse_model(model_cls: type[T], data: dict[str, Any] | Any) -> T:
    """Walidacja ze słownika lub obiektu (model_validate)."""
    return model_cls.model_validate(data)


def parse_json(model_cls: type[T], raw: str | bytes) -> T:
    """Parsuje JSON → model (`model_validate_json`)."""
    return model_cls.model_validate_json(raw)


def coerce_json(obj: Any) -> Any:
    """`json.loads` jeśli str/bytes; w przeciwnym razie zwraca obiekt."""
    if isinstance(obj, (bytes, bytearray)):
        return json.loads(obj.decode())
    if isinstance(obj, str):
        return json.loads(obj)
    return obj


def adapt_validate[T](adapter: TypeAdapter[T], value: Any) -> T:
    """Walidacja przez `TypeAdapter` (np. list[Model], Union)."""
    return adapter.validate_python(value)


def merge_dicts(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    """Płytka kopia: `base` nadpisane kluczami z `override`."""
    out = dict(base)
    out.update(override)
    return out
