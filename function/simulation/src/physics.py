"""Physics primitives for quantum simulation: operators, Hamiltonians, observables, and dynamics."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import re
from dataclasses import dataclass
from functools import reduce
from typing import Any

import jax
import jax.numpy as jnp
from helper import RiceError
from jax.scipy.linalg import expm as jax_expm

from .const import H_BAR, PRECISION_COMPLEX, PRECISION_REAL

_REAL_DTYPE = jnp.float64 if PRECISION_REAL == "float64" else jnp.float32
_COMPLEX_DTYPE = jnp.complex128 if PRECISION_COMPLEX == "complex128" else jnp.complex64

I: jax.Array = jnp.asarray([[1.0, 0.0], [0.0, 1.0]], dtype=_COMPLEX_DTYPE)
X: jax.Array = jnp.asarray([[0.0, 1.0], [1.0, 0.0]], dtype=_COMPLEX_DTYPE)
Y: jax.Array = jnp.asarray([[0.0, -1j], [1j, 0.0]], dtype=_COMPLEX_DTYPE)
Z: jax.Array = jnp.asarray([[1.0, 0.0], [0.0, -1.0]], dtype=_COMPLEX_DTYPE)
_PAULI = {"I": I, "X": X, "Y": Y, "Z": Z}

_INDEXED_TERM = re.compile(r"^([IXYZ])(\d+)$")


def _kron(a: jax.Array, b: jax.Array) -> jax.Array:
    return jnp.kron(a, b)


def _normalize_pauli_string(label: str, n_qubits: int | None = None) -> str:
    s = label.strip().upper().replace(" ", "")
    if not s:
        raise ValueError("pauli label cannot be empty")
    if all(ch in _PAULI for ch in s):
        if n_qubits is not None and len(s) != n_qubits:
            raise ValueError(f"pauli string length {len(s)} != n_qubits {n_qubits}")
        return s

    tokens = [tok for tok in s.split("+") if tok]
    if len(tokens) != 1:
        raise ValueError(f"invalid pauli label: {label!r}")
    m = _INDEXED_TERM.match(tokens[0])
    if m is None:
        raise ValueError(f"invalid indexed pauli label: {label!r}")
    op = m.group(1)
    idx = int(m.group(2))
    n = max((n_qubits or 0), idx + 1)
    chars = ["I"] * n
    chars[idx] = op
    return "".join(chars)


def pauli_kron(pauli_string: str) -> jax.Array:
    """Build N-qubit operator from a Pauli string (e.g. ``XIYZ``)."""
    ps = _normalize_pauli_string(pauli_string)
    mats = [_PAULI[ch] for ch in ps]
    return reduce(_kron, mats)


@jax.jit
def _expectation_state_jit(state: jax.Array, operator: jax.Array) -> jax.Array:
    bra = jnp.conj(state)
    return jnp.vdot(bra, operator @ state)


@jax.jit
def _expectation_density_jit(rho: jax.Array, operator: jax.Array) -> jax.Array:
    return jnp.trace(rho @ operator)


@jax.jit
def _trace_jit(rho: jax.Array) -> jax.Array:
    return jnp.trace(rho)


@jax.jit
def _is_hermitian_jit(mat: jax.Array, tol: float) -> jax.Array:
    return jnp.allclose(mat, jnp.conj(mat.T), atol=tol, rtol=tol)


@jax.jit
def _is_unitary_jit(mat: jax.Array, tol: float) -> jax.Array:
    ident = jnp.eye(mat.shape[0], dtype=mat.dtype)
    return jnp.allclose(jnp.conj(mat.T) @ mat, ident, atol=tol, rtol=tol)


def expectation_value(state_or_rho: Any, operator: Any) -> complex:
    """Compute ``<psi|O|psi>`` for state vectors or ``Tr(rho O)`` for density matrices."""
    arr = jnp.asarray(state_or_rho, dtype=_COMPLEX_DTYPE)
    op = jnp.asarray(operator, dtype=_COMPLEX_DTYPE)
    if arr.ndim == 1:
        val = _expectation_state_jit(arr, op)
    elif arr.ndim == 2:
        val = _expectation_density_jit(arr, op)
    else:
        raise ValueError("state_or_rho must be a vector or square density matrix")
    return complex(val)


def trace_density(rho: Any) -> complex:
    """Trace of a density matrix."""
    arr = jnp.asarray(rho, dtype=_COMPLEX_DTYPE)
    return complex(_trace_jit(arr))


def partial_trace_density(rho: Any, keep: list[int], n_qubits: int) -> jax.Array:
    """Partial trace over qubits not in ``keep`` for an ``n_qubits`` density matrix."""
    arr = jnp.asarray(rho, dtype=_COMPLEX_DTYPE)
    if arr.shape != (2**n_qubits, 2**n_qubits):
        raise ValueError("rho shape does not match n_qubits")
    keep_set = sorted(set(int(i) for i in keep))
    if any(i < 0 or i >= n_qubits for i in keep_set):
        raise ValueError("keep indices out of range")
    dims = [2] * n_qubits
    reshaped = arr.reshape(*dims, *dims)
    trace_out = [i for i in range(n_qubits) if i not in keep_set]
    for q in reversed(trace_out):
        reshaped = jnp.trace(reshaped, axis1=q, axis2=q + n_qubits)
    out_dim = 2 ** len(keep_set)
    return reshaped.reshape(out_dim, out_dim)


def is_hermitian(operator: Any, tol: float = 1e-8) -> bool:
    arr = jnp.asarray(operator, dtype=_COMPLEX_DTYPE)
    return bool(_is_hermitian_jit(arr, float(tol)))


def is_unitary(operator: Any, tol: float = 1e-8) -> bool:
    arr = jnp.asarray(operator, dtype=_COMPLEX_DTYPE)
    if arr.ndim != 2 or arr.shape[0] != arr.shape[1]:
        return False
    return bool(_is_unitary_jit(arr, float(tol)))


def random_hermitian(key: Any, dim: int) -> jax.Array:
    """Generate a random Hermitian matrix for tests/benchmarks."""
    if dim <= 0:
        raise ValueError("dim must be positive")
    k = key if hasattr(key, "shape") else jax.random.PRNGKey(int(key))
    re = jax.random.normal(k, (dim, dim), dtype=_REAL_DTYPE)
    im = jax.random.normal(k, (dim, dim), dtype=_REAL_DTYPE)
    mat = re + 1j * im
    return jnp.asarray((mat + jnp.conj(mat.T)) / 2.0, dtype=_COMPLEX_DTYPE)


@dataclass(frozen=True)
class PauliTerm:
    coeff: float
    pauli: str


class Hamiltonian:
    """Weighted sum of Pauli terms with export helpers for Qiskit and PennyLane."""

    def __init__(self, terms: list[PauliTerm] | None = None, *, n_qubits: int | None = None) -> None:
        self._terms: list[PauliTerm] = []
        self._n_qubits = int(n_qubits) if n_qubits is not None else None
        for t in terms or []:
            self.add_term(t.coeff, t.pauli)

    @property
    def n_qubits(self) -> int:
        if self._n_qubits is None:
            raise ValueError("n_qubits is undefined for empty Hamiltonian")
        return self._n_qubits

    @property
    def terms(self) -> list[PauliTerm]:
        return list(self._terms)

    def add_term(self, coeff: float, pauli: str) -> Hamiltonian:
        normalized = _normalize_pauli_string(pauli, self._n_qubits)
        if self._n_qubits is None:
            self._n_qubits = len(normalized)
        self._terms.append(PauliTerm(coeff=float(coeff), pauli=normalized))
        return self

    def matrix(self) -> jax.Array:
        if not self._terms:
            raise ValueError("Hamiltonian has no terms")
        dim = 2 ** self.n_qubits
        acc = jnp.zeros((dim, dim), dtype=_COMPLEX_DTYPE)
        for term in self._terms:
            acc = acc + jnp.asarray(term.coeff, dtype=_COMPLEX_DTYPE) * pauli_kron(term.pauli)
        return acc

    def energy_time_phase(self, t: float) -> jax.Array:
        """Unitary ``U = exp(-i H t / hbar)``."""
        h = self.matrix()
        return jax_expm((-1j / H_BAR) * h * jnp.asarray(t, dtype=_REAL_DTYPE))

    def to_qiskit_sparse_pauli_op(self) -> Any:
        """Convert to Qiskit ``SparsePauliOp``."""
        try:
            from qiskit.quantum_info import SparsePauliOp
        except Exception as exc:
            raise RiceError(
                "qiskit is required for SparsePauliOp export",
                error_code="SIM_PHYSICS_QISKIT_EXPORT",
                details={"reason": str(exc)},
            ) from exc
        labels = [term.pauli for term in self._terms]
        coeffs = [complex(term.coeff) for term in self._terms]
        return SparsePauliOp(labels, coeffs=coeffs)

    def to_pennylane_hamiltonian(self) -> Any:
        """Convert to PennyLane ``qml.Hamiltonian``."""
        try:
            import pennylane as qml
        except Exception as exc:
            raise RiceError(
                "pennylane is required for Hamiltonian export",
                error_code="SIM_PHYSICS_PENNYLANE_EXPORT",
                details={"reason": str(exc)},
            ) from exc

        ops: list[Any] = []
        coeffs: list[float] = []
        for term in self._terms:
            factors: list[Any] = []
            for idx, ch in enumerate(term.pauli):
                if ch == "I":
                    factors.append(qml.Identity(idx))
                elif ch == "X":
                    factors.append(qml.PauliX(idx))
                elif ch == "Y":
                    factors.append(qml.PauliY(idx))
                elif ch == "Z":
                    factors.append(qml.PauliZ(idx))
                else:
                    raise ValueError(f"unknown pauli symbol {ch!r}")
            ops.append(factors[0] if len(factors) == 1 else qml.prod(*factors))
            coeffs.append(term.coeff)
        return qml.Hamiltonian(coeffs, ops)


def ising_model_placeholder(n_qubits: int, j_coupling: float, h_field: float) -> Hamiltonian:
    """Placeholder generator for transverse-field Ising model."""
    ham = Hamiltonian(n_qubits=n_qubits)
    for i in range(max(0, n_qubits - 1)):
        chars = ["I"] * n_qubits
        chars[i] = "Z"
        chars[i + 1] = "Z"
        ham.add_term(-j_coupling, "".join(chars))
    for i in range(n_qubits):
        chars = ["I"] * n_qubits
        chars[i] = "X"
        ham.add_term(-h_field, "".join(chars))
    return ham


def fermi_hubbard_placeholder() -> None:
    """Placeholder for future Fermi-Hubbard model builder."""
    return None


def evolve_state(
    hamiltonian: Any,
    psi0: Any,
    t: float,
) -> Any:
    """Schrodinger evolution: ``|psi(t)> = exp(-i H t / hbar) |psi(0)>``."""
    h = jnp.asarray(hamiltonian, dtype=_COMPLEX_DTYPE)
    p = jnp.asarray(psi0, dtype=_COMPLEX_DTYPE)
    u = jax_expm((-1j / H_BAR) * h * jnp.asarray(t, dtype=_REAL_DTYPE))
    return u @ p


def euler_step(
    rhs: Any,
    y: Any,
    dt: float,
) -> Any:
    """One Euler step for ``dy/dt = rhs(y)``."""
    return y + jnp.asarray(dt, dtype=_REAL_DTYPE) * rhs(y)


def rk4_step(
    rhs: Any,
    y: Any,
    dt: float,
) -> Any:
    """One RK4 step for ``dy/dt = rhs(y)``."""
    k1 = rhs(y)
    k2 = rhs(y + 0.5 * dt * k1)
    k3 = rhs(y + 0.5 * dt * k2)
    k4 = rhs(y + dt * k3)
    return y + (dt / 6.0) * (k1 + 2 * k2 + 2 * k3 + k4)


def harmonic_oscillator_rhs(m: float, k: float) -> Any:
    """RHS for ``(x, p)`` with ``dx/dt = p/m`` and ``dp/dt = -k x``."""

    def rhs(state: Any) -> Any:
        x, p = state[0], state[1]
        return jnp.stack([p / m, -k * x])

    return rhs


__all__ = [
    "Hamiltonian",
    "I",
    "PauliTerm",
    "X",
    "Y",
    "Z",
    "euler_step",
    "evolve_state",
    "expectation_value",
    "fermi_hubbard_placeholder",
    "harmonic_oscillator_rhs",
    "is_hermitian",
    "is_unitary",
    "ising_model_placeholder",
    "partial_trace_density",
    "pauli_kron",
    "random_hermitian",
    "rk4_step",
    "trace_density",
]
