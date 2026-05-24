"""LiteLLM model router + LangGraph edge routing for SAGE."""

# TODO(agent):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Any

import litellm
from helper import logger
from litellm import Router

from .state import AgentState
from .typed import RiceMessage, ToolResult

# TODO:
# [ ] implement LiteLLM router with model_list from function/model/litellm_config.yaml
# [ ]     config path read from CLERK_LITELLM_CONFIG env var
# [ ] configure routing strategies: simple-shuffle|least-busy|latency-based|cost-based
# [ ]     strategy read from CLERK_LITELLM_STRATEGY env var (default: least-busy)
# [ ] implement per-role model routing:
# [ ]     role=king   → CLERK_KING_MODEL   (Qwen3-8B, reasoning)
# [ ]     role=mason  → CLERK_MASON_MODEL  (Coder)
# [ ]     role=smith  → CLERK_SMITH_MODEL  (Coder)
# [ ]     role=clerk  → CLERK_OFFICE_MODEL  (Coder, highest rank)
# [ ]     role=sage   → CLERK_SAGE_MODEL   (Coder)
# [ ]     role=bard   → CLERK_BARD_MODEL   (VL model)
# [ ]     role=chief  → CLERK_CHIEF_MODEL  (fine-tuned on .rice)
# [ ] implement fallback chain: vllm → ollama → litellm_cloud
# [ ]     each endpoint from env var, never hardcoded
# [ ] implement caching: LiteLLM semantic cache via Qdrant
# [ ]     cache_collection = CLERK_CACHE_COLLECTION env var
# [ ]     similarity threshold = CLERK_CACHE_THRESHOLD env var
# [ ] implement rate limiting per model: CLERK_RATE_LIMIT_RPM env var
# [ ] implement token budget: CLERK_MAX_TOKENS env var per request
# [ ] implement cost tracking: log token usage to OTel counter metric
# [ ]     metric name: sage.litellm.tokens_used, labels: model, role


def default_model_list() -> list[dict[str, Any]]:
    """Lista modeli dla `Router`: pierwszy to domyślny worker; kolejne — fallback."""
    ollama_base = os.getenv("OLLAMA_API_BASE", "http://127.0.0.1:11434")
    vllm_base = os.getenv("VLLM_API_BASE", "http://127.0.0.1:8000/v1")
    cloud_model = os.getenv("SAGE_CLOUD_MODEL", "gpt-4o-mini")
    return [
        {
            "model_name": "primary",
            "litellm_params": {
                "model": os.getenv("SAGE_PRIMARY_MODEL", "ollama/llama3.2"),
                "api_base": ollama_base,
            },
        },
        {
            "model_name": "vllm",
            "litellm_params": {
                "model": os.getenv("SAGE_VLLM_MODEL", "openai/mistral-7b"),
                "api_base": vllm_base,
            },
        },
        {
            "model_name": "cloud",
            "litellm_params": {"model": cloud_model},
        },
    ]


def default_fallbacks() -> list[dict[str, list[str]]]:
    """Fallback chain: primary → vllm → cloud (nazwy jak w `default_model_list`)."""
    return [{"primary": ["vllm", "cloud"]}]


@dataclass
class CostLedger:
    """Prosty rejestr kosztów LiteLLM (USD) i liczby wywołań."""

    total_usd: float = 0.0
    calls: list[dict[str, Any]] = field(default_factory=list)

    def record(self, response: Any, *, model: str | None = None) -> float:
        cost = 0.0
        try:
            from litellm import completion_cost

            cost = float(completion_cost(completion_response=response) or 0.0)
        except Exception as exc:  # noqa: BLE001 — koszt jest best-effort
            logger.debug("completion_cost failed: {}", exc)
        self.total_usd += cost
        self.calls.append({"model": model, "cost_usd": cost})
        return cost


class SageRouter:
    """Router oparty o `litellm.Router` + opcjonalne śledzenie kosztów."""

    def __init__(
        self,
        *,
        model_list: list[dict[str, Any]] | None = None,
        fallbacks: list[dict[str, list[str]]] | None = None,
        num_retries: int = 0,
        track_cost: bool = True,
    ) -> None:
        self.model_list = model_list or default_model_list()
        self.fallbacks = fallbacks if fallbacks is not None else default_fallbacks()
        self._router = Router(
            model_list=self.model_list,
            fallbacks=self.fallbacks,
            num_retries=num_retries or None,
        )
        self.track_cost = track_cost
        self.ledger = CostLedger()

    @property
    def default_route(self) -> str:
        """Nazwa pierwszego modelu w `model_list` (routing LiteLLM)."""
        return str(self.model_list[0]["model_name"])

    async def acompletion(self, **kwargs: Any) -> Any:
        """Asynchroniczne wywołanie przez wewnętrzny `Router`."""
        model = kwargs.get("model") or self.default_route
        kwargs.setdefault("model", model)
        response = await self._router.acompletion(**kwargs)
        if self.track_cost:
            self.ledger.record(response, model=str(model))
        return response

    def completion(self, **kwargs: Any) -> Any:
        """Synchroniczne wywołanie — dla skryptów / testów."""
        model = kwargs.get("model") or self.default_route
        kwargs.setdefault("model", model)
        response = self._router.completion(**kwargs)
        if self.track_cost:
            self.ledger.record(response, model=str(model))
        return response


# --- LangGraph routing ---------------------------------------------------------------------------

_TERMINATION_MARKERS = (
    "<final_answer>",
    "</final_answer>",
    "FINAL_ANSWER:",
    "FINISH_REASON=STOP",
)
_STOP_SEQUENCES = ("<END>", "[DONE]", "STOP_SEQUENCE")
_SENSITIVE_TOOLS = frozenset(
    {
        "run_quantum_simulation",
        "analyze_physics",
    },
)


def _last_message(state: AgentState) -> Any | None:
    msgs = list(state.get("messages", []))
    return msgs[-1] if msgs else None


def _extract_message_text(msg: Any | None) -> str:
    if msg is None:
        return ""
    if isinstance(msg, RiceMessage):
        return str(msg.content or "")
    if isinstance(msg, dict):
        return str(msg.get("content") or "")
    content = getattr(msg, "content", None)
    return str(content or "")


def _extract_tool_calls(msg: Any | None) -> list[dict[str, Any]]:
    if msg is None:
        return []
    raw: Any
    if isinstance(msg, RiceMessage):
        raw = msg.tool_calls
    elif isinstance(msg, dict):
        raw = msg.get("tool_calls", [])
    else:
        raw = getattr(msg, "tool_calls", []) or []
    out: list[dict[str, Any]] = []
    for tc in list(raw or []):
        if isinstance(tc, dict):
            if "arguments" in tc and "args" not in tc:
                args = tc.get("arguments") or {}
            else:
                args = tc.get("args") or {}
            out.append(
                {
                    "id": str(tc.get("id") or ""),
                    "name": str(tc.get("name") or ""),
                    "args": dict(args) if isinstance(args, dict) else {},
                },
            )
            continue
        # typed.ToolCall or langchain tool-call-like object
        out.append(
            {
                "id": str(getattr(tc, "id", "") or ""),
                "name": str(getattr(tc, "name", "") or ""),
                "args": dict(getattr(tc, "arguments", {}) or getattr(tc, "args", {}) or {}),
            },
        )
    return out


def _tool_result_status(tr: Any) -> tuple[bool, bool]:
    """Return ``(is_error, is_critical)`` for a single tool result payload."""
    if isinstance(tr, ToolResult):
        is_error = bool(tr.is_error)
        critical = bool((tr.metadata or {}).get("critical", False))
        return is_error, critical
    if isinstance(tr, dict):
        is_error = bool(tr.get("is_error", False))
        md = tr.get("metadata", {})
        critical = bool(md.get("critical", False)) if isinstance(md, dict) else False
        return is_error, critical
    return False, False


def has_termination_signal(state: AgentState) -> bool:
    """Detect explicit final-answer markers/stop sequences in state and latest message."""
    md = state.get("metadata", {}) or {}
    if bool(md.get("final_answer_ready")) or bool(md.get("terminate")):
        return True
    if str(state.get("next_step", "")).lower() in {"done", "end", "terminate"}:
        return True

    last = _last_message(state)
    text = _extract_message_text(last).upper()
    if any(m.upper() in text for m in _TERMINATION_MARKERS):
        return True
    if any(s.upper() in text for s in _STOP_SEQUENCES):
        return True
    return False


def requires_human_approval(state: AgentState) -> bool:
    """Check HITL gate for sensitive tools."""
    md = state.get("metadata", {}) or {}
    hitl_enabled = bool(
        md.get("human_in_the_loop")
        or md.get("hitl_enabled")
        or os.getenv("CLERK_HITL_ENABLED", "false").strip().lower() in {"1", "true", "yes", "on"}
    )
    if not hitl_enabled:
        return False
    if bool(md.get("human_approved", False)):
        return False

    tool_calls = _extract_tool_calls(_last_message(state))
    for tc in tool_calls:
        if tc.get("name") in _SENSITIVE_TOOLS:
            return True
    return False


def route_after_reasoning(state: AgentState) -> str:
    """Route after LLM reasoning: tools vs answer (+ termination/HITL/fallback)."""
    if has_termination_signal(state):
        logger.info("Router: Moving from REASONING to ANSWER (termination signal).")
        return "answer_node"

    if requires_human_approval(state):
        logger.info("Router: Moving from REASONING to HUMAN_APPROVAL (sensitive tool gate).")
        return "human_approval_node"

    tool_calls = _extract_tool_calls(_last_message(state))
    if tool_calls:
        logger.info("Router: Moving from REASONING to TOOLS ({} tool call(s)).", len(tool_calls))
        return "tool_node"

    logger.info("Router: Moving from REASONING to ANSWER (no tool calls).")
    return "answer_node"


def route_after_tools(state: AgentState) -> str:
    """Route after tool execution: retry/reasoning/answer based on result quality."""
    if has_termination_signal(state):
        logger.info("Router: Moving from TOOLS to ANSWER (termination signal).")
        return "answer_node"

    tool_results = list(state.get("tool_results", []) or [])
    if not tool_results:
        logger.warning("Router: TOOLS produced no results; fallback to REASONING.")
        return "reasoning_node"

    has_error = False
    has_critical = False
    for tr in tool_results:
        is_error, critical = _tool_result_status(tr)
        has_error = has_error or is_error
        has_critical = has_critical or (is_error and critical)

    md = state.get("metadata", {}) or {}
    retry_count = int(md.get("node_retry_count", 0))
    max_retries = int(md.get("max_retries", os.getenv("CLERK_NODE_MAX_RETRIES", "3")))

    if has_critical and retry_count < max_retries:
        logger.warning(
            "Router: Moving from TOOLS to RETRY (critical failures, retry {}/{}).",
            retry_count + 1,
            max_retries,
        )
        return "retry_node"

    if has_critical:
        logger.error("Router: Critical failures exceeded retries; forcing ANSWER fallback.")
        return "answer_node"

    if has_error:
        logger.warning("Router: Non-critical tool errors; returning to REASONING with error context.")
        return "reasoning_node"

    logger.info("Router: Moving from TOOLS to REASONING (all tools succeeded).")
    return "reasoning_node"


def _safe_default_with_error(state: AgentState) -> str:
    """Safety fallback to prevent routing loops."""
    logger.error("Router: Undetermined edge; defaulting to ANSWER with system-error fallback.")
    md = dict(state.get("metadata", {}) or {})
    md["router_error"] = "undetermined_route"
    md.setdefault("system_error", "router could not determine next step")
    state["metadata"] = md
    state["next_step"] = "answer"
    return "answer_node"


def should_continue(state: AgentState) -> str:
    """Master edge router for ``add_conditional_edges``.

    Decision precedence:
    1. explicit termination / final-answer markers
    2. explicit ``next_step`` hint
    3. status-aware routing (thinking -> route_after_reasoning, simulating -> route_after_tools)
    4. safe fallback to answer_node
    """
    try:
        if has_termination_signal(state):
            logger.info("Router: should_continue -> ANSWER (global termination signal).")
            return "answer_node"

        hint = str(state.get("next_step", "")).strip().lower()
        if hint in {"tools", "tool", "tool_node"}:
            return route_after_reasoning(state)
        if hint in {"answer", "answer_node", "done", "end"}:
            logger.info("Router: should_continue -> ANSWER (explicit next_step hint).")
            return "answer_node"
        if hint in {"retry", "retry_node"}:
            logger.info("Router: should_continue -> RETRY (explicit next_step hint).")
            return "retry_node"
        if hint in {"reason", "reasoning", "reasoning_node"}:
            logger.info("Router: should_continue -> REASONING (explicit next_step hint).")
            return "reasoning_node"
        if hint in {"human_approval", "human_in_the_loop"}:
            logger.info("Router: should_continue -> HUMAN_APPROVAL (explicit next_step hint).")
            return "human_approval_node"

        status = str(state.get("status", "idle")).strip().lower()
        if status in {"thinking", "idle"}:
            return route_after_reasoning(state)
        if status in {"simulating", "tooling"}:
            return route_after_tools(state)
        if status in {"answering"}:
            logger.info("Router: should_continue -> ANSWER (status=answering).")
            return "answer_node"
    except Exception as exc:  # noqa: BLE001
        logger.exception("Router: should_continue failed | err={!r}", exc)
        return _safe_default_with_error(state)

    return _safe_default_with_error(state)


__all__ = [
    "CostLedger",
    "SageRouter",
    "default_fallbacks",
    "default_model_list",
    "has_termination_signal",
    "requires_human_approval",
    "route_after_reasoning",
    "route_after_tools",
    "should_continue",
]
