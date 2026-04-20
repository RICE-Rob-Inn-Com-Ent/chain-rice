"""Wspólne szablony promptów — system, few-shot, warianty workflow."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from string import Template
from typing import Any

# TODO:
# [ ] implement prompt registry: load templates from infra/configs/prompts/*.cue
# [ ]     template path from RICE_PROMPT_DIR env var
# [ ] implement role system prompt loader: per-role MDC → system prompt
# [ ]     reads .cursor/rules/{role}.mdc, strips MDC frontmatter
# [ ] implement project context injector: inject custom/{project}/*.rice manifest
# [ ]     into system prompt when rice cook is active
# [ ] implement few-shot example loader: load examples from function/model/datasets/
# [ ]     dataset path from RICE_DATASET_DIR env var
# [ ] implement prompt compression: truncate + summarize when > token limit
# [ ]     limit from RICE_PROMPT_MAX_TOKENS env var
# [ ] implement prompt versioning: track which prompt version produced which output
# [ ]     store version hash in OTel span attributes
# [ ] use minijinja (via subprocess to base/mint/) for template rendering
# [ ]     fallback to Python string.Template if mint not available


def sage_system_prompt() -> str:
    """Domyślna tożsamość agenta SAGE (bez danych projektowych — uzupełnia CHIEF przez .rice)."""
    return (
        "You are SAGE, a careful assistant. "
        "Use tools when they improve correctness. "
        "If uncertain, say so briefly."
    )


def render_template(tpl: str, mapping: dict[str, Any]) -> str:
    """Bezpieczny `string.Template` (identyfikatory `$name` / `${name}`)."""
    return Template(tpl).safe_substitute(mapping)


def few_shot_block(examples: list[tuple[str, str]]) -> str:
    """Buduje blok few-shot z par (user, assistant)."""
    parts: list[str] = []
    for u, a in examples:
        parts.append(f"User: {u}\nAssistant: {a}")
    return "\n\n".join(parts)
