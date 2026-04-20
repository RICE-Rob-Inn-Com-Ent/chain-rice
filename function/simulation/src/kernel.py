"""PennyLane — jądra kwantowe, fidelność, embeddingi, most do klasyfikatorów."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import Any

import pennylane as qml

# TODO:
# [ ] implement JAX custom kernels via jax.pure_callback:
# [ ]     bridge to Mojo kernels in job/src/mojo/ for GPU ops
# [ ] implement GPU kernel dispatch:
# [ ]     cuBLAS via jax.lax operations on GPU device
# [ ] implement JAX PRNG: jax.random.PRNGKey seeding
# [ ]     seed from RICE_JAX_SEED env var (default: 42)
# [ ] implement scan/fori_loop for sequential computation without Python loop


def fidelity_between_states(state0: Any, state1: Any) -> Any:
    """|⟨ψ|φ⟩|² dla wektorów stanu (normalizowanych)."""
    from pennylane import math as pmath

    return pmath.abs(pmath.vdot(state0, state1)) ** 2


def quantum_embedding_angle(x: float, wire: int) -> None:
    """Prosty embedding: obrót RX proporcjonalny do cechy."""
    qml.RX(x, wires=wire)


def kernel_matrix_from_fidelity(
    feature_circuits: list[Any],
    n_qubits: int,
) -> Any:
    """Szkic: macierz podobieństwa wymaga ewaluacji stanów — użyj `default.qubit` + stan wektorowy."""
    raise NotImplementedError(
        "kernel_matrix_from_fidelity: zdefiniuj feature map i policz stany przez oddzielne QNode"
    )


def svm_bridge_note() -> str:
    """Wskazówka: macierz jądra K_ij → klasyczny SVM (sklearn) na K."""
    return (
        "Compute K_ij = |<phi(x_i)|phi(x_j)>|^2 via fidelity; then "
        "sklearn.svm.SVC(kernel='precomputed', ...)"
    )
