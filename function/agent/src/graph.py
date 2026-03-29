"""LangGraph — StateGraph (DAG), krawędzie, checkpointing, kompilacja workflow."""

from __future__ import annotations

from typing import Any

from langgraph.graph import END, START, StateGraph
from langgraph.prebuilt import ToolNode, tools_condition

from .memory import build_memory_saver
from .nodes import make_agent_node
from .router import SageRouter
from .state import SageAgentState
from .tools import default_sage_tools

# TODO:
# [ ] define StateGraph with AgentState as state schema
# [ ] add nodes: planner, executor, validator, memory_read, memory_write, tool_executor
# [ ] add conditional edges: router decides next node based on state.tool_calls
# [ ] add entry point: START → memory_read → planner
# [ ] add finish condition: validator → END when output is valid
# [ ] compile graph with checkpointer from memory.py
# [ ] add subgraph support: each role (agent/planner/executor) as separate compiled graph
# [ ]     invoke subgraph via graph.invoke() with subgraph_config
# [ ] add interrupt_before=["tool_executor"] for human-in-the-loop mode
# [ ]     RICE_HITL_ENABLED=true activates interrupt
# [ ] add streaming: graph.astream() with stream_mode from state
# [ ] add graph visualization: graph.get_graph().draw_mermaid()
# [ ]     output to test/notebook/explore_agent.py for marimo display
# [ ] implement multi-agent: supervisor graph delegates to specialist subgraphs
# [ ]     one subgraph per rice role: mason_agent, smith_agent, clerk_agent etc.


def build_sage_react_graph(
    *,
    router: SageRouter | None = None,
    tools: list[Any] | None = None,
    checkpointer: Any | None = None,
) -> Any:
    """Buduje skompilowany graf ReAct: agent ⟷ narzędzia, z checkpointem."""
    r = router or SageRouter()
    t = tools or default_sage_tools()
    cp = checkpointer if checkpointer is not None else build_memory_saver()

    g = StateGraph(SageAgentState)
    g.add_node("agent", make_agent_node(r, t))
    g.add_node("tools", ToolNode(t))
    g.add_edge(START, "agent")
    g.add_conditional_edges("agent", tools_condition, {"tools": "tools", END: END})
    g.add_edge("tools", "agent")
    return g.compile(checkpointer=cp)
