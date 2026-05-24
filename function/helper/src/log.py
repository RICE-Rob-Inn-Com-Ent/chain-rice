"""Loguru — konfiguracja stderr, JSON (prod), tekst (dev), OTel, maskowanie, sampling DEBUG."""

from __future__ import annotations

import random
import sys
from typing import Any

from loguru import logger

from .const import DATETIME_FORMAT, ENCODING, LOGURU_BACKTRACE, LOGURU_DIAGNOSE
from .settings import get_settings

_CONFIGURED = False

# Jawny eksport: ten sam UTF-8 co `env_file_encoding` w ustawieniach (pliki obok logów).
LOG_LINE_ENCODING: str = ENCODING

_LOGURU_DEBUG_LEVEL_NO: int = 10


def _log_use_json(settings: Any) -> bool:
    return settings.log_format == "json" or bool(settings.log_json)


def _extra_key_should_mask(key: str, tokens: tuple[str, ...]) -> bool:
    kl = key.lower()
    return any(tok in kl for tok in tokens)


def _mask_sensitive_extra(record: dict[str, Any], tokens: tuple[str, ...]) -> None:
    if not tokens:
        return
    extra = record.get("extra")
    if not isinstance(extra, dict):
        return
    for key in list(extra):
        if _extra_key_should_mask(str(key), tokens):
            extra[key] = "***"


def _make_debug_sample_filter(sample_rate: float) -> Any:
    """Zwraca filtr loguru: odrzuca część rekordów DEBUG wg `sample_rate` (0..1)."""

    def _filter(record: dict[str, Any]) -> bool:
        try:
            level_no = int(record["level"].no)
        except (KeyError, TypeError, ValueError):
            return True
        if level_no != _LOGURU_DEBUG_LEVEL_NO:
            return True
        if sample_rate >= 1.0:
            return True
        if sample_rate <= 0.0:
            return False
        return random.random() < sample_rate

    return _filter


def _make_combined_filter(sample_rate: float, mask_tokens: tuple[str, ...]) -> Any:
    sample_filter = _make_debug_sample_filter(sample_rate)

    def _filter(record: dict[str, Any]) -> bool:
        if not sample_filter(record):
            return False
        _mask_sensitive_extra(record, mask_tokens)
        return True

    return _filter


def _make_core_patcher(default_role: str) -> Any:
    """Wstrzykuje `role`, `trace_id`, `span_id` do `extra` (OTel w czasie emisji)."""

    def _patcher(record: dict[str, Any]) -> None:
        extra = record.setdefault("extra", {})
        if not isinstance(extra, dict):
            return
        extra.setdefault("role", default_role)
        try:
            from opentelemetry import trace

            span = trace.get_current_span()
            sc = span.get_span_context() if span is not None else None
            if sc is not None and getattr(sc, "is_valid", False):
                extra["trace_id"] = f"{sc.trace_id:032x}"
                extra["span_id"] = f"{sc.span_id:016x}"
            else:
                extra.setdefault("trace_id", "-")
                extra.setdefault("span_id", "-")
        except ImportError:
            extra.setdefault("trace_id", "-")
            extra.setdefault("span_id", "-")

    return _patcher


def configure_logging(
    *,
    level: str | None = None,
    sample_rate: float | None = None,
    diagnose: bool | None = None,
) -> None:
    """Idempotentna konfiguracja: jeden sink `stderr`, filtr (sampling + maski), patcher OTel/role."""
    global _CONFIGURED  # noqa: PLW0603
    if _CONFIGURED:
        return

    settings = get_settings()
    eff_level = level if level is not None else settings.log_level
    eff_sample = float(sample_rate if sample_rate is not None else settings.log_debug_sample_rate)
    eff_diagnose = LOGURU_DIAGNOSE if diagnose is None else diagnose
    use_json = _log_use_json(settings)
    mask_tokens = settings.log_mask_tokens
    text_fmt = (
        f"<green>{{time:{DATETIME_FORMAT}}}</green> | "
        "<level>{level: <8}</level> | "
        "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
        "<level>{message}</level>"
    )

    logger.remove()
    logger.configure(patcher=_make_core_patcher(settings.log_role))

    combined_filter = _make_combined_filter(eff_sample, mask_tokens)

    if use_json:
        logger.add(
            sys.stderr,
            level=eff_level,
            serialize=True,
            diagnose=eff_diagnose,
            filter=combined_filter,
            colorize=False,
            catch=True,
            enqueue=False,
            backtrace=LOGURU_BACKTRACE,
        )
    else:
        logger.add(
            sys.stderr,
            level=eff_level,
            format=text_fmt,
            diagnose=eff_diagnose,
            filter=combined_filter,
            colorize=True,
            catch=True,
            enqueue=False,
            backtrace=LOGURU_BACKTRACE,
        )

    _CONFIGURED = True


def get_logger() -> Any:
    """Globalny logger Loguru (wywołaj `configure_logging()` przy starcie procesu)."""
    return logger


def bind_context(**kwargs: Any) -> Any:
    """`logger.bind` — pola w `extra` dla całego zakresu."""
    return logger.bind(**kwargs)


def bind_trace_context() -> Any:
    """Dokleja `role` z ustawień oraz `trace_id` / `span_id` z OTel (bez twardej zależności)."""
    settings = get_settings()
    bound = logger.bind(role=settings.log_role)
    try:
        from opentelemetry import trace

        span = trace.get_current_span()
        sc = span.get_span_context() if span is not None else None
        if sc is not None and getattr(sc, "is_valid", False):
            return bound.bind(
                trace_id=f"{sc.trace_id:032x}",
                span_id=f"{sc.span_id:016x}",
            )
    except ImportError:
        pass
    return bound


def otel_log_record_exporter_hook() -> None:
    """Rezerwa pod eksport logów do OTel (włącz `opentelemetry-sdk` + LoggingHandler)."""
    return None
