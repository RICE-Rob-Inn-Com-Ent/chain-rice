"""Centralized JAX JIT layer for HPC-oriented simulation workloads."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from collections.abc import Callable
from functools import wraps
from time import perf_counter
from typing import Any, ParamSpec, TypeVar

import jax
import jax.numpy as jnp
from helper import logger

from .backend import get_backend_manager

P = ParamSpec("P")
R = TypeVar("R")
F = TypeVar("F", bound=Callable[..., Any])

_JIT_REGISTRY: dict[str, dict[str, Any]] = {}


def _pick_device() -> Any | None:
    info = get_backend_manager().get_info()
    platform = str(info.get("jax_platform", "cpu"))
    devices = jax.devices(platform)
    if devices:
        return devices[0]
    fallback = jax.devices()
    return fallback[0] if fallback else None


def rice_jit(
    *,
    static_argnums: int | tuple[int, ...] | None = None,
    donate_argnums: int | tuple[int, ...] | None = None,
    device: Any | None = None,
) -> Callable[[Callable[P, R]], Callable[P, R]]:
    """JAX JIT decorator with compile/execute telemetry and optional device pinning."""

    def _decorator(fun: Callable[P, R]) -> Callable[P, R]:
        name = getattr(fun, "__name__", repr(fun))
        chosen_device = device if device is not None else _pick_device()
        compiled = jax.jit(
            fun,
            static_argnums=static_argnums,
            donate_argnums=donate_argnums,
            device=chosen_device,
        )

        @wraps(fun)
        def _wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            t0 = perf_counter()
            out = compiled(*args, **kwargs)
            out = block_until_ready(out)
            dt = (perf_counter() - t0) * 1000.0
            rec = _JIT_REGISTRY.setdefault(
                name,
                {
                    "calls": 0,
                    "last_latency_ms": 0.0,
                    "compiled": True,
                    "device": str(chosen_device) if chosen_device is not None else "default",
                },
            )
            rec["calls"] = int(rec.get("calls", 0)) + 1
            rec["last_latency_ms"] = float(dt)
            logger.debug("rice_jit | fn={} calls={} latency_ms={:.2f}", name, rec["calls"], dt)
            return out

        setattr(_wrapper, "_compiled_jax", compiled)
        return _wrapper

    return _decorator


def jit_compile(
    fun: F,
    *,
    static_argnums: int | tuple[int, ...] | None = None,
    donate_argnums: int | tuple[int, ...] | None = None,
) -> F:
    """Backward-compatible explicit JIT compiler (uses same device policy as ``rice_jit``)."""
    compiled = jax.jit(
        fun,
        static_argnums=static_argnums,
        donate_argnums=donate_argnums,
        device=_pick_device(),
    )
    return compiled  # type: ignore[return-value]


def rice_vmap(
    fun: Callable[..., Any],
    *,
    in_axes: Any = 0,
    out_axes: Any = 0,
) -> Callable[..., Any]:
    """Vectorization wrapper for batched parameter/state evaluation."""
    vmapped = jax.vmap(fun, in_axes=in_axes, out_axes=out_axes)
    logger.debug("rice_vmap | fn={} in_axes={} out_axes={}", getattr(fun, "__name__", repr(fun)), in_axes, out_axes)
    return vmapped


def vectorize_axis0(fun: Callable[..., Any]) -> Callable[..., Any]:
    return rice_vmap(fun, in_axes=0, out_axes=0)


def parallel_map(fun: Callable[..., Any], in_axes: int = 0) -> Callable[..., Any]:
    """`pmap` — wymaga zainicjalizowanych urządzeń XLA."""
    return jax.pmap(fun, in_axes=in_axes)


def scan_loop(
    f: Callable[[Any, Any], tuple[Any, Any]],
    init: Any,
    xs: Any,
    *,
    length: int | None = None,
) -> tuple[Any, Any]:
    """`jax.lax.scan` — pętle z stanem."""
    return jax.lax.scan(f, init, xs, length=length)


def cond_branch(
    pred: Any,
    true_fun: Callable[[Any], Any],
    false_fun: Callable[[Any], Any],
    operand: Any,
) -> Any:
    """JIT-friendly control-flow branch using ``jax.lax.cond``."""
    return jax.lax.cond(pred, true_fun, false_fun, operand)


def block_until_ready(x: Any) -> Any:
    return jax.block_until_ready(x)


def device_put(x: Any, device: Any | None = None) -> Any:
    target = device if device is not None else _pick_device()
    return jax.device_put(x, target)


def warmup(calls: list[tuple[Callable[..., Any], tuple[Any, ...], dict[str, Any] | None]]) -> list[Any]:
    """Compile hot kernels ahead of time by running representative dummy inputs."""
    outputs: list[Any] = []
    for fn, args, kwargs in calls:
        kw = kwargs or {}
        t0 = perf_counter()
        out = fn(*args, **kw)
        out = block_until_ready(out)
        dt = (perf_counter() - t0) * 1000.0
        logger.info("jit warmup | fn={} latency_ms={:.2f}", getattr(fn, "__name__", repr(fn)), dt)
        outputs.append(out)
    return outputs


def clear_cache() -> None:
    """Clear JAX/XLA caches and local JIT registry to release memory pressure."""
    try:
        jax.clear_caches()
    except Exception as exc:
        logger.warning("clear_cache: jax.clear_caches failed | err={!r}", exc)
    _JIT_REGISTRY.clear()
    logger.info("clear_cache: jit registry cleared")


def jit_info() -> dict[str, dict[str, Any]]:
    """Return telemetry for compiled ``rice_jit`` functions."""
    return {k: dict(v) for k, v in _JIT_REGISTRY.items()}


def qnode_ready(fn: Callable[..., Any], *, static_argnums: int | tuple[int, ...] | None = None) -> Callable[..., Any]:
    """Wrap PennyLane JAX-interface qnodes/functions with stable JIT defaults."""
    return rice_jit(static_argnums=static_argnums)(fn)


def _warmup_identity_impl(x: Any) -> Any:
    return jnp.asarray(x)


warmup_identity = rice_jit()(_warmup_identity_impl)


__all__ = [
    "block_until_ready",
    "clear_cache",
    "cond_branch",
    "device_put",
    "jit_compile",
    "jit_info",
    "parallel_map",
    "qnode_ready",
    "rice_jit",
    "rice_vmap",
    "scan_loop",
    "vectorize_axis0",
    "warmup",
    "warmup_identity",
]
