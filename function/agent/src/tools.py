"""LangGraph — definicje narzędzi, wzorce tool-calling, fabryka ToolNode."""

from __future__ import annotations

from typing import Any

from langchain_core.tools import tool
from langgraph.prebuilt import ToolNode

# TODO:
# [ ] implement filesystem_tool: read/write files in custom/{project}/
# [ ]     uses MCP filesystem protocol — path prefix from RICE_CUSTOM_DIR env
# [ ] implement nats_publish_tool: publish message to NATS subject
# [ ]     subject pattern: {domain}.{role}.{event} — soft-coded
# [ ]     connection from NATS_URL env var
# [ ] implement nats_request_tool: request/reply pattern via NATS
# [ ]     timeout from RICE_NATS_REQUEST_TIMEOUT_S env var
# [ ] implement temporal_start_tool: start Temporal workflow
# [ ]     workflow_id pattern: {project}-{role}-{uuid} — soft-coded
# [ ]     namespace from TEMPORAL_NAMESPACE env var
# [ ] implement temporal_query_tool: query running workflow state
# [ ] implement temporal_signal_tool: send signal to running workflow
# [ ] implement qdrant_search_tool: hybrid search via vector/search.py
# [ ]     collection from RICE_VECTOR_COLLECTION env var
# [ ] implement code_exec_tool: execute Python snippet in sandbox
# [ ]     sandbox: RestrictedPython, timeout from RICE_EXEC_TIMEOUT_S
# [ ] implement fetch_tool: HTTP GET with retry via helper/retry.py
# [ ]     user-agent from RICE_FETCH_UA env var
# [ ] all tools: decorated with @tool (LangChain tool protocol)
# [ ]     name, description, args_schema (Pydantic) — required for LangGraph


@tool
def echo_text(text: str) -> str:
    """Zwraca ten sam tekst — placeholder pod testy i ścieżkę narzędzi."""
    return text


@tool
def now_iso() -> str:
    """Aktualny czas ISO 8601 (UTC) — lekki tool bez IO."""
    from datetime import UTC, datetime

    return datetime.now(tz=UTC).isoformat()


def default_sage_tools() -> list[Any]:
    """Domyślny zestaw narzędzi agenta; rozszerzaj w jednym miejscu."""
    return [echo_text, now_iso]


def build_tool_node(tools: list[Any] | None = None) -> ToolNode:
    """`ToolNode` z listy narzędzi LangChain (`@tool`)."""
    return ToolNode(tools or default_sage_tools())
