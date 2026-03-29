"""Modele błędów (Pydantic) + integracja z loguru — strukturalne zgłaszanie."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, Field
from typing_extensions import Literal

from .schema import SchemaBase

# TODO:
# [ ] define SAGE exception hierarchy:
# [ ]     RiceError(Exception) — base
# [ ]     ModelError(RiceError) — LLM call failures
# [ ]     ValidationError(RiceError) — output validation failures
# [ ]     MaxRetriesExceeded(RiceError) — retry limit hit
# [ ]     CircuitOpenError(RiceError) — circuit breaker open
# [ ]     ContextLimitError(RiceError) — context window exceeded
# [ ]     GuardError(RiceError) — guardrails validation failed
# [ ]     StorageError(RiceError) — Qdrant/checkpointer failures
# [ ]     StreamError(RiceError) — streaming interrupted
# [ ] add error codes: soft-coded constants, not hardcoded integers
# [ ]     RICE_ERROR_PREFIX env var (default: "SAGE")
# [ ] add OTel error recording: every exception → record_exception(span)
# [ ] add NATS error publishing:
# [ ]     on RiceError → publish to NATS subject errors.sage.{error_type}
# [ ]     SMITH guard/ subscribes and alerts


class ErrorDetail(SchemaBase):
    """Pojedynczy wpis walidacji / kontekstu."""

    loc: tuple[str | int, ...] = Field(default_factory=tuple)
    msg: str
    type: str


class StructuredError(SchemaBase):
    """Jednolity błąd API / warstwy domenowej."""

    code: str
    message: str
    kind: Literal["client", "server", "validation"] = "server"
    details: dict[str, Any] = Field(default_factory=dict)
    errors: list[ErrorDetail] = Field(default_factory=list)


def structured_error_from_exception(
    exc: BaseException,
    *,
    code: str = "internal_error",
    kind: Literal["client", "server", "validation"] = "server",
) -> StructuredError:
    """Mapuje wyjątek na `StructuredError` (bez wycieku stacku do klienta)."""
    return StructuredError(
        code=code,
        message=str(exc),
        kind=kind,
        details={"type": type(exc).__name__},
    )


def log_structured_error(
    err: StructuredError,
    *,
    exc_info: bool = False,
) -> None:
    """Zapisuje błąd przez loguru z polami `error_code` / `kind`."""
    from loguru import logger

    logger.bind(error_code=err.code, kind=err.kind).error(
        "{}",
        err.message,
        exc_info=exc_info,
    )


def to_http_payload(err: StructuredError) -> dict[str, Any]:
    """Payload do JSON odpowiedzi (bez sekretów)."""
    return err.model_dump(mode="json")
