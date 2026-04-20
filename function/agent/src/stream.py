"""LangGraph + LiteLLM — strumieniowanie odpowiedzi, callbacki tokenów, SSE."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import json
from collections.abc import AsyncIterator
from typing import Any

from loguru import logger

# TODO:
# [ ] implement async streaming via LiteLLM acompletion(stream=True):
# [ ]     yield chunks as they arrive — do not buffer full response
# [ ] implement LangGraph streaming:
# [ ]     graph.astream(input, config, stream_mode=["values","updates","messages"])
# [ ]     stream_mode from RICE_STREAM_MODE env var
# [ ] implement NATS streaming output:
# [ ]     publish each chunk to NATS subject stream.sage.{session_id}
# [ ]     subscribers: BARD browser (WebSocket), CHIEF compiler
# [ ] implement token usage streaming:
# [ ]     emit OTel metric per chunk: sage.stream.tokens_per_second
# [ ] implement interrupt handling:
# [ ]     on KeyboardInterrupt → cancel astream, publish cancel event to NATS
# [ ]     on timeout → cancel after RICE_STREAM_TIMEOUT_S seconds


async def astream_graph_updates(
    compiled: Any,
    state: dict[str, Any],
    config: dict[str, Any] | None = None,
) -> AsyncIterator[dict[str, Any]]:
    """Yields kolejne stany z `compiled.astream` (tryb `values`)."""
    cfg = config or {}
    async for chunk in compiled.astream(state, cfg, stream_mode="values"):
        yield chunk


async def astream_events_sse(
    compiled: Any,
    state: dict[str, Any],
    config: dict[str, Any] | None = None,
) -> AsyncIterator[str]:
    """Async generator linii SSE (`data: ...\\n\\n`) z `astream_events` v2."""
    cfg = config or {}
    try:
        async for ev in compiled.astream_events(state, cfg, version="v2"):
            payload = json.dumps(ev, default=str)
            yield f"data: {payload}\n\n"
    except TypeError:
        logger.warning("astream_events(version=v2) unavailable — falling back to astream")
        async for chunk in astream_graph_updates(compiled, state, cfg):
            payload = json.dumps({"values": chunk}, default=str)
            yield f"data: {payload}\n\n"


def format_sse(data: dict[str, Any]) -> str:
    """Pojedyncza ramka SSE z JSON."""
    return f"data: {json.dumps(data, default=str)}\n\n"
