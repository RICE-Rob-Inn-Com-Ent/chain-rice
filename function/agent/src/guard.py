"""Multi-layer safety system for SAGE (Guardrails + Instructor + static checks)."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import asyncio
import json
import os
import re
import time
from dataclasses import dataclass
from typing import Any

import litellm
from helper import RiceError, logger
from pydantic import BaseModel

from .const import (
    GUARD_BLOCKED_CODE_PATTERNS,
    GUARD_MAX_NOISE,
    GUARD_MAX_QUBITS,
    GUARD_MIN_NOISE,
    GUARD_MIN_QUBITS,
    GUARD_SAFE_MODE_DEFAULT,
    GUARD_TOXICITY_THRESHOLD_DEFAULT,
)
from .retry import async_llm_retry
from .state import AgentState
from .typed import instructor_client


_PROMPT_INJECTION_PATTERNS = (
    r"ignore\s+(all\s+)?previous\s+instructions",
    r"disregard\s+(the\s+)?system\s+prompt",
    r"reveal\s+system\s+prompt",
    r"act\s+as\s+developer\s+mode",
    r"jailbreak",
)
_PII_PATTERNS = (
    # email
    (re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"), "[REDACTED_EMAIL]"),
    # phone
    (re.compile(r"\b(?:\+?\d{1,3}[-.\s]?)?(?:\(?\d{2,4}\)?[-.\s]?)\d{3,4}[-.\s]?\d{3,4}\b"), "[REDACTED_PHONE]"),
    # naive credit card
    (re.compile(r"\b(?:\d[ -]*?){13,19}\b"), "[REDACTED_CARD]"),
)
_TOXIC_TERMS = (
    "idiot",
    "stupid",
    "moron",
    "hate",
    "kill yourself",
    "retard",
)


def _env_bool(name: str, default: bool) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


def _safe_mode(enabled: bool | None = None) -> bool:
    if enabled is not None:
        return bool(enabled)
    return _env_bool("RICE_SAFE_MODE", GUARD_SAFE_MODE_DEFAULT)


def _raise_or_warn(message: str, *, safe_mode: bool, details: dict[str, Any] | None = None) -> None:
    if safe_mode:
        raise RiceError(
            message,
            error_code="AGENT_GUARD_BLOCK",
            details=details or {},
        )
    logger.warning("{} | details={}", message, details or {})


@dataclass(slots=True)
class RiceGuard:
    """Dual-layer defense: Guardrails validation + Instructor schema checks."""

    input_guard: Any
    output_guard: Any
    safe_mode: bool = GUARD_SAFE_MODE_DEFAULT

    async def validate_input(self, text: str) -> str:
        txt = pii_filter(text, mask=True)
        detected, reason = detect_prompt_injection(txt)
        if detected:
            _raise_or_warn(
                "prompt injection detected",
                safe_mode=self.safe_mode,
                details={"reason": reason},
            )
        try:
            apply_guard(self.input_guard, txt)
        except Exception as exc:  # noqa: BLE001
            _raise_or_warn(
                "input guard validation failed",
                safe_mode=self.safe_mode,
                details={"reason": str(exc)},
            )
        return txt

    async def validate_output(
        self,
        text: str,
        *,
        state: AgentState | None = None,
    ) -> str:
        ok, payload = validate_output(
            text,
            guard=self.output_guard,
            state=state,
            safe_mode=self.safe_mode,
        )
        if not ok and self.safe_mode:
            raise RiceError(
                "output validation failed",
                error_code="AGENT_GUARD_OUTPUT",
                details={"reason": str(payload)},
            )
        return text

    async def validate_structured[T: BaseModel](
        self,
        raw: str,
        model: type[T],
    ) -> T:
        try:
            return model.model_validate_json(raw)
        except Exception:
            client = instructor_client()
            # "Repair" path: ask model to transform raw to target schema.
            fixed = await client.chat.completions.create(
                model=os.getenv("SAGE_PRIMARY_MODEL", "gpt-4o-mini"),
                messages=[
                    {"role": "system", "content": "Return valid JSON for the target schema."},
                    {"role": "user", "content": raw},
                ],
                response_model=model,
            )
            return fixed


def build_default_guard() -> Any:
    """Build a permissive Guard object (lazy import for compatibility)."""
    from guardrails import Guard

    try:
        return Guard()
    except Exception:
        # Backward compatibility across guardrails versions.
        return Guard.for_string()


def build_input_guard() -> Any:
    return build_default_guard()


def build_output_guard() -> Any:
    return build_default_guard()


def build_rice_guard(*, safe_mode: bool | None = None) -> RiceGuard:
    return RiceGuard(
        input_guard=build_input_guard(),
        output_guard=build_output_guard(),
        safe_mode=_safe_mode(safe_mode),
    )


def apply_guard(guard: Any, text: str) -> Any:
    """Call whichever Guardrails method is available in current runtime."""
    if hasattr(guard, "validate"):
        return guard.validate(text)  # type: ignore[no-any-return, operator]
    if callable(guard):
        return guard(text)  # type: ignore[operator]
    return guard.parse(text)  # type: ignore[no-any-return]


def detect_prompt_injection(text: str) -> tuple[bool, str]:
    """Detect common prompt-injection patterns."""
    t = text.lower()
    for p in _PROMPT_INJECTION_PATTERNS:
        if re.search(p, t, flags=re.IGNORECASE):
            return True, p
    return False, ""


def pii_filter(text: str, *, mask: bool = True) -> str:
    """Mask probable PII tokens (email/phone/card)."""
    out = text
    for pat, token in _PII_PATTERNS:
        if mask:
            out = pat.sub(token, out)
        else:
            if pat.search(out):
                return ""
    return out


def _extract_numeric_candidates(text: str) -> dict[str, float]:
    vals: dict[str, float] = {}
    pairs = re.findall(r"\b(qubits?|noise(?:_level)?)\s*[:=]\s*([0-9]*\.?[0-9]+)", text, flags=re.I)
    for k, v in pairs:
        try:
            vals[k.lower()] = float(v)
        except ValueError:
            continue
    return vals


def _valid_range_check(text: str) -> tuple[bool, str]:
    vals = _extract_numeric_candidates(text)
    for key, val in vals.items():
        if key.startswith("qubit"):
            if not (GUARD_MIN_QUBITS <= int(val) <= GUARD_MAX_QUBITS):
                return False, f"qubits out of range: {val}"
        if key.startswith("noise"):
            if not (GUARD_MIN_NOISE <= float(val) <= GUARD_MAX_NOISE):
                return False, f"noise out of range: {val}"
    return True, ""


def _code_safety_check(text: str) -> tuple[bool, str]:
    for pattern in GUARD_BLOCKED_CODE_PATTERNS:
        if re.search(pattern, text, flags=re.IGNORECASE):
            return False, pattern
    return True, ""


def _toxicity_score(text: str) -> float:
    t = text.lower()
    if not t.strip():
        return 0.0
    hits = sum(1 for w in _TOXIC_TERMS if w in t)
    return min(1.0, hits / max(1, len(_TOXIC_TERMS)))


def _provenance_check(text: str, state: AgentState | None) -> tuple[bool, str]:
    if state is None:
        return True, ""
    ctx = state.get("context", {}) or {}
    if not ctx:
        return True, ""
    ctx_blob = json.dumps(ctx, default=str).lower()
    claims = [s.strip() for s in re.split(r"[.!?\n]+", text) if s.strip()]
    unsupported = 0
    for c in claims[:12]:
        tokens = [tok for tok in re.findall(r"[a-z0-9_]{5,}", c.lower()) if tok not in {"therefore", "assume"}]
        if not tokens:
            continue
        overlap = sum(1 for t in tokens[:8] if t in ctx_blob)
        if overlap == 0:
            unsupported += 1
    if unsupported >= max(2, len(claims) // 2):
        return False, f"unsupported claims={unsupported}"
    return True, ""


def _content_policy_blocked_patterns() -> list[str]:
    raw = os.getenv("RICE_BLOCKED_PATTERNS", "")
    if not raw.strip():
        return []
    return [p.strip() for p in raw.split("||") if p.strip()]


def _policy_check(text: str) -> tuple[bool, str]:
    for pat in _content_policy_blocked_patterns():
        if re.search(pat, text, flags=re.IGNORECASE):
            return False, f"blocked-pattern:{pat}"
    threshold = float(os.getenv("RICE_TOXICITY_THRESHOLD", str(GUARD_TOXICITY_THRESHOLD_DEFAULT)))
    tox = _toxicity_score(text)
    if tox > threshold:
        return False, f"toxicity>{threshold:.2f}"
    return True, ""


def _validate_output_sync_checks(
    text: str,
    *,
    guard: Any,
    state: AgentState | None,
    safe_mode: bool,
) -> tuple[bool, Any]:
    try:
        apply_guard(guard, text)
        ok, reason = _valid_range_check(text)
        if not ok:
            _raise_or_warn("ValidRange failed", safe_mode=safe_mode, details={"reason": reason})
        ok, reason = _code_safety_check(text)
        if not ok:
            _raise_or_warn("CodeSafety failed", safe_mode=safe_mode, details={"reason": reason})
        ok, reason = _policy_check(text)
        if not ok:
            _raise_or_warn("Content policy failed", safe_mode=safe_mode, details={"reason": reason})
        ok, reason = _provenance_check(text, state)
        if not ok:
            _raise_or_warn("Provenance failed", safe_mode=safe_mode, details={"reason": reason})
        return True, {"ok": True}
    except Exception as exc:  # noqa: BLE001
        return False, exc


async def _validate_output_async(
    text: str,
    *,
    guard: Any,
    state: AgentState | None,
    safe_mode: bool,
) -> Any:
    apply_guard(guard, text)

    ok, reason = _valid_range_check(text)
    if not ok:
        _raise_or_warn("ValidRange failed", safe_mode=safe_mode, details={"reason": reason})

    ok, reason = _code_safety_check(text)
    if not ok:
        _raise_or_warn("CodeSafety failed", safe_mode=safe_mode, details={"reason": reason})

    ok, reason = _policy_check(text)
    if not ok:
        _raise_or_warn("Content policy failed", safe_mode=safe_mode, details={"reason": reason})

    ok, reason = _provenance_check(text, state)
    if not ok:
        _raise_or_warn("Provenance failed", safe_mode=safe_mode, details={"reason": reason})

    return {"ok": True}


async def validate_output_async(
    text: str,
    *,
    guard: Any | None = None,
    state: AgentState | None = None,
    safe_mode: bool | None = None,
) -> tuple[bool, Any]:
    """Async output validation with retries (guardrails + static checks)."""
    g = guard or build_output_guard()
    sm = _safe_mode(safe_mode)
    max_reasks = int(os.getenv("RICE_GUARD_MAX_REASKS", "2")) + 1

    @async_llm_retry(max_attempts=max_reasks)
    async def _run() -> Any:
        return await _validate_output_async(text, guard=g, state=state, safe_mode=sm)

    try:
        t0 = time.perf_counter()
        out = await _run()
        logger.info(
            "guard.validate_output ok | latency_ms={:.2f}",
            (time.perf_counter() - t0) * 1000.0,
        )
        return True, out
    except Exception as exc:  # noqa: BLE001
        logger.warning("guard blocked or failed: {}", exc)
        return False, exc


def validate_output(
    text: str,
    guard: Any | None = None,
    *,
    state: AgentState | None = None,
    safe_mode: bool | None = None,
) -> tuple[bool, Any]:
    """Sync wrapper for async validator for compatibility with older call sites."""
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        return asyncio.run(
            validate_output_async(
                text,
                guard=guard,
                state=state,
                safe_mode=safe_mode,
            ),
        )
    # already in async context: run synchronous subset to avoid silently passing.
    if loop.is_running():
        logger.warning("validate_output called in running loop; using sync safety checks")
        return _validate_output_sync_checks(
            text,
            guard=guard or build_output_guard(),
            state=state,
            safe_mode=_safe_mode(safe_mode),
        )
    return loop.run_until_complete(
        validate_output_async(text, guard=guard, state=state, safe_mode=safe_mode),
    )


async def guard_validate_litellm_call(
    *,
    model: str,
    messages: list[dict[str, Any]],
    guard: RiceGuard | None = None,
    safe_mode: bool | None = None,
    **kwargs: Any,
) -> Any:
    """Run input+output guard pipeline around a LiteLLM call."""
    rg = guard or build_rice_guard(safe_mode=safe_mode)
    if messages:
        last = messages[-1]
        content = str(last.get("content") or "")
        cleaned = await rg.validate_input(content)
        last["content"] = cleaned

    resp = await litellm.acompletion(model=model, messages=messages, **kwargs)
    txt = str(resp.choices[0].message.content or "")
    ok, reason = await validate_output_async(txt, guard=rg.output_guard, safe_mode=rg.safe_mode)
    if not ok and rg.safe_mode:
        raise RiceError(
            "Guard validation blocked model output",
            error_code="AGENT_GUARD_LLM_OUTPUT",
            details={"reason": str(reason)},
        )
    return resp


__all__ = [
    "RiceGuard",
    "apply_guard",
    "build_default_guard",
    "build_input_guard",
    "build_output_guard",
    "build_rice_guard",
    "detect_prompt_injection",
    "guard_validate_litellm_call",
    "pii_filter",
    "validate_output",
    "validate_output_async",
]
