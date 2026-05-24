"""Centralized randomness engine for JAX, Qiskit, and PennyLane simulations."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import threading
from dataclasses import dataclass
from typing import Any, Literal

import jax
import jax.numpy as jnp
import numpy as np
from helper import RiceError, logger

from .const import PARAM_SHIFT, PRECISION_COMPLEX, PRECISION_REAL

_DTYPE_REAL = jnp.float64 if PRECISION_REAL == "float64" else jnp.float32
_DTYPE_COMPLEX = jnp.complex128 if PRECISION_COMPLEX == "complex128" else jnp.complex64

_SEED_LOCK = threading.Lock()
_GLOBAL_SEED: int = 42
_GLOBAL_KEY = jax.random.PRNGKey(_GLOBAL_SEED)
_AER_SEED: int = _GLOBAL_SEED
np.random.seed(_GLOBAL_SEED)


@dataclass(frozen=True, slots=True)
class SamplingStats:
    mean: float
    variance: float
    std: float
    n_samples: int


def set_seed(seed: int) -> int:
    """Set global reproducible seed for JAX, NumPy, and Qiskit Aer consumers."""
    global _GLOBAL_SEED, _GLOBAL_KEY, _AER_SEED
    s = int(seed)
    with _SEED_LOCK:
        _GLOBAL_SEED = s
        _GLOBAL_KEY = jax.random.PRNGKey(s)
        _AER_SEED = s
        np.random.seed(s)
    logger.info("simulation.random.set_seed | seed={} (jax/numpy/qiskit-aer)", s)
    return s


def get_aer_seed() -> int:
    return int(_AER_SEED)


def prng_key(seed: int) -> Any:
    return jax.random.PRNGKey(int(seed))


def get_next_key(num: int = 1) -> Any:
    """Split and return fresh JAX key(s), preventing key reuse in JIT paths."""
    global _GLOBAL_KEY
    n = max(1, int(num))
    with _SEED_LOCK:
        keys = jax.random.split(_GLOBAL_KEY, n + 1)
        _GLOBAL_KEY = keys[0]
        out = keys[1:]
    return out[0] if n == 1 else out


def split_key(key: Any, num: int = 2) -> Any:
    return jax.random.split(key, num)


def normal_sample(key: Any, shape: tuple[int, ...], *, loc: float = 0.0, scale: float = 1.0) -> Any:
    return jnp.asarray(loc, dtype=_DTYPE_REAL) + jnp.asarray(scale, dtype=_DTYPE_REAL) * jax.random.normal(
        key,
        shape,
        dtype=_DTYPE_REAL,
    )


def uniform_sample(key: Any, shape: tuple[int, ...], *, minval: float = 0.0, maxval: float = 1.0) -> Any:
    return jax.random.uniform(
        key,
        shape,
        minval=jnp.asarray(minval, dtype=_DTYPE_REAL),
        maxval=jnp.asarray(maxval, dtype=_DTYPE_REAL),
        dtype=_DTYPE_REAL,
    )


def get_random_statevector(num_qubits: int, *, key: Any | None = None) -> jax.Array:
    """Sample Haar-random pure state uniformly from Hilbert space."""
    n = max(1, int(num_qubits))
    dim = 2**n
    k_re, k_im = split_key(get_next_key() if key is None else key, 2)
    re = jax.random.normal(k_re, (dim,), dtype=_DTYPE_REAL)
    im = jax.random.normal(k_im, (dim,), dtype=_DTYPE_REAL)
    vec = re + 1j * im
    norm = jnp.linalg.norm(vec) + 1e-12
    state = jnp.asarray(vec / norm, dtype=_DTYPE_COMPLEX)
    return state


def get_random_density_matrix(num_qubits: int, *, key: Any | None = None) -> jax.Array:
    """Generate random PSD density matrix with unit trace via Ginibre ensemble."""
    n = max(1, int(num_qubits))
    dim = 2**n
    k_re, k_im = split_key(get_next_key() if key is None else key, 2)
    re = jax.random.normal(k_re, (dim, dim), dtype=_DTYPE_REAL)
    im = jax.random.normal(k_im, (dim, dim), dtype=_DTYPE_REAL)
    x = re + 1j * im
    rho = x @ jnp.conj(x.T)
    rho = rho / (jnp.trace(rho) + 1e-12)
    return jnp.asarray(rho, dtype=_DTYPE_COMPLEX)


def is_valid_state(state: Any, *, tol: float = 1e-6) -> bool:
    """Validate vector normalization or density matrix physicality."""
    arr = jnp.asarray(state)
    if arr.ndim == 1:
        nrm = jnp.linalg.norm(arr)
        return bool(jnp.isfinite(nrm) and jnp.abs(nrm - 1.0) <= tol)
    if arr.ndim == 2 and arr.shape[0] == arr.shape[1]:
        herm = jnp.allclose(arr, jnp.conj(arr.T), atol=tol, rtol=tol)
        tr1 = jnp.abs(jnp.trace(arr) - 1.0) <= tol
        evals = jnp.linalg.eigvalsh(arr)
        psd = jnp.all(evals >= -tol)
        return bool(herm and tr1 and psd)
    return False


def get_random_circuit(
    num_qubits: int,
    depth: int,
    *,
    backend: Literal["qiskit", "rice"] = "qiskit",
    include_measure: bool = True,
    seed: int | None = None,
) -> Any:
    """Generate random RX/RY/RZ/CNOT benchmark circuits for Qiskit or RiceCircuit."""
    n = max(1, int(num_qubits))
    d = max(1, int(depth))
    local_seed = int(_GLOBAL_SEED if seed is None else seed)
    rng = np.random.default_rng(local_seed)
    one_q = ("rx", "ry", "rz")
    two_q = ("cx",)

    if backend == "rice":
        from .circuit import RiceCircuit

        rc = RiceCircuit(n_qubits=n)
        for _ in range(d):
            if n > 1 and rng.random() < 0.35:
                q1, q2 = rng.choice(n, size=2, replace=False)
                rc.add_gate("cx", int(q1), int(q2))
            else:
                q = int(rng.integers(0, n))
                gate = str(rng.choice(one_q))
                angle = float((rng.random() * 2.0 - 1.0) * float(PARAM_SHIFT))
                rc.add_gate(gate, q, param=angle)
        if include_measure:
            for q in range(min(rc.n_qubits, rc.n_clbits)):
                rc.add_gate("measure", q)
        return rc

    from qiskit import QuantumCircuit

    qc = QuantumCircuit(n, n if include_measure else 0)
    for _ in range(d):
        if n > 1 and rng.random() < 0.35:
            q1, q2 = rng.choice(n, size=2, replace=False)
            qc.cx(int(q1), int(q2))
        else:
            q = int(rng.integers(0, n))
            angle = float((rng.random() * 2.0 - 1.0) * float(PARAM_SHIFT))
            gate = str(rng.choice(one_q))
            if gate == "rx":
                qc.rx(angle, q)
            elif gate == "ry":
                qc.ry(angle, q)
            else:
                qc.rz(angle, q)
    if include_measure:
        qc.measure(list(range(n)), list(range(n)))
    return qc


def generate_thermal_noise(amplitude: float, shape: tuple[int, ...], *, key: Any | None = None) -> jax.Array:
    """Gaussian thermal fluctuation field for environment-noise experiments."""
    k = get_next_key() if key is None else key
    amp = float(max(0.0, amplitude))
    return amp * jax.random.normal(k, shape, dtype=_DTYPE_REAL)


def sampling_statistics(
    probabilities: Any,
    shots: int,
    *,
    method: Literal["multinomial", "poisson", "binomial"] = "multinomial",
    key: Any | None = None,
) -> tuple[dict[str, int], SamplingStats]:
    """Sample finite-shot counts and return summary stats."""
    probs = jnp.asarray(probabilities, dtype=_DTYPE_REAL).reshape(-1)
    if probs.size == 0:
        raise ValueError("probabilities cannot be empty")
    probs = probs / (jnp.sum(probs) + 1e-12)
    n = max(1, int(shots))
    k = get_next_key() if key is None else key
    if method == "poisson":
        lam = probs * n
        counts_arr = jax.random.poisson(k, lam=lam, shape=lam.shape)
    elif method == "binomial":
        # Independent binomials are an approximation (not strictly multinomial-coupled).
        counts_arr = jax.random.binomial(k, n=n, p=probs, shape=probs.shape)
    else:
        counts_arr = jax.random.multinomial(k, n=n, p=probs)
    counts_np = np.asarray(counts_arr, dtype=np.int64).reshape(-1)
    labels = [format(i, f"0{int(np.ceil(np.log2(max(2, len(counts_np))))) }b").replace(" ", "") for i in range(len(counts_np))]
    counts = {labels[i]: int(counts_np[i]) for i in range(len(counts_np))}
    vals = counts_np.astype(np.float64)
    stats = SamplingStats(
        mean=float(np.mean(vals)),
        variance=float(np.var(vals)),
        std=float(np.std(vals)),
        n_samples=int(vals.size),
    )
    return counts, stats


def monte_carlo_mean(key: Any, sampler: Any, n: int) -> Any:
    """Średnia z `n` próbek `sampler(subkey)` — `sampler` przyjmuje jeden PRNG key."""
    keys = jax.random.split(key, n)
    samples = jax.vmap(sampler)(keys)
    return jnp.mean(samples, axis=0)


__all__ = [
    "SamplingStats",
    "generate_thermal_noise",
    "get_aer_seed",
    "get_next_key",
    "get_random_circuit",
    "get_random_density_matrix",
    "get_random_statevector",
    "is_valid_state",
    "monte_carlo_mean",
    "normal_sample",
    "prng_key",
    "sampling_statistics",
    "set_seed",
    "split_key",
    "uniform_sample",
]
