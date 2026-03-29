"""Tenacity — dekoratory retry, strategie oczekiwania, stop, callbacki."""

from __future__ import annotations

from collections.abc import Callable
from typing import ParamSpec, TypeVar

from tenacity import (
    RetryCallState,
    retry,
    retry_if_exception,
    retry_if_exception_type,
    stop_after_attempt,
    stop_after_delay,
    wait_chain,
    wait_exponential,
    wait_fixed,
    wait_random_exponential,
)

P = ParamSpec("P")
T = TypeVar("T")

# TODO:
# [ ] implement tenacity retry factory:
# [ ]     make_retry(max_attempts, min_wait, max_wait, exceptions) → Retrying
# [ ]     all params from settings.py — no hardcoded values
# [ ] implement async retry decorator: @async_retry wraps async functions
# [ ] implement retry with fallback: on final failure → call fallback function
# [ ] implement retry metrics: count retries per function via OTel counter
# [ ]     metric: sage.retry.attempts, labels: function, exception_type
# [ ] implement jitter: add random jitter to wait times
# [ ]     jitter range from RICE_RETRY_JITTER_S env var


def log_retry_state(retry_state: RetryCallState) -> None:
    """Callback `before_sleep` — loguje próbę (podłącz loguru w aplikacji)."""
    from loguru import logger

    exc = retry_state.outcome.exception() if retry_state.outcome else None
    logger.warning(
        "retry attempt={} next_wait={} exc={}",
        retry_state.attempt_number,
        retry_state.next_action.sleep
        if retry_state.next_action and hasattr(retry_state.next_action, "sleep")
        else None,
        exc,
    )


def retry_transient_io(
    *,
    max_attempts: int = 4,
    min_s: float = 0.5,
    max_s: float = 8.0,
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Błędy IO / sieci — wykładniczy backoff + limit prób."""
    return retry(
        stop=stop_after_attempt(max_attempts),
        wait=wait_exponential(multiplier=1, min=min_s, max=max_s),
        retry=retry_if_exception_type((OSError, TimeoutError, ConnectionError)),
        reraise=True,
        before_sleep=log_retry_state,
    )


def retry_idempotent(
    *,
    max_attempts: int = 3,
    wait_s: float = 1.0,
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Stały odstęp między próbami (np. rate limit)."""
    return retry(
        stop=stop_after_attempt(max_attempts),
        wait=wait_fixed(wait_s),
        reraise=True,
    )


def retry_with_jitter(
    *,
    max_attempts: int = 5,
    multiplier: float = 1.0,
    min_s: float = 1.0,
    max_s: float = 60.0,
) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Losowy wykładniczy jitter (kolizje klientów)."""
    return retry(
        stop=stop_after_attempt(max_attempts),
        wait=wait_random_exponential(multiplier=multiplier, min=min_s, max=max_s),
        reraise=True,
    )


def retry_chain_example() -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Przykład `wait_chain`: krótkie próby, potem dłuższe."""
    return retry(
        stop=stop_after_attempt(6),
        wait=wait_chain(wait_fixed(1), wait_fixed(2), wait_exponential(min=4, max=30)),
        reraise=True,
    )


def retry_if_message_contains(substr: str) -> Callable[[Callable[P, T]], Callable[P, T]]:
    """Retry tylko gdy `str(exc)` zawiera fragment (np. \"Rate limit\")."""

    def _pred(exc: BaseException) -> bool:
        return substr.lower() in str(exc).lower()

    return retry(
        stop=stop_after_attempt(5),
        wait=wait_exponential(multiplier=1, min=1, max=20),
        retry=retry_if_exception(_pred),
        reraise=True,
    )


def stop_after_elapsed(seconds: float) -> object:
    """Limit łącznego czasu retry (sekundy)."""
    return stop_after_delay(seconds)
