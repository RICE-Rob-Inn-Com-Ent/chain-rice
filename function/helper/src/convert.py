"""Konwersja danych: Pydantic, JSON/MsgPack (NATS), NumPy, Arrow→NumPy, Base64."""

from __future__ import annotations

import base64
import binascii
import json
from datetime import UTC, date, datetime
from typing import Any, TypeVar

import msgpack
import msgpack.exceptions
import numpy as np
from pydantic import BaseModel, TypeAdapter
from pydantic import ValidationError as PydanticValidationError

from .error import ValidationError as RiceValidationError
from .log import get_logger
from .settings import get_settings

TModel = TypeVar("TModel", bound=BaseModel)


def _log_conversion_failure(stage: str, *, exc: BaseException | None = None, binary: bool = False) -> None:
    log = get_logger()
    if binary:
        log.bind(stage=stage).error("conversion failed (binary payload) | stage={}", stage)
    else:
        log.bind(stage=stage).warning("conversion failed | stage={} | err={}", stage, exc)


def _json_default(obj: Any) -> Any:
    if isinstance(obj, datetime):
        dt = obj if obj.tzinfo is not None else obj.replace(tzinfo=UTC)
        return dt.astimezone(UTC).isoformat().replace("+00:00", "Z")
    if isinstance(obj, date):
        return obj.isoformat()
    if isinstance(obj, (bytes, bytearray)):
        return bytes(obj).decode("utf-8", errors="surrogateescape")
    if isinstance(obj, np.generic):
        return numpy_to_list(obj)
    if isinstance(obj, np.ndarray):
        return numpy_to_list(obj)
    msg = f"JSON default not implemented for {type(obj)!r}"
    raise TypeError(msg)


def _msgpack_default(obj: Any) -> Any:
    if isinstance(obj, datetime):
        dt = obj if obj.tzinfo is not None else obj.replace(tzinfo=UTC)
        return dt.astimezone(UTC).isoformat().replace("+00:00", "Z")
    if isinstance(obj, date):
        return obj.isoformat()
    if isinstance(obj, np.generic):
        return obj.item()
    if isinstance(obj, np.ndarray):
        if obj.ndim == 0:
            return obj.item()
        return obj.tolist()
    if isinstance(obj, (bytes, bytearray)):
        return bytes(obj)
    msg = f"msgpack default not implemented for {type(obj)!r}"
    raise TypeError(msg)


def model_to_dict(
    model: BaseModel,
    *,
    mode: str = "python",
    exclude_none: bool = False,
    wire_iso8601_utc: bool = False,
) -> dict[str, Any]:
    """`model_dump`; `wire_iso8601_utc=True` wymusza `mode='json'` (ISO-8601 UTC dla `datetime`)."""
    eff_mode = "json" if wire_iso8601_utc else mode
    return model.model_dump(mode=eff_mode, exclude_none=exclude_none)


def model_to_json(
    model: BaseModel,
    *,
    indent: int | None = None,
    exclude_none: bool = False,
) -> str:
    """JSON UTF-8 — serializacja czasu jak w trybie `json` Pydantic."""
    return model.model_dump_json(indent=indent, exclude_none=exclude_none)


def parse_model(model_cls: type[TModel], data: Any) -> TModel:
    """`model_validate` z opakowaniem błędów w `RiceValidationError`."""
    try:
        return model_cls.model_validate(data)
    except PydanticValidationError as exc:
        _log_conversion_failure("parse_model", exc=exc)
        raise RiceValidationError(
            f"invalid data for {model_cls.__name__}",
            details={"model": model_cls.__name__, "errors": exc.errors()},
        ) from exc


def parse_json(model_cls: type[TModel], raw: str | bytes | bytearray) -> TModel:
    """`model_validate_json` z opakowaniem błędów."""
    try:
        return model_cls.model_validate_json(raw)
    except PydanticValidationError as exc:
        _log_conversion_failure("parse_json", exc=exc)
        raise RiceValidationError(
            f"invalid json for {model_cls.__name__}",
            details={"model": model_cls.__name__, "errors": exc.errors()},
        ) from exc


def coerce_json(obj: Any) -> Any:
    """`json.loads` dla str/bytes; inne zwraca bez zmian."""
    try:
        if isinstance(obj, (bytes, bytearray)):
            return json.loads(bytes(obj))
        if isinstance(obj, str):
            return json.loads(obj)
    except json.JSONDecodeError as exc:
        _log_conversion_failure("coerce_json", exc=exc)
        raise RiceValidationError("invalid json document", details={"stage": "coerce_json"}) from exc
    return obj


def adapt_validate[T](adapter: TypeAdapter[T], value: Any) -> T:
    """Walidacja przez `TypeAdapter` (np. `list[Model]`, `Union`)."""
    try:
        return adapter.validate_python(value)
    except PydanticValidationError as exc:
        _log_conversion_failure("adapt_validate", exc=exc)
        raise RiceValidationError(
            "type adapter validation failed",
            details={"errors": exc.errors()},
        ) from exc


def merge_dicts(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    """Płytka kopia: `base` nadpisane kluczami z `override`."""
    out = dict(base)
    out.update(override)
    return out


def numpy_to_list(obj: Any) -> Any:
    """Skalary `np.generic` i tablice `ndarray` (float16/32, complex128, …) → typy Pythona.

    Dla `ndim>0` używa `tolist()` (jedna alokacja listy — wymagana do JSON/MsgPack).
    """
    if isinstance(obj, np.generic):
        return obj.item()
    if isinstance(obj, np.ndarray):
        if obj.ndim == 0:
            return obj.item()
        return obj.tolist()
    return obj


def to_msgpack(obj: Any) -> bytes:
    """MsgPack bytes (`use_bin_type=True`, obsługa `datetime` / NumPy przez `default`)."""
    try:
        return msgpack.packb(obj, default=_msgpack_default, use_bin_type=True, strict_types=False)
    except (TypeError, ValueError, OverflowError) as exc:
        _log_conversion_failure("to_msgpack", exc=exc, binary=True)
        raise RiceValidationError("msgpack encode failed", details={"stage": "to_msgpack"}) from exc


def from_msgpack(raw: bytes | bytearray) -> Any:
    """Dekodowanie MsgPack (`strict_map_key=True`)."""
    try:
        return msgpack.unpackb(bytes(raw), raw=False, strict_map_key=True)
    except (msgpack.exceptions.UnpackException, ValueError, TypeError, UnicodeDecodeError) as exc:
        _log_conversion_failure("from_msgpack", exc=exc, binary=True)
        raise RiceValidationError("msgpack decode failed", details={"stage": "from_msgpack"}) from exc


def to_nats_json_bytes(obj: Any) -> bytes:
    """JSON UTF-8 z ISO-8601 UTC dla `datetime` / `date` i obsługą NumPy."""
    try:
        return json.dumps(obj, default=_json_default, separators=(",", ":")).encode("utf-8")
    except (TypeError, ValueError) as exc:
        _log_conversion_failure("to_nats_json_bytes", exc=exc)
        raise RiceValidationError("json encode failed", details={"stage": "nats_json"}) from exc


def encode_nats_payload(obj: Any) -> bytes:
    """Ładunek NATS: MsgPack lub JSON wg `settings.nats_serializer` (`RICE_NATS_SERIALIZER`)."""
    if get_settings().nats_serializer == "msgpack":
        return to_msgpack(obj)
    return to_nats_json_bytes(obj)


def decode_nats_payload(raw: bytes | bytearray) -> Any:
    """Odwrotność `encode_nats_payload` wg bieżącego `settings.nats_serializer`."""
    if get_settings().nats_serializer == "msgpack":
        return from_msgpack(raw)
    try:
        return json.loads(bytes(raw))
    except json.JSONDecodeError as exc:
        _log_conversion_failure("decode_nats_payload", exc=exc, binary=True)
        raise RiceValidationError("json decode failed", details={"stage": "nats_json"}) from exc


def to_base64(data: bytes | bytearray) -> str:
    """ASCII Base64 (bez nowych linii) do osadzania binariów w tekście."""
    return base64.b64encode(bytes(data)).decode("ascii")


def from_base64(text: str) -> bytes:
    """Dekodowanie Base64 — błędy alfabetu → `RiceValidationError`."""
    try:
        return base64.b64decode(text.encode("ascii"), validate=True)
    except (binascii.Error, ValueError) as exc:
        _log_conversion_failure("from_base64", exc=exc, binary=True)
        raise RiceValidationError("invalid base64 payload", details={"stage": "from_base64"}) from exc


def arrow_table_to_numpy(table: Any) -> dict[str, np.ndarray]:
    """`pyarrow.Table` → `dict[str, np.ndarray]` dla mostu Python ↔ Mojo (`job/bridge.py`).

    Kolumny są scalane (`combine_chunks`) przed `to_numpy` tam, gdzie to konieczne.
    """
    try:
        import pyarrow as pa
    except ImportError as exc:
        raise RiceValidationError(
            "pyarrow is required for arrow_table_to_numpy",
            details={"stage": "arrow_to_numpy"},
        ) from exc
    if not isinstance(table, pa.Table):
        raise RiceValidationError(
            "expected pyarrow.Table",
            details={"stage": "arrow_to_numpy", "got": type(table).__name__},
        )
    out: dict[str, np.ndarray] = {}
    for name in table.column_names:
        col = table.column(name)
        if isinstance(col, pa.ChunkedArray):
            col = col.combine_chunks()
        out[name] = col.to_numpy(zero_copy_only=False)
    return out


__all__ = [
    "adapt_validate",
    "arrow_table_to_numpy",
    "coerce_json",
    "decode_nats_payload",
    "encode_nats_payload",
    "from_base64",
    "from_msgpack",
    "merge_dicts",
    "model_to_dict",
    "model_to_json",
    "numpy_to_list",
    "parse_json",
    "parse_model",
    "to_base64",
    "to_msgpack",
    "to_nats_json_bytes",
]
