"""Hierarchia wyjątków `.rice`, modele Pydantic, logi (loguru) i OTel."""

from __future__ import annotations

from typing import Any, ClassVar, Literal, TypedDict, cast

from pydantic import Field, ValidationError as PydanticValidationError, field_validator

from . import const
from .schema import SchemaBase

ErrorKind = Literal["client", "server", "validation"]


def qualify_error_code(code: str) -> str:
    """Normalizuje kod: UPPER_SNAKE + jednorazowy prefiks `const.ERROR_CODE_PREFIX`."""
    prefix = const.ERROR_CODE_PREFIX
    s = str(code).strip().upper().replace(" ", "_").replace("-", "_")
    if not s:
        s = "UNKNOWN"
    if s.startswith(prefix):
        return s
    return f"{prefix}{s}"


def record_error_on_current_span(exc: BaseException) -> None:
    """Zapisuje wyjątek na aktywnym spanie OTel (`record_exception`); brak SDK = no-op."""
    try:
        from opentelemetry import trace

        span = trace.get_current_span()
        if span is not None and span.is_recording():
            span.record_exception(exc)
    except ImportError:
        return


class ErrorDetail(SchemaBase):
    """Pojedynczy wpis walidacji / kontekstu (kompatybilny z `SchemaBase`)."""

    loc: tuple[str | int, ...] = Field(default_factory=tuple)
    msg: str
    type: str


class StructuredError(SchemaBase):
    """Jednolity błąd API / warstwy domenowej."""

    code: str
    message: str
    kind: ErrorKind = "server"
    details: dict[str, Any] = Field(default_factory=dict)
    errors: list[ErrorDetail] = Field(default_factory=list)

    @field_validator("code", mode="before")
    @classmethod
    def _normalize_code(cls, v: Any) -> str:
        if not isinstance(v, str):
            msg = "error code must be a string"
            raise TypeError(msg)
        return qualify_error_code(v)


class StructuredErrorHttpPayload(TypedDict):
    """Bezpieczny kształt JSON dla klientów (bez tracebacków)."""

    code: str
    message: str
    kind: str
    details: dict[str, Any]
    errors: list[dict[str, Any]]


class RiceError(Exception):
    """Bazowy błąd domenowy `.rice` / SAGE."""

    _default_error_code: ClassVar[str] = "INTERNAL_ERROR"
    _default_kind: ClassVar[ErrorKind] = "server"

    __slots__ = ("_message", "_error_code", "_details")

    def __init__(
        self,
        message: str,
        *,
        error_code: str | None = None,
        details: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(message)
        self._message = str(message)
        code = error_code if error_code is not None else self._default_error_code
        self._error_code = qualify_error_code(code)
        self._details = dict(details) if details else {}

    @property
    def message(self) -> str:
        return self._message

    @property
    def error_code(self) -> str:
        return self._error_code

    @property
    def details(self) -> dict[str, Any]:
        return dict(self._details)

    def to_structured(self, *, kind: ErrorKind | None = None) -> StructuredError:
        """Fabryka: `RiceError` → `StructuredError` (kody znormalizowane, brak stacku)."""
        return StructuredError(
            code=self._error_code,
            message=self._message,
            kind=kind if kind is not None else self._default_kind,
            details=dict(self._details),
            errors=[],
        )


class ModelError(RiceError):
    """Błąd modelu / inferencji LLM."""

    _default_error_code = "MODEL_ERROR"


class ValidationError(RiceError):
    """Błąd walidacji wyjścia / kontraktu (nie mylić z `pydantic.ValidationError`)."""

    _default_error_code = "VALIDATION_FAILED"
    _default_kind: ClassVar[ErrorKind] = "validation"


class MaxRetriesExceeded(RiceError):
    """Wyczerpany limit ponów (np. tenacity)."""

    _default_error_code = "MAX_RETRIES_EXCEEDED"


class CircuitOpenError(RiceError):
    """Circuit breaker w stanie OPEN."""

    _default_error_code = "CIRCUIT_OPEN"


class ContextLimitError(RiceError):
    """Przekroczony limit kontekstu (okno tokenów)."""

    _default_error_code = "CONTEXT_WINDOW_EXCEEDED"


class GuardError(RiceError):
    """Naruszenie guardrails."""

    _default_error_code = "GUARD_REJECTED"
    _default_kind: ClassVar[ErrorKind] = "validation"


class StorageError(RiceError):
    """Błąd magazynu (Qdrant, checkpoint, blob)."""

    _default_error_code = "STORAGE_ERROR"


class StreamError(RiceError):
    """Przerwany lub uszkodzony strumień odpowiedzi."""

    _default_error_code = "STREAM_ERROR"


def _sanitize_details(details: dict[str, Any]) -> dict[str, Any]:
    blocked = frozenset({"traceback", "stack", "__traceback__", "exc_info", "tb"})
    out: dict[str, Any] = {}
    for k, v in details.items():
        ks = str(k).lower()
        if ks.startswith("_") or ks in blocked:
            continue
        out[str(k)] = v
    return out


def _structured_from_pydantic_validation(exc: PydanticValidationError) -> StructuredError:
    errors: list[ErrorDetail] = []
    for item in exc.errors():
        loc_raw = item.get("loc", ())
        loc = tuple(str(x) if not isinstance(x, (str, int)) else x for x in loc_raw)
        errors.append(
            ErrorDetail(
                loc=loc,
                msg=str(item.get("msg", "validation error")),
                type=str(item.get("type", "value_error")),
            )
        )
    return StructuredError(
        code=qualify_error_code("VALIDATION_ERROR"),
        message="Request validation failed",
        kind="validation",
        details=_sanitize_details({"type": "PydanticValidationError"}),
        errors=errors,
    )


def structured_error_from_exception(
    exc: BaseException,
    *,
    code: str | None = None,
    kind: ErrorKind | None = None,
    record_span: bool = True,
) -> StructuredError:
    """Mapuje wyjątek na `StructuredError`; opcjonalnie `span.record_exception` (OTel)."""
    if record_span:
        record_error_on_current_span(exc)

    if isinstance(exc, RiceError):
        structured = exc.to_structured(kind=kind)
        if code is not None:
            structured = structured.model_copy(update={"code": qualify_error_code(code)})
        return structured

    if isinstance(exc, PydanticValidationError):
        return _structured_from_pydantic_validation(exc)

    resolved_code = qualify_error_code(code if code is not None else "INTERNAL_ERROR")
    resolved_kind: ErrorKind = kind if kind is not None else "server"

    return StructuredError(
        code=resolved_code,
        message=str(exc),
        kind=resolved_kind,
        details=_sanitize_details({"type": type(exc).__name__}),
        errors=[],
    )


def log_structured_error(
    err: StructuredError,
    *,
    exc_info: bool = False,
    source_exc: BaseException | None = None,
) -> None:
    """Loguje przez loguru z `extra`: `error_code`, `kind` (+ opcjonalny OTel z `source_exc`)."""
    from loguru import logger

    if source_exc is not None:
        record_error_on_current_span(source_exc)

    logger.bind(error_code=err.code, kind=err.kind).error(
        "{}",
        err.message,
        exc_info=exc_info,
    )


def to_http_payload(err: StructuredError) -> StructuredErrorHttpPayload:
    """Ładunek JSON dla HTTP — wyłącznie pola modelu, oczyszczone `details` (bez stacków)."""
    raw = err.model_dump(mode="json")
    details = raw.get("details")
    if not isinstance(details, dict):
        details = {}
    raw["details"] = _sanitize_details(details)
    return cast(StructuredErrorHttpPayload, raw)


__all__ = [
    "CircuitOpenError",
    "ContextLimitError",
    "ErrorDetail",
    "GuardError",
    "MaxRetriesExceeded",
    "ModelError",
    "RiceError",
    "StorageError",
    "StreamError",
    "StructuredError",
    "StructuredErrorHttpPayload",
    "ValidationError",
    "log_structured_error",
    "qualify_error_code",
    "record_error_on_current_span",
    "structured_error_from_exception",
    "to_http_payload",
]
