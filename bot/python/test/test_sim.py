"""Tests for sim layer (Qiskit, PennyLane): models, optional quantum tests when extra sim installed."""

import pytest

from sim.models import CircuitConfig, JobStatus, ResultSummary


def test_sim_models() -> None:
    """Sim models are importable."""
    c = CircuitConfig(num_qubits=2)
    assert c.num_qubits == 2
    r = ResultSummary(shots=1024, num_qubits=2)
    assert r.success
    assert JobStatus.DONE.value == "DONE"


@pytest.mark.quantum
def test_sim_placeholder() -> None:
    """Placeholder for Qiskit/PennyLane tests when extra sim is installed."""
    assert ResultSummary(shots=0, num_qubits=0).success
