"""Qiskit — transpiler, poziomy optymalizacji, bazy bramek, coupling map."""

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
# [ ] implement Qiskit transpilation pipeline:
# [ ]     PassManager with: UnrollCustomDefinitions, BasisTranslator,
# [ ]     Optimize1qGates, CXCancellation, CommutativeCancellation
# [ ]     optimization_level from RICE_TRANSPILE_OPT_LEVEL (0-3)
# [ ] implement circuit depth reduction passes
# [ ] implement noise-aware routing: layout from backend coupling_map
# [ ] implement circuit equivalence checking: Statevector comparison


def transpile_circuit(
    circuit: "QuantumCircuit",
    *,
    optimization_level: int = 1,
    basis_gates: list[str] | None = None,
    coupling_map: Any | None = None,
    seed_transpiler: int | None = None,
    **kwargs: Any,
) -> "QuantumCircuit":
    from qiskit import transpile

    return transpile(
        circuit,
        optimization_level=optimization_level,
        basis_gates=basis_gates,
        coupling_map=coupling_map,
        seed_transpiler=seed_transpiler,
        **kwargs,
    )


def coupling_grid(rows: int, cols: int) -> Any:
    """Prosta siatka sąsiedztwa; przy braku krawędzi — linia dwóch qubitów."""
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


def default_basis_gates() -> list[str]:
    return ["cx", "id", "rz", "sx", "x"]
