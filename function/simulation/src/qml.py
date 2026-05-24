"""High-level QML layers/models for PennyLane + JAX hybrid workflows."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from collections.abc import Callable
from typing import Any

import jax
import jax.numpy as jnp
from helper import logger
import pennylane as qml

from .const import DEFAULT_QUBITS, OPTIMIZER_TOLERANCE, PARAM_SHIFT
from .grad import apply_gradients, hybrid_value_and_grad
from .gradient import QuantumOptimizer, parameter_shift_grad

DEFAULT_WEIGHT_INIT = "uniform"
DEFAULT_WEIGHT_SCALE = float(PARAM_SHIFT)
DEFAULT_BIAS_INIT = 0.0


def default_qubit_device(wires: int, *, shots: int | None = None) -> Any:
    """Domyślne `default.qubit` (bez szumu; `shots=None` = dokładny stan)."""
    return qml.device("default.qubit", wires=wires, shots=shots)


def make_qnode(
    func: Callable[..., Any],
    device: Any,
    *,
    interface: str = "auto",
    diff_method: str | None = "best",
) -> Any:
    """Owrapowanie funkcji w `qml.QNode`."""
    return qml.QNode(func, device, interface=interface, diff_method=diff_method)


def strong_entangler_layers(weights: Any, wires: range | list[int]) -> None:
    from pennylane.templates import StronglyEntanglingLayers

    StronglyEntanglingLayers(weights=weights, wires=wires)


def basic_entangler_layer(theta: Any, wires: list[int]) -> None:
    """Jedna warstwa: RX + CNOT łańcuch."""
    for i, w in enumerate(wires):
        qml.RX(theta[i], wires=w)
    for i in range(len(wires) - 1):
        qml.CNOT(wires=[wires[i], wires[i + 1]])


class QuantumFeatureMap:
    """Classical-to-quantum encodings (angle, amplitude, data reuploading)."""

    @staticmethod
    def angle_encoding(x: Any, wires: list[int], *, rotation: str = "ry") -> None:
        vals = jnp.asarray(x).reshape(-1)
        n = min(len(wires), vals.shape[0])
        rot = rotation.strip().lower()
        for i in range(n):
            if rot == "rx":
                qml.RX(vals[i], wires=wires[i])
            elif rot == "rz":
                qml.RZ(vals[i], wires=wires[i])
            else:
                qml.RY(vals[i], wires=wires[i])

    @staticmethod
    def amplitude_encoding(x: Any, wires: list[int], *, normalize: bool = True) -> None:
        vec = jnp.asarray(x).reshape(-1)
        target_len = 2 ** len(wires)
        if vec.shape[0] < target_len:
            vec = jnp.pad(vec, (0, target_len - vec.shape[0]))
        elif vec.shape[0] > target_len:
            vec = vec[:target_len]
        if normalize:
            norm = jnp.linalg.norm(vec) + 1e-12
            vec = vec / norm
        qml.AmplitudeEmbedding(vec, wires=wires, normalize=False)

    @staticmethod
    def data_reuploading(
        x: Any,
        weights: Any,
        wires: list[int],
        *,
        repeats: int = 2,
    ) -> None:
        vals = jnp.asarray(x).reshape(-1)
        w = jnp.asarray(weights)
        rep = max(1, int(repeats))
        for r in range(rep):
            for i, qubit in enumerate(wires):
                x_i = vals[i % max(1, vals.shape[0])]
                w_i = w[r % max(1, w.shape[0]), i % max(1, w.shape[-1])] if w.ndim >= 2 else w[i % max(1, w.shape[0])]
                qml.RY(x_i + w_i, wires=qubit)
            for i in range(len(wires) - 1):
                qml.CNOT(wires=[wires[i], wires[i + 1]])


class QuantumLayer:
    """JAX-compatible wrapper around a PennyLane qnode."""

    def __init__(
        self,
        qnode: Any,
        *,
        use_quantum_optimizer: bool = False,
    ) -> None:
        self.qnode = qnode
        self.optimizer = QuantumOptimizer(method="parameter_shift") if use_quantum_optimizer else None

    def __call__(self, x: Any, params: Any) -> jax.Array:
        return jnp.asarray(self.qnode(x, params))

    def gradients(self, x: Any, params: Any) -> jax.Array:
        if self.optimizer is not None:
            g = self.optimizer.gradient(lambda p: self.qnode(x, p), params)
        else:
            g = parameter_shift_grad(lambda p: self.qnode(x, p), params)
        return jnp.asarray(g)

    def value_and_grad(self, x: Any, params: Any) -> tuple[jax.Array, Any]:
        fun = lambda p: jnp.real(jnp.asarray(self.qnode(x, p))).sum()
        vg = hybrid_value_and_grad(fun)
        val, grad = vg(params)
        return jnp.asarray(val), grad


def init_quantum_weights(
    key: Any,
    shape: tuple[int, ...],
    *,
    strategy: str = DEFAULT_WEIGHT_INIT,
    scale: float = DEFAULT_WEIGHT_SCALE,
) -> jax.Array:
    strat = strategy.strip().lower()
    if strat == "normal":
        return jax.random.normal(key, shape) * float(scale)
    return jax.random.uniform(key, shape, minval=-float(scale), maxval=float(scale))


class HybridModel:
    """Composable hybrid model: classical preprocess -> quantum layer -> classical head."""

    def __init__(
        self,
        quantum_layer: QuantumLayer,
        *,
        preprocess: Callable[[Any], Any] | None = None,
        postprocess: Callable[[Any], Any] | None = None,
    ) -> None:
        self.quantum_layer = quantum_layer
        self.preprocess = preprocess
        self.postprocess = postprocess

    def __call__(self, x: Any, qparams: Any, *, cparams: Any | None = None) -> Any:
        h = self.preprocess(x) if self.preprocess is not None else x
        qout = self.quantum_layer(h, qparams)
        out = self.postprocess((qout, cparams)) if self.postprocess is not None else qout
        return out

    def train_step(
        self,
        x: Any,
        y: Any,
        qparams: Any,
        *,
        learning_rate: float = 1e-2,
    ) -> tuple[Any, jax.Array, float]:
        target = jnp.asarray(y)

        def loss_fn(p: Any) -> jax.Array:
            pred = jnp.asarray(self(x, p))
            return jnp.mean((pred - target) ** 2)

        vg = hybrid_value_and_grad(loss_fn, has_aux=False, check_finite=True)
        loss, grads = vg(qparams)
        new_params = apply_gradients(qparams, grads, learning_rate=learning_rate, clip_norm=1.0)
        leaves = [jnp.asarray(x).reshape(-1) for x in jax.tree_util.tree_leaves(grads)]
        grad_norm = float(jnp.linalg.norm(jnp.concatenate(leaves))) if leaves else 0.0
        loss_value = float(jnp.asarray(loss))
        logger.info("HybridModel.train_step | loss={:.6f} grad_norm={:.6f}", loss_value, grad_norm)
        return new_params, jnp.asarray(loss), grad_norm


class QuantumKernel:
    """Quantum kernel helper for SVM/GP style methods."""

    def __init__(self, embedding_qnode: Any) -> None:
        self.embedding_qnode = embedding_qnode

    def kernel(self, x1: Any, x2: Any) -> jax.Array:
        s1 = jnp.asarray(self.embedding_qnode(x1))
        s2 = jnp.asarray(self.embedding_qnode(x2))
        return jnp.abs(jnp.vdot(s1, s2)) ** 2

    def matrix(self, x_a: Any, x_b: Any | None = None) -> jax.Array:
        xa = jnp.asarray(x_a)
        xb = xa if x_b is None else jnp.asarray(x_b)
        mat = jnp.zeros((xa.shape[0], xb.shape[0]))
        for i in range(xa.shape[0]):
            for j in range(xb.shape[0]):
                mat = mat.at[i, j].set(self.kernel(xa[i], xb[j]))
        return mat


def make_vqc_qnode(
    device: Any,
    n_qubits: int | None = None,
    *,
    n_layers: int = 2,
) -> Any:
    """Template for a variational quantum classifier (multi-qubit outputs)."""
    nq = int(DEFAULT_QUBITS if n_qubits is None else n_qubits)
    wires = list(range(nq))

    @qml.qnode(device, interface="jax", diff_method="adjoint")
    def _vqc(x: Any, weights: Any, bias: Any = DEFAULT_BIAS_INIT) -> Any:
        QuantumFeatureMap.angle_encoding(x, wires, rotation="ry")
        w = jnp.asarray(weights)
        for l in range(max(1, int(n_layers))):
            basic_entangler_layer(w[l], wires)
            for q in wires:
                qml.RZ(w[l, q] + bias, wires=q)
        return [qml.expval(qml.PauliZ(q)) for q in wires]

    return _vqc


def vqc_template(
    key: Any,
    *,
    n_qubits: int | None = None,
    n_layers: int = 2,
    init_strategy: str = DEFAULT_WEIGHT_INIT,
) -> tuple[Any, jax.Array]:
    """Factory returning `(vqc_qnode, initial_weights)`."""
    nq = int(DEFAULT_QUBITS if n_qubits is None else n_qubits)
    dev = default_qubit_device(nq)
    qnode = make_vqc_qnode(dev, nq, n_layers=n_layers)
    weights = init_quantum_weights(key, (max(1, n_layers), nq), strategy=init_strategy)
    return qnode, weights


def ensure_converged(loss: Any, *, tolerance: float = OPTIMIZER_TOLERANCE) -> bool:
    return float(jnp.asarray(loss)) <= float(tolerance)


__all__ = [
    "DEFAULT_BIAS_INIT",
    "DEFAULT_WEIGHT_INIT",
    "DEFAULT_WEIGHT_SCALE",
    "HybridModel",
    "QuantumFeatureMap",
    "QuantumKernel",
    "QuantumLayer",
    "basic_entangler_layer",
    "default_qubit_device",
    "ensure_converged",
    "init_quantum_weights",
    "make_qnode",
    "make_vqc_qnode",
    "strong_entangler_layers",
    "vqc_template",
]
