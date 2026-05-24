"""Public API for the SAGE agent module.

Primary entry points:
- ``ask_sage(prompt, session_id)`` for one-shot async calls returning final text.
- ``chat_sage(prompt, session_id)`` for incremental async UI streaming.
"""

from __future__ import annotations

import os
from collections.abc import AsyncIterator
from typing import Any

from helper import logger

from .graph import ainvoke_sage, graph, invoke_sage
from .guard import build_rice_guard
from .memory import build_memory_saver, get_thread_config
from .state import AgentState
from .stream import stream_graph_updates, stream_text
from .typed import AgentRole, RiceMessage

__version__ = "0.1.0"


def _extract_final_text(result: dict[str, Any]) -> str:
    msgs = list(result.get("messages", []))
    if not msgs:
        return ""
    last = msgs[-1]
    if isinstance(last, dict):
        return str(last.get("content") or "")
    return str(getattr(last, "content", "") or "")


async def ask_sage(prompt: str, session_id: str = "default") -> str:
    """Run SAGE once and return final assistant text.

    This is the preferred high-level API for non-streaming workflows.
    """
    cfg = get_thread_config(session_id)
    out = await ainvoke_sage(prompt, config=cfg)
    return _extract_final_text(out)


async def chat_sage(prompt: str, session_id: str = "default") -> AsyncIterator[str]:
    """Stream user-facing chunks for UI chat surfaces.

    Yields UTF-8 safe text snippets. Primarily streams graph updates and extracts
    assistant content deltas from message payloads.
    """
    cfg = get_thread_config(session_id)
    state: AgentState = {
        "messages": [{"role": "user", "content": prompt}],
        "context": {},
        "simulation_results": {},
        "next_step": "reasoning",
        "metadata": {},
        "status": "thinking",
    }
    last_seen = ""
    async for ev in stream_graph_updates(graph, state, cfg):
        if ev.type == "error":
            yield f"[stream-error] {ev.content or 'unknown'}"
            continue
        if ev.type != "graph":
            continue
        payload = ev.payload
        msgs = payload.get("messages", []) if isinstance(payload, dict) else []
        if not isinstance(msgs, list) or not msgs:
            continue
        m = msgs[-1]
        content = ""
        if isinstance(m, dict):
            content = str(m.get("content") or "")
        else:
            content = str(getattr(m, "content", "") or "")
        if not content:
            continue
        if content.startswith(last_seen):
            delta = content[len(last_seen) :]
        else:
            delta = content
        if delta:
            yield delta
        last_seen = content


def _check_environment() -> None:
    keys = (
        "LITELLM_API_KEY",
        "OPENAI_API_KEY",
        "ANTHROPIC_API_KEY",
    )
    if not any(os.getenv(k) for k in keys):
        logger.warning(
            "SAGE init warning: no API key found in {}. "
            "Local backends may still work if configured via api_base.",
            keys,
        )


# Eager subsystem init for operational readiness.
_MEMORY_SAVER = build_memory_saver()
try:
    _RICE_GUARD = build_rice_guard()
except Exception as exc:  # noqa: BLE001
    _RICE_GUARD = None
    logger.warning("SAGE init warning: guard bootstrap failed | err={!r}", exc)
_check_environment()
logger.info(
    "SAGE Agent Core v0.1.0 initialized. Logic: LangGraph | Safety: Guardrails | Performance: LiteLLM.",
)

__all__ = [
    "__version__",
    "AgentRole",
    "AgentState",
    "RiceMessage",
    "ask_sage",
    "chat_sage",
    "graph",
    "invoke_sage",
    "stream_graph_updates",
    "stream_text",
]
