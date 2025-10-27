# LangGraph - Agent Workflows

## Overview

LangGraph is a library for building stateful, multi-actor applications with LLMs. It extends LangChain with graph-based
workflows for complex agent systems.

## Features

- ✅ **State Management** - Persistent state across agent steps
- ✅ **Cyclical Graphs** - Loops and conditional flows
- ✅ **Multi-Agent** - Multiple specialized agents working together
- ✅ **Human-in-the-Loop** - Approval and intervention points
- ✅ **Streaming** - Real-time output streaming
- ✅ **Persistence** - Save and resume workflows

## Architecture

```
┌─────────────────────────────────────────┐
│           LangGraph Workflow            │
│                                         │
│  ┌─────────┐      ┌─────────┐          │
│  │ Agent 1 │─────>│ Agent 2 │          │
│  └─────────┘      └─────────┘          │
│       │                 │               │
│       ▼                 ▼               │
│  ┌─────────┐      ┌─────────┐          │
│  │  State  │<────>│  Tools  │          │
│  └─────────┘      └─────────┘          │
└─────────────────────────────────────────┘
```

## Quick Start

### Basic Agent Graph

```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, List

# Define state
class AgentState(TypedDict):
    messages: List[str]
    next_action: str

# Define nodes
def research_node(state: AgentState):
    """Research information"""
    # Perform research
    return {
        "messages": state["messages"] + ["Research complete"],
        "next_action": "analyze"
    }

def analyze_node(state: AgentState):
    """Analyze research"""
    # Perform analysis
    return {
        "messages": state["messages"] + ["Analysis complete"],
        "next_action": "report"
    }

def report_node(state: AgentState):
    """Generate report"""
    # Generate report
    return {
        "messages": state["messages"] + ["Report generated"],
        "next_action": END
    }

# Create graph
workflow = StateGraph(AgentState)

# Add nodes
workflow.add_node("research", research_node)
workflow.add_node("analyze", analyze_node)
workflow.add_node("report", report_node)

# Add edges
workflow.add_edge("research", "analyze")
workflow.add_edge("analyze", "report")
workflow.add_edge("report", END)

# Set entry point
workflow.set_entry_point("research")

# Compile
app = workflow.compile()

# Run
result = app.invoke({"messages": [], "next_action": "research"})
```

## Multi-Agent System

```python
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI
from langchain.agents import AgentExecutor, create_openai_functions_agent
from langchain.tools import Tool

# Initialize LLM
llm = ChatOpenAI(temperature=0)

# Create specialized agents
def create_researcher_agent():
    tools = [
        Tool(
            name="search",
            func=lambda q: f"Search results for: {q}",
            description="Search for information"
        )
    ]
    return create_openai_functions_agent(llm, tools)

def create_analyst_agent():
    tools = [
        Tool(
            name="analyze",
            func=lambda data: f"Analysis of: {data}",
            description="Analyze data"
        )
    ]
    return create_openai_functions_agent(llm, tools)

# Define workflow state
class WorkflowState(TypedDict):
    query: str
    research_result: str
    analysis_result: str
    final_report: str

# Create multi-agent graph
def create_multi_agent_workflow():
    workflow = StateGraph(WorkflowState)

    # Research node
    def research(state):
        researcher = create_researcher_agent()
        result = researcher.invoke({"input": state["query"]})
        return {"research_result": result}

    # Analysis node
    def analyze(state):
        analyst = create_analyst_agent()
        result = analyst.invoke({"input": state["research_result"]})
        return {"analysis_result": result}

    # Report node
    def report(state):
        report = f"""
        Query: {state['query']}
        Research: {state['research_result']}
        Analysis: {state['analysis_result']}
        """
        return {"final_report": report}

    workflow.add_node("research", research)
    workflow.add_node("analyze", analyze)
    workflow.add_node("report", report)

    workflow.add_edge("research", "analyze")
    workflow.add_edge("analyze", "report")
    workflow.add_edge("report", END)

    workflow.set_entry_point("research")

    return workflow.compile()

# Run workflow
app = create_multi_agent_workflow()
result = app.invoke({"query": "Latest AI trends"})
```

## Conditional Routing

```python
from langgraph.graph import StateGraph, END

class State(TypedDict):
    question: str
    answer: str
    needs_review: bool

def answer_question(state):
    # Generate answer
    answer = "Generated answer..."
    needs_review = len(answer) > 100  # Review if long
    return {"answer": answer, "needs_review": needs_review}

def review_answer(state):
    # Review and improve
    improved = state["answer"] + " (reviewed)"
    return {"answer": improved}

def should_review(state):
    """Conditional routing"""
    if state["needs_review"]:
        return "review"
    return "end"

workflow = StateGraph(State)

workflow.add_node("answer", answer_question)
workflow.add_node("review", review_answer)

workflow.add_edge("answer", should_review)
workflow.add_conditional_edges(
    "review",
    lambda x: "end",
    {"end": END}
)

workflow.set_entry_point("answer")

app = workflow.compile()
```

## Human-in-the-Loop

```python
from langgraph.checkpoint import MemorySaver
from langgraph.graph import StateGraph, END

# Add checkpointer for persistence
memory = MemorySaver()

class State(TypedDict):
    task: str
    draft: str
    approved: bool

def create_draft(state):
    draft = f"Draft for: {state['task']}"
    return {"draft": draft}

def human_review(state):
    """Requires human approval"""
    # This will pause until human input is provided
    return {"approved": True}  # Placeholder

workflow = StateGraph(State)

workflow.add_node("draft", create_draft)
workflow.add_node("review", human_review)

workflow.add_edge("draft", "review")
workflow.add_conditional_edges(
    "review",
    lambda x: "end" if x["approved"] else "draft",
    {"end": END, "draft": "draft"}
)

workflow.set_entry_point("draft")

# Compile with checkpointer
app = workflow.compile(checkpointer=memory)

# Run with thread for persistence
config = {"configurable": {"thread_id": "1"}}
result = app.invoke({"task": "Write blog post"}, config=config)
```

## Streaming Outputs

```python
async def stream_workflow():
    app = create_workflow()

    async for event in app.astream({"query": "AI news"}):
        print(f"Event: {event}")

    # Stream individual tokens
    async for chunk in app.astream_log({"query": "AI news"}):
        print(chunk)
```

## RAG with LangGraph

```python
from langgraph.graph import StateGraph, END
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import OllamaEmbeddings

class RAGState(TypedDict):
    question: str
    documents: List[str]
    answer: str

def retrieve_documents(state):
    # Retrieve relevant docs
    vectorstore = Chroma(embedding_function=OllamaEmbeddings())
    docs = vectorstore.similarity_search(state["question"], k=3)
    return {"documents": [d.page_content for d in docs]}

def generate_answer(state):
    # Generate answer from docs
    context = "\n".join(state["documents"])
    prompt = f"Context: {context}\n\nQuestion: {state['question']}"
    answer = llm.invoke(prompt)
    return {"answer": answer}

workflow = StateGraph(RAGState)
workflow.add_node("retrieve", retrieve_documents)
workflow.add_node("generate", generate_answer)
workflow.add_edge("retrieve", "generate")
workflow.add_edge("generate", END)
workflow.set_entry_point("retrieve")

app = workflow.compile()
```

## Complex Agent Loop

```python
from langgraph.graph import StateGraph, END

class AgentState(TypedDict):
    task: str
    plan: List[str]
    results: List[str]
    iteration: int
    max_iterations: int

def planner(state):
    """Create execution plan"""
    plan = ["step1", "step2", "step3"]
    return {"plan": plan, "iteration": 0}

def executor(state):
    """Execute current step"""
    current_step = state["plan"][state["iteration"]]
    result = f"Executed: {current_step}"
    return {
        "results": state["results"] + [result],
        "iteration": state["iteration"] + 1
    }

def should_continue(state):
    """Check if should continue"""
    if state["iteration"] >= len(state["plan"]):
        return "end"
    if state["iteration"] >= state["max_iterations"]:
        return "end"
    return "execute"

workflow = StateGraph(AgentState)

workflow.add_node("plan", planner)
workflow.add_node("execute", executor)

workflow.add_edge("plan", "execute")
workflow.add_conditional_edges(
    "execute",
    should_continue,
    {"execute": "execute", "end": END}
)

workflow.set_entry_point("plan")

app = workflow.compile()
result = app.invoke({
    "task": "Complete project",
    "results": [],
    "max_iterations": 10
})
```

## References

- [LangGraph Docs](https://langchain-ai.github.io/langgraph/)
- [Examples](https://github.com/langchain-ai/langgraph/tree/main/examples)
