"""Quantum-specific gradient methods (parameter-shift, adjoint, SPSA, QNG)."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import math
from typing import Any

import jax
import jax.numpy as jnp
from helper import RiceError, logger
import pennylane as qml

from .const import OPTIMIZER_TOLERANCE, PARAM_SHIFT
from .grad import apply_gradients

def _as_jax_array(x: Any) -> jax.Array:
    return jnp.asarray(x)


def parameter_shift_grad(qnode: Any, params: Any, *, shift: float = PARAM_SHIFT) -> jax.Array:
    """Manual parameter-shift gradient: ``[f(theta+s)-f(theta-s)] / (2*sin(s))``."""
    theta = _as_jax_array(params)
    flat = theta.reshape(-1)
    s = float(shift)
    denom = 2.0 * math.sin(s)
    grads: list[jax.Array] = []
    evals = 0
    for i in range(flat.shape[0]):
        basis = jnp.zeros_like(flat).at[i].set(1.0)
        plus = (flat + s * basis).reshape(theta.shape)
        minus = (flat - s * basis).reshape(theta.shape)
        f_plus = _as_jax_array(qnode(plus))
        f_minus = _as_jax_array(qnode(minus))
        grads.append((f_plus - f_minus) / denom)
        evals += 2
    out = jnp.stack(grads).reshape(theta.shape)
    logger.info("parameter_shift_grad | evals={} shift={} params={}", evals, s, flat.shape[0])
    return out


def finite_difference_grad(qnode: Any, params: Any, *, epsilon: float = 1e-4) -> jax.Array:
    """Central finite-difference gradient for debugging/verification."""
    theta = _as_jax_array(params)
    flat = theta.reshape(-1)
    eps = float(epsilon)
    grads: list[jax.Array] = []
    evals = 0
    for i in range(flat.shape[0]):
        basis = jnp.zeros_like(flat).at[i].set(1.0)
        plus = (flat + eps * basis).reshape(theta.shape)
        minus = (flat - eps * basis).reshape(theta.shape)
        f_plus = _as_jax_array(qnode(plus))
        f_minus = _as_jax_array(qnode(minus))
        grads.append((f_plus - f_minus) / (2.0 * eps))
        evals += 2
    out = jnp.stack(grads).reshape(theta.shape)
    logger.info("finite_difference_grad | evals={} epsilon={} params={}", evals, eps, flat.shape[0])
    return out


def adjoint_grad(qnode: Any, params: Any) -> jax.Array:
    """Use PennyLane adjoint differentiation when available."""
    try:
        adj_qnode = qml.QNode(
            qnode.func if hasattr(qnode, "func") else qnode,
            qnode.device if hasattr(qnode, "device") else None,
            interface="jax",
            diff_method="adjoint",
        )
    except Exception:
        # Fallback for callables / already-constructed adjoint nodes.
        adj_qnode = qnode
    grad_fn = jax.grad(lambda p: jnp.real(_as_jax_array(adj_qnode(p))))
    g = _as_jax_array(grad_fn(_as_jax_array(params)))
    logger.info("adjoint_grad | params={}", g.size)
    return g


def qiskit_estimator_gradient(
    estimator: Any,
    circuits: list[Any],
    observables: list[Any],
    parameter_values: list[Any],
    *,
    method: str = "parameter_shift",
) -> Any:
    """Wrapper for Qiskit's estimator gradients (`parameter_shift` / `lincomb`)."""
    try:
        if method == "lincomb":
            from qiskit_algorithms.gradients import LinCombEstimatorGradient as _Grad
        else:
            from qiskit_algorithms.gradients import ParameterShiftEstimatorGradient as _Grad
    except Exception as exc:
        raise RiceError(
            "qiskit gradient package unavailable",
            error_code="SIM_GRAD_QISKIT_IMPORT",
            details={"reason": str(exc), "method": method},
        ) from exc
    grad = _Grad(estimator)
    job = grad.run(circuits, observables, parameter_values)
    return job.result()


def spsa_grad(
    qnode: Any,
    params: Any,
    *,
    epsilon: float = 1e-2,
    rng_key: Any | None = None,
) -> jax.Array:
    """SPSA noisy gradient estimator (2 function evaluations independent of dimension)."""
    theta = _as_jax_array(params)
    key = rng_key if rng_key is not None else jax.random.PRNGKey(0)
    delta = jax.random.choice(key, jnp.asarray([-1.0, 1.0]), shape=theta.shape)
    eps = float(epsilon)
    f_plus = _as_jax_array(qnode(theta + eps * delta))
    f_minus = _as_jax_array(qnode(theta - eps * delta))
    g = (f_plus - f_minus) / (2.0 * eps * delta)
    logger.info("spsa_grad | evals=2 epsilon={} params={}", eps, theta.size)
    return _as_jax_array(g)


def quantum_natural_gradient_step(
    qnode: Any,
    params: Any,
    *,
    learning_rate: float,
    damping: float = 1e-6,
) -> tuple[jax.Array, jax.Array, jax.Array]:
    """One QNG step: ``params - lr * (G + damping I)^(-1) grad``."""
    theta = _as_jax_array(params)
    val_fn = lambda p: jnp.real(_as_jax_array(qnode(p)))
    grad = _as_jax_array(jax.grad(val_fn)(theta))
    try:
        metric = _as_jax_array(qml.metric_tensor(qnode)(theta))
    except Exception:
        # Fallback to identity metric if unavailable.
        metric = jnp.eye(theta.reshape(-1).shape[0], dtype=theta.dtype)
    dim = metric.shape[0]
    reg_metric = metric + jnp.eye(dim, dtype=metric.dtype) * float(damping)
    nat_grad = jnp.linalg.solve(reg_metric, grad.reshape(-1)).reshape(theta.shape)
    updated = _as_jax_array(apply_gradients(theta, nat_grad, learning_rate=learning_rate))
    return updated, nat_grad, metric


def value_and_grad_qnode(qnode: Any, params: Any) -> tuple[jax.Array, jax.Array]:
    """Value + gradient with JAX/PennyLane compatibility."""
    val = _as_jax_array(qnode(params))
    g = _as_jax_array(jax.grad(lambda p: jnp.real(_as_jax_array(qnode(p))))(_as_jax_array(params)))
    return val, g


def vqe_energy_qnode(hamiltonian: Any, ansatz: Any, params: Any, device: Any) -> Any:
    """Przykład VQE: `ansatz` jako callable zwracający oczekiwanie H."""
    return ansatz(params)


def qaoa_layer_rx_mixer(gamma: float, beta: float, wires: list[int], n_ising_pairs: int) -> None:
    """Uproszczona warstwa QAOA: faza ZZ (para kolejnych qubitów) + mikser RX."""
    for i in range(min(n_ising_pairs, len(wires) - 1)):
        qml.IsingZZ(2 * gamma, wires=[wires[i], wires[i + 1]])
    for w in wires:
        qml.RX(2 * beta, wires=w)


def metric_tensor_natural_gradient(qnode: Any, params: Any) -> Any:
    """Tensor metryczny (PennyLane — API zależne od wersji)."""
    try:
        mt = qml.metric_tensor(qnode)
        return mt(params)
    except Exception:
        return None


def parameter_shift_gradient(qnode: Any, params: Any) -> Any:
    """Backward-compatible alias."""
    return parameter_shift_grad(qnode, params)


class QuantumOptimizer:
    """Bridge between quantum gradient estimators and update rules from ``src.grad``."""

    def __init__(
        self,
        *,
        method: str = "parameter_shift",
        learning_rate: float = 1e-2,
        tolerance: float = OPTIMIZER_TOLERANCE,
        clip_norm: float | None = None,
    ) -> None:
        self.method = method
        self.learning_rate = float(learning_rate)
        self.tolerance = float(tolerance)
        self.clip_norm = clip_norm

    def gradient(self, qnode: Any, params: Any, *, rng_key: Any | None = None) -> jax.Array:
        m = self.method.strip().lower()
        if m in {"parameter_shift", "shift"}:
            return parameter_shift_grad(qnode, params)
        if m in {"adjoint"}:
            return adjoint_grad(qnode, params)
        if m in {"finite_diff", "finite_difference", "fd"}:
            return finite_difference_grad(qnode, params)
        if m in {"spsa"}:
            return spsa_grad(qnode, params, rng_key=rng_key)
        raise ValueError(f"unsupported quantum gradient method {self.method!r}")

    def step(self, qnode: Any, params: Any, *, rng_key: Any | None = None) -> tuple[jax.Array, jax.Array]:
        g = self.gradient(qnode, params, rng_key=rng_key)
        g_norm = float(jnp.linalg.norm(jnp.asarray(g).reshape(-1)))
        logger.info("QuantumOptimizer.step | method={} grad_norm={:.6f}", self.method, g_norm)
        updated = _as_jax_array(
            apply_gradients(
                _as_jax_array(params),
                g,
                learning_rate=self.learning_rate,
                clip_norm=self.clip_norm,
            ),
        )
        return updated, _as_jax_array(g)

    def converged(self, grad: Any) -> bool:
        norm = float(jnp.linalg.norm(_as_jax_array(grad).reshape(-1)))
        return norm <= self.tolerance


__all__ = [
    "QuantumOptimizer",
    "adjoint_grad",
    "finite_difference_grad",
    "metric_tensor_natural_gradient",
    "parameter_shift_grad",
    "parameter_shift_gradient",
    "qaoa_layer_rx_mixer",
    "qiskit_estimator_gradient",
    "quantum_natural_gradient_step",
    "spsa_grad",
    "value_and_grad_qnode",
    "vqe_energy_qnode",
]
