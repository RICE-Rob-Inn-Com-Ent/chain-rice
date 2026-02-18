"""Shared utilities: logger setup, retry, exceptions, validators, helpers.

Used across the app module. No business logic; generic helpers only.
"""

from __future__ import annotations

import re
import sys
import time
import uuid
from functools import wraps
from typing import Any, Callable, TypeVar

from loguru import logger

# -----------------------------------------------------------------------------
# Exceptions
# -----------------------------------------------------------------------------


class AppError(Exception):
    """Base exception for application errors. All custom exceptions inherit from this."""


class ConfigurationError(AppError):
    """Raised when configuration is invalid or missing required settings."""


class LLMError(AppError):
    """Raised when LLM API calls fail (timeout, rate limit, invalid response)."""


class DataError(AppError):
    """Raised when data processing fails (query, table ops, compute)."""


class SecurityError(AppError):
    """Raised when security checks fail (injection, unsafe query, guardrail violation)."""


class ValidationError(AppError):
    """Raised when input or output validation fails."""


# -----------------------------------------------------------------------------
# Logger setup (loguru)
# -----------------------------------------------------------------------------


def setup_logger(
    level: str = "INFO",
    format_type: str = "json",
    file_path: str | None = None,
) -> None:
    """Configure loguru logger from config.

    Args:
        level: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL).
        format_type: 'json' for structured JSON lines, 'text' for human-readable.
        file_path: Optional file path to also write logs. None = stdout only.

    Side effects:
        Removes default handler and adds configured ones.
    """
    logger.remove()
    if format_type == "json":
        fmt = (
            "{{"
            '"timestamp":"{time:ISO8601}",'
            '"level":"{level}",'
            '"message":"{message}",'
            '"module":"{module}",'
            '"function":"{function}"'
            "}}"
        )
    else:
        fmt = "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan> - <level>{message}</level>"

    logger.add(sys.stderr, format=fmt, level=level, serialize=(format_type == "json"))
    if file_path:
        logger.add(
            file_path,
            format=fmt,
            level=level,
            serialize=(format_type == "json"),
            rotation="10 MB",
        )


# -----------------------------------------------------------------------------
# Retry decorator (tenacity)
# -----------------------------------------------------------------------------

T = TypeVar("T")


def retry_with_backoff(
    max_attempts: int = 3,
    backoff_factor: float = 2.0,
    exceptions: tuple[type[Exception], ...] = (Exception,),
) -> Callable[[Callable[..., T]], Callable[..., T]]:
    """Decorator that retries a function with exponential backoff using tenacity.

    Args:
        max_attempts: Maximum number of attempts (including first).
        backoff_factor: Multiplier for wait time between retries (seconds).
        exceptions: Tuple of exception types to catch and retry. Others are raised.

    Returns:
        Decorated function that retries on specified exceptions.

    Example:
        @retry_with_backoff(max_attempts=3, exceptions=(ConnectionError,))
        def call_api(): ...
    """

    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> T:
            from tenacity import (
                retry,
                retry_if_exception_type,
                stop_after_attempt,
                wait_exponential,
            )

            r = retry(
                retry=retry_if_exception_type(exceptions),
                stop=stop_after_attempt(max_attempts),
                wait=wait_exponential(multiplier=backoff_factor),
                reraise=True,
            )
            return r(lambda: func(*args, **kwargs))()

        return wrapper  # type: ignore[return-value]

    return decorator


# -----------------------------------------------------------------------------
# Validators
# -----------------------------------------------------------------------------

# Block destructive or write SQL keywords (read-only safety)
_BLOCKED_SQL = re.compile(
    r"\b(ALTER|CREATE|DELETE|DROP|EXEC|EXECUTE|INSERT|TRUNCATE|UPDATE|GRANT|REVOKE)\b",
    re.I,
)

# Prompt injection / jailbreak heuristics (simple; use secure.guards for full check)
_BLOCK_PATTERNS = [
    re.compile(r"ignore\s+(previous|all)\s+instructions", re.I),
    re.compile(r"disregard\s+(previous|all)", re.I),
    re.compile(r"you\s+are\s+now\s+", re.I),
    re.compile(r"jail\s*break", re.I),
    re.compile(r"system\s*:\s*you\s+are", re.I),
    re.compile(r"<\s*script|javascript\s*:", re.I),
]

# Sensitive patterns to redact in sanitize_output (example)
_SENSITIVE_PATTERNS = [
    (re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"), "[EMAIL]"),
    (re.compile(r"\b\d{3}-\d{2}-\d{4}\b"), "[SSN]"),
]


def is_safe_sql(query: str) -> bool:
    """Return True if query appears read-only (no DROP/DELETE/UPDATE etc.).

    Use for quick checks; data.query.is_safe_query returns (bool, reason) for APIs.
    """
    if not (query or "").strip():
        return False
    return _BLOCKED_SQL.search(query) is None


def detect_prompt_injection(text: str) -> bool:
    """Simple heuristics for prompt injection. For full check use secure.guards.

    Returns True if text looks suspicious (jailbreak, ignore instructions, etc.).
    """
    if not text or not text.strip():
        return False
    for pat in _BLOCK_PATTERNS:
        if pat.search(text):
            return True
    return False


def sanitize_output(text: str, redact_email: bool = True, redact_ssn: bool = True) -> str:
    """Remove or redact sensitive patterns from text.

    Args:
        text: Raw output string.
        redact_email: Replace email-like patterns with [EMAIL].
        redact_ssn: Replace SSN-like patterns with [SSN].

    Returns:
        Sanitized string.
    """
    out = text
    for pat, repl in _SENSITIVE_PATTERNS:
        if (pat.pattern == r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b" and not redact_email):
            continue
        if (pat.pattern == r"\b\d{3}-\d{2}-\d{4}\b" and not redact_ssn):
            continue
        out = pat.sub(repl, out)
    return out


def is_suspicious_prompt(text: str) -> bool:
    """Alias for detect_prompt_injection for backwards compatibility."""
    return detect_prompt_injection(text)


def validate_prompt(text: str) -> tuple[bool, str | None]:
    """Validate user prompt. Returns (ok, error_message). Use before sending to LLM."""
    if detect_prompt_injection(text):
        return False, "Request rejected: invalid or disallowed input."
    return True, None


# Legacy: (bool, reason) for SQL - delegate to data.query if needed to avoid circular import
def is_safe_query(sql: str) -> tuple[bool, str | None]:
    """(True, None) if read-only safe; (False, reason) otherwise."""
    sql = (sql or "").strip()
    if not sql:
        return False, "Empty query."
    if _BLOCKED_SQL.search(sql):
        return False, "Destructive or write operations are not allowed."
    return True, None


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------


def generate_request_id() -> str:
    """Generate a unique request ID for tracing (UUID4)."""
    return str(uuid.uuid4())


def format_error_response(exc: Exception) -> dict[str, Any]:
    """Build a consistent error JSON for API responses.

    Returns:
        Dict with keys: error, detail, type (optional). Safe to return from FastAPI.
    """
    detail = str(exc) or "An error occurred"
    return {
        "error": exc.__class__.__name__,
        "detail": detail,
    }


def measure_duration(func: Callable[..., T]) -> Callable[..., T]:
    """Decorator that logs the duration of a function call."""

    @wraps(func)
    def wrapper(*args: Any, **kwargs: Any) -> T:
        start = time.perf_counter()
        try:
            result = func(*args, **kwargs)
            logger.debug("duration_ms", function=func.__name__, ms=(time.perf_counter() - start) * 1000)
            return result
        except Exception as e:
            logger.debug("duration_ms", function=func.__name__, ms=(time.perf_counter() - start) * 1000, error=str(e))
            raise

    return wrapper  # type: ignore[return-value]


def get_logger(name: str | None = None):  # noqa: ANN201
    """Return loguru logger optionally bound to a name."""
    return logger.bind(name=name or "app")


# -----------------------------------------------------------------------------
# Legacy retry (simple)
# -----------------------------------------------------------------------------


def retry_once(fn: Callable[[], T], exc: type[Exception] = Exception) -> T:
    """Run fn; on exc retry once. For simple cases; use retry_with_backoff for more."""
    try:
        return fn()
    except exc:
        return fn()
