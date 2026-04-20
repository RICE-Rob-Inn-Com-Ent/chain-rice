"""JAX — jit, vmap, pmap, scan — szybkie jądra numeryczne."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from collections.abc import Callable
from typing import Any, TypeVar

import jax

F = TypeVar("F", bound=Callable[..., Any])

# TODO:
# [ ] implement JAX JIT compilation:
# [ ]     @jax.jit with static_argnums for shape-dependent operations
# [ ]     static_argnums from config — not hardcoded
# [ ] implement JAX vmap: vectorize function across batch dimension
# [ ]     in_axes, out_axes from config
# [ ] implement JAX pmap: parallel execution across devices
# [ ]     when RICE_JAX_PMAP=true and multiple devices available
# [ ] implement AOT compilation: jax.jit(...).lower(...).compile()
# [ ]     compile once, run many — cache compiled function
# [ ] implement compilation cache: jax.config.jax_compilation_cache_dir
# [ ]     cache dir from RICE_JAX_CACHE_DIR env var


def jit_compile(
    fun: F,
    *,
    static_argnums: int | tuple[int, ...] | None = None,
    donate_argnums: int | tuple[int, ...] | None = None,
) -> F:
    return jax.jit(fun, static_argnums=static_argnums, donate_argnums=donate_argnums)


def vectorize_axis0(fun: Callable[..., Any]) -> Callable[..., Any]:
    return jax.vmap(fun, in_axes=0, out_axes=0)


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


def block_until_ready(x: Any) -> Any:
    return jax.block_until_ready(x)


def device_put(x: Any, device: Any | None = None) -> Any:
    return jax.device_put(x, device)
