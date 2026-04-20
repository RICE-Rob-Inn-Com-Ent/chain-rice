"""SAGE agent — LangGraph (workflow), LiteLLM (routing), Instructor / Outlines / Guardrails (jakość wyjść)."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from .constrain import (
    ConstraintKind,
    match_regex,
    outlines_cfg_hook,
    outlines_json_schema_hook,
    outlines_regex_hook,
    validate_json_to_model,
)
from .context import estimate_tokens_litellm, truncate_messages
from .graph import build_sage_react_graph
from .guard import apply_guard, build_default_guard, validate_output
from .memory import build_cross_thread_store, build_memory_saver, build_sqlite_saver
from .prompt import few_shot_block, render_template, sage_system_prompt
from .retry import CircuitBreaker, async_llm_retry
from .router import CostLedger, SageRouter, default_fallbacks, default_model_list
from .state import SageAgentState, SageToolAuditState
from .stream import astream_events_sse, astream_graph_updates, format_sse
from .tools import build_tool_node, default_sage_tools, echo_text, now_iso
from .typed import complete_structured, instructor_client

__all__ = [
    "CircuitBreaker",
    "ConstraintKind",
    "CostLedger",
    "SageAgentState",
    "SageRouter",
    "SageToolAuditState",
    "apply_guard",
    "async_llm_retry",
    "astream_events_sse",
    "astream_graph_updates",
    "build_cross_thread_store",
    "build_default_guard",
    "build_memory_saver",
    "build_sage_react_graph",
    "build_sqlite_saver",
    "build_tool_node",
    "complete_structured",
    "default_fallbacks",
    "default_model_list",
    "default_sage_tools",
    "echo_text",
    "estimate_tokens_litellm",
    "few_shot_block",
    "format_sse",
    "instructor_client",
    "match_regex",
    "now_iso",
    "outlines_cfg_hook",
    "outlines_json_schema_hook",
    "outlines_regex_hook",
    "render_template",
    "sage_system_prompt",
    "truncate_messages",
    "validate_json_to_model",
    "validate_output",
]
