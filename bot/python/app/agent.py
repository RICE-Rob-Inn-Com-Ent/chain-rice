"""LangGraph state machine orchestration for agents.

Generic state schema (input, output, context, steps, metadata); nodes for
retrieve_context, llm_call, tool_call, validate_output, format_response.
Conditional edges and recursion_limit from config. No business-specific logic.
"""

from __future__ import annotations

from typing import Any, TypedDict

from loguru import logger

from app.config import get_settings


# -----------------------------------------------------------------------------
# State schema (generic)
# -----------------------------------------------------------------------------


class AgentState(TypedDict, total=False):
    """State passed through the graph. All fields optional for flexibility."""

    input: str | dict[str, Any]
    output: str | dict[str, Any]
    context: list[dict] | str
    steps: list[str]
    metadata: dict[str, Any]
    error: str
    next_node: str


# -----------------------------------------------------------------------------
# Node implementations (stubs when optional deps missing)
# -----------------------------------------------------------------------------


def _retrieve_context(state: AgentState) -> AgentState:
    """RAG retrieval from model.memory (hybrid search)."""
    try:
        from model.memory import search
        query = state.get("input")
        if isinstance(query, dict):
            query = query.get("query") or query.get("message") or str(query)
        else:
            query = str(query)
        top_k = (state.get("metadata") or {}).get("top_k", 5)
        results = search(query, top_k=top_k) if callable(search) else []
        return {**state, "context": results, "steps": (state.get("steps") or []) + ["retrieve_context"]}
    except ImportError:
        return {**state, "context": [], "steps": (state.get("steps") or []) + ["retrieve_context"]}


async def _llm_call_async(state: AgentState) -> AgentState:
    """Async LLM node."""
    from app.llm import completion_async
    inp = state.get("input")
    if isinstance(inp, dict):
        prompt = inp.get("message") or inp.get("query") or str(inp)
    else:
        prompt = str(inp)
    context = state.get("context")
    if context:
        prompt = f"Context: {context}\n\nUser: {prompt}"
    try:
        response = await completion_async(prompt)
        return {**state, "output": response, "steps": (state.get("steps") or []) + ["llm_call"]}
    except Exception as e:
        logger.warning("llm_call failed", error=str(e))
        return {**state, "output": "", "error": str(e), "steps": (state.get("steps") or []) + ["llm_call"]}


def _tool_call(state: AgentState) -> AgentState:
    """Execute tools from app.tools (placeholder: no tool selected in state)."""
    steps = (state.get("steps") or []) + ["tool_call"]
    return {**state, "steps": steps}


def _validate_output(state: AgentState) -> AgentState:
    """Check response with secure.guards if available."""
    try:
        from secure.guards import validate_prompt_guardrails
        out = state.get("output") or ""
        if isinstance(out, dict):
            out = str(out)
        report = validate_prompt_guardrails(out)
        if not report.valid:
            return {**state, "error": "Validation failed", "steps": (state.get("steps") or []) + ["validate_output"]}
    except ImportError:
        pass
    return {**state, "steps": (state.get("steps") or []) + ["validate_output"]}


def _format_response(state: AgentState) -> AgentState:
    """Structure final output for API."""
    return {**state, "steps": (state.get("steps") or []) + ["format_response"]}


# -----------------------------------------------------------------------------
# Graph build and compile
# -----------------------------------------------------------------------------


def _build_graph():
    """Build LangGraph StateGraph with nodes and edges. Returns compiled graph."""
    try:
        from langgraph.graph import END, StateGraph
    except ImportError as e:
        raise ImportError("LangGraph required: pip install langgraph") from e

    graph = StateGraph(AgentState)

    # Register nodes (wrap async for sync graph)
    async def llm_node(s: AgentState) -> AgentState:
        return await _llm_call_async(s)

    graph.add_node("retrieve_context", _retrieve_context)
    graph.add_node("llm_call", llm_node)
    graph.add_node("tool_call", _tool_call)
    graph.add_node("validate_output", _validate_output)
    graph.add_node("format_response", _format_response)

    graph.set_entry_point("retrieve_context")
    graph.add_edge("retrieve_context", "llm_call")
    graph.add_edge("llm_call", "validate_output")
    graph.add_edge("validate_output", "format_response")
    graph.add_edge("format_response", END)

    return graph.compile()


_graph = None


def get_agent_graph():
    """Return compiled agent graph (cached)."""
    global _graph
    if _graph is None:
        _graph = _build_graph()
    return _graph


async def run_agent(input_data: str | dict[str, Any], **kwargs: Any) -> dict[str, Any]:
    """Run agent graph with given input. Returns state with output and steps.

    Args:
        input_data: User message or dict with 'message'/'query'.
        **kwargs: Passed to graph.invoke (e.g. config with recursion_limit).

    Returns:
        Final state dict with output, steps, metadata.
    """
    settings = get_settings()
    graph = get_agent_graph()
    initial: AgentState = {"input": input_data, "steps": [], "metadata": kwargs.get("metadata", {})}
    config = {"recursion_limit": settings.AGENT_RECURSION_LIMIT, **kwargs.get("config", {})}
    try:
        # LangGraph invoke can be sync or async
        if hasattr(graph, "ainvoke"):
            result = await graph.ainvoke(initial, config=config)
        else:
            result = graph.invoke(initial, config=config)
    except Exception as e:
        logger.exception("Agent run failed", error=str(e))
        return {"output": "", "error": str(e), "steps": initial.get("steps", [])}
    return dict(result) if isinstance(result, dict) else {"output": str(result), "steps": []}
