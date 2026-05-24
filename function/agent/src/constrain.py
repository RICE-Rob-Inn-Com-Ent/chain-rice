"""Structured generation layer (Outlines + Instructor) for reliable machine-readable outputs."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import functools
import os
import re
import time
from collections.abc import Awaitable, Callable
from typing import Any, TypeVar

import instructor
import litellm
from helper import RiceError, logger
from outlines import generate as outlines_generate
from outlines import models as outlines_models
from pydantic import BaseModel
from typing_extensions import Literal

from .const import (
    CONSTRAIN_DEFAULT_MAX_RETRIES,
    CONSTRAIN_DEFAULT_MAX_TOKENS,
    CONSTRAIN_DEFAULT_TEMPERATURE,
    CONSTRAIN_DEFAULT_TIMEOUT_S,
)
from .retry import async_llm_retry

T = TypeVar("T", bound=BaseModel)


class ConstraintKind:
    JSON_SCHEMA = "json_schema"
    REGEX = "regex"
    CFG = "cfg"
    CHOICE = "choice"


def _env_float(name: str, default: float) -> float:
    try:
        return float(os.getenv(name, str(default)))
    except ValueError:
        return float(default)


def _env_int(name: str, default: int) -> int:
    try:
        return int(os.getenv(name, str(default)))
    except ValueError:
        return int(default)


def _default_generation_args() -> dict[str, Any]:
    return {
        "max_tokens": _env_int("RICE_CONSTRAIN_MAX_TOKENS", CONSTRAIN_DEFAULT_MAX_TOKENS),
        "temperature": _env_float("RICE_CONSTRAIN_TEMPERATURE", CONSTRAIN_DEFAULT_TEMPERATURE),
        "timeout": _env_float("RICE_CONSTRAIN_TIMEOUT_S", CONSTRAIN_DEFAULT_TIMEOUT_S),
    }


def _default_max_retries() -> int:
    return _env_int("RICE_SAGE_MAX_RETRIES", CONSTRAIN_DEFAULT_MAX_RETRIES)


def _outlines_model_name() -> str:
    return os.getenv("RICE_OUTLINES_MODEL", os.getenv("SAGE_PRIMARY_MODEL", "openai/gpt-4o-mini"))


def _build_outlines_litellm_model(*, model: str | None = None, **kwargs: Any) -> Any:
    """Create an Outlines LiteLLM backend wrapper."""
    mdl = model or _outlines_model_name()
    try:
        return outlines_models.litellm(mdl, **kwargs)
    except Exception as exc:  # noqa: BLE001
        raise RiceError(
            "Outlines LiteLLM backend initialization failed",
            error_code="AGENT_CONSTRAIN_OUTLINES_INIT",
            details={"model": mdl, "reason": str(exc)},
        ) from exc


def validate_json_to_model[T: BaseModel](model: type[T], raw: str) -> T:
    """Parsuje JSON do modelu Pydantic — twarda gwarancja struktury po generacji."""
    return model.model_validate_json(raw)


def match_regex(pattern: str, text: str) -> bool:
    """Regex jako prosty constraint na pełny tekst odpowiedzi."""
    return re.fullmatch(pattern, text, flags=re.DOTALL) is not None


def schema_converter(model_class: type[BaseModel]) -> dict[str, Any]:
    """Convert Pydantic model into JSON schema compatible with Outlines JSON mode."""
    schema = model_class.model_json_schema()
    # Outlines works best with explicit object schema in strict contexts.
    if "type" not in schema:
        schema["type"] = "object"
    return schema


async def _acompletion_text(
    *,
    prompt: str,
    model: str | None = None,
    generation_kwargs: dict[str, Any] | None = None,
) -> str:
    params = _default_generation_args()
    if generation_kwargs:
        params.update(generation_kwargs)
    mdl = model or _outlines_model_name()
    resp = await litellm.acompletion(
        model=mdl,
        messages=[{"role": "user", "content": prompt}],
        **params,
    )
    return str(resp.choices[0].message.content or "")


def _posthoc_validate_json[TModel: BaseModel](
    raw: str,
    model_class: type[TModel],
) -> TModel:
    try:
        return model_class.model_validate_json(raw)
    except Exception as exc:  # noqa: BLE001
        raise RiceError(
            "Post-hoc JSON validation failed",
            error_code="AGENT_CONSTRAIN_VALIDATE_JSON",
            details={"reason": str(exc), "raw_preview": raw[:500]},
        ) from exc


async def generate_json[TModel: BaseModel](
    model_class: type[TModel],
    *,
    prompt: str,
    model: str | None = None,
    generation_kwargs: dict[str, Any] | None = None,
    allow_flexible_fallback: bool = True,
) -> TModel:
    """Guided JSON generation using Outlines; optional flexible fallback + Pydantic validation."""
    t0 = time.perf_counter()
    mdl = model or _outlines_model_name()
    retries = _default_max_retries()

    @async_llm_retry(max_attempts=retries)
    async def _run_guided() -> TModel:
        backend = _build_outlines_litellm_model(model=mdl)
        schema = schema_converter(model_class)
        generator = outlines_generate.json(backend, schema)
        kwargs = _default_generation_args()
        if generation_kwargs:
            kwargs.update(generation_kwargs)
        out = generator(prompt, **kwargs)
        if isinstance(out, str):
            return _posthoc_validate_json(out, model_class)
        return model_class.model_validate(out)

    try:
        result = await _run_guided()
        dt_ms = (time.perf_counter() - t0) * 1000.0
        logger.info("constrain.generate_json ok | model={} latency_ms={:.2f} guided=true", mdl, dt_ms)
        return result
    except Exception as guided_exc:
        if not allow_flexible_fallback:
            raise RiceError(
                "Guided JSON generation failed",
                error_code="AGENT_CONSTRAIN_JSON_GUIDED",
                details={"model": mdl, "reason": str(guided_exc)},
            ) from guided_exc
        logger.warning("constrain.generate_json fallback | reason={!r}", guided_exc)
        raw = await _acompletion_text(prompt=prompt, model=mdl, generation_kwargs=generation_kwargs)
        result = _posthoc_validate_json(raw, model_class)
        dt_ms = (time.perf_counter() - t0) * 1000.0
        logger.info("constrain.generate_json ok | model={} latency_ms={:.2f} guided=false", mdl, dt_ms)
        return result


async def generate_choice(
    options: list[str],
    *,
    prompt: str,
    model: str | None = None,
    generation_kwargs: dict[str, Any] | None = None,
) -> str:
    """Strict option selection constrained to one value from ``options``."""
    if not options:
        raise ValueError("options must not be empty")
    t0 = time.perf_counter()
    mdl = model or _outlines_model_name()
    retries = _default_max_retries()

    @async_llm_retry(max_attempts=retries)
    async def _run() -> str:
        backend = _build_outlines_litellm_model(model=mdl)
        generator = outlines_generate.choice(backend, options)
        kwargs = _default_generation_args()
        if generation_kwargs:
            kwargs.update(generation_kwargs)
        out = str(generator(prompt, **kwargs)).strip()
        if out not in options:
            raise ValueError(f"choice output {out!r} not in options")
        return out

    try:
        out = await _run()
        logger.info(
            "constrain.generate_choice ok | model={} options={} latency_ms={:.2f}",
            mdl,
            len(options),
            (time.perf_counter() - t0) * 1000.0,
        )
        return out
    except Exception as exc:  # noqa: BLE001
        raise RiceError(
            "Constrained choice generation failed",
            error_code="AGENT_CONSTRAIN_CHOICE",
            details={"model": mdl, "reason": str(exc), "options": options},
        ) from exc


async def generate_with_regex(
    regex_pattern: str,
    *,
    prompt: str,
    model: str | None = None,
    generation_kwargs: dict[str, Any] | None = None,
) -> str:
    """Constrained text generation matching full regex."""
    if not regex_pattern.strip():
        raise ValueError("regex_pattern cannot be empty")
    t0 = time.perf_counter()
    mdl = model or _outlines_model_name()
    retries = _default_max_retries()

    @async_llm_retry(max_attempts=retries)
    async def _run() -> str:
        backend = _build_outlines_litellm_model(model=mdl)
        generator = outlines_generate.regex(backend, regex_pattern)
        kwargs = _default_generation_args()
        if generation_kwargs:
            kwargs.update(generation_kwargs)
        out = str(generator(prompt, **kwargs))
        if not match_regex(regex_pattern, out):
            raise ValueError("generated text does not satisfy regex")
        return out

    try:
        out = await _run()
        logger.info(
            "constrain.generate_regex ok | model={} latency_ms={:.2f}",
            mdl,
            (time.perf_counter() - t0) * 1000.0,
        )
        return out
    except Exception as exc:  # noqa: BLE001
        raise RiceError(
            "Constrained regex generation failed",
            error_code="AGENT_CONSTRAIN_REGEX",
            details={"model": mdl, "reason": str(exc), "pattern": regex_pattern},
        ) from exc


def structured_output[TModel: BaseModel](
    response_model: type[TModel],
    *,
    max_retries: int | None = None,
) -> Callable[[Callable[..., Awaitable[Any]]], Callable[..., Awaitable[TModel]]]:
    """Decorator for Instructor-validated structured outputs with retries."""
    retries = max_retries if max_retries is not None else _default_max_retries()

    def _decorator(fn: Callable[..., Awaitable[Any]]) -> Callable[..., Awaitable[TModel]]:
        @functools.wraps(fn)
        @async_llm_retry(max_attempts=retries)
        async def _wrapped(*args: Any, **kwargs: Any) -> TModel:
            t0 = time.perf_counter()
            try:
                payload = await fn(*args, **kwargs)
                if isinstance(payload, response_model):
                    dt_ms = (time.perf_counter() - t0) * 1000.0
                    logger.info(
                        "constrain.structured_output ok | model={} latency_ms={:.2f}",
                        response_model.__name__,
                        dt_ms,
                    )
                    return payload

                mode = os.getenv("RICE_INSTRUCTOR_MODE", "JSON")
                client = instructor.from_litellm(litellm.acompletion)

                if isinstance(payload, dict) and "model" in payload and "messages" in payload:
                    result = await client.chat.completions.create(
                        model=payload["model"],
                        messages=payload["messages"],
                        response_model=response_model,
                        mode=mode,
                        **{k: v for k, v in payload.items() if k not in {"model", "messages"}},
                    )
                else:
                    result = response_model.model_validate(payload)
                dt_ms = (time.perf_counter() - t0) * 1000.0
                logger.info(
                    "constrain.structured_output ok | model={} latency_ms={:.2f}",
                    response_model.__name__,
                    dt_ms,
                )
                return result
            except Exception as exc:  # noqa: BLE001
                raise RiceError(
                    "Structured output validation failed",
                    error_code="AGENT_CONSTRAIN_STRUCTURED",
                    details={"response_model": response_model.__name__, "reason": str(exc)},
                ) from exc

        return _wrapped

    return _decorator


def outlines_json_schema_hook(schema: dict[str, Any]) -> dict[str, Any]:
    """Zwraca uchwyt schematu dla integracji Outlines (generator podłączany do modelu lokalnego).

    Outlines wymaga backendu (Transformers/vLLM/llamacpp) — tu tylko przekazujemy metadane;
    faktyczne constrained decoding ustawiasz w pipeline z modelem Outlines.
    """
    return {"kind": ConstraintKind.JSON_SCHEMA, "schema": schema}


def outlines_regex_hook(pattern: str) -> dict[str, Any]:
    """Metadane pod regex constraint (Outlines `regex`)."""
    return {"kind": ConstraintKind.REGEX, "pattern": pattern}


def outlines_cfg_hook(grammar: str) -> dict[str, Any]:
    """Metadane pod CFG — np. gramatyka Lark/EBNF zależnie od backendu Outlines."""
    return {"kind": ConstraintKind.CFG, "grammar": grammar}


def constraint_mode() -> Literal["post", "outlines", "instructor"]:
    """Constraint backend selected from env: ``post`` / ``outlines`` / ``instructor``."""
    mode = os.getenv("RICE_CONSTRAIN_MODE", "outlines").strip().lower()
    if mode in {"post", "outlines", "instructor"}:
        return mode  # type: ignore[return-value]
    return "outlines"


__all__ = [
    "ConstraintKind",
    "constraint_mode",
    "generate_choice",
    "generate_json",
    "generate_with_regex",
    "match_regex",
    "outlines_cfg_hook",
    "outlines_json_schema_hook",
    "outlines_regex_hook",
    "schema_converter",
    "structured_output",
    "validate_json_to_model",
]
