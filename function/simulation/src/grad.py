"""Automatic differentiation and optimization helpers for JAX-based simulations."""

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
import jax.numpy as jnp
from helper import RiceError, logger

from .const import OPTIMIZER_TOLERANCE
from .jit import rice_jit

F = TypeVar("F", bound=Callable[..., Any])
DEFAULT_LEARNING_RATE = 1e-2


def _tree_l2_norm(tree: Any) -> jax.Array:
    leaves = jax.tree_util.tree_leaves(tree)
    if not leaves:
        return jnp.asarray(0.0, dtype=jnp.float32)
    sq = [jnp.sum(jnp.abs(jnp.asarray(x)) ** 2) for x in leaves]
    return jnp.sqrt(jnp.sum(jnp.stack(sq)))


def _complex_safe_delta(param: Any, grad: Any, lr: float) -> Any:
    p = jnp.asarray(param)
    g = jnp.asarray(grad)
    if jnp.iscomplexobj(g) and not jnp.iscomplexobj(p):
        g = jnp.real(g)
    return p - jnp.asarray(lr, dtype=p.dtype) * g


def grad_scalar(fun: F, argnums: int = 0) -> F:
    return jax.grad(fun, argnums=argnums)


def jacobian(fun: F, argnums: int = 0) -> F:
    """Higher-order derivative wrapper for Jacobian matrices/tensors."""
    return jax.jacobian(fun, argnums=argnums)


def hessian(fun: F, argnums: int = 0) -> F:
    """Second-order derivative wrapper for Hessians."""
    return jax.hessian(fun, argnums=argnums)


def value_and_grad(fun: F, argnums: int = 0, *, has_aux: bool = False) -> F:
    """Logged wrapper around ``jax.value_and_grad`` for optimization telemetry."""
    vag = jax.value_and_grad(fun, argnums=argnums, has_aux=has_aux)

    def _wrapped(*args: Any, **kwargs: Any) -> Any:
        out = vag(*args, **kwargs)
        if has_aux:
            (val, aux), grads = out
        else:
            val, grads = out
            aux = None
        grad_norm = float(_tree_l2_norm(grads))
        logger.debug(
            "value_and_grad | fn={} value={} grad_norm={:.6f} has_aux={}",
            getattr(fun, "__name__", repr(fun)),
            float(jnp.real(jnp.asarray(val))),
            grad_norm,
            has_aux,
        )
        return ((val, aux), grads) if has_aux else (val, grads)

    return _wrapped  # type: ignore[return-value]


def value_and_grad_fn(fun: F, argnums: int = 0) -> F:
    return value_and_grad(fun, argnums=argnums, has_aux=False)


def gradient_clipping(grads: Any, max_norm: float = 1.0) -> Any:
    """Clip gradient pytree by global L2 norm."""
    n = _tree_l2_norm(grads)
    max_n = jnp.asarray(float(max_norm), dtype=n.dtype)
    scale = jnp.where((n > 0) & (n > max_n), max_n / (n + 1e-12), 1.0)
    return jax.tree_util.tree_map(lambda g: jnp.asarray(g) * scale, grads)


@rice_jit(static_argnums=(2, 3))
def _apply_gradients_jitted(params: Any, grads: Any, learning_rate: float, clip_norm: float | None) -> Any:
    used = gradient_clipping(grads, max_norm=float(clip_norm)) if clip_norm is not None else grads
    return jax.tree_util.tree_map(
        lambda p, g: _complex_safe_delta(p, g, learning_rate),
        params,
        used,
    )


def apply_gradients(
    params: Any,
    grads: Any,
    learning_rate: float = DEFAULT_LEARNING_RATE,
    *,
    clip_norm: float | None = None,
) -> Any:
    """Functional SGD update on immutable JAX pytrees."""
    return _apply_gradients_jitted(params, grads, float(learning_rate), clip_norm)


def check_nans(tree: Any, *, name: str = "gradients") -> None:
    """Raise when NaN/Inf appears in optimization state."""
    leaves = jax.tree_util.tree_leaves(tree)
    for idx, leaf in enumerate(leaves):
        arr = jnp.asarray(leaf)
        if bool(jnp.any(~jnp.isfinite(arr))):
            raise RiceError(
                f"{name} contains NaN/Inf",
                error_code="SIM_GRAD_NAN",
                details={"leaf_index": idx, "shape": tuple(arr.shape)},
            )


def freeze_tree(tree: Any, mask: Any | None = None) -> Any:
    """Apply stop-gradient globally or selectively via boolean mask pytree."""
    if mask is None:
        return jax.tree_util.tree_map(jax.lax.stop_gradient, tree)
    return jax.tree_util.tree_map(
        lambda x, m: jax.lax.stop_gradient(x) if bool(m) else x,
        tree,
        mask,
    )


def batch_value_and_grad(
    fun: F,
    *,
    argnums: int = 0,
    in_axes: Any = 0,
    has_aux: bool = False,
) -> Callable[..., Any]:
    """Vectorized value-and-grad over batch dimension(s) using ``jax.vmap``."""
    vag = jax.value_and_grad(fun, argnums=argnums, has_aux=has_aux)
    return jax.vmap(vag, in_axes=in_axes, out_axes=0)


def hybrid_value_and_grad(
    fun: F,
    *,
    argnums: int = 0,
    has_aux: bool = False,
    clip_norm: float | None = None,
    check_finite: bool = True,
) -> Callable[..., Any]:
    """Robust wrapper for classical-pre/quantum/post pipelines."""
    vag = value_and_grad(fun, argnums=argnums, has_aux=has_aux)

    def _wrapped(*args: Any, **kwargs: Any) -> Any:
        out = vag(*args, **kwargs)
        if has_aux:
            (val, aux), grads = out
        else:
            val, grads = out
            aux = None
        if clip_norm is not None:
            grads = gradient_clipping(grads, max_norm=clip_norm)
        if check_finite:
            check_nans(grads, name="hybrid_gradients")
        return ((val, aux), grads) if has_aux else (val, grads)

    return _wrapped


def custom_vjp_stub() -> None:
    """Placeholder — full ``jax.custom_vjp`` hooks can be added here later."""
    return None


__all__ = [
    "DEFAULT_LEARNING_RATE",
    "OPTIMIZER_TOLERANCE",
    "apply_gradients",
    "batch_value_and_grad",
    "check_nans",
    "custom_vjp_stub",
    "freeze_tree",
    "grad_scalar",
    "gradient_clipping",
    "hessian",
    "hybrid_value_and_grad",
    "jacobian",
    "value_and_grad",
    "value_and_grad_fn",
]
