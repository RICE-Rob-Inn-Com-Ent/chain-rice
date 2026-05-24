"""LangGraph — węzły SAGE: rozumowanie, narzędzia, research, odpowiedź (LiteLLM + śledzenie)."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import functools
import inspect
import json
import os
import time
import uuid
from collections.abc import Awaitable, Callable
from typing import Any, ParamSpec, TypeVar

from helper import logger
from langchain_core.messages import AIMessage, BaseMessage, HumanMessage, SystemMessage, ToolMessage
from langchain_core.messages import convert_to_openai_messages
from langchain_core.utils.function_calling import convert_to_openai_tool

from .prompt import format_prompt, wrap_xml
from .retry import async_llm_retry
from .router import SageRouter
from .state import SageAgentState, log_state_transition
from .stream import record_stream_chunk
from .typed import AgentRole, RiceMessage, ToolResult

P = ParamSpec("P")
R = TypeVar("R")

_SIM_TOOL_NAMES = frozenset({"run_quantum_simulation", "analyze_physics"})
_CTX_TOOL_NAMES = frozenset({"search_memory", "read_code"})

_DEFAULT_LLM_TIMEOUT_S = float(os.getenv("RICE_LLM_TIMEOUT_S", "120"))
_DEFAULT_NODE_RETRIES = int(os.getenv("RICE_NODE_MAX_RETRIES", "3"))
_DEFAULT_ROUTER = SageRouter()


def node_timer(node_name: str) -> Callable[[Callable[P, Awaitable[R]]], Callable[P, Awaitable[R]]]:
    """Dekorator mierzący czas wykonania węzła async (entry/exit w logach)."""

    def _decorator(fn: Callable[P, Awaitable[R]]) -> Callable[P, Awaitable[R]]:
        @functools.wraps(fn)
        async def _wrapped(*args: P.args, **kwargs: P.kwargs) -> R:
            t0 = time.perf_counter()
            logger.info("sage.node.enter | node={}", node_name)
            try:
                return await fn(*args, **kwargs)
            finally:
                dt_ms = (time.perf_counter() - t0) * 1000.0
                logger.info("sage.node.exit | node={} elapsed_ms={:.2f}", node_name, dt_ms)

        return _wrapped

    return _decorator


def _metadata_copy(state: SageAgentState) -> dict[str, Any]:
    return dict(state.get("metadata") or {})


def _failure_update(
    state: SageAgentState,
    *,
    node: str,
    exc: BaseException,
    max_retries: int = _DEFAULT_NODE_RETRIES,
) -> dict[str, Any]:
    md = _metadata_copy(state)
    n = int(md.get("node_retry_count", 0)) + 1
    md["node_retry_count"] = n
    md["last_node_error"] = str(exc)
    md["last_failed_node"] = node
    retry_ok = n <= max_retries
    md["retry_requested"] = retry_ok
    recovery = (
        f"Retry from {node} (attempt {n}/{max_retries})."
        if retry_ok
        else "Max node retries exceeded; escalate or end."
    )
    err_msg = wrap_xml(
        "error_recovery",
        f"node={node}\nerror={exc!s}\nrecovery={recovery}",
    )
    rice = RiceMessage(role="assistant", content=err_msg, metadata={"node": node, "failed": True})
    return {
        "messages": [rice_message_to_base_message(rice)],
        "metadata": md,
        "next_step": "retry" if retry_ok else "abort",
        "status": "idle",
    }


def rice_message_to_base_message(rm: RiceMessage) -> BaseMessage:
    """Mapowanie kontraktu SAGE na typy LangChain (``add_messages`` w grafie)."""
    role = rm.role
    if role == "system":
        return SystemMessage(content=rm.content or "")
    if role == "user":
        return HumanMessage(content=rm.content or "")
    if role == "tool":
        return ToolMessage(
            content=rm.content or "",
            tool_call_id=rm.tool_call_id or "",
            name=rm.name or "",
        )
    tcs = list(rm.tool_calls or [])
    lc_calls: list[dict[str, Any]] = []
    for tc in tcs:
        lc_calls.append(
            {
                "name": tc.name,
                "args": dict(tc.arguments),
                "id": tc.id,
                "type": "tool_call",
            },
        )
    return AIMessage(content=rm.content or "", tool_calls=lc_calls or [])


def state_messages_to_lc(msgs: list[Any]) -> list[BaseMessage]:
    """Normalizacja historii do listy :class:`BaseMessage` dla LiteLLM."""
    out: list[BaseMessage] = []
    for m in msgs:
        if isinstance(m, BaseMessage):
            out.append(m)
            continue
        if isinstance(m, RiceMessage):
            out.append(rice_message_to_base_message(m))
            continue
        if isinstance(m, dict):
            role = str(m.get("role", "user"))
            content = m.get("content")
            if role == "assistant":
                out.append(
                    AIMessage(
                        content=str(content or ""),
                        tool_calls=list(m.get("tool_calls") or []),
                    ),
                )
            elif role == "tool":
                out.append(
                    ToolMessage(
                        content=str(content or ""),
                        tool_call_id=str(m.get("tool_call_id") or ""),
                        name=str(m.get("name") or ""),
                    ),
                )
            elif role == "system":
                out.append(SystemMessage(content=str(content or "")))
            else:
                out.append(HumanMessage(content=str(content or "")))
    return out


def _choice_to_ai_message(choice: Any) -> AIMessage:
    """Mapuje `choices[0]` z odpowiedzi LiteLLM/OpenAI na `AIMessage`."""
    m = choice.message
    content = m.content or ""
    raw = getattr(m, "tool_calls", None)
    if not raw:
        return AIMessage(content=content)
    tool_calls: list[dict[str, Any]] = []
    for tc in raw:
        fn = getattr(tc, "function", None)
        if fn is None and isinstance(tc, dict):
            fn = tc.get("function", {})
        if fn is None:
            continue
        name = getattr(fn, "name", None) or (fn.get("name") if isinstance(fn, dict) else None)
        args_raw = getattr(fn, "arguments", None) or (
            fn.get("arguments", "{}") if isinstance(fn, dict) else "{}"
        )
        tid = getattr(tc, "id", None) or (tc.get("id") if isinstance(tc, dict) else "")
        if isinstance(args_raw, str):
            args_dict: Any = json.loads(args_raw or "{}")
        else:
            args_dict = args_raw
        tool_calls.append({"id": tid, "name": name, "args": args_dict, "type": "tool_call"})
    return AIMessage(content=content, tool_calls=tool_calls)


def tools_to_litellm_schema(tools: list[Any]) -> list[dict[str, Any]]:
    """Konwertuje narzędzia LangChain na listę `tools` dla LiteLLM."""
    out: list[dict[str, Any]] = []
    for t in tools:
        fn = convert_to_openai_tool(t)
        out.append({"type": "function", "function": fn})
    return out


def _emit_stream(metadata: dict[str, Any], *, node: str, chunk: str) -> None:
    record_stream_chunk(metadata, node=node, chunk=chunk)
    sink = metadata.get("_sage_stream_sink")
    if callable(sink):
        sink({"node": node, "chunk": chunk})


async def call_model(
    router: SageRouter,
    *,
    model: str,
    messages: list[dict[str, Any]],
    tools: list[dict[str, Any]] | None = None,
    stream: bool = False,
    timeout_s: float | None = None,
    metadata: dict[str, Any] | None = None,
    stream_node: str = "call_model",
) -> Any:
    """Wywołanie LiteLLM przez router — timeout, retry (``async_llm_retry``), opcjonalny stream."""
    timeout = float(timeout_s if timeout_s is not None else _DEFAULT_LLM_TIMEOUT_S)
    md = metadata or {}

    @async_llm_retry(max_attempts=3, min_wait=1.0, max_wait=8.0)
    async def _once() -> Any:
        kwargs: dict[str, Any] = {
            "model": model,
            "messages": messages,
            "timeout": timeout,
        }
        if tools:
            kwargs["tools"] = tools
        if stream:
            kwargs["stream"] = True
            return await router.acompletion(**kwargs)
        return await router.acompletion(**kwargs)

    response = await _once()

    if stream and response is not None and (
        inspect.isasyncgen(response) or hasattr(response, "__aiter__")
    ):
        parts: list[str] = []
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
                        delta = str(getattr(d, "content", None) or (d.get("content") if isinstance(d, dict) else "") or "")
            except Exception:  # noqa: BLE001 — agregacja streamu best-effort
                delta = ""
            if delta:
                parts.append(delta)
                _emit_stream(md, node=stream_node, chunk=delta)
        text = "".join(parts)
        return _synthetic_response_from_text(text)

    if stream and metadata is not None:
        text = _extract_message_text(response)
        if text:
            _emit_stream(md, node=stream_node, chunk=text)

    return response


def _extract_message_text(response: Any) -> str:
    try:
        ch0 = response.choices[0]
        m = ch0.message
        return str(m.content or "")
    except Exception:
        return ""


def _synthetic_response_from_text(text: str) -> Any:
    """Minimalna struktura jak odpowiedź chat, gdy agregujemy stream ręcznie."""

    class _Msg:
        content = text

    class _Choice:
        message = _Msg()

    class _Resp:
        choices = [_Choice()]

    return _Resp()


def _build_router_messages(
    state: SageAgentState,
    *,
    role: AgentRole,
    include_tools_catalog: bool,
    tail: int = 40,
) -> list[dict[str, Any]]:
    system = format_prompt(
        state,
        role=role,
        strict_mode=False,
        include_tools_catalog=include_tools_catalog,
    )
    lc = state_messages_to_lc(list(state.get("messages", []))[-tail:])
    oai = convert_to_openai_messages(lc)
    return [{"role": "system", "content": system}, *oai]


def _last_ai_message(msgs: list[Any]) -> AIMessage | None:
    for m in reversed(msgs):
        if isinstance(m, AIMessage):
            return m
        if isinstance(m, dict) and m.get("role") == "assistant":
            return AIMessage(
                content=str(m.get("content") or ""),
                tool_calls=list(m.get("tool_calls") or []),
            )
    return None


def _tool_result_to_rice(tr: ToolResult) -> RiceMessage:
    return RiceMessage(
        role="tool",
        content=tr.content,
        tool_call_id=tr.tool_call_id,
        name=tr.name,
        metadata={"is_error": tr.is_error, **tr.metadata},
    )


def _merge_context(state: SageAgentState, key: str, value: Any) -> dict[str, Any]:
    ctx = dict(state.get("context") or {})
    ctx[key] = value
    return ctx


def _merge_simulation(state: SageAgentState, key: str, value: Any) -> dict[str, Any] | list[Any]:
    cur = state.get("simulation_results")
    if isinstance(cur, dict):
        out = dict(cur)
        out[key] = value
        return out
    if isinstance(cur, list):
        return [*cur, {"key": key, "value": value}]
    return {key: value}


def _route_tool_artifact(name: str, tr: ToolResult) -> tuple[str, str, Any] | None:
    if name in _SIM_TOOL_NAMES:
        return "sim", name, tr.model_dump(mode="json")
    if name in _CTX_TOOL_NAMES:
        return "ctx", name, tr.content
    return None


async def _invoke_langchain_tool(tools: list[Any], name: str, args: dict[str, Any]) -> str:
    for t in tools:
        tname = getattr(t, "name", None)
        if tname != name:
            continue
        if hasattr(t, "ainvoke"):
            return str(await t.ainvoke(args))
        if hasattr(t, "invoke"):
            return str(t.invoke(args))
    raise KeyError(f"tool not found: {name}")


def make_reasoning_node(
    router: SageRouter,
    tools: list[Any],
    *,
    include_tools_catalog: bool = True,
) -> Callable[[SageAgentState], Awaitable[dict[str, Any]]]:
    """Węzeł REASONER: ``format_prompt`` + LiteLLM + tag ``<thought_process>`` w treści asystenta."""

    tool_schemas = tools_to_litellm_schema(tools)

    @node_timer("reasoning")
    async def reasoning_node(state: SageAgentState) -> dict[str, Any]:
        md = _metadata_copy(state)
        try:
            model = str(state.get("model") or router.default_route)
            stream = bool(md.get("stream", False))
            oai = _build_router_messages(
                state,
                role=AgentRole.ARCHITECT,
                include_tools_catalog=include_tools_catalog,
            )
            resp = await call_model(
                router,
                model=model,
                messages=oai,
                tools=tool_schemas,
                stream=stream,
                metadata=md,
                stream_node="reasoning",
            )
            choice = resp.choices[0]
            raw_ai = _choice_to_ai_message(choice)
            body = (raw_ai.content or "").strip()
            wrapped = (
                f"<thought_process>\n{body or '—'}\n</thought_process>"
                if body or raw_ai.tool_calls
                else "<thought_process>\n—\n</thought_process>"
            )
            rice_tool_calls: list[dict[str, Any]] = []
            for tc in list(raw_ai.tool_calls or []):
                if not isinstance(tc, dict):
                    continue
                rice_tool_calls.append(
                    {
                        "id": str(tc.get("id") or uuid.uuid4().hex),
                        "name": str(tc.get("name") or ""),
                        "arguments": dict(tc.get("args") or {}),
                        "type": "function",
                    },
                )
            rice = RiceMessage(
                role="assistant",
                content=wrapped,
                tool_calls=rice_tool_calls,
                metadata={"node": "reasoning"},
            )
            final_ai = rice_message_to_base_message(rice)
            out_md = log_state_transition({**state, "metadata": md}, "thinking")["metadata"]
            return {
                "messages": [final_ai],
                "metadata": out_md,
                "status": "thinking",
                "next_step": "tools" if bool(raw_ai.tool_calls) else "answer",
            }
        except Exception as exc:  # noqa: BLE001
            logger.exception("reasoning_node failed | err={!r}", exc)
            return _failure_update(state, node="reasoning", exc=exc)

    return reasoning_node


def make_tool_node(
    tools: list[Any],
) -> Callable[[SageAgentState], Awaitable[dict[str, Any]]]:
    """Węzeł ACTION: wykonuje wywołania narzędzi z ostatniego AIMessage (async, aktualizuje stan)."""
    from .tools import invoke_rice_tool, list_rice_tool_specs

    rice_names = frozenset(s.name for s in list_rice_tool_specs())

    @node_timer("tool_executor")
    async def tool_node(state: SageAgentState) -> dict[str, Any]:
        md = _metadata_copy(state)
        msgs = list(state.get("messages", []))
        last = _last_ai_message(msgs)
        if last is None or not last.tool_calls:
            logger.warning("tool_node: brak tool_calls — noop")
            return {"next_step": "answer", "status": "answering"}

        ctx = dict(state.get("context") or {})
        sim_merged: dict[str, Any] | list[Any] = state.get("simulation_results") or {}
        tool_results: list[ToolResult] = list(state.get("tool_results") or [])
        out_messages: list[BaseMessage] = []

        try:
            for tc in last.tool_calls:
                if isinstance(tc, dict):
                    name = str(tc.get("name") or "")
                    tid = str(tc.get("id") or uuid.uuid4().hex)
                    args = dict(tc.get("args") or {})
                else:
                    name = str(getattr(tc, "name", "") or "")
                    tid = str(getattr(tc, "id", "") or uuid.uuid4().hex)
                    args = dict(getattr(tc, "args", {}) or {})

                if name in rice_names:
                    tr = await invoke_rice_tool(name, args, tool_call_id=tid)
                    tool_results.append(tr)
                    routed = _route_tool_artifact(name, tr)
                    if routed:
                        kind, k, v = routed
                        if kind == "sim":
                            sim_merged = _merge_simulation({**state, "simulation_results": sim_merged}, k, v)
                        else:
                            ctx = _merge_context({**state, "context": ctx}, k, v)
                    out_messages.append(rice_message_to_base_message(_tool_result_to_rice(tr)))
                else:
                    payload = await _invoke_langchain_tool(tools, name, args)
                    tr = ToolResult(tool_call_id=tid, name=name, content=payload, is_error=False)
                    tool_results.append(tr)
                    ctx = _merge_context({**state, "context": ctx}, name, payload)
                    out_messages.append(
                        rice_message_to_base_message(_tool_result_to_rice(tr)),
                    )

            out_md = log_state_transition({**state, "metadata": md}, "simulating")["metadata"]
            patch: dict[str, Any] = {
                "messages": out_messages,
                "context": ctx,
                "simulation_results": sim_merged,
                "tool_results": tool_results,
                "metadata": out_md,
                "status": "simulating",
                "next_step": "reason",
            }
            return patch
        except Exception as exc:  # noqa: BLE001
            logger.exception("tool_node failed | err={!r}", exc)
            return _failure_update(state, node="tool_executor", exc=exc)

    return tool_node


def make_researcher_node(
    router: SageRouter,
    *,
    default_top_k: int = 8,
) -> Callable[[SageAgentState], Awaitable[dict[str, Any]]]:
    """Węzeł RESEARCHER: tylko ``search_memory`` (vector), bez LLM planera."""

    from .tools import invoke_rice_tool

    @node_timer("researcher")
    async def researcher_node(state: SageAgentState) -> dict[str, Any]:
        md = _metadata_copy(state)
        try:
            q = str(md.get("research_query") or "").strip()
            if not q:
                last_human = None
                for m in reversed(state.get("messages", [])):
                    if isinstance(m, HumanMessage) or (isinstance(m, dict) and m.get("role") == "user"):
                        last_human = m
                        break
                if isinstance(last_human, HumanMessage):
                    q = str(last_human.content or "").strip()
                elif isinstance(last_human, dict):
                    q = str(last_human.get("content") or "").strip()
            if not q:
                raise ValueError("Brak zapytania research (metadata.research_query lub ostatni user).")

            tid = str(md.get("research_tool_call_id") or f"research-{uuid.uuid4().hex}")
            tr = await invoke_rice_tool("search_memory", {"query": q}, tool_call_id=tid)
            ctx = _merge_context(state, "vector_research", tr.model_dump(mode="json"))
            note = RiceMessage(
                role="assistant",
                content=wrap_xml(
                    "thought_process",
                    f"Vector research ({default_top_k} hint): query={q!r}\nstatus={'error' if tr.is_error else 'ok'}",
                ),
                metadata={"node": "researcher"},
            )
            out_md = log_state_transition({**state, "metadata": md}, "thinking")["metadata"]
            tool_results = list(state.get("tool_results") or [])
            tool_results.append(tr)
            return {
                "messages": [rice_message_to_base_message(note)],
                "context": ctx,
                "tool_results": tool_results,
                "metadata": out_md,
                "status": "thinking",
                "next_step": "answer",
            }
        except Exception as exc:  # noqa: BLE001
            logger.exception("researcher_node failed | err={!r}", exc)
            return _failure_update(state, node="researcher", exc=exc)

    return researcher_node


def make_answer_node(
    router: SageRouter,
    *,
    role: AgentRole = AgentRole.CODER,
) -> Callable[[SageAgentState], Awaitable[dict[str, Any]]]:
    """Węzeł ANSWER: synteza końcowa bez narzędzi."""

    @node_timer("answer")
    async def answer_node(state: SageAgentState) -> dict[str, Any]:
        md = _metadata_copy(state)
        try:
            model = str(state.get("model") or router.default_route)
            stream = bool(md.get("stream", False))
            system = (
                format_prompt(state, role=role, strict_mode=False, include_tools_catalog=False)
                + "\n\nSynthesize a concise technical final answer from context, simulation, and history."
            )
            lc = state_messages_to_lc(list(state.get("messages", []))[-48:])
            oai = [{"role": "system", "content": system}, *convert_to_openai_messages(lc)]
            resp = await call_model(
                router,
                model=model,
                messages=oai,
                tools=None,
                stream=stream,
                metadata=md,
                stream_node="answer",
            )
            raw_ai = _choice_to_ai_message(resp.choices[0])
            rice = RiceMessage(
                role="assistant",
                content=raw_ai.content or "",
                metadata={"node": "answer"},
            )
            ai = rice_message_to_base_message(rice)
            out_md = log_state_transition({**state, "metadata": md}, "idle")["metadata"]
            return {
                "messages": [ai],
                "metadata": out_md,
                "status": "idle",
                "next_step": "done",
            }
        except Exception as exc:  # noqa: BLE001
            logger.exception("answer_node failed | err={!r}", exc)
            return _failure_update(state, node="answer", exc=exc)

    return answer_node


def make_agent_node(
    router: SageRouter,
    tools: list[Any],
) -> Callable[[SageAgentState], Awaitable[dict[str, Any]]]:
    """Fabryka węzła LLM zgodna z grafem ReAct (alias rozumowania z katalogiem narzędzi)."""
    return make_reasoning_node(router, tools, include_tools_catalog=True)


# Domyślne, gotowe do użycia funkcje węzłów (sygnatury wymagane przez specyfikację).
async def reasoning_node(state: SageAgentState) -> dict[str, Any]:
    from .tools import default_sage_tools

    fn = make_reasoning_node(_DEFAULT_ROUTER, default_sage_tools(), include_tools_catalog=True)
    return await fn(state)


async def tool_node(state: SageAgentState) -> dict[str, Any]:
    from .tools import default_sage_tools

    fn = make_tool_node(default_sage_tools())
    return await fn(state)


async def researcher_node(state: SageAgentState) -> dict[str, Any]:
    fn = make_researcher_node(_DEFAULT_ROUTER)
    return await fn(state)


async def answer_node(state: SageAgentState) -> dict[str, Any]:
    fn = make_answer_node(_DEFAULT_ROUTER)
    return await fn(state)


__all__ = [
    "answer_node",
    "call_model",
    "make_agent_node",
    "make_answer_node",
    "make_reasoning_node",
    "make_researcher_node",
    "make_tool_node",
    "node_timer",
    "reasoning_node",
    "researcher_node",
    "rice_message_to_base_message",
    "state_messages_to_lc",
    "tool_node",
    "tools_to_litellm_schema",
]
