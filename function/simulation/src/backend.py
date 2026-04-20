"""Qiskit Aer — symulatory, konfiguracja, liczba shotów."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import Any

from qiskit_aer import AerSimulator

# TODO:
# [ ] implement backend registry:
# [ ]     qiskit: AerSimulator, FakeBackend, IBMBackend (when RICE_IBM_TOKEN set)
# [ ]     pennylane: default.qubit, default.mixed, lightning.qubit, lightning.gpu
# [ ]     jax: cpu|gpu|tpu — device from RICE_JAX_DEVICE env var
# [ ] implement backend selection strategy:
# [ ]     select based on: circuit_depth, n_qubits, noise_model, gpu_available
# [ ]     selection logic reads .rice-compute.json
# [ ] implement backend health check on startup
# [ ] implement shot configuration: n_shots from RICE_QUANTUM_SHOTS env var
# [ ] implement backend caching: reuse initialized backend across circuits


def aer_simulator(**kwargs: Any) -> AerSimulator:
    """`AerSimulator` z opcjonalnymi parametrami (np. `method`, `max_parallel_threads`)."""
    return AerSimulator(**kwargs)


def statevector_simulator(**kwargs: Any) -> Any:
    from qiskit_aer import StatevectorSimulator

    return StatevectorSimulator(**kwargs)


def unitary_simulator(**kwargs: Any) -> Any:
    from qiskit_aer import UnitarySimulator

    return UnitarySimulator(**kwargs)


def density_matrix_simulator(**kwargs: Any) -> Any:
    from qiskit_aer import AerSimulator

    opts = {"method": "density_matrix", **kwargs}
    return AerSimulator(**opts)


def configure_shots(backend: AerSimulator, shots: int) -> None:
    """Ustawia domyślne shoty (`set_options` na backendzie Aer)."""
    backend.set_options(shots=shots)
