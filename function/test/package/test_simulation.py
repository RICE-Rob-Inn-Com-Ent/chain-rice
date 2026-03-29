"""Unit: `function/simulation` — Qiskit, PennyLane, JAX."""

from __future__ import annotations

import jax.numpy as jnp
import pennylane as qml
import pytest

from function.simulation.circuit import bell_state_circuit
from function.simulation.execute import counts_from_result, run_shots
from function.simulation.physics import evolve_state
from function.simulation.qml import default_qubit_device

# TODO:
# [ ] test circuit: QuantumCircuit builds without error
# [ ] test execute: circuit runs on AerSimulator, returns counts
# [ ] test noise model: noisy circuit has higher error rate than noiseless
# [ ] test jit: jit-compiled function returns same result as eager
# [ ] test grad: gradient of x^2 at x=3 ≈ 6
# [ ] test vmap: vectorized function matches loop result
# [ ] test qml VQE: energy converges below threshold for simple Hamiltonian
# [ ] gpu(jax): jax.devices() includes GPU when RICE_JAX_DEVICE=gpu
# [ ] quantum: Qiskit circuit measures correct probabilities for Bell state


def test_bell_and_shots() -> None:
    qc = bell_state_circuit(measure=True)
    r = run_shots(qc, shots=32)
    c = counts_from_result(r)
    assert sum(c.values()) == 32


def test_evolve_state() -> None:
    h = jnp.array([[1.0, 0.0], [0.0, -1.0]], dtype=jnp.complex128)
    psi = jnp.array([1.0, 0.0], dtype=jnp.complex128)
    out = evolve_state(h, psi, 0.05)
    assert out.shape == (2,)


@pytest.mark.quantum
def test_pennylane_expval() -> None:
    dev = default_qubit_device(1, shots=None)

    @qml.qnode(dev)
    def f():
        qml.Hadamard(0)
        return qml.expval(qml.PauliZ(0))

    assert abs(float(f())) < 0.01
