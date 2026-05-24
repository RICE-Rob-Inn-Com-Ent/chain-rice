"""Benchmarks for the ``simulation`` package (circuit build; optional execute)."""

from __future__ import annotations

from ._resolve import simulation_module
from ._timing import TimingSample, bench_call

_s = simulation_module()
RiceCircuit = _s.RiceCircuit


def _build_circuit() -> object:
    c = RiceCircuit(n_qubits=6)
    for _ in range(8):
        c.add_entanglement_layer()
    return c


def run_simulation_benchmarks(*, repeat: int = 7, warmup: int = 2) -> list[TimingSample]:
    samples: list[TimingSample] = [
        bench_call(
            "simulation.RiceCircuit build (6q, layers)",
            _build_circuit,
            repeat=repeat,
            warmup=warmup,
        ),
    ]

    try:
        execute_circuit = _s.execute_circuit
        get_backend_manager = _s.get_backend_manager

        rice = _build_circuit()
        qc = rice.to_qiskit()
        backend = get_backend_manager().get_qiskit_backend()

        def run_shot() -> None:
            execute_circuit(qc, backend, shots=32)

        samples.append(
            bench_call(
                "simulation.execute_circuit (shots=32)",
                run_shot,
                repeat=max(3, repeat // 2),
                warmup=1,
                note="qiskit",
            ),
        )
    except Exception as exc:  # noqa: BLE001 — bench must not fail env
        samples.append(
            TimingSample(
                name="simulation.execute_circuit (skipped)",
                seconds_mean=0.0,
                seconds_stdev=0.0,
                iterations=0,
                warmup=0,
                note=f"skip: {exc!r}",
            ),
        )

    return samples
