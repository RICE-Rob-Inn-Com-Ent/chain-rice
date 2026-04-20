"""Qiskit Aer — modele szumu: depolaryzacja, relaksacja termiczna, błąd odczytu."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import Any

from qiskit_aer.noise import NoiseModel

# TODO:
# [ ] implement Qiskit noise models:
# [ ]     depolarizing_error, thermal_relaxation_error, amplitude_damping_error
# [ ]     error rates from RICE_NOISE_* env vars — never hardcoded
# [ ] implement fake backend noise: load from Qiskit fake provider
# [ ]     fake backend name from RICE_FAKE_BACKEND env var
# [ ] implement PennyLane noise channels:
# [ ]     DepolarizingChannel, AmplitudeDamping, PhaseFlip
# [ ] implement noise model serialization to JSON for reproducibility


def empty_noise_model() -> NoiseModel:
    return NoiseModel()


def depolarizing_single_and_two_qubit(p1: float, p2: float | None = None) -> NoiseModel:
    """Depolaryzacja na bramkach 1Q i 2Q (wszystkie qubity)."""
    from qiskit_aer.noise import depolarizing_error

    p2 = p2 if p2 is not None else p1
    nm = NoiseModel()
    nm.add_all_qubit_quantum_error(depolarizing_error(p1, 1), ["h", "rx", "ry", "rz", "id", "x", "y", "z"])
    nm.add_all_qubit_quantum_error(depolarizing_error(p2, 2), ["cx", "cz", "swap"])
    return nm


def thermal_relaxation_on_gate(
    t1_ns: float,
    t2_ns: float,
    gate_time_ns: float,
    num_qubits: int,
) -> NoiseModel:
    from qiskit_aer.noise import thermal_relaxation_error

    nm = NoiseModel()
    err = thermal_relaxation_error(t1_ns, t2_ns, gate_time_ns)
    for q in range(num_qubits):
        nm.add_quantum_error(err, ["id"], [q])
    return nm


def readout_error_matrix(prob_meas0_prep1: float, prob_meas1_prep0: float) -> Any:
    """Macierz błędu odczytu dla `ReadoutError`."""
    from qiskit_aer.noise import ReadoutError

    p0 = 1.0 - prob_meas0_prep1
    p1 = 1.0 - prob_meas1_prep0
    return ReadoutError([[p0, prob_meas0_prep1], [prob_meas1_prep0, p1]])
