"""Pydantic models for sim: circuit config, results, measurements, job status. English only."""

from __future__ import annotations

from enum import Enum
from pydantic import BaseModel, Field


# -----------------------------------------------------------------------------
# Circuit configs
# -----------------------------------------------------------------------------


class CircuitConfig(BaseModel):
    """Circuit build config: num_qubits, num_clbits, basis_gates, optimization_level."""

    num_qubits: int = Field(ge=1, le=100, description="Number of qubits")
    num_clbits: int | None = Field(default=None, description="Number of classical bits (default = num_qubits)")
    basis_gates: list[str] = Field(
        default_factory=lambda: ["id", "rz", "sx", "x", "cx"],
        description="Basis gates for transpilation",
    )
    optimization_level: int = Field(default=1, ge=0, le=3, description="Optimization level (0-3)")


class SimulatorConfig(BaseModel):
    """Aer simulator config: method, shots, noise_model, error rates."""

    method: str = Field(default="automatic", description="automatic|statevector|density_matrix|matrix_product_state")
    shots: int = Field(default=1024, ge=1, description="Number of shots")
    noise_model: bool = Field(default=False, description="Use noise model")
    p_depol_1q: float = Field(default=0.001, ge=0.0, le=1.0)
    p_depol_2q: float = Field(default=0.01, ge=0.0, le=1.0)
    p_meas: float = Field(default=0.01, ge=0.0, le=1.0)


# -----------------------------------------------------------------------------
# Result models
# -----------------------------------------------------------------------------


class MeasurementOutcome(BaseModel):
    """Single measurement outcome: bitstring -> count."""

    bitstring: str = Field(description="e.g. '00', '11'")
    count: int = Field(ge=0, description="Number of occurrences")


class ResultSummary(BaseModel):
    """Simulation result summary: counts, shots, num_qubits, success."""

    counts: dict[str, int] = Field(default_factory=dict, description="Counts: bitstring -> count")
    shots: int = Field(ge=0)
    num_qubits: int = Field(ge=0)
    success: bool = True


# -----------------------------------------------------------------------------
# Measurement outcomes
# -----------------------------------------------------------------------------


class MeasurementResults(BaseModel):
    """Measurement results from multiple shots: outcomes, total_shots, probabilities."""

    outcomes: list[MeasurementOutcome] = Field(default_factory=list)
    total_shots: int = 0
    probabilities: dict[str, float] = Field(default_factory=dict, description="bitstring -> probability")


# -----------------------------------------------------------------------------
# Job status models
# -----------------------------------------------------------------------------


class JobStatus(str, Enum):
    """Job status in queue/simulator."""

    QUEUED = "QUEUED"
    RUNNING = "RUNNING"
    DONE = "DONE"
    CANCELLED = "CANCELLED"
    ERROR = "ERROR"
    UNKNOWN = "UNKNOWN"


class JobInfo(BaseModel):
    """Job info: job_id, status, backend_name, shots, error_message."""

    job_id: str = Field(default="", description="Job ID")
    status: JobStatus = Field(default=JobStatus.UNKNOWN)
    backend_name: str = Field(default="")
    shots: int = 0
    error_message: str | None = Field(default=None)


class HybridConfig(BaseModel):
    """Hybrid circuit config (PennyLane): wires, interface, diff_method."""

    wires: int = Field(default=2, ge=1)
    interface: str = Field(default="auto", description="auto|numpy|torch|jax")
    diff_method: str = Field(default="parameter-shift", description="parameter-shift|backprop|finite-diff")


# -----------------------------------------------------------------------------
# JAX compute config
# -----------------------------------------------------------------------------


class JAXComputeConfig(BaseModel):
    """JAX compute config: backend, xla_compilation, default_precision."""

    backend: str = Field(default="gpu")
    xla_compilation: bool = True
    default_precision: str = Field(default="float32")  # float32, bfloat16


class PytreeStructure(BaseModel):
    """JAX pytree structure description (for serialization)."""

    num_leaves: int = 0
    treedef_str: str = ""
