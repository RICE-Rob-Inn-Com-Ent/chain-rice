"""Loguru — konfiguracja loggera, sinki, format, OTel (opcjonalnie), kontekst."""

from __future__ import annotations

import sys
from typing import Any

from loguru import logger

_CONFIGURED = False

# TODO:
# [ ] configure loguru with structured JSON output:
# [ ]     format: {time:ISO8601} {level} {name} {function} {line} {message} {extra}
# [ ]     serialize=True when RICE_LOG_FORMAT=json (default in Docker)
# [ ]     colorize=True when RICE_LOG_FORMAT=text (default in dev)
# [ ] set log level from RICE_SAGE_LOG_LEVEL env var
# [ ] add OTel log bridge: emit loguru records as OTel log events
# [ ]     OTEL_EXPORTER_OTLP_ENDPOINT from env
# [ ] add request context: inject trace_id, span_id into every log record
# [ ]     via loguru contextvars integration
# [ ] add role context: inject RICE_ROLE into every log record
# [ ] implement log sampling: sample DEBUG logs at RICE_LOG_SAMPLE_RATE (default: 0.1)
# [ ]     always emit ERROR and above
# [ ] implement sensitive data masking:
# [ ]     mask fields matching RICE_LOG_MASK_FIELDS (comma-separated list from env)
# [ ]     default mask: api_key, password, token, secret


def configure_logging(
    *,
    level: str = "INFO",
    json_sink: bool = False,
    diagnose: bool = False,
) -> None:
    """Idempotentna konfiguracja: jeden handler stderr, opcjonalnie JSON."""
    global _CONFIGURED  # noqa: PLW0603 — celowy singleton konfiguracji
    if _CONFIGURED:
        return
    logger.remove()
    fmt = (
        "<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | "
        "<level>{level: <8}</level> | "
        "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
        "<level>{message}</level>"
    )
    if json_sink:
        logger.add(sys.stderr, level=level, serialize=True, diagnose=diagnose)
    else:
        logger.add(sys.stderr, level=level, format=fmt, diagnose=diagnose)
    _CONFIGURED = True


def bind_context(**kwargs: Any) -> Any:
    """`logger.bind` — pola dodawane do każdej linii w zakresie."""
    return logger.bind(**kwargs)


def bind_trace_context() -> Any:
    """Jeśli zainstalowane jest OpenTelemetry, dokleja trace_id/span_id do logów."""
    try:
        from opentelemetry import trace

        span = trace.get_current_span()
        sc = span.get_span_context() if span is not None else None
        if sc is not None and getattr(sc, "is_valid", False):
            return logger.bind(
                trace_id=f"{sc.trace_id:032x}",
                span_id=f"{sc.span_id:016x}",
            )
    except ImportError:
        pass
    return logger


def otel_log_record_exporter_hook() -> None:
    """Rezerwa pod eksport logów do OTel (włącz `opentelemetry-sdk` + LoggingHandler)."""
    # Implementacja zależna od stacku SMITH/OTel — tu tylko punkt zaczepienia.
    return None
