"""Helper — ustawienia, schematy, walidacja, retry, logi, błędy, konwersje."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from .convert import (
    adapt_validate,
    coerce_json,
    merge_dicts,
    model_to_dict,
    model_to_json,
    parse_json,
    parse_model,
)
from .error import (
    ErrorDetail,
    StructuredError,
    log_structured_error,
    structured_error_from_exception,
    to_http_payload,
)
from .log import bind_context, bind_trace_context, configure_logging, otel_log_record_exporter_hook
from .retry import (
    log_retry_state,
    retry_chain_example,
    retry_idempotent,
    retry_if_message_contains,
    retry_transient_io,
    retry_with_jitter,
    stop_after_elapsed,
)
from .schema import NonEmptyStr, SchemaBase, TimestampedSchema, dumps_json_value
from .settings import HelperSettings, get_settings
from .validate import CrossFieldExample, EmailMixin, validate_slug

Settings = HelperSettings

__all__ = [
    "CrossFieldExample",
    "EmailMixin",
    "ErrorDetail",
    "HelperSettings",
    "NonEmptyStr",
    "SchemaBase",
    "Settings",
    "StructuredError",
    "TimestampedSchema",
    "adapt_validate",
    "bind_context",
    "bind_trace_context",
    "coerce_json",
    "configure_logging",
    "dumps_json_value",
    "get_settings",
    "log_retry_state",
    "log_structured_error",
    "merge_dicts",
    "model_to_dict",
    "model_to_json",
    "otel_log_record_exporter_hook",
    "parse_json",
    "parse_model",
    "retry_chain_example",
    "retry_idempotent",
    "retry_if_message_contains",
    "retry_transient_io",
    "retry_with_jitter",
    "stop_after_elapsed",
    "structured_error_from_exception",
    "to_http_payload",
    "validate_slug",
]
