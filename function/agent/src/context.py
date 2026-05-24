"""Context engineering utilities: fetch, rerank, trim, and format prompt context."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import asyncio
import html
from dataclasses import dataclass
from typing import Any

from langchain_core.messages import BaseMessage
from loguru import logger

from .state import AgentState


@dataclass(frozen=True, slots=True)
class ContextChunk:
    kind: str
    content: str
    priority: int = 0
    metadata: dict[str, Any] | None = None


def estimate_tokens_litellm(model: str, text: str) -> int:
    """Estimate token count using LiteLLM, with a deterministic char fallback."""
    try:
        from litellm import token_counter

        return int(token_counter(model=model, messages=[{"role": "user", "content": text}]))
    except Exception as exc:  # noqa: BLE001
        logger.debug("token_counter fallback: {}", exc)
        return max(1, len(text) // 4)


def truncate_messages(
    messages: list[BaseMessage],
    *,
    model: str,
    max_tokens: int,
) -> list[BaseMessage]:
    """Keep newest messages under token budget while preserving order."""
    if not messages:
        return messages
    kept: list[BaseMessage] = []
    budget = 0
    for m in reversed(messages):
        cost = estimate_tokens_litellm(model, str(m.content))
        if budget + cost > max_tokens and kept:
            break
        kept.append(m)
        budget += cost
    return list(reversed(kept))


class ContextManager:
    """Asynchronous context aggregator for vector retrieval + simulation reports."""

    def __init__(
        self,
        *,
        model: str,
        max_context_tokens: int = 8_000,
        vector_fetcher: Any | None = None,
        simulation_fetcher: Any | None = None,
    ) -> None:
        self.model = model
        self.max_context_tokens = int(max_context_tokens)
        self._vector_fetcher = vector_fetcher
        self._simulation_fetcher = simulation_fetcher

    async def fetch_vector_context(self, query: str, limit: int = 5) -> list[dict[str, Any]]:
        """Fetch vector-retrieved snippets; auto-fallback to state context when absent."""
        if self._vector_fetcher is None:
            logger.debug("ContextManager.fetch_vector_context: no vector fetcher configured")
            return []
        try:
            if asyncio.iscoroutinefunction(self._vector_fetcher):
                rows = await self._vector_fetcher(query, limit=limit)
            else:
                rows = await asyncio.to_thread(self._vector_fetcher, query, limit)
            return list(rows or [])
        except Exception as exc:  # noqa: BLE001
            logger.warning("fetch_vector_context failed | err={!r}", exc)
            return []

    async def fetch_simulation_context(self, job_id: str) -> dict[str, Any]:
        """Fetch simulation summary by job id."""
        if self._simulation_fetcher is None:
            logger.debug("ContextManager.fetch_simulation_context: no simulation fetcher configured")
            return {}
        try:
            if asyncio.iscoroutinefunction(self._simulation_fetcher):
                out = await self._simulation_fetcher(job_id)
            else:
                out = await asyncio.to_thread(self._simulation_fetcher, job_id)
            return dict(out or {})
        except Exception as exc:  # noqa: BLE001
            logger.warning("fetch_simulation_context failed | job_id={} err={!r}", job_id, exc)
            return {}

    def rerank_placeholder(self, chunks: list[ContextChunk], state: AgentState) -> list[ContextChunk]:
        """Placeholder reranker: prefer chunks matching ``state.next_step`` in metadata."""
        step = str(state.get("next_step", "")).strip().lower()
        if not step:
            return sorted(chunks, key=lambda c: -c.priority)

        def _score(ch: ContextChunk) -> tuple[int, int]:
            md = ch.metadata or {}
            hint = str(md.get("step", "")).lower()
            bonus = 10 if hint == step else 0
            return (bonus + ch.priority, len(ch.content))

        return sorted(chunks, key=_score, reverse=True)

    def _trim_chunks(self, chunks: list[ContextChunk]) -> list[ContextChunk]:
        """Priority-aware trimming under context token budget."""
        used = 0
        kept: list[ContextChunk] = []
        for ch in sorted(chunks, key=lambda c: c.priority, reverse=True):
            cost = estimate_tokens_litellm(self.model, ch.content)
            if used + cost > self.max_context_tokens and kept:
                continue
            kept.append(ch)
            used += cost
        logger.info(
            "ContextManager trim | kept={} tokens={} max_tokens={} truncated={}",
            len(kept),
            used,
            self.max_context_tokens,
            max(0, len(chunks) - len(kept)),
        )
        return kept

    @staticmethod
    def format_as_markdown(chunks: list[ContextChunk]) -> str:
        """Render context in structured markdown blocks."""
        parts: list[str] = []
        for ch in chunks:
            title = ch.kind.replace("_", " ").title()
            parts.append(f"### {title}\n{ch.content.strip()}")
        return "\n\n".join(parts).strip()

    @staticmethod
    def format_as_xml(chunks: list[ContextChunk]) -> str:
        """Render context in tagged XML blocks for strict prompt parsing."""
        parts: list[str] = []
        for ch in chunks:
            tag = ch.kind.strip().lower() or "context"
            body = html.escape(ch.content.strip())
            parts.append(f"<{tag}>{body}</{tag}>")
        return "\n".join(parts).strip()

    async def get_system_context(
        self,
        state: AgentState,
        *,
        query: str,
        vector_limit: int = 5,
        format: str = "markdown",
    ) -> str:
        """Assemble final context block injected into the system prompt."""
        vector_rows = await self.fetch_vector_context(query, limit=vector_limit)

        simulation_payload: dict[str, Any] = {}
        meta = state.get("metadata", {})
        sim_job_id = meta.get("simulation_job_id")
        if isinstance(sim_job_id, str) and sim_job_id.strip():
            simulation_payload = await self.fetch_simulation_context(sim_job_id)

        chunks: list[ContextChunk] = []
        if vector_rows:
            for row in vector_rows:
                text = str(row.get("content") or row.get("text") or "").strip()
                if not text:
                    continue
                chunks.append(
                    ContextChunk(
                        kind="code_snippet",
                        content=text,
                        priority=int(row.get("priority", 20)),
                        metadata={"source": row.get("source", "vector"), "step": row.get("step")},
                    ),
                )
        if simulation_payload:
            chunks.append(
                ContextChunk(
                    kind="simulation_report",
                    content=str(simulation_payload),
                    priority=90,
                    metadata={"source": "simulation", "step": "simulating"},
                ),
            )

        # Inject user/session metadata when available.
        if meta:
            chunks.append(
                ContextChunk(
                    kind="user_metadata",
                    content=str(meta),
                    priority=70,
                    metadata={"source": "state.metadata"},
                ),
            )

        reranked = self.rerank_placeholder(chunks, state)
        trimmed = self._trim_chunks(reranked)
        if format.strip().lower() == "xml":
            block = self.format_as_xml(trimmed)
        else:
            block = self.format_as_markdown(trimmed)

        logger.info(
            "ContextManager.get_system_context | chunks={} format={} chars={}",
            len(trimmed),
            format,
            len(block),
        )
        return block


__all__ = [
    "ContextChunk",
    "ContextManager",
    "estimate_tokens_litellm",
    "truncate_messages",
]
