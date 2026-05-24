"""Noise modeling for Qiskit Aer with lightweight PennyLane bridge helpers."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from helper import RiceError, get_settings, logger
from qiskit_aer.noise import NoiseModel, ReadoutError, depolarizing_error, thermal_relaxation_error

from .const import DEFAULT_QUBITS, GATE_DURATIONS_S, GATE_ERROR_RATES

@dataclass(frozen=True, slots=True)
class SimpleNoiseProfile:
    """Quick-start profile for approximate noisy simulations."""

    single_qubit_error: float = 1e-3
    two_qubit_error: float = 1e-2
    readout_01: float = 0.02
    readout_10: float = 0.02
    t1_s: float = 80e-6
    t2_s: float = 60e-6

    def as_dict(self) -> dict[str, float]:
        return {
            "single_qubit_error": float(self.single_qubit_error),
            "two_qubit_error": float(self.two_qubit_error),
            "readout_01": float(self.readout_01),
            "readout_10": float(self.readout_10),
            "t1_s": float(self.t1_s),
            "t2_s": float(self.t2_s),
        }


def _is_noise_enabled(default: bool = True) -> bool:
    """Settings-based toggle with safe fallbacks."""
    try:
        settings = get_settings()
    except Exception as exc:
        logger.warning("noise: get_settings failed, using default toggle | err={!r}", exc)
        return default
    for attr in ("simulation_use_noise", "use_noise", "quantum_use_noise"):
        if hasattr(settings, attr):
            return bool(getattr(settings, attr))
    return default


class NoiseManager:
    """Builder/facade for Aer noise models + summary/bridge utilities."""

    _ONE_Q_GATES = ("id", "sx", "x", "rz", "h", "rx", "ry", "z", "y")
    _TWO_Q_GATES = ("cx", "cz", "swap")

    def __init__(self, *, enabled: bool | None = None, profile: SimpleNoiseProfile | None = None) -> None:
        self.enabled = _is_noise_enabled(default=True) if enabled is None else bool(enabled)
        self.profile = profile or SimpleNoiseProfile()

    def build_noise_model(self, *, n_qubits: int | None = None) -> NoiseModel:
        """Construct complete noise model: depolarizing + thermal + readout."""
        if not self.enabled:
            logger.info("NoiseManager: noise disabled, returning empty NoiseModel")
            return NoiseModel()

        nq = max(1, int(DEFAULT_QUBITS if n_qubits is None else n_qubits))
        nm = NoiseModel()
        self._add_depolarizing(nm)
        self._add_thermal_relaxation(nm)
        self._add_readout(nm, n_qubits=nq)
        logger.info("NoiseManager: built model | qubits={} profile={}", nq, self.profile.as_dict())
        return nm

    def _add_depolarizing(self, nm: NoiseModel) -> None:
        p1 = float(self.profile.single_qubit_error)
        p2 = float(self.profile.two_qubit_error)
        nm.add_all_qubit_quantum_error(depolarizing_error(p1, 1), list(self._ONE_Q_GATES))
        nm.add_all_qubit_quantum_error(depolarizing_error(p2, 2), list(self._TWO_Q_GATES))

    def _add_thermal_relaxation(self, nm: NoiseModel) -> None:
        t1 = float(self.profile.t1_s)
        t2 = float(self.profile.t2_s)
        for gate, duration_s in GATE_DURATIONS_S.items():
            dur = float(max(duration_s, 0.0))
            if gate in self._ONE_Q_GATES:
                err = thermal_relaxation_error(t1, t2, dur)
                nm.add_all_qubit_quantum_error(err, [gate])
            elif gate in self._TWO_Q_GATES:
                # Tensor product of independent single-qubit thermal channels.
                err = thermal_relaxation_error(t1, t2, dur).expand(thermal_relaxation_error(t1, t2, dur))
                nm.add_all_qubit_quantum_error(err, [gate])

    def _add_readout(self, nm: NoiseModel, *, n_qubits: int) -> None:
        ro = readout_error_matrix(self.profile.readout_01, self.profile.readout_10)
        for q in range(n_qubits):
            nm.add_readout_error(ro, [q])

    def get_noise_model_from_backend(self, backend: Any | None = None) -> NoiseModel:
        """Try to emulate noise from real/fake backend, fallback to local profile."""
        if not self.enabled:
            return NoiseModel()
        try:
            if backend is None:
                # Placeholder path for IBMQ/provider wiring in future.
                from qiskit.providers.fake_provider import FakeManilaV2

                backend = FakeManilaV2()
            model = NoiseModel.from_backend(backend)
            logger.info("NoiseManager: imported backend noise | backend={}", getattr(backend, "name", backend))
            return model
        except Exception as exc:
            logger.warning("NoiseManager: backend noise unavailable, using local profile | err={!r}", exc)
            return self.build_noise_model()

    def summarize(self, model: NoiseModel | None = None) -> dict[str, Any]:
        """Summary useful for quick diagnostics and logs."""
        nm = model if model is not None else self.build_noise_model()
        noisy_gates = sorted(getattr(nm, "_local_quantum_errors", {}).keys() | getattr(nm, "_default_quantum_errors", {}).keys())
        return {
            "enabled": self.enabled,
            "profile": self.profile.as_dict(),
            "noisy_gates": [str(g) for g in noisy_gates],
            "basis_gates": sorted(list(getattr(nm, "basis_gates", []))),
            "n_readout_errors": int(len(getattr(nm, "_local_readout_errors", {}))),
        }

    def bitflip_channel(self, p: float, *, wire: int) -> tuple[str, float, int]:
        """Descriptor for PennyLane insertion hook (`qml.BitFlip`)."""
        prob = float(min(max(p, 0.0), 1.0))
        return ("BitFlip", prob, int(wire))

    def phaseflip_channel(self, p: float, *, wire: int) -> tuple[str, float, int]:
        """Descriptor for PennyLane insertion hook (`qml.PhaseFlip`)."""
        prob = float(min(max(p, 0.0), 1.0))
        return ("PhaseFlip", prob, int(wire))

    def apply_pennylane_channel(self, channel: tuple[str, float, int]) -> None:
        """Apply one channel descriptor to current PennyLane tape/circuit."""
        name, p, wire = channel
        try:
            import pennylane as qml
        except Exception as exc:
            raise RiceError(
                "pennylane is required for noise-channel bridge",
                error_code="SIM_NOISE_PENNYLANE_IMPORT",
                details={"reason": str(exc)},
            ) from exc
        if name == "BitFlip":
            qml.BitFlip(float(p), wires=int(wire))
            return
        if name == "PhaseFlip":
            qml.PhaseFlip(float(p), wires=int(wire))
            return
        raise ValueError(f"unsupported PennyLane channel {name!r}")


def empty_noise_model() -> NoiseModel:
    return NoiseModel()


def depolarizing_single_and_two_qubit(p1: float, p2: float | None = None) -> NoiseModel:
    """Depolaryzacja na bramkach 1Q i 2Q (wszystkie qubity)."""
    p2 = p2 if p2 is not None else p1
    nm = NoiseModel()
    nm.add_all_qubit_quantum_error(depolarizing_error(p1, 1), ["h", "rx", "ry", "rz", "id", "x", "y", "z"])
    nm.add_all_qubit_quantum_error(depolarizing_error(p2, 2), ["cx", "cz", "swap"])
    return nm


def thermal_relaxation_on_gate(
    t1_s: float,
    t2_s: float,
    gate_time_s: float,
    num_qubits: int,
) -> NoiseModel:
    nm = NoiseModel()
    err = thermal_relaxation_error(t1_s, t2_s, gate_time_s)
    for q in range(num_qubits):
        nm.add_quantum_error(err, ["id"], [q])
    return nm


def readout_error_matrix(prob_meas0_prep1: float, prob_meas1_prep0: float) -> Any:
    """Macierz błędu odczytu dla `ReadoutError`."""
    p0 = 1.0 - prob_meas0_prep1
    p1 = 1.0 - prob_meas1_prep0
    return ReadoutError([[p0, prob_meas0_prep1], [prob_meas1_prep0, p1]])


def bitflip(probability: float, *, wire: int = 0) -> tuple[str, float, int]:
    """Manual bit-flip utility descriptor for PennyLane/JAX noisy tapes."""
    return NoiseManager(enabled=True).bitflip_channel(probability, wire=wire)


def phaseflip(probability: float, *, wire: int = 0) -> tuple[str, float, int]:
    """Manual phase-flip utility descriptor for PennyLane/JAX noisy tapes."""
    return NoiseManager(enabled=True).phaseflip_channel(probability, wire=wire)


def get_noise_model_from_backend(backend: Any | None = None) -> NoiseModel:
    """Module-level convenience wrapper."""
    return NoiseManager().get_noise_model_from_backend(backend)


def summarize_noise_model(model: NoiseModel | None = None) -> dict[str, Any]:
    """Module-level convenience summary."""
    manager = NoiseManager()
    return manager.summarize(model)


def simple_noise_profile() -> SimpleNoiseProfile:
    """Quick testing template with standard rates."""
    defaults = SimpleNoiseProfile(
        single_qubit_error=float(GATE_ERROR_RATES.get("x", 2e-4)),
        two_qubit_error=float(GATE_ERROR_RATES.get("cx", 1.5e-2)),
        readout_01=float(GATE_ERROR_RATES.get("measure", 2e-2)),
        readout_10=float(GATE_ERROR_RATES.get("measure", 2e-2)),
        t1_s=80e-6,
        t2_s=60e-6,
    )
    return defaults


__all__ = [
    "NoiseManager",
    "SimpleNoiseProfile",
    "bitflip",
    "depolarizing_single_and_two_qubit",
    "empty_noise_model",
    "get_noise_model_from_backend",
    "phaseflip",
    "readout_error_matrix",
    "simple_noise_profile",
    "summarize_noise_model",
    "thermal_relaxation_on_gate",
]
