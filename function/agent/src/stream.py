"""Real-time streaming primitives for SAGE (tokens, graph events, SSE/WebSocket mux)."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when MASON wires; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import asyncio
import json
import os
import time
from collections.abc import AsyncIterator, Callable
from typing import Any

from helper import logger

from .retry import MaxRetriesExceeded, UserInterventionRequired
from .typed import RiceEvent

_HEARTBEAT_INTERVAL_S = float(os.getenv("RICE_STREAM_HEARTBEAT_S", "5.0"))
_STREAM_TIMEOUT_S = float(os.getenv("RICE_STREAM_TIMEOUT_S", "120.0"))


def _now() -> float:
    return time.time()


def _utf8_clean(text: str) -> str:
    return text.encode("utf-8", errors="replace").decode("utf-8", errors="replace")


def _to_event(
    *,
    event_type: str,
    content: str | None = None,
    node: str | None = None,
    payload: dict[str, Any] | None = None,
) -> RiceEvent:
    return RiceEvent(
        type=event_type,  # type: ignore[arg-type]
        ts=_now(),
        content=_utf8_clean(content or "") if content is not None else None,
        node=node,
        payload=payload or {},
    )


def record_stream_chunk(
    metadata: dict[str, Any],
    *,
    node: str,
    chunk: str,
    phase: str = "token",
) -> None:
    """Zapisuje fragment wyjścia LLM pod SSE / astream (``metadata`` mutowane in-place)."""
    events = metadata.setdefault("_sage_stream_events", [])
    events.append(
        {
            "ts": time.time(),
            "node": node,
            "phase": phase,
            "chunk": chunk,
        },
    )


async def stream_text(response: Any) -> AsyncIterator[RiceEvent]:
    """Yield token delta events from LiteLLM streaming response."""
    t0 = time.perf_counter()
    n = 0
    thought_mode = False
    tag_open = "<thought_process>"
    tag_close = "</thought_process>"
    try:
        async for chunk in response:
            delta = ""
            try:
                choices = getattr(chunk, "choices", None) or (
                    chunk.get("choices", []) if isinstance(chunk, dict) else []
                )
                if choices:
                    c0 = choices[0]
                    d = getattr(c0, "delta", None) or (
                        c0.get("delta", {}) if isinstance(c0, dict) else None
                    )
                    if d is not None:
                        delta = str(
                            getattr(d, "content", None)
                            or (d.get("content") if isinstance(d, dict) else "")
                            or "",
                        )
            except Exception:  # noqa: BLE001
                delta = ""
            if not delta:
                continue
            clean = _utf8_clean(delta)
            n += 1

            # Contextual streaming for thought tags in dedicated block.
            if tag_open in clean:
                thought_mode = True
            if tag_close in clean:
                # emit and then close mode
                yield _to_event(
                    event_type="thought_token" if thought_mode else "token",
                    content=clean,
                )
                thought_mode = False
                continue

            yield _to_event(
                event_type="thought_token" if thought_mode else "token",
                content=clean,
            )
        yield _to_event(event_type="done", payload={"kind": "text", "chunks": n})
        dt_ms = (time.perf_counter() - t0) * 1000.0
        logger.info("stream_text completed | chunks={} latency_ms={:.2f}", n, dt_ms)
    except (ConnectionError, asyncio.TimeoutError) as exc:
        logger.warning("stream_text interrupted | err={!r}", exc)
        yield _to_event(
            event_type="error",
            content=str(exc),
            payload={"source": "stream_text", "recoverable": True},
        )
    except Exception as exc:  # noqa: BLE001
        logger.exception("stream_text failed | err={!r}", exc)
        yield _to_event(
            event_type="error",
            content=str(exc),
            payload={"source": "stream_text"},
        )


async def stream_graph_updates(
    graph: Any,
    input_data: dict[str, Any],
    config: dict[str, Any] | None = None,
) -> AsyncIterator[RiceEvent]:
    """Yield LangGraph runtime updates as typed ``RiceEvent`` objects."""
    cfg = config or {}
    stream_mode = os.getenv("RICE_STREAM_MODE", "updates")
    t0 = time.perf_counter()
    n = 0
    try:
        async for chunk in graph.astream(input_data, cfg, stream_mode=stream_mode):
            n += 1
            payload = chunk if isinstance(chunk, dict) else {"value": str(chunk)}
            node = None
            if isinstance(payload, dict):
                node = str(payload.get("node") or payload.get("name") or "") or None
            yield _to_event(event_type="graph", node=node, payload=payload)
        dt_ms = (time.perf_counter() - t0) * 1000.0
        logger.info("stream_graph_updates completed | events={} latency_ms={:.2f}", n, dt_ms)
        yield _to_event(event_type="done", payload={"kind": "graph", "events": n})
    except (ConnectionError, asyncio.TimeoutError) as exc:
        logger.warning("stream_graph_updates interrupted | err={!r}", exc)
        yield _to_event(
            event_type="error",
            content=str(exc),
            payload={"source": "graph", "recoverable": True},
        )
    except Exception as exc:  # noqa: BLE001
        logger.exception("stream_graph_updates failed | err={!r}", exc)
        yield _to_event(event_type="error", content=str(exc), payload={"source": "graph"})


async def astream_graph_updates(
    compiled: Any,
    state: dict[str, Any],
    config: dict[str, Any] | None = None,
) -> AsyncIterator[dict[str, Any]]:
    """Backward-compatible wrapper yielding raw graph payload dicts."""
    async for ev in stream_graph_updates(compiled, state, config):
        yield ev.model_dump(mode="json")


async def astream_events_sse(
    compiled: Any,
    state: dict[str, Any],
    config: dict[str, Any] | None = None,
) -> AsyncIterator[str]:
    """Async generator linii SSE (`data: ...\\n\\n`) z `astream_events` v2."""
    cfg = config or {}
    try:
        async for ev in compiled.astream_events(state, cfg, version="v2"):
            payload = json.dumps(ev, default=str, ensure_ascii=False)
            yield f"data: {payload}\n\n"
    except TypeError:
        logger.warning("astream_events(version=v2) unavailable — falling back to astream")
        async for chunk in stream_graph_updates(compiled, state, cfg):
            payload = json.dumps(chunk.model_dump(mode="json"), default=str, ensure_ascii=False)
            yield f"data: {payload}\n\n"
    except Exception as exc:  # noqa: BLE001
        ev = _to_event(event_type="error", content=str(exc), payload={"source": "astream_events_sse"})
        yield format_sse(ev.model_dump(mode="json"))


def format_sse(data: dict[str, Any]) -> str:
    """Pojedyncza ramka SSE z JSON."""
    return f"data: {json.dumps(data, default=str, ensure_ascii=False)}\n\n"


def stream_events_from_metadata(metadata: dict[str, Any]) -> list[dict[str, Any]]:
    """Zwraca skopiowaną listę zdarzeń zebranych przez :func:`record_stream_chunk`."""
    raw = metadata.get("_sage_stream_events")
    return list(raw) if isinstance(raw, list) else []


def attach_stream_sink(
    metadata: dict[str, Any],
    sink: Callable[[dict[str, Any]], None] | None,
) -> None:
    """Opcjonalny callback (np. format SSE) — wywoływany przez węzły przy każdym chunku."""
    if sink is not None:
        metadata["_sage_stream_sink"] = sink


async def _heartbeat_stream(
    *,
    interval_s: float = _HEARTBEAT_INTERVAL_S,
    stop_event: asyncio.Event,
) -> AsyncIterator[RiceEvent]:
    while not stop_event.is_set():
        await asyncio.sleep(max(0.25, interval_s))
        if stop_event.is_set():
            break
        yield _to_event(event_type="heartbeat", payload={"interval_s": interval_s})


async def stream_multiplexer(
    *,
    text_stream: AsyncIterator[RiceEvent] | None = None,
    graph_stream: AsyncIterator[RiceEvent] | None = None,
    include_heartbeat: bool = True,
    heartbeat_interval_s: float = _HEARTBEAT_INTERVAL_S,
    timeout_s: float = _STREAM_TIMEOUT_S,
) -> AsyncIterator[RiceEvent]:
    """Combine token + graph + heartbeat streams into a single async channel."""
    stop = asyncio.Event()
    queue: asyncio.Queue[RiceEvent] = asyncio.Queue(maxsize=512)

    async def _pump(it: AsyncIterator[RiceEvent], label: str) -> None:
        try:
            async for ev in it:
                await queue.put(ev)
        except (MaxRetriesExceeded, UserInterventionRequired) as exc:
            await queue.put(
                _to_event(
                    event_type="reset",
                    content=f"{label} reset: {exc}",
                    payload={"source": label, "reason": _utf8_clean(str(exc))},
                ),
            )
        except Exception as exc:  # noqa: BLE001
            await queue.put(
                _to_event(
                    event_type="error",
                    content=str(exc),
                    payload={"source": label},
                ),
            )

    tasks: list[asyncio.Task[Any]] = []
    if text_stream is not None:
        tasks.append(asyncio.create_task(_pump(text_stream, "text")))
    if graph_stream is not None:
        tasks.append(asyncio.create_task(_pump(graph_stream, "graph")))
    if include_heartbeat:
        tasks.append(
            asyncio.create_task(_pump(_heartbeat_stream(interval_s=heartbeat_interval_s, stop_event=stop), "heartbeat")),
        )

    t0 = time.perf_counter()
    emitted = 0
    try:
        while True:
            if tasks and all(t.done() for t in tasks) and queue.empty():
                break
            try:
                ev = await asyncio.wait_for(queue.get(), timeout=timeout_s)
            except asyncio.TimeoutError:
                yield _to_event(
                    event_type="error",
                    content="stream timeout",
                    payload={"source": "multiplexer", "timeout_s": timeout_s},
                )
                break
            emitted += 1
            yield ev
    except asyncio.CancelledError:
        yield _to_event(event_type="error", content="stream cancelled", payload={"source": "multiplexer"})
        raise
    finally:
        stop.set()
        for t in tasks:
            t.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        dt_ms = (time.perf_counter() - t0) * 1000.0
        logger.info("stream_multiplexer done | events={} latency_ms={:.2f}", emitted, dt_ms)


__all__ = [
    "astream_events_sse",
    "astream_graph_updates",
    "stream_graph_updates",
    "attach_stream_sink",
    "format_sse",
    "record_stream_chunk",
    "stream_multiplexer",
    "stream_events_from_metadata",
    "stream_text",
]
