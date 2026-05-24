"""Public API for `simulation`: core execution, physics primitives, and JAX acceleration."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import Any

from loguru import logger

from .backend import BackendManager, get_backend_manager
from .circuit import RiceCircuit
from .const import DEFAULT_QUBITS, PRECISION_COMPLEX, PRECISION_REAL
from .execute import execute_batch, execute_circuit
from .jit import rice_jit, rice_vmap
from .physics import Hamiltonian, I, X, Y, Z
from .transpile import transpile_qiskit

__version__ = "0.1.0"

# Unified, user-facing precision token.
PRECISION = f"{PRECISION_REAL}/{PRECISION_COMPLEX}"

_INITIALIZED = False


def initialize_simulation_env() -> dict[str, Any]:
    """Initialize runtime once and log detected hardware (CPU/GPU/TPU)."""
    global _INITIALIZED
    mgr = get_backend_manager()
    info = mgr.get_info()
    if not _INITIALIZED:
        logger.info(
            "simulation env initialized | platform={} devices={} precision={}",
            info.get("jax_platform"),
            info.get("jax_devices"),
            PRECISION,
        )
        _INITIALIZED = True
    return info


def simulate(
    circuit: Any,
    *,
    backend: Any | None = None,
    shots: int | None = None,
    noise_model: Any | None = None,
    optimization_level: int = 3,
    transpile_before_execute: bool = True,
    **kwargs: Any,
) -> Any:
    """One-call convenience wrapper: backend select -> transpile -> execute."""
    mgr = get_backend_manager()
    be = backend if backend is not None else mgr.get_qiskit_backend()
    prepared = (
        transpile_qiskit(circuit, backend=be, optimization_level=optimization_level)
        if transpile_before_execute
        else circuit
    )
    return execute_circuit(prepared, be, shots=shots, noise_model=noise_model, **kwargs)


# Initialize lazily on import and keep idempotent behavior.
initialize_simulation_env()

__all__ = [  # noqa: RUF022
    "__version__",
    "BackendManager",
    "DEFAULT_QUBITS",
    "Hamiltonian",
    "I",
    "PRECISION",
    "RiceCircuit",
    "execute_batch",
    "execute_circuit",
    "initialize_simulation_env",
    "rice_jit",
    "rice_vmap",
    "simulate",
    "X",
    "Y",
    "Z",
]
