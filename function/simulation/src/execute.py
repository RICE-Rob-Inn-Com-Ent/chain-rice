"""Qiskit + Aer — uruchomienie jobów, wyniki, counts, statevector."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from qiskit import QuantumCircuit

# TODO:
# [ ] implement Qiskit transpile + execute pipeline:
# [ ]     transpile(circuit, backend, optimization_level=RICE_TRANSPILE_OPT_LEVEL)
# [ ]     backend.run(transpiled, shots=RICE_QUANTUM_SHOTS)
# [ ] implement result extraction: counts, statevector, density_matrix, expectation
# [ ] implement error mitigation:
# [ ]     ZNE (Zero Noise Extrapolation) when RICE_ERROR_MITIGATION=zne
# [ ]     M3 readout mitigation when RICE_ERROR_MITIGATION=m3
# [ ] implement parallel circuit execution: batch_size from RICE_CIRCUIT_BATCH_SIZE
# [ ] implement Temporal activity wrapping for long-running simulations
# [ ]     timeout from RICE_SIM_TIMEOUT_S env var
# [ ] implement OTel tracing: span per circuit execution with n_qubits, depth, shots


def run_shots(
    circuit: "QuantumCircuit",
    *,
    shots: int = 1024,
    backend: Any | None = None,
    noise_model: Any | None = None,
    **run_kwargs: Any,
) -> Any:
    """`backend.run` na skompilowanym obwodzie — zwraca `Result`."""
    from qiskit import transpile
    from qiskit_aer import AerSimulator

    if backend is not None:
        be = backend
    elif noise_model is not None:
        be = AerSimulator(noise_model=noise_model)
    else:
        be = AerSimulator()
    tc = transpile(circuit, backend=be)
    job = be.run(tc, shots=shots, **run_kwargs)
    return job.result()


def counts_from_result(result: Any) -> dict[str, int]:
    return result.get_counts()


def statevector_from_result(result: Any) -> Any:
    return result.get_statevector()


def unitary_from_result(result: Any) -> Any:
    return result.get_unitary()


def run_statevector(circuit: "QuantumCircuit", **kwargs: Any) -> Any:
    from qiskit import transpile
    from qiskit_aer import StatevectorSimulator

    sim = StatevectorSimulator(**kwargs)
    tc = transpile(circuit, backend=sim)
    job = sim.run(tc, shots=1)
    return job.result().get_statevector()
