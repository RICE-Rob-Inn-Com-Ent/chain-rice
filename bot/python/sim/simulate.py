"""Qiskit Aer: simulations, noise models, backends, job execution, result processing. Requires: qiskit-aer (extra sim).

Provides get_aer_simulator, get_statevector_simulator, get_density_matrix_simulator, build_noise_model,
simulator_with_noise, run_circuit, run_sync, run_simulation, get_counts, get_statevector, get_unitary.
Install with: uv sync --extra sim. All comments in English.
"""

from __future__ import annotations

# -----------------------------------------------------------------------------
# Aer simulator setup
# -----------------------------------------------------------------------------


def get_aer_simulator(method: str = "automatic", **kwargs):
    """Create AerSimulator backend (method: automatic, statevector, density_matrix, matrix_product_state)."""
    try:
        from qiskit_aer import AerSimulator
        return AerSimulator(method=method, **kwargs)
    except ImportError as e:
        raise ImportError(
            "get_aer_simulator requires qiskit-aer; install: uv sync --extra sim"
        ) from e


def get_statevector_simulator():
    """Statevector simulator (exact, up to ~30 qubits)."""
    return get_aer_simulator(method="statevector")


def get_density_matrix_simulator():
    """Density matrix simulator (for noise)."""
    return get_aer_simulator(method="density_matrix")


# -----------------------------------------------------------------------------
# Noise models
# -----------------------------------------------------------------------------


def build_noise_model(
    p_depol_1q: float = 0.001,
    p_depol_2q: float = 0.01,
    p_meas: float = 0.01,
):
    """Build simple noise model: depolarizing 1q/2q + readout error."""
    try:
        from qiskit_aer.noise import depolarizing_error, NoiseModel, ReadoutError
    except ImportError as e:
        raise ImportError("build_noise_model wymaga qiskit-aer") from e
    noise = NoiseModel()
    noise.add_all_qubit_quantum_error(depolarizing_error(p_depol_1q, 1), ["u1", "u2", "u3", "h", "x", "y", "z", "s", "t"])
    noise.add_all_qubit_quantum_error(depolarizing_error(p_depol_2q, 2), ["cx", "cz"])
    # Readout: P(0|1)=p_meas, P(1|0)=p_meas
    readout = ReadoutError([[1 - p_meas, p_meas], [p_meas, 1 - p_meas]])
    noise.add_all_qubit_readout_error(readout)
    return noise


def simulator_with_noise(noise_model=None):
    """AerSimulator with given noise model (or default)."""
    try:
        from qiskit_aer import AerSimulator
    except ImportError as e:
        raise ImportError("simulator_with_noise wymaga qiskit-aer") from e
    if noise_model is None:
        noise_model = build_noise_model()
    return AerSimulator(noise_model=noise_model)


# -----------------------------------------------------------------------------
# Backend configuration
# -----------------------------------------------------------------------------


def backend_options(max_parallel_threads: int | None = None, max_parallel_experiments: int | None = None):
    """Aer backend options (max_parallel_threads, max_parallel_experiments)."""
    opts = {}
    if max_parallel_threads is not None:
        opts["max_parallel_threads"] = max_parallel_threads
    if max_parallel_experiments is not None:
        opts["max_parallel_experiments"] = max_parallel_experiments
    return opts


# -----------------------------------------------------------------------------
# Job execution i monitoring
# -----------------------------------------------------------------------------


def run_circuit(qc, backend=None, shots: int = 1024, **transpile_kwargs):
    """Execute circuit on backend; returns job (or result when synchronous)."""
    try:
        from qiskit import transpile
    except ImportError as e:
        raise ImportError("run_circuit wymaga qiskit") from e
    if backend is None:
        backend = get_aer_simulator()
    tqc = transpile(qc, backend, **transpile_kwargs)
    job = backend.run(tqc, shots=shots)
    return job


def run_sync(qc, backend=None, shots: int = 1024):
    """Run circuit synchronously; returns Result."""
    job = run_circuit(qc, backend=backend, shots=shots)
    return job.result()


def run_simulation(circuit, shots: int = 1024, backend=None):
    """Run circuit on backend (default AerSimulator); returns Result with get_counts(), etc."""
    return run_sync(circuit, backend=backend, shots=shots)


def job_status(job) -> str:
    """Return job status: QUEUED, RUNNING, DONE, CANCELLED, ERROR."""
    return str(job.status().name) if hasattr(job, "status") else "UNKNOWN"


# -----------------------------------------------------------------------------
# Result processing
# -----------------------------------------------------------------------------


def get_counts(result, index: int = 0) -> dict[str, int]:
    """Get counts from result (experiment index)."""
    return result.get_counts(index) if hasattr(result, "get_counts") else {}


def get_statevector(result, index: int = 0):
    """Statevector from result (if available)."""
    if hasattr(result, "get_statevector"):
        return result.get_statevector(index)
    return None


def get_unitary(qc):
    """Unitary matrix of the circuit (without measurements)."""
    try:
        from qiskit.quantum_info import Operator
        return Operator(qc)
    except ImportError as e:
        raise ImportError("get_unitary requires qiskit") from e


def get_simulator(method: str = "automatic", **kwargs):
    """Return AerSimulator. Alias for get_aer_simulator."""
    return get_aer_simulator(method=method, **kwargs)


def configure_noise_model(params: dict | None = None):
    """Build noise model from params dict (p_depol_1q, p_depol_2q, p_meas)."""
    p = params or {}
    return build_noise_model(
        p_depol_1q=p.get("p_depol_1q", 0.001),
        p_depol_2q=p.get("p_depol_2q", 0.01),
        p_meas=p.get("p_meas", 0.01),
    )


def run_batch(circuits: list, shots: int = 1024, backend=None) -> list:
    """Run multiple circuits; returns list of Result objects."""
    if backend is None:
        backend = get_aer_simulator()
    results = []
    for qc in circuits:
        r = run_simulation(qc, shots=shots, backend=backend)
        results.append(r)
    return results


def add_depolarizing_error(noise_model, prob: float, qubits: list[int] | None = None) -> None:
    """Add depolarizing error to noise model (1q or 2q)."""
    try:
        from qiskit_aer.noise import depolarizing_error as dep
        if qubits is None or len(qubits) == 1:
            noise_model.add_all_qubit_quantum_error(dep(prob, 1), ["u1", "u2", "u3", "h", "x", "y", "z", "s", "t"])
        else:
            noise_model.add_all_qubit_quantum_error(dep(prob, 2), ["cx", "cz"])
    except ImportError as e:
        raise ImportError("add_depolarizing_error requires qiskit-aer") from e


def add_thermal_relaxation(noise_model, t1: float, t2: float, qubits: list[int] | None = None) -> None:
    """Add thermal relaxation error (T1, T2 in seconds)."""
    try:
        from qiskit_aer.noise import thermal_relaxation_error
        err = thermal_relaxation_error(t1, t2, 0)
        noise_model.add_all_qubit_quantum_error(err, ["u1", "u2", "u3", "h", "x", "y", "z", "s", "t"])
    except ImportError as e:
        raise ImportError("add_thermal_relaxation requires qiskit-aer") from e


def calculate_expectation(result, observable) -> float:
    """Compute expectation value of observable from result (statevector). Placeholder: use get_statevector and manual dot."""
    try:
        sv = get_statevector(result)
        if sv is None:
            return 0.0
        import numpy as np
        from qiskit.quantum_info import SparsePauliOp
        if hasattr(observable, "to_matrix"):
            mat = observable.to_matrix()
        elif isinstance(observable, str):
            mat = SparsePauliOp(observable).to_matrix()
        else:
            mat = np.asarray(observable)
        return float(np.real(np.vdot(sv, mat @ sv)))
    except Exception:
        return 0.0
