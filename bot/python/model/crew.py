"""CrewAI agents, tasks, and crews. Generic roles and parameterized prompts.

Provides create_orchestrator, create_retriever, create_analyst, create_validator, create_responder,
create_retrieval_task, create_analysis_task, create_validation_task, create_response_task,
create_standard_crew, create_hierarchical_crew, create_crew. Requires: crewai (extra model).
All prompts and backstories are passed as parameters (no hardcoded business text). English only.
"""

from __future__ import annotations

from typing import Any

from loguru import logger

# Default prompt templates (overridable via args)
SYSTEM_PROMPT = "You are a helpful assistant for the Rice-Bot (generic backend)."
USER_PROMPT_TEMPLATE = "{query}"


def _get_llm_config() -> str:
    """Return LLM model name from config for CrewAI agents."""
    try:
        from app.config import get_settings
        return get_settings().LITELLM_MODEL
    except Exception:
        return "gpt-4o-mini"


def create_orchestrator(
    role: str = "Orchestrator",
    goal: str = "Coordinate tasks and delegate to specialists.",
    backstory: str = "Expert at breaking down problems and assigning work.",
    **kwargs: Any,
):
    """Create Orchestrator agent. All text from parameters."""
    try:
        from crewai import Agent
    except ImportError as e:
        raise ImportError("create_orchestrator requires crewai; uv sync --extra model") from e
    return Agent(
        role=role,
        goal=goal,
        backstory=backstory,
        llm=_get_llm_config(),
        **kwargs,
    )


def create_retriever(
    role: str = "Retriever",
    goal: str = "Fetch relevant context from documents.",
    backstory: str = "Expert at search and retrieval.",
    **kwargs: Any,
):
    """Create Retriever agent (fetches context from memory)."""
    try:
        from crewai import Agent
    except ImportError as e:
        raise ImportError("create_retriever requires crewai; uv sync --extra model") from e
    return Agent(role=role, goal=goal, backstory=backstory, llm=_get_llm_config(), **kwargs)


def create_analyst(
    role: str = "Analyst",
    goal: str = "Process data and produce insights.",
    backstory: str = "Expert at analysis and reasoning.",
    **kwargs: Any,
):
    """Create Analyst agent."""
    try:
        from crewai import Agent
    except ImportError as e:
        raise ImportError("create_analyst requires crewai; uv sync --extra model") from e
    return Agent(role=role, goal=goal, backstory=backstory, llm=_get_llm_config(), **kwargs)


def create_validator(
    role: str = "Validator",
    goal: str = "Check outputs against constraints.",
    backstory: str = "Expert at validation and quality.",
    **kwargs: Any,
):
    """Create Validator agent."""
    try:
        from crewai import Agent
    except ImportError as e:
        raise ImportError("create_validator requires crewai; uv sync --extra model") from e
    return Agent(role=role, goal=goal, backstory=backstory, llm=_get_llm_config(), **kwargs)


def create_responder(
    role: str = "Responder",
    goal: str = "Format final answer for the user.",
    backstory: str = "Expert at clear communication.",
    **kwargs: Any,
):
    """Create Responder agent."""
    try:
        from crewai import Agent
    except ImportError as e:
        raise ImportError("create_responder requires crewai; uv sync --extra model") from e
    return Agent(role=role, goal=goal, backstory=backstory, llm=_get_llm_config(), **kwargs)


def create_retrieval_task(
    agent,
    description: str = "Search documents and return relevant context.",
    expected_output: str = "Relevant context excerpts.",
    **kwargs: Any,
):
    """Create RetrievalTask (search documents)."""
    try:
        from crewai import Task
    except ImportError as e:
        raise ImportError("create_retrieval_task requires crewai") from e
    logger.debug("RetrievalTask created", description=description[:50])
    return Task(description=description, agent=agent, expected_output=expected_output, **kwargs)


def create_analysis_task(
    agent,
    description: str = "Analyze the context and data.",
    expected_output: str = "Analysis results.",
    **kwargs: Any,
):
    """Create AnalysisTask (run computations/analysis)."""
    try:
        from crewai import Task
    except ImportError as e:
        raise ImportError("create_analysis_task requires crewai") from e
    return Task(description=description, agent=agent, expected_output=expected_output, **kwargs)


def create_validation_task(
    agent,
    description: str = "Validate the output against rules.",
    expected_output: str = "Validation result.",
    **kwargs: Any,
):
    """Create ValidationTask (check constraints)."""
    try:
        from crewai import Task
    except ImportError as e:
        raise ImportError("create_validation_task requires crewai") from e
    return Task(description=description, agent=agent, expected_output=expected_output, **kwargs)


def create_response_task(
    agent,
    description: str = "Format the final response.",
    expected_output: str = "User-facing answer.",
    **kwargs: Any,
):
    """Create ResponseTask (format final answer)."""
    try:
        from crewai import Task
    except ImportError as e:
        raise ImportError("create_response_task requires crewai") from e
    return Task(description=description, agent=agent, expected_output=expected_output, **kwargs)


def create_standard_crew(
    goal: str = "",
    system_prompt: str | None = None,
    verbose: bool = False,
    **agent_kwargs: Any,
):
    """StandardCrew: sequential retrieve → analyze → validate → respond.

    Args:
        goal: Overall crew goal (passed to agents/tasks).
        system_prompt: Optional system message override (reserved for future use).
        verbose: Crew verbosity.
        **agent_kwargs: Passed to agent constructors (roles, backstories).

    Returns:
        Crew instance; call .kickoff() or .crew_run() with inputs.
    """
    _ = system_prompt  # reserved for future LLM system message
    try:
        from crewai import Crew
    except ImportError as e:
        raise ImportError("create_standard_crew requires crewai; uv sync --extra model") from e
    retriever = create_retriever(**agent_kwargs.get("retriever", {}))
    analyst = create_analyst(**agent_kwargs.get("analyst", {}))
    validator = create_validator(**agent_kwargs.get("validator", {}))
    responder = create_responder(**agent_kwargs.get("responder", {}))
    t1 = create_retrieval_task(retriever, description=f"Retrieve context for: {goal or 'user request'}")
    t2 = create_analysis_task(analyst, description="Analyze the retrieved context.")
    t3 = create_validation_task(validator, description="Validate the analysis.")
    t4 = create_response_task(responder, description="Produce the final response.")
    logger.info("StandardCrew created", goal=goal[:50] if goal else "")
    return Crew(
        agents=[retriever, analyst, validator, responder],
        tasks=[t1, t2, t3, t4],
        verbose=verbose,
    )


def create_hierarchical_crew(
    goal: str = "",
    verbose: bool = False,
    manager_role: str = "Manager",
    manager_goal: str = "Delegate tasks to specialists and synthesize results.",
    **agent_kwargs: Any,
):
    """HierarchicalCrew: manager delegates to specialists (retriever, analyst, validator, responder).

    Args:
        goal: Overall goal.
        verbose: Crew verbosity.
        manager_role: Manager agent role.
        manager_goal: Manager agent goal.
        **agent_kwargs: Per-agent overrides.

    Returns:
        Crew instance with manager and specialist agents.
    """
    try:
        from crewai import Agent, Crew, Task
    except ImportError as e:
        raise ImportError("create_hierarchical_crew requires crewai; uv sync --extra model") from e
    manager = Agent(
        role=manager_role,
        goal=manager_goal,
        backstory="Coordinates specialists and synthesizes outputs.",
        llm=_get_llm_config(),
    )
    retriever = create_retriever(**agent_kwargs.get("retriever", {}))
    analyst = create_analyst(**agent_kwargs.get("analyst", {}))
    validator = create_validator(**agent_kwargs.get("validator", {}))
    responder = create_responder(**agent_kwargs.get("responder", {}))
    task_retrieve = create_retrieval_task(retriever, description=f"Retrieve: {goal or 'context'}")
    task_analyze = create_analysis_task(analyst)
    task_validate = create_validation_task(validator)
    task_respond = create_response_task(responder)
    manager_task = Task(
        description=f"Coordinate and synthesize results for: {goal or 'user request'}",
        agent=manager,
        expected_output="Final synthesized response.",
        context=[task_retrieve, task_analyze, task_validate, task_respond],
    )
    logger.info("HierarchicalCrew created", goal=goal[:50] if goal else "")
    return Crew(
        agents=[manager, retriever, analyst, validator, responder],
        tasks=[task_retrieve, task_analyze, task_validate, task_respond, manager_task],
        verbose=verbose,
    )


def create_crew(*, goal: str = "", verbose: bool = False, hierarchical: bool = False, **kwargs: Any):
    """Create Crew (standard or hierarchical). Returns object for .kickoff() / .crew_run()."""
    if hierarchical:
        return create_hierarchical_crew(goal=goal, verbose=verbose, **kwargs)
    return create_standard_crew(goal=goal, verbose=verbose, **kwargs)
