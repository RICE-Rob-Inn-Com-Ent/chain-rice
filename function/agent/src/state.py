"""LangGraph state contracts for SAGE agent workflows."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import Annotated, Any, Literal, NotRequired

from langgraph.graph.message import add_messages
from loguru import logger
from typing_extensions import TypedDict

from .typed import RiceMessage, ToolResult

AgentStatus = Literal["idle", "thinking", "simulating", "answering"]


class AgentState(TypedDict):
    """Shared LangGraph memory used by SAGE reasoning nodes.

    Fields:
    - ``messages``: full chat history (LangGraph reducer ``add_messages``).
    - ``context``: retrieved context blobs (vector search snippets, etc.).
    - ``simulation_results``: outputs from simulation tasks keyed by run/tool id.
    - ``next_step``: router hint for the next node.
    - ``metadata``: session-level metadata (``user_id``, ``session_id``, flags).
    - ``status``: coarse progress status for tracing and UI.
    """

    messages: Annotated[list[RiceMessage], add_messages]
    context: dict[str, Any]
    simulation_results: dict[str, Any] | list[Any]
    next_step: str
    metadata: dict[str, Any]
    status: AgentStatus

    # Optional runtime hints for compatibility with existing graph code.
    thread_id: NotRequired[str]
    run_id: NotRequired[str]
    model: NotRequired[str]
    tool_results: NotRequired[list[ToolResult]]
    extra: NotRequired[dict[str, Any]]


def get_last_message(state: AgentState) -> RiceMessage | None:
    """Return the last message in history, or ``None`` when empty."""
    msgs = state.get("messages", [])
    return msgs[-1] if msgs else None


def get_combined_context(state: AgentState) -> str:
    """Combine messages + retrieved/simulation context into one prompt block."""
    parts: list[str] = []

    for m in state.get("messages", []):
        content = (m.content or "").strip()
        if not content:
            continue
        parts.append(f"[{m.role}] {content}")

    ctx = state.get("context", {})
    if ctx:
        parts.append("Context:\n" + str(ctx))

    sim = state.get("simulation_results", {})
    if sim:
        parts.append("Simulation:\n" + str(sim))

    return "\n\n".join(parts).strip()


def log_state_transition(state: AgentState, new_status: AgentStatus) -> AgentState:
    """Log and return updated state with a new status value."""
    old = state.get("status", "idle")
    logger.info("agent state transition | {} -> {}", old, new_status)
    out = dict(state)
    out["status"] = new_status
    return out


# Backward-compatible aliases used elsewhere in the package.
SageAgentState = AgentState


class SageToolAuditState(TypedDict):
    """Auxiliary audit trail for tool execution rounds."""

    last_tool_results: NotRequired[list[dict[str, Any]]]
    tool_rounds: NotRequired[int]


__all__ = [
    "AgentState",
    "AgentStatus",
    "SageAgentState",
    "SageToolAuditState",
    "get_combined_context",
    "get_last_message",
    "log_state_transition",
]
