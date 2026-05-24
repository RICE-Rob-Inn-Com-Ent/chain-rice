"""Structured prompt system for SAGE persona, context injection, and strict output control."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from string import Template
from typing import Any

from .state import AgentState, get_combined_context
from .typed import AgentRole

SAGE_SYSTEM_PROMPT = """\
You are SAGE, a high-performance system architect operating under the .rice philosophy.

Core principles:
- Optimize for performance, safety (type-safety), correctness, and modularity.
- Prefer deterministic, inspectable, production-grade solutions.
- Minimize conversational filler; output technical execution directly.

Role stack:
- SAGE: Python, Mojo, Go, Elixir (systems orchestration, simulation, workflow glue)
- SMITH: Rust, Zig (low-level performance paths)
- CLERK: Haskell (formal correctness, proof-oriented logic)
- BARD: Odin, Dart, UI/UX (front-end and interaction systems)
- MASON: CUE (configuration schemas and contracts)

Execution directives:
- Use context blocks as source-of-truth.
- Explicitly state assumptions when data is incomplete.
- Prefer composable interfaces and strict schemas.
"""

CONTEXT_BLOCK = """\
<documentation>
{content}
</documentation>
"""

SIMULATION_BLOCK = """\
<simulation_report>
{content}
</simulation_report>
"""

ERROR_RECOVERY_BLOCK = """\
<error_recovery>
- error: {error}
- last_successful_step: {last_step}
- recovery_plan: {recovery_plan}
</error_recovery>
"""

STRICT_MODE_BLOCK = """\
<strict_mode>
Return only valid JSON that matches the requested schema.
Do not add markdown fences, commentary, or extra keys.
</strict_mode>
"""

ROLE_PROMPTS: dict[AgentRole, str] = {
    AgentRole.ARCHITECT: "Prioritize system boundaries, interfaces, reliability, and long-term maintainability.",
    AgentRole.CODER: "Produce implementation-ready details, concrete APIs, and testable steps.",
    AgentRole.SCIENTIST: "Prioritize modeling assumptions, numerical stability, and experiment design.",
    AgentRole.CRITIC: "Prioritize risk analysis, failure modes, and verification strategy.",
}


def sage_system_prompt() -> str:
    """Return the base SAGE system prompt."""
    return SAGE_SYSTEM_PROMPT.strip()


def render_template(tpl: str, mapping: dict[str, Any]) -> str:
    """Bezpieczny `string.Template` (identyfikatory `$name` / `${name}`)."""
    return Template(tpl).safe_substitute(mapping)


def few_shot_block(examples: list[tuple[str, str]]) -> str:
    """Buduje blok few-shot z par (user, assistant)."""
    parts: list[str] = []
    for u, a in examples:
        parts.append(f"User: {u}\nAssistant: {a}")
    return "\n\n".join(parts)


def wrap_xml(tag: str, content: str) -> str:
    """Wrap arbitrary content in a lightweight XML tag."""
    t = tag.strip().lower() or "block"
    return f"<{t}>\n{content.strip()}\n</{t}>"


def sage_tools_catalog_block() -> str:
    """Lista narzędzi .rice dla rozszerzenia system promptu (ToolDiscovery)."""
    from .tools import ToolDiscovery

    return wrap_xml("available_tools", ToolDiscovery.catalog_plain())


def format_prompt(
    state: AgentState,
    *,
    role: AgentRole = AgentRole.ARCHITECT,
    strict_mode: bool = False,
    extra_context: str | None = None,
    include_tools_catalog: bool = False,
) -> str:
    """Assemble the final system prompt from role + state context + optional strict mode."""
    sections: list[str] = [sage_system_prompt()]

    role_block = ROLE_PROMPTS.get(role, ROLE_PROMPTS[AgentRole.ARCHITECT])
    sections.append(wrap_xml("thought_process", role_block))

    if include_tools_catalog:
        sections.append(sage_tools_catalog_block())

    context_text = get_combined_context(state)
    if context_text:
        sections.append(CONTEXT_BLOCK.format(content=context_text))

    sim = state.get("simulation_results", {})
    if sim:
        sections.append(SIMULATION_BLOCK.format(content=str(sim)))

    if extra_context:
        sections.append(wrap_xml("action_plan", extra_context))

    if strict_mode:
        sections.append(STRICT_MODE_BLOCK)

    # Keep instruction against filler at the end as an always-on reminder.
    sections.append(
        "Instruction: avoid conversational filler; respond with direct technical execution."
    )
    return "\n\n".join(s.strip() for s in sections if s and s.strip())


__all__ = [
    "CONTEXT_BLOCK",
    "ERROR_RECOVERY_BLOCK",
    "ROLE_PROMPTS",
    "SAGE_SYSTEM_PROMPT",
    "SIMULATION_BLOCK",
    "STRICT_MODE_BLOCK",
    "few_shot_block",
    "format_prompt",
    "render_template",
    "sage_system_prompt",
    "sage_tools_catalog_block",
    "wrap_xml",
]
