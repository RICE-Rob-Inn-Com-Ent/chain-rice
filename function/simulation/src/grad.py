"""JAX — grad, jacobian, hessian, value_and_grad, niestandardowe VJP."""

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
# [ ] implement JAX gradient computation:
# [ ]     jax.grad, jax.value_and_grad, jax.jacfwd, jax.jacrev
# [ ]     argnums from config — which argument to differentiate
# [ ] implement higher-order gradients: jax.hessian
# [ ] implement gradient clipping: clip by norm from RICE_GRAD_CLIP_NORM env var
# [ ] implement PennyLane gradient methods:
# [ ]     parameter-shift, adjoint, backprop — method from RICE_GRAD_METHOD env var


def grad_scalar(fun: F, argnums: int = 0) -> F:
    return jax.grad(fun, argnums=argnums)


def jacobian(fun: F, argnums: int = 0) -> F:
    return jax.jacobian(fun, argnums=argnums)


def hessian(fun: F, argnums: int = 0) -> F:
    return jax.hessian(fun, argnums=argnums)


def value_and_grad_fn(fun: F, argnums: int = 0) -> F:
    return jax.value_and_grad(fun, argnums=argnums)


def custom_vjp_stub() -> None:
    """Placeholder — pełne `jax.custom_vjp` / `defvjp` zobacz dokumentację JAX."""
    return None
