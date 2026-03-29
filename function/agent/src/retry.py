"""LiteLLM + tenacity — retry, łańcuchy fallback, prosty circuit breaker."""

from __future__ import annotations

import time
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from typing import ParamSpec, TypeVar

from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

P = ParamSpec("P")
T = TypeVar("T")

# TODO:
# [ ] implement tenacity retry decorator for LLM calls:
# [ ]     stop: stop_after_attempt(RICE_SAGE_MAX_RETRIES)
# [ ]     wait: wait_exponential(multiplier=1, min=1, max=RICE_RETRY_MAX_WAIT_S)
# [ ]     retry on: RateLimitError, APIConnectionError, APITimeoutError
# [ ]     before_sleep: log retry attempt to loguru + OTel
# [ ] implement circuit breaker pattern:
# [ ]     open circuit after RICE_CIRCUIT_BREAKER_FAILURES consecutive failures
# [ ]     half-open after RICE_CIRCUIT_BREAKER_TIMEOUT_S seconds
# [ ]     closed when request succeeds in half-open state
# [ ] implement per-model retry routing:
# [ ]     on primary model failure → fallback to next in chain via router.py
# [ ]     log fallback event to NATS subject events.sage.fallback


@dataclass
class CircuitBreaker:
    """Otwiera obwód po `failure_threshold` błędów w oknie czasu."""

    failure_threshold: int = 5
    cooldown_seconds: float = 30.0
    failures: int = 0
    opened_at: float | None = None

    def allow(self) -> bool:
        if self.opened_at is None:
            return True
        if time.monotonic() - self.opened_at >= self.cooldown_seconds:
            self.failures = 0
            self.opened_at = None
            return True
        return False

    def record_success(self) -> None:
        self.failures = 0
        self.opened_at = None

    def record_failure(self) -> None:
        self.failures += 1
        if self.failures >= self.failure_threshold:
            self.opened_at = time.monotonic()


def async_llm_retry(
    *,
    max_attempts: int = 3,
    min_wait: float = 1.0,
    max_wait: float = 8.0,
    retry_exceptions: tuple[type[BaseException], ...] = (Exception,),
) -> Callable[[Callable[P, Awaitable[T]]], Callable[P, Awaitable[T]]]:
    """Dekorator tenacity dla async wywołań LLM."""

    return retry(
        stop=stop_after_attempt(max_attempts),
        wait=wait_exponential(multiplier=1, min=min_wait, max=max_wait),
        retry=retry_if_exception_type(retry_exceptions),
        reraise=True,
    )
