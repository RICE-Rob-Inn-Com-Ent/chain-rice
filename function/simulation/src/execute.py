"""Unified execution engine for Qiskit and PennyLane/JAX workflows."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import asyncio
import time
from collections.abc import Callable
from typing import TYPE_CHECKING, Any

import jax.numpy as jnp
from helper import RiceError, SchemaBase, logger
from pydantic import Field

from .const import PRECISION_COMPLEX, PRECISION_REAL, SHOTS
from .jit import jit_compile, vectorize_axis0
from .transpile import transpile_qiskit

if TYPE_CHECKING:  # pragma: no cover - typing only
    from qiskit import QuantumCircuit

class Result(SchemaBase):
    """Unified result model across Qiskit and PennyLane backends."""

    backend_type: str
    job_id: str | None = None
    status: str = "unknown"
    shots: int = Field(ge=0, default=0)
    counts: dict[str, int] = Field(default_factory=dict)
    statevector: list[complex] | None = None
    probabilities: dict[str, float] = Field(default_factory=dict)
    metadata: dict[str, Any] = Field(default_factory=dict)
    error: str | None = None


def _is_qiskit_circuit(obj: Any) -> bool:
    return hasattr(obj, "num_qubits") and hasattr(obj, "count_ops") and hasattr(obj, "copy")


def _normalize_probabilities(counts: dict[str, int]) -> dict[str, float]:
    total = float(sum(max(0, int(v)) for v in counts.values()))
    if total <= 0:
        return {}
    return {k: float(v) / total for k, v in counts.items()}


def _probabilities_from_statevector(statevector: list[complex]) -> dict[str, float]:
    if not statevector:
        return {}
    n = len(statevector)
    if n <= 0:
        return {}
    n_qubits = int(round(jnp.log2(n)))
    arr = jnp.asarray(statevector, dtype=jnp.complex128 if PRECISION_COMPLEX == "complex128" else jnp.complex64)
    probs = jnp.abs(arr) ** 2
    out: dict[str, float] = {}
    for i, p in enumerate(probs.tolist()):
        bit = format(i, f"0{n_qubits}b")
        out[bit] = float(p)
    return out


def post_process(result: Result) -> Result:
    """Normalize probabilities and ensure stable dictionary outputs."""
    probs = dict(result.probabilities)
    if not probs and result.counts:
        probs = _normalize_probabilities(result.counts)
    if probs:
        s = sum(probs.values())
        if s > 0:
            probs = {k: float(v) / s for k, v in probs.items()}
    return result.model_copy(update={"probabilities": probs, "counts": dict(result.counts)})


def dry_run(circuit: Any, shots: int | None = None) -> dict[str, Any]:
    """Estimate rough resources before execution (qubits, depth, statevector memory)."""
    n_qubits = int(getattr(circuit, "num_qubits", 0) or 0)
    depth = int(circuit.depth()) if hasattr(circuit, "depth") else None
    n_states = 2**n_qubits if n_qubits > 0 else 0
    bytes_per_amp = 16 if PRECISION_COMPLEX == "complex128" else 8
    statevector_bytes = n_states * bytes_per_amp
    return {
        "qubits": n_qubits,
        "depth": depth,
        "shots": int(SHOTS if shots is None else shots),
        "precision_real": PRECISION_REAL,
        "precision_complex": PRECISION_COMPLEX,
        "estimated_statevector_mb": float(statevector_bytes) / (1024.0 * 1024.0),
    }


def _run_qiskit_job(
    circuit: QuantumCircuit,
    backend: Any,
    *,
    shots: int,
    noise_model: Any | None = None,
    optimization_level: int = 3,
    timeout_s: float | None = None,
    run_kwargs: dict[str, Any] | None = None,
) -> Result:
    t0 = time.perf_counter()
    kwargs = dict(run_kwargs or {})
    if noise_model is not None and "noise_model" not in kwargs:
        kwargs["noise_model"] = noise_model
    try:
        tc = transpile_qiskit(circuit, backend=backend, optimization_level=optimization_level)
        job = backend.run(tc, shots=int(shots), **kwargs)
        jid = str(job.job_id()) if hasattr(job, "job_id") else None
        logger.info("execute_circuit: submitted qiskit job | id={} shots={}", jid, shots)
        result_obj = job.result(timeout=timeout_s) if timeout_s is not None else job.result()
        counts = result_obj.get_counts() if hasattr(result_obj, "get_counts") else {}
        statevector = None
        if hasattr(result_obj, "get_statevector"):
            try:
                sv = result_obj.get_statevector()
                statevector = [complex(x) for x in sv]
            except Exception:
                statevector = None
        probabilities = _normalize_probabilities(counts) if counts else {}
        if not probabilities and statevector is not None:
            probabilities = _probabilities_from_statevector(statevector)
        dt = (time.perf_counter() - t0) * 1000.0
        out = Result(
            backend_type="qiskit",
            job_id=jid,
            status="success",
            shots=int(shots),
            counts={str(k): int(v) for k, v in (counts or {}).items()},
            statevector=statevector,
            probabilities=probabilities,
            metadata={"latency_ms": dt},
        )
        logger.info("execute_circuit: qiskit finished | id={} latency_ms={:.2f}", jid, dt)
        return post_process(out)
    except Exception as exc:
        dt = (time.perf_counter() - t0) * 1000.0
        logger.error("execute_circuit: qiskit failed | latency_ms={:.2f} err={!r}", dt, exc)
        raise RiceError(
            "qiskit execution failed",
            error_code="SIM_EXEC_QISKIT",
            details={"reason": str(exc), "latency_ms": dt},
        ) from exc


def _run_pennylane_qnode(
    qnode: Callable[..., Any],
    *,
    args: tuple[Any, ...] = (),
    kwargs: dict[str, Any] | None = None,
    use_jit: bool = True,
    use_vmap: bool = False,
) -> Result:
    t0 = time.perf_counter()
    kw = dict(kwargs or {})
    try:
        fn: Callable[..., Any] = qnode
        if use_jit:
            fn = jit_compile(fn)
        if use_vmap:
            fn = vectorize_axis0(fn)
        raw = fn(*args, **kw)
        arr = jnp.asarray(raw)
        statevector = [complex(x) for x in arr.reshape(-1).tolist()] if arr.ndim >= 1 else [complex(arr.item())]
        probs = _probabilities_from_statevector(statevector)
        dt = (time.perf_counter() - t0) * 1000.0
        out = Result(
            backend_type="pennylane",
            status="success",
            shots=0,
            statevector=statevector,
            probabilities=probs,
            metadata={"latency_ms": dt, "jit": bool(use_jit), "vmap": bool(use_vmap)},
        )
        logger.info("execute_circuit: pennylane finished | latency_ms={:.2f}", dt)
        return post_process(out)
    except Exception as exc:
        dt = (time.perf_counter() - t0) * 1000.0
        logger.error("execute_circuit: pennylane failed | latency_ms={:.2f} err={!r}", dt, exc)
        raise RiceError(
            "pennylane execution failed",
            error_code="SIM_EXEC_PENNYLANE",
            details={"reason": str(exc), "latency_ms": dt},
        ) from exc


def execute_circuit(
    circuit: Any,
    backend: Any,
    shots: int | None = None,
    noise_model: Any | None = None,
    *,
    qnode_args: tuple[Any, ...] = (),
    qnode_kwargs: dict[str, Any] | None = None,
    optimization_level: int = 3,
    timeout_s: float | None = None,
    dry_run_mode: bool = False,
) -> Result | dict[str, Any]:
    """Execute one circuit/qnode with unified output model."""
    if dry_run_mode:
        return dry_run(circuit, shots=shots)
    n_shots = int(SHOTS if shots is None else shots)
    if _is_qiskit_circuit(circuit):
        return _run_qiskit_job(
            circuit,
            backend,
            shots=n_shots,
            noise_model=noise_model,
            optimization_level=optimization_level,
            timeout_s=timeout_s,
        )
    if callable(circuit):
        return _run_pennylane_qnode(
            circuit,
            args=qnode_args,
            kwargs=qnode_kwargs,
            use_jit=True,
            use_vmap=False,
        )
    raise RiceError(
        "unsupported circuit type for execute_circuit",
        error_code="SIM_EXEC_TYPE",
        details={"type": type(circuit).__name__},
    )


async def execute_circuit_async(
    circuit: Any,
    backend: Any,
    shots: int | None = None,
    noise_model: Any | None = None,
    **kwargs: Any,
) -> Result | dict[str, Any]:
    """Async wrapper to avoid blocking event loop on long-running jobs."""
    return await asyncio.to_thread(
        execute_circuit,
        circuit,
        backend,
        shots,
        noise_model,
        **kwargs,
    )


async def execute_batch(
    circuits: list[Any],
    backend: Any,
    *,
    shots: int | None = None,
    noise_model: Any | None = None,
    return_exceptions: bool = False,
) -> list[Result | dict[str, Any]]:
    """Execute many circuits concurrently."""
    tasks = [
        execute_circuit_async(c, backend, shots=shots, noise_model=noise_model)
        for c in circuits
    ]
    results = await asyncio.gather(*tasks, return_exceptions=return_exceptions)
    out: list[Result | dict[str, Any]] = []
    for item in results:
        if isinstance(item, Exception):
            if return_exceptions:
                out.append(
                    Result(
                        backend_type="unknown",
                        status="failed",
                        error=str(item),
                    ),
                )
                continue
            raise item
        out.append(item)
    return out


def run_shots(
    circuit: "QuantumCircuit",
    *,
    shots: int = 1024,
    backend: Any | None = None,
    noise_model: Any | None = None,
    **run_kwargs: Any,
) -> Any:
    """Backward-compatible Qiskit execution returning raw backend result object."""
    from qiskit_aer import AerSimulator

    be = backend if backend is not None else AerSimulator(noise_model=noise_model) if noise_model is not None else AerSimulator()
    tc = transpile_qiskit(circuit, backend=be, optimization_level=3)
    job = be.run(tc, shots=shots, **run_kwargs)
    return job.result()


def counts_from_result(result: Any) -> dict[str, int]:
    raw = result.get_counts() if hasattr(result, "get_counts") else {}
    return {str(k): int(v) for k, v in raw.items()}


def statevector_from_result(result: Any) -> Any:
    if not hasattr(result, "get_statevector"):
        return None
    try:
        return [complex(x) for x in result.get_statevector()]
    except Exception:
        return None


def unitary_from_result(result: Any) -> Any:
    if not hasattr(result, "get_unitary"):
        return None
    try:
        return result.get_unitary()
    except Exception:
        return None


def run_statevector(circuit: "QuantumCircuit", **kwargs: Any) -> Any:
    from qiskit_aer import StatevectorSimulator

    sim = StatevectorSimulator(**kwargs)
    tc = transpile_qiskit(circuit, backend=sim, optimization_level=3)
    job = sim.run(tc, shots=1)
    return job.result().get_statevector()


def probabilities_from_result(result: Any) -> dict[str, float]:
    counts = counts_from_result(result)
    if counts:
        return _normalize_probabilities(counts)
    sv = statevector_from_result(result)
    if sv is None:
        return {}
    return _probabilities_from_statevector(sv)


__all__ = [
    "Result",
    "counts_from_result",
    "dry_run",
    "execute_batch",
    "execute_circuit",
    "execute_circuit_async",
    "post_process",
    "probabilities_from_result",
    "run_shots",
    "run_statevector",
    "statevector_from_result",
    "unitary_from_result",
]
