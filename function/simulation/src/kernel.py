"""Low-level simulation buffer + external kernel dispatch (Mojo/C++ bridge)."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import asyncio
import ctypes
import threading
import time
from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

import jax
import jax.numpy as jnp
import numpy as np
from helper import RiceError, logger
import pennylane as qml

from .const import PRECISION_COMPLEX, PRECISION_REAL

_DTYPE_REAL = np.float64 if PRECISION_REAL == "float64" else np.float32
_DTYPE_COMPLEX = np.complex128 if PRECISION_COMPLEX == "complex128" else np.complex64


def _to_numpy_contiguous(array: Any) -> np.ndarray:
    arr = np.asarray(array)
    if np.iscomplexobj(arr):
        arr = arr.astype(_DTYPE_COMPLEX, copy=False)
    elif np.issubdtype(arr.dtype, np.floating):
        arr = arr.astype(_DTYPE_REAL, copy=False)
    return np.ascontiguousarray(arr)


@dataclass(slots=True)
class SimulationBuffer:
    """Contiguous simulation payload prepared for zero-copy external kernel access."""

    host_array: np.ndarray
    pinned: bool = False

    @classmethod
    def from_array(cls, array: Any, *, pinned: bool = False) -> SimulationBuffer:
        arr = _to_numpy_contiguous(array)
        return cls(host_array=arr, pinned=bool(pinned))

    @property
    def nbytes(self) -> int:
        return int(self.host_array.nbytes)

    @property
    def shape(self) -> tuple[int, ...]:
        return tuple(int(x) for x in self.host_array.shape)

    @property
    def dtype(self) -> str:
        return str(self.host_array.dtype)

    @property
    def ptr(self) -> int:
        return int(self.host_array.ctypes.data)

    def flatten_for_mojo(self) -> np.ndarray:
        """Return 1D contiguous view (complex kept as interleaved complex dtype)."""
        return np.ascontiguousarray(self.host_array.reshape(-1))

    def to_dlpack(self) -> Any:
        """DLPack capsule (zero-copy where producer backend supports it)."""
        try:
            from jax import dlpack as jdlpack

            return jdlpack.to_dlpack(jnp.asarray(self.host_array))
        except Exception as exc:
            raise RiceError(
                "failed to convert SimulationBuffer to DLPack",
                error_code="SIM_KERNEL_DLPACK",
                details={"reason": str(exc)},
            ) from exc

    def python_buffer(self) -> memoryview:
        """Python buffer-protocol view for C/C++/ctypes consumers."""
        return memoryview(self.host_array)


def export_to_mojo(array: jax.Array | np.ndarray | Any) -> int:
    """Return raw memory pointer for direct Mojo/C++ access."""
    try:
        buf = SimulationBuffer.from_array(array)
        return buf.ptr
    except Exception as exc:
        raise RiceError(
            "failed to export array pointer for Mojo",
            error_code="SIM_KERNEL_EXPORT",
            details={"reason": str(exc)},
        ) from exc


@dataclass(slots=True)
class KernelSpec:
    name: str
    entrypoint: Callable[[SimulationBuffer], Any]
    language: str = "cpp"
    async_supported: bool = False
    description: str = ""


class KernelRegistry:
    """Registry of available external kernels (Mojo/C++ extensions)."""

    def __init__(self) -> None:
        self._registry: dict[str, KernelSpec] = {}

    def register(
        self,
        name: str,
        entrypoint: Callable[[SimulationBuffer], Any],
        *,
        language: str = "cpp",
        async_supported: bool = False,
        description: str = "",
    ) -> None:
        key = name.strip().lower()
        if not key:
            raise ValueError("kernel name cannot be empty")
        self._registry[key] = KernelSpec(
            name=key,
            entrypoint=entrypoint,
            language=language,
            async_supported=async_supported,
            description=description,
        )

    def get(self, name: str) -> KernelSpec:
        key = name.strip().lower()
        if key not in self._registry:
            raise RiceError(
                "kernel not found in registry",
                error_code="SIM_KERNEL_NOT_FOUND",
                details={"kernel_name": name},
            )
        return self._registry[key]

    def list(self) -> list[str]:
        return sorted(self._registry.keys())


_GLOBAL_KERNEL_REGISTRY = KernelRegistry()


def get_kernel_registry() -> KernelRegistry:
    return _GLOBAL_KERNEL_REGISTRY


def dispatch_to_kernel(
    kernel_name: str,
    data: SimulationBuffer,
    *,
    wait: bool = True,
) -> Any:
    """Dispatch payload to a registered external kernel with timing/bandwidth logs."""
    spec = get_kernel_registry().get(kernel_name)

    async def _run_async() -> Any:
        t0 = time.perf_counter()
        try:
            if asyncio.iscoroutinefunction(spec.entrypoint):
                out = await spec.entrypoint(data)
            else:
                out = await asyncio.to_thread(spec.entrypoint, data)
        except Exception as exc:
            raise RiceError(
                "kernel dispatch failed",
                error_code="SIM_KERNEL_DISPATCH",
                details={"kernel_name": spec.name, "reason": str(exc)},
            ) from exc
        dt = max(1e-9, time.perf_counter() - t0)
        bw = float(data.nbytes) / dt / (1024.0**3)
        logger.info(
            "dispatch_to_kernel | kernel={} lang={} bytes={} time_ms={:.3f} bw_gib_s={:.3f}",
            spec.name,
            spec.language,
            data.nbytes,
            dt * 1000.0,
            bw,
        )
        return out

    if wait:
        return asyncio.run(_run_async())

    # Fire-and-forget mode.
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        loop = None
    if loop is not None and loop.is_running():
        return loop.create_task(_run_async())
    thread = threading.Thread(target=lambda: asyncio.run(_run_async()), daemon=True)
    thread.start()
    return thread


def generate_c_header(struct_name: str = "SageSimulationBuffer") -> str:
    """Generate C-compatible struct definition for Mojo/C++ interop."""
    sname = struct_name.strip() or "SageSimulationBuffer"
    return (
        f"typedef struct {sname} {{\n"
        "    void* data;\n"
        "    long long nbytes;\n"
        "    long long ndim;\n"
        "    long long shape[8];\n"
        "    int dtype_code; /* 0=float32,1=float64,2=complex64,3=complex128 */\n"
        "}} "
        f"{sname};\n"
    )


def pin_memory_placeholder(array: Any) -> SimulationBuffer:
    """Pinned-memory placeholder for future GPU transfer optimization."""
    # Real host-pinning should be implemented via CUDA driver/runtime or a C-extension.
    return SimulationBuffer.from_array(array, pinned=True)


def fidelity_between_states(state0: Any, state1: Any) -> Any:
    """|⟨ψ|φ⟩|² dla wektorów stanu (normalizowanych)."""
    from pennylane import math as pmath

    return pmath.abs(pmath.vdot(state0, state1)) ** 2


def quantum_embedding_angle(x: float, wire: int) -> None:
    """Prosty embedding: obrót RX proporcjonalny do cechy."""
    qml.RX(x, wires=wire)


def kernel_matrix_from_fidelity(
    feature_circuits: list[Any],
    n_qubits: int,
) -> Any:
    """Compute K_ij = |<psi_i|psi_j>|^2 for precomputed state vectors."""
    if not feature_circuits:
        return np.zeros((0, 0), dtype=_DTYPE_REAL)
    states = [np.asarray(s).reshape(-1) for s in feature_circuits]
    dim = 2**int(n_qubits)
    for st in states:
        if st.shape[0] != dim:
            raise ValueError(f"state dimension {st.shape[0]} does not match 2**n_qubits={dim}")
    n = len(states)
    kmat = np.zeros((n, n), dtype=_DTYPE_REAL)
    for i in range(n):
        for j in range(i, n):
            val = float(np.abs(np.vdot(states[i], states[j])) ** 2)
            kmat[i, j] = val
            kmat[j, i] = val
    return kmat


def svm_bridge_note() -> str:
    """Wskazówka: macierz jądra K_ij → klasyczny SVM (sklearn) na K."""
    return (
        "Compute K_ij = |<phi(x_i)|phi(x_j)>|^2 via fidelity; then "
        "sklearn.svm.SVC(kernel='precomputed', ...)"
    )


__all__ = [
    "KernelRegistry",
    "KernelSpec",
    "SimulationBuffer",
    "dispatch_to_kernel",
    "export_to_mojo",
    "fidelity_between_states",
    "generate_c_header",
    "get_kernel_registry",
    "kernel_matrix_from_fidelity",
    "pin_memory_placeholder",
    "svm_bridge_note",
]
