"""Reliability primitives for SAGE: async retries, circuit-breaker, and intervention-aware policies."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import os
import time
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from typing import Any, ParamSpec, TypeVar

import litellm
from helper import CircuitOpenError, MaxRetriesExceeded, RiceError, logger
from tenacity import (
    RetryCallState,
    after_log,
    retry,
    retry_if_exception,
    retry_if_exception_type,
    stop_after_attempt,
    wait_base,
    wait_exponential,
)
from .const import (
    MAX_RETRIES as CONST_MAX_RETRIES,
    RETRY_EXPONENTIAL_MULTIPLIER as CONST_RETRY_EXPONENTIAL_MULTIPLIER,
    RETRY_MAX_WAIT_S as CONST_RETRY_MAX_WAIT_S,
    RETRY_MIN_WAIT_S as CONST_RETRY_MIN_WAIT_S,
)

P = ParamSpec("P")
T = TypeVar("T")


class UserInterventionRequired(RiceError):
    """Bypass retries and request user/operator help."""

    def __init__(self, message: str = "User intervention required", **details: Any) -> None:
        super().__init__(
            message,
            error_code="USER_INTERVENTION_REQUIRED",
            details=details or {},
        )


def _env_int(name: str, default: int) -> int:
    try:
        return int(os.getenv(name, str(default)))
    except ValueError:
        return default


def _env_float(name: str, default: float) -> float:
    try:
        return float(os.getenv(name, str(default)))
    except ValueError:
        return default


# src.const-compatible defaults (fallback to env first, then sane hard defaults)
MAX_RETRIES: int = _env_int("RICE_SAGE_MAX_RETRIES", _env_int("RICE_MAX_RETRIES", CONST_MAX_RETRIES))
RETRY_MIN_WAIT_S: float = _env_float("RICE_RETRY_MIN_WAIT_S", CONST_RETRY_MIN_WAIT_S)
RETRY_MAX_WAIT_S: float = _env_float("RICE_RETRY_MAX_WAIT_S", CONST_RETRY_MAX_WAIT_S)
RETRY_EXPONENTIAL_MULTIPLIER: float = _env_float(
    "RICE_RETRY_EXPONENTIAL_MULTIPLIER",
    CONST_RETRY_EXPONENTIAL_MULTIPLIER,
)
CB_FAILURE_THRESHOLD: int = _env_int("RICE_CIRCUIT_BREAKER_FAILURES", 5)
CB_COOLDOWN_SECONDS: float = _env_float("RICE_CIRCUIT_BREAKER_TIMEOUT_S", 30.0)


@dataclass
class CircuitBreaker:
    """Otwiera obwód po `failure_threshold` błędów w oknie czasu."""

    failure_threshold: int = CB_FAILURE_THRESHOLD
    cooldown_seconds: float = CB_COOLDOWN_SECONDS
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


@dataclass(slots=True)
class RetryTelemetry:
    attempts: int = 0
    healed_successes: int = 0


_telemetry = RetryTelemetry()


def get_retry_telemetry() -> RetryTelemetry:
    return RetryTelemetry(
        attempts=_telemetry.attempts,
        healed_successes=_telemetry.healed_successes,
    )


def _class_name(exc: BaseException) -> str:
    return type(exc).__name__


def _llm_retryable_exception_types() -> tuple[type[BaseException], ...]:
    """Retry only for explicit LLM transient/context exceptions."""
    ex_mod = getattr(litellm, "exceptions", None)
    out: list[type[BaseException]] = []
    for name in ("ServiceUnavailableError", "ContextWindowExceededError"):
        t = getattr(ex_mod, name, None) if ex_mod is not None else None
        if isinstance(t, type) and issubclass(t, BaseException):
            out.append(t)
    # compatibility fallback for local domain error names
    if not out:
        out.append(Exception)
    return tuple(out)


def _is_retryable_validation_error(exc: BaseException) -> bool:
    if isinstance(exc, UserInterventionRequired):
        return False
    n = _class_name(exc).lower()
    return "validation" in n or "guard" in n or "schema" in n


def _is_retryable_tool_error(exc: BaseException) -> bool:
    if isinstance(exc, UserInterventionRequired):
        return False
    n = _class_name(exc).lower()
    transient_keys = (
        "timeout",
        "temporar",
        "connection",
        "unavailable",
        "network",
        "throttle",
        "rate",
    )
    return any(k in n or k in str(exc).lower() for k in transient_keys)


def _before_sleep_log(name: str) -> Callable[[RetryCallState], None]:
    def _cb(state: RetryCallState) -> None:
        _telemetry.attempts += 1
        exc = state.outcome.exception() if state.outcome else None
        logger.warning(
            "retry.{} attempt={} next_sleep={:.2f}s exc={}",
            name,
            state.attempt_number,
            float(getattr(state.next_action, "sleep", 0.0) or 0.0),
            _class_name(exc) if exc is not None else "None",
        )

    return _cb


def _after_log_healed(name: str) -> Callable[[RetryCallState], None]:
    base_cb = after_log(logger, "INFO")

    def _cb(state: RetryCallState) -> None:
        base_cb(state)
        if state.outcome is not None and not state.outcome.failed and state.attempt_number > 1:
            _telemetry.healed_successes += 1
            logger.info(
                "retry.{} healed | attempts={} total_healed={}",
                name,
                state.attempt_number,
                _telemetry.healed_successes,
            )

    return _cb


class wait_exponential_multiplier(wait_base):
    """Compatibility alias requested by workflow spec."""

    def __init__(self, multiplier: float = 1.0, min: float = 0.0, max: float = 60.0) -> None:  # noqa: A002
        self._delegate = wait_exponential(multiplier=multiplier, min=min, max=max)

    def __call__(self, retry_state: RetryCallState) -> float:
        return float(self._delegate(retry_state))


def _raise_last_retry_error(state: RetryCallState) -> None:
    exc = state.outcome.exception() if state.outcome else None
    if isinstance(exc, UserInterventionRequired):
        raise exc
    raise MaxRetriesExceeded(
        "Retry attempts exhausted",
        details={
            "attempts": state.attempt_number,
            "last_exception": _class_name(exc) if exc else None,
            "last_error": str(exc) if exc else None,
        },
    ) from exc


def _retry_config(
    *,
    name: str,
    max_attempts: int,
    retry_rule: Any,
    min_wait: float,
    max_wait: float,
    multiplier: float,
) -> dict[str, Any]:
    return {
        "stop": stop_after_attempt(max_attempts),
        "wait": wait_exponential_multiplier(multiplier=multiplier, min=min_wait, max=max_wait),
        "retry": retry_rule,
        "reraise": False,
        "before_sleep": _before_sleep_log(name),
        "after": _after_log_healed(name),
        "retry_error_callback": _raise_last_retry_error,
    }


def retry_llm_call(
    *,
    max_attempts: int = MAX_RETRIES,
    min_wait: float = RETRY_MIN_WAIT_S,
    max_wait: float = RETRY_MAX_WAIT_S,
    multiplier: float = RETRY_EXPONENTIAL_MULTIPLIER,
    retry_exceptions: tuple[type[BaseException], ...] | None = None,
) -> Callable[[Callable[P, Awaitable[T]]], Callable[P, Awaitable[T]]]:
    """Tenacity decorator for LLM calls (ServiceUnavailable/ContextWindowExceeded only)."""
    ex_types = retry_exceptions or _llm_retryable_exception_types()
    rule = retry_if_exception_type(ex_types) & ~retry_if_exception_type(UserInterventionRequired)
    return retry(
        **_retry_config(
            name="llm",
            max_attempts=max_attempts,
            retry_rule=rule,
            min_wait=min_wait,
            max_wait=max_wait,
            multiplier=multiplier,
        ),
    )


def retry_on_validation_error(
    *,
    max_attempts: int = MAX_RETRIES,
    min_wait: float = RETRY_MIN_WAIT_S,
    max_wait: float = RETRY_MAX_WAIT_S,
    multiplier: float = RETRY_EXPONENTIAL_MULTIPLIER,
) -> Callable[[Callable[P, Awaitable[T]]], Callable[P, Awaitable[T]]]:
    """Retry schema/guard validation errors; for self-correction loops."""
    return retry(
        **_retry_config(
            name="validation",
            max_attempts=max_attempts,
            retry_rule=retry_if_exception(_is_retryable_validation_error),
            min_wait=min_wait,
            max_wait=max_wait,
            multiplier=multiplier,
        ),
    )


def inject_validation_feedback(
    messages: list[dict[str, Any]],
    *,
    error: BaseException,
) -> list[dict[str, Any]]:
    """Append self-correction hint for next model pass after validation failure."""
    out = list(messages)
    out.append(
        {
            "role": "system",
            "content": (
                "Previous output failed validation. Regenerate and strictly satisfy schema. "
                f"Validation error: {type(error).__name__}: {error}"
            ),
        },
    )
    return out


def retry_tool_execution(
    *,
    circuit_breaker: CircuitBreaker | None = None,
    max_attempts: int = MAX_RETRIES,
    min_wait: float = RETRY_MIN_WAIT_S,
    max_wait: float = RETRY_MAX_WAIT_S,
    multiplier: float = RETRY_EXPONENTIAL_MULTIPLIER,
) -> Callable[[Callable[P, Awaitable[T]]], Callable[P, Awaitable[T]]]:
    """Retry transient tool errors with circuit-breaker protection."""
    cb = circuit_breaker or CircuitBreaker()

    def _decorator(fn: Callable[P, Awaitable[T]]) -> Callable[P, Awaitable[T]]:
        @retry(
            **_retry_config(
                name="tool",
                max_attempts=max_attempts,
                retry_rule=retry_if_exception(_is_retryable_tool_error),
                min_wait=min_wait,
                max_wait=max_wait,
                multiplier=multiplier,
            ),
        )
        async def _wrapped(*args: P.args, **kwargs: P.kwargs) -> T:
            if not cb.allow():
                raise CircuitOpenError(
                    "Circuit breaker open for tool execution",
                    details={
                        "failure_threshold": cb.failure_threshold,
                        "cooldown_seconds": cb.cooldown_seconds,
                        "failures": cb.failures,
                    },
                )
            try:
                out = await fn(*args, **kwargs)
                cb.record_success()
                return out
            except UserInterventionRequired:
                raise
            except Exception:
                cb.record_failure()
                raise

        return _wrapped

    return _decorator


def async_llm_retry(
    *,
    max_attempts: int = MAX_RETRIES,
    min_wait: float = RETRY_MIN_WAIT_S,
    max_wait: float = RETRY_MAX_WAIT_S,
    multiplier: float = RETRY_EXPONENTIAL_MULTIPLIER,
    retry_exceptions: tuple[type[BaseException], ...] = (Exception,),
) -> Callable[[Callable[P, Awaitable[T]]], Callable[P, Awaitable[T]]]:
    """Backward-compatible generic async retry decorator."""
    rule = retry_if_exception_type(retry_exceptions) & ~retry_if_exception_type(UserInterventionRequired)
    return retry(
        **_retry_config(
            name="generic",
            max_attempts=max_attempts,
            retry_rule=rule,
            min_wait=min_wait,
            max_wait=max_wait,
            multiplier=multiplier,
        ),
    )


__all__ = [
    "CB_COOLDOWN_SECONDS",
    "CB_FAILURE_THRESHOLD",
    "CircuitBreaker",
    "MAX_RETRIES",
    "RETRY_EXPONENTIAL_MULTIPLIER",
    "RETRY_MAX_WAIT_S",
    "RETRY_MIN_WAIT_S",
    "UserInterventionRequired",
    "async_llm_retry",
    "get_retry_telemetry",
    "inject_validation_feedback",
    "retry_llm_call",
    "retry_on_validation_error",
    "retry_tool_execution",
    "wait_exponential_multiplier",
]
