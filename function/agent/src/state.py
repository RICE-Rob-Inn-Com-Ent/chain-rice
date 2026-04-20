"""LangGraph TypedDict state — dane przepływające między węzłami workflow."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import Annotated, Any, NotRequired

from langgraph.graph.message import add_messages
from typing_extensions import TypedDict

# TODO:
# [ ] define TypedDict AgentState with LangGraph Annotated fields:
# [ ]     messages: Annotated[list[AnyMessage], add_messages]
# [ ]     context: str — current project context injected by CHIEF
# [ ]     role: str — which rice role is active (read from RICE_ROLE env)
# [ ]     memory_id: str — LangGraph checkpointer thread_id (soft-coded per session)
# [ ]     tool_calls: list[ToolCall] — pending tool invocations
# [ ]     retry_count: int — current retry attempt (max from RICE_SAGE_MAX_RETRIES)
# [ ]     stream_mode: str — values|updates|messages (read from RICE_STREAM_MODE)
# [ ]     error: str | None — last error message for retry logic
# [ ]     output: BaseModel | None — validated typed output
# [ ] define SubgraphState for each agent subgraph:
# [ ]     separate state per: planner, executor, validator, memory subgraph
# [ ] implement state reducers for message deduplication
# [ ] implement state snapshot for Temporal activity checkpointing
# [ ] add input/output schemas as Pydantic models for graph.invoke() type safety


class SageAgentState(TypedDict):
    """Stan głównego agenta ReAct: wiadomości + metadane wątku."""

    messages: Annotated[list[Any], add_messages]
    thread_id: NotRequired[str]
    """Identyfikator wątku (LangGraph config.configurable.thread_id)."""
    run_id: NotRequired[str]
    """Id pojedynczego uruchomienia (np. trace / audit)."""
    model: NotRequired[str]
    """Ewentualny override modelu dla tego przebiegu."""
    extra: NotRequired[dict[str, Any]]
    """Dowolne pola rozszerzające (np. tenant, locale)."""


class SageToolAuditState(TypedDict):
    """Stan pomocniczy: co narzędzia zwróciły (dla logów / guardów)."""

    last_tool_results: NotRequired[list[dict[str, Any]]]
    tool_rounds: NotRequired[int]
