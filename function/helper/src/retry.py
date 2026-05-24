"""Tenacity — strategie retry dla IO, wektorów, agentów i symulacji (sync + async)."""

from __future__ import annotations

import threading
import urllib.error
from collections.abc import Callable
from typing import Any, ParamSpec, TypeVar

from tenacity import (
    RetryCallState,
    retry,
    retry_any,
    retry_if_exception,
    stop_after_attempt,
    stop_after_delay,
    wait_chain,
    wait_exponential,
    wait_fixed,
    wait_random_exponential,
)

from .const import MAX_RETRY_ATTEMPTS, RETRY_BACKOFF_MAX, RETRY_BACKOFF_MIN
from .error import (
    CircuitOpenError,
    ContextLimitError,
    GuardError,
    ModelError,
    RiceError,
    StorageError,
    StreamError,
    ValidationError,
)
from .log import get_logger
from .settings import get_settings

P = ParamSpec("P")
T = TypeVar("T")

_OTEL_LOCK = threading.Lock()
_otel_retry_counter: Any | None | bool = None


def _fn_qualname(retry_state: RetryCallState) -> str:
    fn = retry_state.fn
    if fn is None:
        return "unknown"
    return getattr(fn, "__qualname__", None) or getattr(fn, "__name__", "unknown")


def _get_otel_retry_counter() -> Any | None:
    """Lazy `Counter` OTel; `None` gdy brak SDK / metryk."""
    global _otel_retry_counter
    with _OTEL_LOCK:
        if _otel_retry_counter is None:
            try:
                from opentelemetry import metrics

                meter = metrics.get_meter("rice.helper.retry")
                _otel_retry_counter = meter.create_counter(
                    "rice.helper.retry.before_sleep",
                    unit="1",
                    description="Liczba zaplanowanych uśpień między próbami (per funkcja i typ wyjątku).",
                )
            except ImportError:
                _otel_retry_counter = False
    if _otel_retry_counter is False:
        return None
    return _otel_retry_counter


def _otel_record_retry_attempt(retry_state: RetryCallState) -> None:
    counter = _get_otel_retry_counter()
    if counter is None:
        return
    exc_name = "none"
    if retry_state.outcome is not None and retry_state.outcome.failed:
        exc = retry_state.outcome.exception()
        if exc is not None:
            exc_name = type(exc).__name__
    counter.add(1, {"function": _fn_qualname(retry_state), "exception_type": exc_name})


def is_transient_io_failure(exc: BaseException) -> bool:
    """True dla błędów sieci / dysku oraz `StorageError` (Qdrant, checkpoint)."""
    if isinstance(exc, StorageError):
        return True
    if isinstance(exc, (TimeoutError, ConnectionError, BrokenPipeError, BlockingIOError, OSError)):
        return True
    if isinstance(exc, urllib.error.HTTPError):
        return exc.code in {408, 409, 425, 429, 500, 502, 503, 504}
    return isinstance(exc, urllib.error.URLError)


def should_retry_default_rice_error(exc: BaseException) -> bool:
    """Domyślna polityka `RiceError`: ponów m.in. `ModelError` / `StreamError`, nie `ValidationError`."""
    if not isinstance(exc, RiceError):
        return False
    if isinstance(exc, (ValidationError, GuardError, CircuitOpenError, ContextLimitError)):
        return False
    return isinstance(exc, (ModelError, StorageError, StreamError))


def log_retry_state(retry_state: RetryCallState) -> None:
    """Callback `before_sleep` — próba, oczekiwanie, wyjątek (loguru z `get_logger`)."""
    log = get_logger()
    exc = retry_state.outcome.exception() if retry_state.outcome else None
    wait_s: float | None = None
    if retry_state.next_action is not None:
        wait_s = float(retry_state.next_action.sleep)
    elif retry_state.upcoming_sleep:
        wait_s = float(retry_state.upcoming_sleep)
    log.bind(
        retry_attempt=retry_state.attempt_number,
        retry_next_wait_s=wait_s,
        retry_fn=_fn_qualname(retry_state),
    ).warning(
        "retry sleep | attempt={} | next_wait_s={} | fn={} | exc_type={} | exc={}",
        retry_state.attempt_number,
        wait_s,
        _fn_qualname(retry_state),
        type(exc).__name__ if exc is not None else "none",
        exc,
    )


def before_sleep_log_and_metrics(retry_state: RetryCallState) -> None:
    """Łączy log + metrykę OTel przed uśpieniem (sync; tenacity obsłuży async wrap)."""
    log_retry_state(retry_state)
    _otel_record_retry_attempt(retry_state)


def _coerce_max_attempts(n: int | None) -> int:
    """Górny limit prób spójny z `HelperSettings` i `const.MAX_RETRY_ATTEMPTS`."""
    if n is None:
        return get_settings().infra_retry_max_attempts
    v = int(n)
    return max(1, min(v, max(MAX_RETRY_ATTEMPTS, 64)))


def retry_transient_io(
    *,
    max_attempts: int | None = None,
    min_s: float | None = None,
    max_s: float | None = None,
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Sieć / dysk / `StorageError` — backoff wykładniczy; domyślnie z `settings` (+ aliasy `const`)."""
    s = get_settings()
    attempts = _coerce_max_attempts(max_attempts)
    lo = float(min_s if min_s is not None else max(s.retry_exponential_min_s, RETRY_BACKOFF_MIN))
    hi = float(max_s if max_s is not None else max(s.retry_exponential_max_s, RETRY_BACKOFF_MAX))
    if lo > hi:
        lo, hi = hi, lo
    return retry(
        stop=stop_after_attempt(attempts),
        wait=wait_exponential(multiplier=1, min=lo, max=hi),
        retry=retry_if_exception(is_transient_io_failure),
        reraise=True,
        before_sleep=before_sleep_log_and_metrics,
    )


def retry_transient_agent(
    *,
    max_attempts: int | None = None,
    min_s: float | None = None,
    max_s: float | None = None,
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Agent LLM: `ModelError` lub typowe błędy IO / magazynu (`retry_any`)."""
    s = get_settings()
    attempts = _coerce_max_attempts(max_attempts)
    lo = float(min_s if min_s is not None else max(s.retry_exponential_min_s, RETRY_BACKOFF_MIN))
    hi = float(max_s if max_s is not None else max(s.retry_exponential_max_s, RETRY_BACKOFF_MAX))
    if lo > hi:
        lo, hi = hi, lo
    return retry(
        stop=stop_after_attempt(attempts),
        wait=wait_exponential(multiplier=1, min=lo, max=hi),
        retry=retry_any(
            retry_if_exception(is_transient_io_failure),
            retry_if_exception(should_retry_default_rice_error),
        ),
        reraise=True,
        before_sleep=before_sleep_log_and_metrics,
    )


def retry_idempotent(
    *,
    max_attempts: int | None = None,
    wait_s: float | None = None,
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Stały odstęp (np. rate limit); domyślnie z `settings`."""
    s = get_settings()
    attempts = max_attempts if max_attempts is not None else s.retry_idempotent_max_attempts
    w = float(wait_s if wait_s is not None else s.retry_idempotent_wait_s)
    return retry(
        stop=stop_after_attempt(max(1, attempts)),
        wait=wait_fixed(w),
        reraise=True,
        before_sleep=before_sleep_log_and_metrics,
    )


def retry_with_jitter(
    *,
    max_attempts: int | None = None,
    multiplier: float | None = None,
    min_s: float | None = None,
    max_s: float | None = None,
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Jitter wykładniczy (kolizje Qdrant / burst); `wait_random_exponential`."""
    s = get_settings()
    attempts = max_attempts if max_attempts is not None else s.retry_jitter_max_attempts
    mult = float(multiplier if multiplier is not None else s.retry_jitter_multiplier)
    lo = float(min_s if min_s is not None else s.retry_jitter_min_s)
    hi = float(max_s if max_s is not None else s.retry_jitter_max_s)
    if lo > hi:
        lo, hi = hi, lo
    return retry(
        stop=stop_after_attempt(max(1, attempts)),
        wait=wait_random_exponential(multiplier=mult, min=lo, max=hi),
        reraise=True,
        before_sleep=before_sleep_log_and_metrics,
    )


def retry_chain_example() -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Łańcuch `wait_chain` — krótkie próby, potem wykładniczy (wartości z `settings`)."""
    s = get_settings()
    cap = min(30.0, float(s.retry_exponential_max_s))
    return retry(
        stop=stop_after_attempt(min(6, max(1, s.infra_retry_max_attempts))),
        wait=wait_chain(
            wait_fixed(1.0),
            wait_fixed(2.0),
            wait_exponential(min=float(s.retry_exponential_min_s), max=cap),
        ),
        reraise=True,
        before_sleep=before_sleep_log_and_metrics,
    )


def retry_if_message_contains(substr: str) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Retry, gdy komunikat wyjątku zawiera `substr` (bez rozróżniania wielkości liter)."""
    needle = substr.strip().lower()

    def _pred(exc: BaseException) -> bool:
        if not needle:
            return False
        return needle in str(exc).lower()

    s = get_settings()
    return retry(
        stop=stop_after_attempt(max(1, s.retry_message_match_max_attempts)),
        wait=wait_exponential(
            multiplier=1,
            min=float(s.retry_message_min_s),
            max=float(s.retry_message_max_s),
        ),
        retry=retry_if_exception(_pred),
        reraise=True,
        before_sleep=before_sleep_log_and_metrics,
    )


def stop_after_elapsed(seconds: float) -> object:
    """Limit łącznego czasu retry (sekundy)."""
    return stop_after_delay(seconds)


__all__ = [
    "before_sleep_log_and_metrics",
    "is_transient_io_failure",
    "log_retry_state",
    "retry_chain_example",
    "retry_idempotent",
    "retry_if_message_contains",
    "retry_transient_agent",
    "retry_transient_io",
    "retry_with_jitter",
    "should_retry_default_rice_error",
    "stop_after_elapsed",
]
