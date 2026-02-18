"""Qiskit: build and compile quantum circuits. Requires: qiskit (extra sim).

Provides create_circuit, bell_circuit, ghz_circuit, add_hadamard, add_cnot, add_rotation,
add_single_qubit_gate, compile_circuit, transpile_to_basis, add_measurement, optimize_circuit,
depth, gate_count, create_bell_state, create_ghz_state, create_qft, create_custom_circuit.
Install with: uv sync --extra sim. All comments in English.
"""

from __future__ import annotations

# -----------------------------------------------------------------------------
# QuantumCircuit definitions
# -----------------------------------------------------------------------------


def _qiskit():
    """Lazy import of Qiskit QuantumCircuit. Raises ImportError with install hint if missing."""
    try:
        from qiskit import QuantumCircuit
        return QuantumCircuit
    except ImportError as e:
        raise ImportError(
            "circuits requires qiskit; install: uv sync --extra sim"
        ) from e


def create_circuit(num_qubits: int = 2, num_clbits: int | None = None) -> "QuantumCircuit":
    """Create empty QuantumCircuit with given num_qubits and num_clbits (default = num_qubits)."""
    QC = _qiskit()
    return QC(num_qubits, num_clbits or num_qubits)


def bell_circuit() -> "QuantumCircuit":
    """Bell state circuit (EPR pair): H on 0, CX(0,1), measure."""
    QC = _qiskit()
    qc = QC(2, 2)
    qc.h(0)
    qc.cx(0, 1)
    qc.measure([0, 1], [0, 1])
    return qc


def ghz_circuit(n: int = 3) -> "QuantumCircuit":
    """GHZ circuit on n qubits."""
    QC = _qiskit()
    qc = QC(n, n)
    qc.h(0)
    for i in range(1, n):
        qc.cx(0, i)
    qc.measure(list(range(n)), list(range(n)))
    return qc


# -----------------------------------------------------------------------------
# Gate operations
# -----------------------------------------------------------------------------


def add_hadamard(qc: "QuantumCircuit", qubit: int) -> None:
    """Add Hadamard gate on qubit."""
    qc.h(qubit)


def add_cnot(qc: "QuantumCircuit", control: int, target: int) -> None:
    """Add CX(control, target)."""
    qc.cx(control, target)


def add_rotation(qc: "QuantumCircuit", qubit: int, theta: float, phi: float) -> None:
    """Add U(theta, phi) on qubit (U3-style)."""
    try:
        from qiskit.circuit.library import UGate
        qc.append(UGate(theta, phi, 0.0), [qubit])
    except ImportError:
        qc.u(theta, phi, 0.0, qubit)


def add_single_qubit_gate(qc: "QuantumCircuit", gate_name: str, qubit: int, *params: float) -> None:
    """Add single-qubit gate: h, x, y, z, s, t, rx, ry, rz (params for rotation gates)."""
    g = gate_name.lower()
    if g == "h":
        qc.h(qubit)
    elif g == "x":
        qc.x(qubit)
    elif g == "y":
        qc.y(qubit)
    elif g == "z":
        qc.z(qubit)
    elif g == "s":
        qc.s(qubit)
    elif g == "t":
        qc.t(qubit)
    elif g == "rx" and params:
        qc.rx(params[0], qubit)
    elif g == "ry" and params:
        qc.ry(params[0], qubit)
    elif g == "rz" and params:
        qc.rz(params[0], qubit)
    else:
        raise ValueError(f"Unknown single-qubit gate: {gate_name}")


# -----------------------------------------------------------------------------
# Compilation and transpilation
# -----------------------------------------------------------------------------


def compile_circuit(qc: "QuantumCircuit", optimization_level: int = 1):
    """Compile circuit for target backend (default: AerSimulator)."""
    try:
        from qiskit import transpile
        from qiskit_aer import AerSimulator
        backend = AerSimulator()
        return transpile(qc, backend, optimization_level=optimization_level)
    except ImportError as e:
        raise ImportError(
            "compile_circuit requires qiskit and qiskit-aer; uv sync --extra sim"
        ) from e


def transpile_to_basis(qc: "QuantumCircuit", basis_gates: list[str] | None = None):
    """Transpile circuit to given basis gates."""
    try:
        from qiskit import transpile
        from qiskit_aer import AerSimulator
        backend = AerSimulator()
        basis = basis_gates or ["id", "rz", "sx", "x", "cx"]
        return transpile(qc, backend, basis_gates=basis)
    except ImportError as e:
        raise ImportError("transpile_to_basis wymaga qiskit i qiskit-aer") from e


# -----------------------------------------------------------------------------
# Measurements
# -----------------------------------------------------------------------------


def add_measurement(qc: "QuantumCircuit", qubits: list[int] | None = None, clbits: list[int] | None = None) -> None:
    """Add measurement qubit -> clbit. Default all qubits."""
    n = qc.num_qubits
    qs = qubits if qubits is not None else list(range(n))
    cs = clbits if clbits is not None else list(range(len(qs)))
    qc.measure(qs, cs)


def add_measurements(qc: "QuantumCircuit", qubits: list[int]) -> None:
    """Add measurements for given qubits (to same-index clbits)."""
    qc.measure(qubits, list(range(len(qubits))))


def measure_all(qc: "QuantumCircuit") -> None:
    """Add measurement for all qubits."""
    n = qc.num_qubits
    qc.measure(list(range(n)), list(range(n)))


def get_measurement_ops(qc: "QuantumCircuit"):
    """Return measurement operations in the circuit."""
    return [op for op in qc.data if op.operation.name == "measure"]


# -----------------------------------------------------------------------------
# Circuit optimization
# -----------------------------------------------------------------------------


def optimize_circuit(qc: "QuantumCircuit", level: int = 2):
    """Optimize circuit (transpile with optimization_level)."""
    return compile_circuit(qc, optimization_level=level)


def depth(qc: "QuantumCircuit") -> int:
    """Circuit depth."""
    return qc.depth()


def gate_count(qc: "QuantumCircuit") -> dict[str, int]:
    """Gate count by type."""
    return dict(qc.count_ops())


# -----------------------------------------------------------------------------
# apply_gates, decompose_circuit (spec)
# -----------------------------------------------------------------------------


def apply_gates(qc: "QuantumCircuit", gate_sequence: list[dict]) -> None:
    """Apply a sequence of gates to circuit. Each item: {gate, qubits, params?}."""
    for g in gate_sequence:
        name = (g.get("gate") or g.get("name") or "h").lower()
        qubits = g.get("qubits", [0])
        params = g.get("params", [])
        if name == "h" and qubits:
            qc.h(qubits[0])
        elif name == "x" and qubits:
            qc.x(qubits[0])
        elif name == "y" and qubits:
            qc.y(qubits[0])
        elif name == "z" and qubits:
            qc.z(qubits[0])
        elif name == "cx" and len(qubits) >= 2:
            qc.cx(qubits[0], qubits[1])
        elif name == "rx" and qubits and params:
            qc.rx(params[0], qubits[0])
        elif name == "ry" and qubits and params:
            qc.ry(params[0], qubits[0])
        elif name == "rz" and qubits and params:
            qc.rz(params[0], qubits[0])
        else:
            add_single_qubit_gate(qc, name, qubits[0], *params)


def decompose_circuit(qc: "QuantumCircuit", basis_gates: list[str] | None = None) -> "QuantumCircuit":
    """Decompose circuit to basis gates. Returns transpiled circuit."""
    return transpile_to_basis(qc, basis_gates=basis_gates)


# -----------------------------------------------------------------------------
# Spec aliases and extra builders
# -----------------------------------------------------------------------------


def create_bell_state() -> "QuantumCircuit":
    """Create Bell state circuit (EPR pair). Alias for bell_circuit."""
    return bell_circuit()


def create_ghz_state(n_qubits: int) -> "QuantumCircuit":
    """Create GHZ state on n_qubits. Alias for ghz_circuit."""
    return ghz_circuit(n_qubits)


def create_qft(n_qubits: int) -> "QuantumCircuit":
    """Create QFT circuit on n_qubits (with measurements)."""
    try:
        from qiskit.circuit.library import QFT
        qc = QFT(n_qubits).to_instruction()
        QC = _qiskit()
        circuit = QC(n_qubits, n_qubits)
        circuit.append(qc, range(n_qubits))
        circuit.measure(range(n_qubits), range(n_qubits))
        return circuit
    except ImportError as e:
        raise ImportError("create_qft requires qiskit.circuit.library") from e


def create_custom_circuit(gates: list[dict]) -> "QuantumCircuit":
    """Build circuit from list of gate specs: {gate, qubits, params?}.
    gate: h, x, y, z, cx, rx, ry, rz, etc. qubits: list of int. params: optional list for rx/ry/rz.
    """
    QC = _qiskit()
    max_q = max((max(g.get("qubits", [0])) for g in gates), default=0) + 1
    qc = QC(max_q, max_q)
    for g in gates:
        name = (g.get("gate") or g.get("name") or "h").lower()
        qubits = g.get("qubits", [0])
        params = g.get("params", [])
        if name == "h" and qubits:
            qc.h(qubits[0])
        elif name == "x" and qubits:
            qc.x(qubits[0])
        elif name == "y" and qubits:
            qc.y(qubits[0])
        elif name == "z" and qubits:
            qc.z(qubits[0])
        elif name == "cx" and len(qubits) >= 2:
            qc.cx(qubits[0], qubits[1])
        elif name == "rx" and qubits and params:
            qc.rx(params[0], qubits[0])
        elif name == "ry" and qubits and params:
            qc.ry(params[0], qubits[0])
        elif name == "rz" and qubits and params:
            qc.rz(params[0], qubits[0])
        else:
            add_single_qubit_gate(qc, name, qubits[0], *params)
    qc.measure(list(range(max_q)), list(range(max_q)))
    return qc
