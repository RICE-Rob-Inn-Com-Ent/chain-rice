#!/usr/bin/env python3
"""
Research Agent with LangGraph
Multi-step research workflow with planning and synthesis
"""

import operator
from typing import Annotated, List, TypedDict

from langchain.prompts import ChatPromptTemplate
from langchain_community.llms import Ollama
from langgraph.graph import END, StateGraph
from rich.console import Console
from rich.panel import Panel

console = Console()


# Define state
class ResearchState(TypedDict):
    query: str
    plan: List[str]
    research_results: Annotated[List[str], operator.add]
    synthesis: str
    iteration: int


# Initialize LLM
llm = Ollama(model="llama3.3")


def create_research_plan(state: ResearchState) -> dict:
    """Create a research plan"""
    console.print(Panel("[bold cyan]Creating Research Plan...[/bold cyan]"))

    prompt = ChatPromptTemplate.from_template(
        """
    Create a research plan for the following query. List 3-5 specific research topics to investigate.

    Query: {query}

    Respond with a numbered list of research topics:
    """
    )

    response = llm.invoke(prompt.format(query=state["query"]))

    # Parse plan (simplified)
    plan_items = [line.strip() for line in response.split("\n") if line.strip() and line[0].isdigit()]

    console.print(f"[green]Plan created with {len(plan_items)} steps[/green]")

    return {"plan": plan_items, "iteration": 0}


def conduct_research(state: ResearchState) -> dict:
    """Conduct research on current topic"""
    current_topic = state["plan"][state["iteration"]]

    console.print(f"\n[bold blue]Researching:[/bold blue] {current_topic}")

    prompt = ChatPromptTemplate.from_template(
        """
    Research the following topic and provide key findings:

    Topic: {topic}

    Provide 2-3 key points:
    """
    )

    result = llm.invoke(prompt.format(topic=current_topic))

    console.print(f"[green]✓ Research complete[/green]")

    return {"research_results": [f"Topic: {current_topic}\n{result}"], "iteration": state["iteration"] + 1}


def synthesize_findings(state: ResearchState) -> dict:
    """Synthesize all research findings"""
    console.print(Panel("[bold magenta]Synthesizing Findings...[/bold magenta]"))

    all_research = "\n\n---\n\n".join(state["research_results"])

    prompt = ChatPromptTemplate.from_template(
        """
    Synthesize the following research findings into a comprehensive summary:

    Original Query: {query}

    Research Findings:
    {findings}

    Provide a cohesive summary:
    """
    )

    synthesis = llm.invoke(prompt.format(query=state["query"], findings=all_research))

    console.print("[green]✓ Synthesis complete[/green]")

    return {"synthesis": synthesis}


def should_continue_research(state: ResearchState) -> str:
    """Determine if more research is needed"""
    if state["iteration"] >= len(state["plan"]):
        return "synthesize"
    return "research"


# Create workflow
def create_research_workflow():
    workflow = StateGraph(ResearchState)

    # Add nodes
    workflow.add_node("plan", create_research_plan)
    workflow.add_node("research", conduct_research)
    workflow.add_node("synthesize", synthesize_findings)

    # Add edges
    workflow.add_edge("plan", "research")
    workflow.add_conditional_edges(
        "research", should_continue_research, {"research": "research", "synthesize": "synthesize"}
    )
    workflow.add_edge("synthesize", END)

    # Set entry point
    workflow.set_entry_point("plan")

    return workflow.compile()


if __name__ == "__main__":
    app = create_research_workflow()

    # Example queries
    queries = [
        "What are the latest developments in quantum computing?",
        "How is AI being used in healthcare?",
        "Explain blockchain scalability solutions",
    ]

    for query in queries:
        console.print(f"\n{'='*80}")
        console.print(Panel(f"[bold yellow]Query:[/bold yellow] {query}", title="Research Agent"))
        console.print(f"{'='*80}\n")

        result = app.invoke({"query": query, "research_results": []})

        console.print(f"\n[bold green]Final Synthesis:[/bold green]")
        console.print(Panel(result["synthesis"], title="Results"))
        console.print()
