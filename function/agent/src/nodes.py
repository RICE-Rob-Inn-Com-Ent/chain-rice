"""LangGraph — funkcje węzłów używane w `graph.py` (agent + integracja LiteLLM)."""

from __future__ import annotations

import json
from collections.abc import Awaitable, Callable
from typing import Any

from langchain_core.messages import AIMessage, convert_to_openai_messages
from langchain_core.utils.function_calling import convert_to_openai_tool

from .router import SageRouter
from .state import SageAgentState

# TODO:
# [ ] implement planner_node: calls LiteLLM via router.py with structured output
# [ ]     model read from RICE_KING_MODEL env var (KING orchestrates planning)
# [ ]     output: Plan(steps: list[Step]) validated by instructor
# [ ] implement executor_node: executes one Step from Plan
# [ ]     dispatches to tool_executor_node if step.requires_tool
# [ ]     dispatches to memory_read_node if step.requires_context
# [ ] implement validator_node: validates executor output via guard.py
# [ ]     on fail: increment state.retry_count, route back to planner
# [ ]     on max retries: raise MaxRetriesExceeded, route to END with error
# [ ] implement memory_read_node: reads from checkpointer + vector store
# [ ]     short-term: LangGraph checkpointer (SQLite dev, Postgres prod)
# [ ]     long-term: Qdrant collection read from RICE_MEMORY_COLLECTION env
# [ ] implement memory_write_node: writes to checkpointer + vector store
# [ ]     embeds assistant output via embed.py before storing in Qdrant
# [ ] implement tool_executor_node: parallel tool execution via asyncio.gather
# [ ]     timeout per tool from RICE_TOOL_TIMEOUT_S env var
# [ ] all nodes: emit OTel span with node name, state hash, latency
# [ ]     OTEL_EXPORTER_OTLP_ENDPOINT from env


def _choice_to_ai_message(choice: Any) -> AIMessage:
    """Mapuje `choices[0]` z odpowiedzi LiteLLM/OpenAI na `AIMessage`."""
    m = choice.message
    content = m.content or ""
    raw = getattr(m, "tool_calls", None)
    if not raw:
        return AIMessage(content=content)
    tool_calls: list[dict[str, Any]] = []
    for tc in raw:
        fn = getattr(tc, "function", None)
        if fn is None and isinstance(tc, dict):
            fn = tc.get("function", {})
        if fn is None:
            continue
        name = getattr(fn, "name", None) or (fn.get("name") if isinstance(fn, dict) else None)
        args_raw = getattr(fn, "arguments", None) or (
            fn.get("arguments", "{}") if isinstance(fn, dict) else "{}"
        )
        tid = getattr(tc, "id", None) or (tc.get("id") if isinstance(tc, dict) else "")
        if isinstance(args_raw, str):
            args_dict: Any = json.loads(args_raw or "{}")
        else:
            args_dict = args_raw
        tool_calls.append({"id": tid, "name": name, "args": args_dict})
    return AIMessage(content=content, tool_calls=tool_calls)


def tools_to_litellm_schema(tools: list[Any]) -> list[dict[str, Any]]:
    """Konwertuje narzędzia LangChain na listę `tools` dla LiteLLM."""
    out: list[dict[str, Any]] = []
    for t in tools:
        fn = convert_to_openai_tool(t)
        out.append({"type": "function", "function": fn})
    return out


def make_agent_node(
    router: SageRouter,
    tools: list[Any],
) -> Callable[[SageAgentState], Awaitable[dict[str, Any]]]:
    """Fabryka węzła LLM: jedno wywołanie `acompletion` z toolami."""

    tool_schemas = tools_to_litellm_schema(tools)

    async def agent(state: SageAgentState) -> dict[str, Any]:
        oai_messages = convert_to_openai_messages(state["messages"])
        model = state.get("model") or router.default_route
        resp = await router.acompletion(
            model=model,
            messages=oai_messages,
            tools=tool_schemas,
        )
        ai = _choice_to_ai_message(resp.choices[0])
        return {"messages": [ai]}

    return agent
