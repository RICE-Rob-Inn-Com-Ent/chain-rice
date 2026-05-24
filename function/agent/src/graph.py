"""LangGraph assembly for the SAGE reasoning engine."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import os
from pathlib import Path
from typing import Any

from helper import logger
from langgraph.graph import END, START, StateGraph

from .memory import build_memory_saver
from .nodes import answer_node, reasoning_node, researcher_node, tool_node
from .router import should_continue
from .state import AgentState, SageAgentState


def build_sage_react_graph(
    *,
    checkpointer: Any | None = None,
) -> Any:
    """Build and compile production SAGE StateGraph."""
    cp = checkpointer if checkpointer is not None else build_memory_saver()
    hitl_enabled = os.getenv("RICE_HITL_ENABLED", "false").strip().lower() in {
        "1",
        "true",
        "yes",
        "on",
    }

    def _route_from_reasoning(state: AgentState) -> str:
        nxt = should_continue(state)
        if nxt in {"tool_node", "researcher_node", "answer_node"}:
            return nxt
        if nxt in {"retry_node", "reasoning_node"}:
            return "reasoning_node"
        if nxt == "human_approval_node":
            # Keep execution deterministic when manual approval path is requested.
            # With interrupt_before enabled, execution pauses before sensitive tools.
            return "researcher_node"
        return "answer_node"

    g = StateGraph(SageAgentState)
    g.add_node("reasoning_node", reasoning_node)
    g.add_node("tool_node", tool_node)
    g.add_node("researcher_node", researcher_node)
    g.add_node("answer_node", answer_node)

    # Entry point
    g.add_edge(START, "reasoning_node")

    # Direct edges
    g.add_edge("tool_node", "reasoning_node")
    g.add_edge("researcher_node", "reasoning_node")
    g.add_edge("answer_node", END)

    # Conditional routing from reasoner
    g.add_conditional_edges(
        "reasoning_node",
        _route_from_reasoning,
        {
            "tool_node": "tool_node",
            "researcher_node": "researcher_node",
            "reasoning_node": "reasoning_node",
            "answer_node": "answer_node",
        },
    )

    interrupt_before = ["tool_node"] if hitl_enabled else None
    compiled = g.compile(checkpointer=cp, interrupt_before=interrupt_before)
    logger.info(
        "SAGE graph compiled | hitl_enabled={} | interrupt_before={}",
        hitl_enabled,
        interrupt_before or [],
    )
    return compiled


graph = build_sage_react_graph()


def invoke_sage(input_text: str, config: dict[str, Any] | None = None) -> dict[str, Any]:
    """Convenience wrapper for synchronous graph invocation."""
    cfg = config or {}
    state: AgentState = {
        "messages": [{"role": "user", "content": input_text}],
        "context": {},
        "simulation_results": {},
        "next_step": "reasoning",
        "metadata": {},
        "status": "thinking",
    }
    return graph.invoke(state, config=cfg)


async def ainvoke_sage(input_text: str, config: dict[str, Any] | None = None) -> dict[str, Any]:
    """Async convenience wrapper for graph invocation."""
    cfg = config or {}
    state: AgentState = {
        "messages": [{"role": "user", "content": input_text}],
        "context": {},
        "simulation_results": {},
        "next_step": "reasoning",
        "metadata": {},
        "status": "thinking",
    }
    return await graph.ainvoke(state, config=cfg)


def draw_graph(
    *,
    output_path: str | None = None,
    as_png: bool = False,
    compiled_graph: Any | None = None,
) -> str:
    """Export graph structure as Mermaid (default) or PNG when supported."""
    g = compiled_graph or graph
    drawable = g.get_graph()
    if as_png:
        if output_path is None:
            output_path = "sage_graph.png"
        png_bytes = drawable.draw_mermaid_png()
        out = Path(output_path)
        out.write_bytes(png_bytes)
        return str(out)
    mermaid = drawable.draw_mermaid()
    if output_path is None:
        output_path = "sage_graph.mmd"
    out = Path(output_path)
    out.write_text(mermaid, encoding="utf-8")
    return str(out)


__all__ = [
    "ainvoke_sage",
    "build_sage_react_graph",
    "draw_graph",
    "graph",
    "invoke_sage",
]
