"""Simulation constants — physics, backend defaults, precision, and optimizer controls."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import importlib
from collections.abc import Mapping
from types import MappingProxyType
from typing import Final, Literal

# ---------------------------------------------------------------------------
# [PHYSICS] — fundamental constants and calibration placeholders
# ---------------------------------------------------------------------------

# Reduced Planck constant (SI): h_bar = h / (2*pi) [J*s]
H_BAR: Final[float] = 1.054_571_817e-34

# Placeholder timing defaults (seconds) for compilation / noise simulations.
GATE_DURATIONS_S: Final[Mapping[str, float]] = MappingProxyType(
    {
        "id": 35e-9,
        "sx": 35e-9,
        "x": 70e-9,
        "rz": 0.0,  # virtual-Z frame update
        "cx": 300e-9,
        "cz": 250e-9,
        "measure": 700e-9,
        "reset": 1_000e-9,
    },
)

# Placeholder error rates (dimensionless probabilities).
GATE_ERROR_RATES: Final[Mapping[str, float]] = MappingProxyType(
    {
        "id": 1e-4,
        "sx": 2e-4,
        "x": 2e-4,
        "rz": 1e-6,
        "cx": 1.5e-2,
        "cz": 1.2e-2,
        "measure": 2e-2,
        "reset": 1e-2,
    },
)

# ---------------------------------------------------------------------------
# [SIMULATION] — core runtime defaults
# ---------------------------------------------------------------------------

DEFAULT_QUBITS: Final[int] = 5
SHOTS: Final[int] = 1024
HIGH_ACCURACY_SHOTS: Final[int] = 4096

# JAX/PennyLane-friendly precision defaults.
PRECISION_REAL: Final[Literal["float32", "float64"]] = "float64"
PRECISION_COMPLEX: Final[Literal["complex64", "complex128"]] = "complex128"

# ---------------------------------------------------------------------------
# [AER BACKEND] — qiskit-aer default simulator options
# ---------------------------------------------------------------------------

AER_METHOD: Final[Literal["statevector", "matrix_product_state"]] = "statevector"
AER_SEED_SIMULATOR: Final[int] = 42
AER_OPTIONS: Final[Mapping[str, object]] = MappingProxyType(
    {
        "method": AER_METHOD,
        "shots": SHOTS,
        "seed_simulator": AER_SEED_SIMULATOR,
    },
)

# ---------------------------------------------------------------------------
# [JAX BACKEND] — platform detection and numerical behavior
# ---------------------------------------------------------------------------


def _detect_jax_platform() -> str:
    """Detect JAX backend: ``gpu``/``tpu``/``cpu`` (fallback to cpu)."""
    try:
        jax = importlib.import_module("jax")
        backend = str(jax.default_backend()).strip().lower()
    except Exception:
        return "cpu"
    if backend in {"gpu", "cuda", "rocm"}:
        return "gpu"
    if backend == "tpu":
        return "tpu"
    return "cpu"


JAX_DEFAULT_DEVICE: Final[str] = _detect_jax_platform()
JAX_ENABLE_X64: Final[bool] = PRECISION_REAL == "float64"

# ---------------------------------------------------------------------------
# [GRADIENT / OPTIMIZATION] — parameter-shift and convergence thresholds
# ---------------------------------------------------------------------------

PARAM_SHIFT: Final[float] = 1.570_796_326_794_896_6  # pi/2
OPTIMIZER_TOLERANCE: Final[float] = 1e-8
OPTIMIZER_MAX_STEPS: Final[int] = 1_000

# ---------------------------------------------------------------------------
# [HELPER ALIGNMENT] — optional compatibility with helper contracts
# ---------------------------------------------------------------------------

try:
    _helper_module = importlib.import_module("helper")
except Exception:
    _helper_module = None
_error_prefix = getattr(_helper_module, "ERROR_CODE_PREFIX", "SAGE")
SIMULATION_ERROR_PREFIX: Final[str] = f"{_error_prefix}_SIMULATION"


__all__ = [  # noqa: RUF022
    "AER_METHOD",
    "AER_OPTIONS",
    "AER_SEED_SIMULATOR",
    "DEFAULT_QUBITS",
    "GATE_DURATIONS_S",
    "GATE_ERROR_RATES",
    "H_BAR",
    "HIGH_ACCURACY_SHOTS",
    "JAX_DEFAULT_DEVICE",
    "JAX_ENABLE_X64",
    "OPTIMIZER_MAX_STEPS",
    "OPTIMIZER_TOLERANCE",
    "PARAM_SHIFT",
    "PRECISION_COMPLEX",
    "PRECISION_REAL",
    "SHOTS",
    "SIMULATION_ERROR_PREFIX",
]
