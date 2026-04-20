"""PennyLane — gradienty: parameter-shift, adjoint, VQE/QAOA."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import Any

import pennylane as qml


def parameter_shift_gradient(qnode: Any, params: Any) -> Any:
    """Gradient przez `qml.grad` (parameter-shift dla wielu urządzeń)."""
    g = qml.grad(qnode)
    return g(params)


def value_and_grad_qnode(qnode: Any, params: Any) -> tuple[Any, Any]:
    """Wartość kosztu i gradient."""
    return qml.value_and_grad(qnode)(params)


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
