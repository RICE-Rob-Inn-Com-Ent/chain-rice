"""Quantum transpilation and optimization utilities for Qiskit and PennyLane."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Any

from helper import RiceError, logger

from .backend import get_backend_manager
if TYPE_CHECKING:
    from qiskit import QuantumCircuit

_DEFAULT_BASIS_GATES = ["id", "rz", "sx", "x", "cx"]


@dataclass(frozen=True, slots=True)
class CircuitStats:
    depth: int
    gate_count: int
    multi_qubit_gate_count: int

    def to_dict(self) -> dict[str, int]:
        return {
            "depth": int(self.depth),
            "gate_count": int(self.gate_count),
            "multi_qubit_gate_count": int(self.multi_qubit_gate_count),
        }


def build_pass_manager(basis_gates: list[str] | None = None) -> Any:
    """Create a lightweight custom pass manager for extra simplification."""
    try:
        from qiskit.transpiler import PassManager
        from qiskit.transpiler.passes import CommutativeCancellation, CXCancellation, Optimize1qGatesDecomposition
    except Exception as exc:
        raise RiceError(
            "qiskit transpiler passes are unavailable",
            error_code="SIM_TRANSPILE_PASSMANAGER_IMPORT",
            details={"reason": str(exc)},
        ) from exc
    pm = PassManager()
    pm.append(Optimize1qGatesDecomposition(basis=basis_gates or default_basis_gates()))
    pm.append(CXCancellation())
    pm.append(CommutativeCancellation())
    return pm


def transpile_qiskit(
    circuit: "QuantumCircuit",
    *,
    backend: Any | None = None,
    optimization_level: int = 3,
    basis_gates: list[str] | None = None,
    coupling_map: Any | None = None,
    initial_layout: list[int] | dict[int, int] | None = None,
    routing_method: str | None = "sabre",
    pass_manager: Any | None = None,
    seed_transpiler: int | None = None,
    **kwargs: Any,
) -> "QuantumCircuit":
    """Transpile with backend/topology-aware defaults and optional custom pass manager."""
    from qiskit import transpile
    if backend is None:
        backend = get_backend_manager().get_qiskit_backend()
    basis = basis_gates or default_basis_gates()
    lvl = max(0, min(3, int(optimization_level)))
    before = get_circuit_stats(circuit).depth
    transpiled = transpile(
        circuit,
        backend=backend,
        optimization_level=lvl,
        basis_gates=basis,
        coupling_map=coupling_map,
        initial_layout=initial_layout,
        routing_method=routing_method,
        seed_transpiler=seed_transpiler,
        **kwargs,
    )
    if pass_manager is not None:
        transpiled = pass_manager.run(transpiled)
    after = get_circuit_stats(transpiled).depth
    logger.info(
        "transpile_qiskit | optimization_level={} depth_before={} depth_after={} reduction={}",
        lvl,
        before,
        after,
        before - after,
    )
    return transpiled


def coupling_grid(rows: int, cols: int) -> Any:
    """Rectangular nearest-neighbor grid."""
    from qiskit.transpiler import CouplingMap

    edges: list[list[int]] = []
    for r in range(rows):
        for c in range(cols):
            i = r * cols + c
            if c + 1 < cols:
                edges.append([i, i + 1])
            if r + 1 < rows:
                edges.append([i, i + cols])
    return CouplingMap(edges if edges else [[0, 1]])


def coupling_linear(n_qubits: int) -> Any:
    from qiskit.transpiler import CouplingMap

    n = max(2, int(n_qubits))
    return CouplingMap([[i, i + 1] for i in range(n - 1)])


def coupling_ring(n_qubits: int) -> Any:
    from qiskit.transpiler import CouplingMap

    n = max(3, int(n_qubits))
    edges = [[i, (i + 1) % n] for i in range(n)]
    return CouplingMap(edges)


def coupling_heavy_hex(distance: int = 3) -> Any:
    """IBM-like heavy-hex connectivity via Qiskit helper."""
    try:
        from qiskit.transpiler import CouplingMap

        return CouplingMap.from_heavy_hex(distance=max(1, int(distance)))
    except Exception as exc:
        raise RiceError(
            "failed to create heavy-hex coupling map",
            error_code="SIM_TRANSPILE_HEAVY_HEX",
            details={"reason": str(exc), "distance": int(distance)},
        ) from exc


def load_coupling_map(topology: str, *, n_qubits: int = 5, distance: int = 3) -> Any:
    topo = topology.strip().lower()
    if topo == "linear":
        return coupling_linear(n_qubits)
    if topo == "ring":
        return coupling_ring(n_qubits)
    if topo in {"heavyhex", "heavy-hex", "ibm"}:
        return coupling_heavy_hex(distance=distance)
    if topo == "grid":
        side = max(2, int(n_qubits**0.5))
        return coupling_grid(side, side)
    raise ValueError(f"unknown topology {topology!r}")


def map_virtual_to_physical(circuit: "QuantumCircuit", layout: list[int] | dict[int, int]) -> "QuantumCircuit":
    """Apply a deterministic initial layout to reduce SWAP insertion."""
    mapping = layout if isinstance(layout, dict) else {i: int(v) for i, v in enumerate(layout)}
    return transpile_qiskit(
        circuit,
        initial_layout=mapping,
        optimization_level=3,
    )


def default_basis_gates() -> list[str]:
    return list(_DEFAULT_BASIS_GATES)


def optimize_pennylane(qnode: Any) -> Any:
    """Apply standard PennyLane circuit simplification transforms."""
    try:
        import pennylane as qml
    except Exception as exc:
        raise RiceError(
            "pennylane is required for optimize_pennylane",
            error_code="SIM_TRANSPILE_PENNYLANE_IMPORT",
            details={"reason": str(exc)},
        ) from exc
    optimized = qml.transforms.cancel_inverses(qnode)
    optimized = qml.transforms.merge_rotations(optimized)
    optimized = qml.transforms.commute_controlled(optimized)
    return optimized


def get_circuit_stats(circuit: Any) -> CircuitStats:
    """Return depth, total gate count, and expensive multi-qubit gate count."""
    depth = int(circuit.depth()) if hasattr(circuit, "depth") else 0
    count_ops = circuit.count_ops() if hasattr(circuit, "count_ops") else {}
    gate_count = int(sum(int(v) for v in count_ops.values()))
    multi = 0
    if hasattr(circuit, "data"):
        for inst in circuit.data:
            op = getattr(inst, "operation", inst[0] if isinstance(inst, tuple) else None)
            n_q = int(getattr(op, "num_qubits", 0) or 0)
            if n_q >= 2:
                multi += 1
    return CircuitStats(depth=depth, gate_count=gate_count, multi_qubit_gate_count=multi)


def check_compatibility(circuit: Any, backend: Any | None = None) -> tuple[bool, str]:
    """Check if circuit can run on backend basis/coupling constraints."""
    if backend is None:
        backend = get_backend_manager().get_qiskit_backend()
    try:
        basis = set(getattr(backend.configuration(), "basis_gates", []))
    except Exception:
        basis = set(default_basis_gates())
    ops = set(str(k) for k in getattr(circuit, "count_ops", lambda: {})().keys())
    unsupported = sorted([op for op in ops if basis and op not in basis and op not in {"measure", "barrier"}])
    if unsupported:
        return False, f"unsupported gates for backend: {unsupported}"
    try:
        n_backend = int(getattr(backend.configuration(), "n_qubits", 0) or 0)
        n_circuit = int(getattr(circuit, "num_qubits", 0) or 0)
        if n_backend > 0 and n_circuit > n_backend:
            return False, f"circuit qubits ({n_circuit}) exceed backend capacity ({n_backend})"
    except Exception:
        pass
    return True, "compatible"


def transpile_circuit(
    circuit: "QuantumCircuit",
    *,
    optimization_level: int = 1,
    basis_gates: list[str] | None = None,
    coupling_map: Any | None = None,
    seed_transpiler: int | None = None,
    **kwargs: Any,
) -> "QuantumCircuit":
    """Backward-compatible wrapper."""
    return transpile_qiskit(
        circuit,
        optimization_level=optimization_level,
        basis_gates=basis_gates,
        coupling_map=coupling_map,
        seed_transpiler=seed_transpiler,
        **kwargs,
    )


__all__ = [
    "CircuitStats",
    "build_pass_manager",
    "check_compatibility",
    "coupling_grid",
    "coupling_heavy_hex",
    "coupling_linear",
    "coupling_ring",
    "default_basis_gates",
    "get_circuit_stats",
    "load_coupling_map",
    "map_virtual_to_physical",
    "optimize_pennylane",
    "transpile_circuit",
    "transpile_qiskit",
]
