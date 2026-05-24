"""Unified quantum circuit factory for Qiskit and PennyLane/JAX."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import random as py_random
from dataclasses import dataclass
from typing import TYPE_CHECKING, Any

from helper import RiceError, logger

from .const import DEFAULT_QUBITS, PARAM_SHIFT, SHOTS
from .physics import I, pauli_kron

if TYPE_CHECKING:  # pragma: no cover - typing only
    from qiskit import QuantumCircuit

_SINGLE_QUBIT_GATES = {"h", "x", "y", "z", "s", "t"}
_PARAM_GATES = {"rx", "ry", "rz"}
_TWO_QUBIT_GATES = {"cx", "cz"}
_THREE_QUBIT_GATES = {"ccx"}


@dataclass(frozen=True, slots=True)
class GateOp:
    name: str
    qubits: tuple[int, ...]
    param: float | str | None = None
    metadata: dict[str, Any] | None = None


class RiceCircuit:
    """Stateful, backend-agnostic circuit representation with export helpers."""

    def __init__(self, n_qubits: int | None = None, n_clbits: int | None = None) -> None:
        nq = int(DEFAULT_QUBITS if n_qubits is None else n_qubits)
        if nq <= 0:
            raise ValueError("n_qubits must be positive")
        self.n_qubits = nq
        self.n_clbits = int(n_clbits if n_clbits is not None else nq)
        self._ops: list[GateOp] = []
        self._gate_counts: dict[str, int] = {}

    @property
    def ops(self) -> list[GateOp]:
        return list(self._ops)

    @property
    def depth(self) -> int:
        return len(self._ops)

    @property
    def gate_counts(self) -> dict[str, int]:
        return dict(self._gate_counts)

    def _validate_qubits(self, qubits: tuple[int, ...]) -> None:
        if not qubits:
            raise ValueError("gate must target at least one qubit")
        for q in qubits:
            if q < 0 or q >= self.n_qubits:
                raise ValueError(f"qubit index {q} out of range [0, {self.n_qubits - 1}]")

    def add_gate(self, name: str, *qubits: int, param: float | str | None = None) -> RiceCircuit:
        gate = name.strip().lower()
        q = tuple(int(i) for i in qubits)
        self._validate_qubits(q)
        if gate in _SINGLE_QUBIT_GATES and len(q) != 1:
            raise ValueError(f"{gate} expects 1 qubit")
        if gate in _PARAM_GATES and len(q) != 1:
            raise ValueError(f"{gate} expects 1 qubit")
        if gate in _PARAM_GATES and param is None:
            raise ValueError(f"{gate} requires a parameter")
        if gate in _TWO_QUBIT_GATES and len(q) != 2:
            raise ValueError(f"{gate} expects 2 qubits")
        if gate in _THREE_QUBIT_GATES and len(q) != 3:
            raise ValueError(f"{gate} expects 3 qubits")
        if gate == "measure" and len(q) != 1:
            raise ValueError("measure expects 1 qubit")
        if gate == "barrier":
            q = tuple(range(self.n_qubits))
        self._ops.append(GateOp(name=gate, qubits=q, param=param))
        self._gate_counts[gate] = self._gate_counts.get(gate, 0) + 1
        return self

    def add_entanglement_layer(self, qubits: list[int] | None = None) -> RiceCircuit:
        wires = qubits if qubits is not None else list(range(self.n_qubits))
        for q in wires:
            self.add_gate("h", q)
        for i in range(len(wires) - 1):
            self.add_gate("cx", wires[i], wires[i + 1])
        return self

    def add_rotation_layer(
        self,
        *,
        rx: list[float | str] | None = None,
        ry: list[float | str] | None = None,
        rz: list[float | str] | None = None,
        qubits: list[int] | None = None,
    ) -> RiceCircuit:
        wires = qubits if qubits is not None else list(range(self.n_qubits))
        for i, q in enumerate(wires):
            if rx is not None:
                self.add_gate("rx", q, param=rx[i])
            if ry is not None:
                self.add_gate("ry", q, param=ry[i])
            if rz is not None:
                self.add_gate("rz", q, param=rz[i])
        return self

    def add_ansatz(self, depth: int = 1, parameter_prefix: str = "theta") -> RiceCircuit:
        """Simple hardware-efficient ansatz: RY-RZ layers + linear CNOT entanglement."""
        d = max(1, int(depth))
        for layer in range(d):
            ry = [f"{parameter_prefix}_ry_{layer}_{q}" for q in range(self.n_qubits)]
            rz = [f"{parameter_prefix}_rz_{layer}_{q}" for q in range(self.n_qubits)]
            self.add_rotation_layer(ry=ry, rz=rz)
            for q in range(self.n_qubits - 1):
                self.add_gate("cx", q, q + 1)
        return self

    def compose(self, other: RiceCircuit) -> RiceCircuit:
        if self.n_qubits != other.n_qubits:
            raise ValueError("cannot compose circuits with different n_qubits")
        out = RiceCircuit(self.n_qubits, n_clbits=max(self.n_clbits, other.n_clbits))
        for op in [*self._ops, *other._ops]:
            out._ops.append(op)
            out._gate_counts[op.name] = out._gate_counts.get(op.name, 0) + 1
        return out

    def _to_qiskit_param(self, param: float | str | None, cache: dict[str, Any]) -> Any:
        if not isinstance(param, str):
            return param
        if param in cache:
            return cache[param]
        from qiskit.circuit import Parameter

        p = Parameter(param)
        cache[param] = p
        return p

    def to_qiskit(self) -> QuantumCircuit:
        from qiskit import QuantumCircuit

        qc = QuantumCircuit(self.n_qubits, self.n_clbits)
        p_cache: dict[str, Any] = {}
        for op in self._ops:
            n = op.name
            q = op.qubits
            if n in _SINGLE_QUBIT_GATES:
                getattr(qc, n)(q[0])
            elif n in _PARAM_GATES:
                getattr(qc, n)(self._to_qiskit_param(op.param, p_cache), q[0])
            elif n in _TWO_QUBIT_GATES:
                getattr(qc, n)(q[0], q[1])
            elif n in _THREE_QUBIT_GATES:
                qc.ccx(q[0], q[1], q[2])
            elif n == "measure":
                qc.measure(q[0], q[0] if q[0] < self.n_clbits else 0)
            elif n == "barrier":
                qc.barrier(*q)
            elif n == "unitary":
                mat = op.metadata.get("matrix") if op.metadata else None
                if mat is None:
                    raise ValueError("unitary gate missing matrix metadata")
                qc.unitary(mat, list(q))
            else:
                raise ValueError(f"unsupported gate for qiskit export: {n!r}")
        logger.info("RiceCircuit.to_qiskit | depth={} gate_counts={}", self.depth, self._gate_counts)
        return qc

    def to_pennylane_qnode(
        self,
        *,
        device: Any,
        params: dict[str, Any] | None = None,
        interface: str = "jax",
        diff_method: str | None = "best",
    ) -> Any:
        import pennylane as qml

        p = params or {}

        def _resolve_param(raw: float | str | None) -> Any:
            if isinstance(raw, str):
                if raw not in p:
                    raise ValueError(f"missing symbolic parameter {raw!r} for PennyLane export")
                return p[raw]
            return raw

        def _circuit() -> Any:
            for op in self._ops:
                n = op.name
                q = list(op.qubits)
                if n == "h":
                    qml.Hadamard(wires=q[0])
                elif n == "x":
                    qml.PauliX(wires=q[0])
                elif n == "y":
                    qml.PauliY(wires=q[0])
                elif n == "z":
                    qml.PauliZ(wires=q[0])
                elif n == "s":
                    qml.S(wires=q[0])
                elif n == "t":
                    qml.T(wires=q[0])
                elif n == "rx":
                    qml.RX(_resolve_param(op.param), wires=q[0])
                elif n == "ry":
                    qml.RY(_resolve_param(op.param), wires=q[0])
                elif n == "rz":
                    qml.RZ(_resolve_param(op.param), wires=q[0])
                elif n == "cx":
                    qml.CNOT(wires=[q[0], q[1]])
                elif n == "cz":
                    qml.CZ(wires=[q[0], q[1]])
                elif n == "barrier":
                    continue
                elif n == "unitary":
                    mat = op.metadata.get("matrix") if op.metadata else None
                    if mat is None:
                        raise ValueError("unitary gate missing matrix metadata")
                    qml.QubitUnitary(mat, wires=q)
                elif n == "measure":
                    continue
                else:
                    raise ValueError(f"unsupported gate for PennyLane export: {n!r}")
            return qml.state()

        qnode = qml.QNode(_circuit, device, interface=interface, diff_method=diff_method)
        logger.info("RiceCircuit.to_pennylane_qnode | depth={} gate_counts={}", self.depth, self._gate_counts)
        return qnode

    def to_qasm(self, version: str = "2.0") -> str:
        qc = self.to_qiskit()
        v = version.strip()
        if v.startswith("3"):
            try:
                from qiskit.qasm3 import dumps as qasm3_dumps
            except Exception as exc:
                raise RiceError(
                    "QASM3 export requires qiskit.qasm3 support",
                    error_code="SIM_CIRCUIT_QASM3",
                    details={"reason": str(exc)},
                ) from exc
            return str(qasm3_dumps(qc))
        return str(qc.qasm())

    def draw(self, output: str = "text") -> Any:
        qc = self.to_qiskit()
        return qc.draw(output=output)

    def add_pauli_unitary(self, pauli_string: str, qubits: list[int] | None = None) -> RiceCircuit:
        wires = qubits if qubits is not None else list(range(self.n_qubits))
        mat = pauli_kron(pauli_string)
        if mat.shape[0] != 2 ** len(wires):
            raise ValueError("pauli unitary dimension mismatch with selected qubits")
        self._validate_qubits(tuple(wires))
        self._ops.append(GateOp(name="unitary", qubits=tuple(wires), metadata={"matrix": mat}))
        self._gate_counts["unitary"] = self._gate_counts.get("unitary", 0) + 1
        return self


def get_random_circuit(
    n_qubits: int | None = None,
    depth: int = 12,
    *,
    seed: int | None = None,
    include_measure: bool = True,
) -> RiceCircuit:
    """Generate a random circuit for stress tests (execute/transpile paths)."""
    rng = py_random.Random(seed)
    rc = RiceCircuit(n_qubits=n_qubits)
    one_qubit = ["h", "x", "y", "z", "s", "t", "rx", "ry", "rz"]
    two_qubit = ["cx", "cz"]
    for _ in range(max(1, int(depth))):
        if rc.n_qubits >= 2 and rng.random() < 0.35:
            g = rng.choice(two_qubit)
            q1, q2 = rng.sample(range(rc.n_qubits), k=2)
            rc.add_gate(g, q1, q2)
            continue
        g = rng.choice(one_qubit)
        q = rng.randrange(rc.n_qubits)
        if g in _PARAM_GATES:
            angle = (rng.random() * 2.0 - 1.0) * float(PARAM_SHIFT)
            rc.add_gate(g, q, param=angle)
        else:
            rc.add_gate(g, q)
    if include_measure:
        for q in range(min(rc.n_qubits, rc.n_clbits)):
            rc.add_gate("measure", q)
    logger.info("get_random_circuit | qubits={} depth={}", rc.n_qubits, rc.depth)
    return rc


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


__all__ = [
    "GateOp",
    "RiceCircuit",
    "add_rotation_y",
    "add_toffoli",
    "barrier_all",
    "bell_state_circuit",
    "compose_circuits",
    "empty_circuit",
    "get_random_circuit",
]
