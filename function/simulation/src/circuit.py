"""Qiskit — `QuantumCircuit`, bramki, bariery, pomiary, składanie obwodów."""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from qiskit import QuantumCircuit

# TODO:
# [ ] implement Qiskit QuantumCircuit builder:
# [ ]     n_qubits, n_classical_bits as parameters — not hardcoded
# [ ] implement standard gate library: H, X, Y, Z, CNOT, CZ, T, S, Rx, Ry, Rz
# [ ] implement parameterized circuits: ParameterVector for VQE/QAOA
# [ ]     parameter names from RICE_CIRCUIT_PARAM_PREFIX env var
# [ ] implement circuit composition: circuit.compose(), append(), tensor()
# [ ] implement PennyLane qnode decorator:
# [ ]     device from backend.py, diff_method from RICE_DIFF_METHOD env var
# [ ] implement circuit visualization: circuit.draw(output="mpl"|"text"|"latex")
# [ ]     output format from RICE_CIRCUIT_DRAW_FORMAT env var


def empty_circuit(num_qubits: int, num_clbits: int | None = None) -> "QuantumCircuit":
    from qiskit import QuantumCircuit

    return QuantumCircuit(num_qubits, num_clbits or num_qubits)


def bell_state_circuit(measure: bool = True) -> "QuantumCircuit":
    """Stan Bella: H, CX; opcjonalnie pomiar."""
    from qiskit import QuantumCircuit

    qc = QuantumCircuit(2, 2 if measure else 0)
    qc.h(0)
    qc.cx(0, 1)
    if measure:
        qc.measure([0, 1], [0, 1])
    return qc


def barrier_all(qc: "QuantumCircuit") -> None:
    qc.barrier()


def compose_circuits(a: "QuantumCircuit", b: "QuantumCircuit", *, front: bool = False) -> "QuantumCircuit":
    """`a.compose(b)` — domyślnie `b` za `a`."""
    return a.compose(b, front=front)


def add_rotation_y(qc: "QuantumCircuit", qubit: int, angle: float) -> None:
    from qiskit.circuit.library import RYGate

    qc.append(RYGate(angle), [qubit])


def add_toffoli(qc: "QuantumCircuit", c1: int, c2: int, t: int) -> None:
    qc.ccx(c1, c2, t)
