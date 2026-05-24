"""Unified backend manager for Qiskit Aer, PennyLane devices, and JAX runtime."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import threading
from dataclasses import dataclass
from typing import Any

from helper import RiceError, get_settings, logger
from qiskit_aer import Aer, AerSimulator

from .const import AER_METHOD, AER_OPTIONS, JAX_ENABLE_X64, PRECISION_COMPLEX, PRECISION_REAL, SHOTS

@dataclass(frozen=True, slots=True)
class BackendInfo:
    """Snapshot of the current simulation environment."""

    jax_platform: str
    jax_devices: tuple[str, ...]
    jax_forced_cpu: bool
    qiskit_default_method: str
    precision_real: str
    precision_complex: str
    default_shots: int
    available_memory_mb: int | None
    ibmq_placeholder: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "jax_platform": self.jax_platform,
            "jax_devices": list(self.jax_devices),
            "jax_forced_cpu": self.jax_forced_cpu,
            "qiskit_default_method": self.qiskit_default_method,
            "precision_real": self.precision_real,
            "precision_complex": self.precision_complex,
            "default_shots": self.default_shots,
            "available_memory_mb": self.available_memory_mb,
            "ibmq_placeholder": self.ibmq_placeholder,
        }


def _coerce_int(value: object, default: int) -> int:
    try:
        return int(value)  # type: ignore[arg-type]
    except Exception:
        return default


class BackendManager:
    """Singleton registry/cacher for Qiskit, PennyLane, and JAX backend resources."""

    _instance: BackendManager | None = None
    _singleton_lock = threading.Lock()

    def __new__(cls) -> BackendManager:
        if cls._instance is None:
            with cls._singleton_lock:
                if cls._instance is None:
                    inst = super().__new__(cls)
                    inst._initialized = False
                    cls._instance = inst
        assert cls._instance is not None
        return cls._instance

    def __init__(self) -> None:
        with BackendManager._singleton_lock:
            if getattr(self, "_initialized", False):
                return
            self._cache_lock = threading.Lock()
            self._qiskit_cache: dict[tuple[str, int], Any] = {}
            self._pennylane_cache: dict[tuple[str, int, int | None], Any] = {}
            self._jax_platform = "cpu"
            self._jax_devices: tuple[str, ...] = ()
            self._jax_forced_cpu = False
            self._available_memory_mb: int | None = None
            self._default_shots = SHOTS
            self._initialize_environment()
            self._initialized = True

    def _setting(self, *names: str, default: object = None) -> object:
        try:
            settings = get_settings()
        except Exception as exc:
            logger.warning("BackendManager: get_settings failed, using defaults | err={!r}", exc)
            return default
        for name in names:
            if hasattr(settings, name):
                return getattr(settings, name)
        return default

    def _initialize_environment(self) -> None:
        self._jax_forced_cpu = bool(
            self._setting("simulation_force_cpu", "jax_force_cpu", "force_cpu", default=False),
        )
        self._default_shots = _coerce_int(
            self._setting("quantum_shots", "simulation_shots", default=SHOTS),
            SHOTS,
        )

        try:
            import jax

            if self._jax_forced_cpu:
                jax.config.update("jax_platform_name", "cpu")
            jax.config.update("jax_enable_x64", bool(JAX_ENABLE_X64))
            devices = tuple(str(d) for d in jax.devices())
            platform = str(jax.default_backend()).strip().lower()
            self._jax_platform = "gpu" if platform in {"gpu", "cuda", "rocm"} else platform
            self._jax_devices = devices

            mem_mb: int | None = None
            for dev in jax.devices():
                stats = getattr(dev, "memory_stats", None)
                if callable(stats):
                    data = stats()
                    if isinstance(data, dict):
                        total = data.get("bytes_limit") or data.get("bytes_reserved")
                        if total is not None:
                            mem_mb = int(int(total) / (1024 * 1024))
                            break
            self._available_memory_mb = mem_mb

            logger.info(
                "BackendManager JAX ready | platform={} devices={} x64={} forced_cpu={}",
                self._jax_platform,
                len(self._jax_devices),
                bool(JAX_ENABLE_X64),
                self._jax_forced_cpu,
            )
        except Exception as exc:
            raise RiceError(
                "failed to initialize JAX backend",
                error_code="SIM_BACKEND_JAX_INIT",
                details={"reason": str(exc), "forced_cpu": self._jax_forced_cpu},
            ) from exc

    def get_qiskit_backend(self, method: str | None = None, *, noisy: bool = False) -> Any:
        """Return cached Qiskit backend (AerSimulator or qasm_simulator for noisy runs)."""
        selected = (method or AER_METHOD).strip().lower()
        shots = self._default_shots

        if noisy or selected == "qasm_simulator":
            key = ("qasm_simulator", shots)
            with self._cache_lock:
                if key in self._qiskit_cache:
                    return self._qiskit_cache[key]
            try:
                backend = Aer.get_backend("qasm_simulator")
                if hasattr(backend, "set_options"):
                    backend.set_options(shots=shots)
            except Exception as exc:
                raise RiceError(
                    "failed to initialize Qiskit qasm_simulator",
                    error_code="SIM_BACKEND_QISKIT_INIT",
                    details={"backend": "qasm_simulator", "reason": str(exc)},
                ) from exc
            with self._cache_lock:
                self._qiskit_cache[key] = backend
            return backend

        key = (selected, shots)
        with self._cache_lock:
            if key in self._qiskit_cache:
                return self._qiskit_cache[key]
        try:
            opts = dict(AER_OPTIONS)
            opts["method"] = selected
            opts["shots"] = shots
            backend = AerSimulator(**opts)
        except Exception as exc:
            raise RiceError(
                "failed to initialize AerSimulator",
                error_code="SIM_BACKEND_QISKIT_INIT",
                details={"method": selected, "reason": str(exc)},
            ) from exc
        with self._cache_lock:
            self._qiskit_cache[key] = backend
        return backend

    def get_pennylane_device(self, wires: int, name: str = "default.qubit.jax", *, shots: int | None = None) -> Any:
        """Return cached PennyLane device with JAX-friendly defaults."""
        n_wires = max(1, int(wires))
        selected_shots = int(shots) if shots is not None else None
        key = (name, n_wires, selected_shots)
        with self._cache_lock:
            if key in self._pennylane_cache:
                return self._pennylane_cache[key]
        try:
            import pennylane as qml

            dev = qml.device(name, wires=n_wires, shots=selected_shots)
        except Exception as exc:
            raise RiceError(
                "failed to initialize PennyLane device",
                error_code="SIM_BACKEND_PENNYLANE_INIT",
                details={"name": name, "wires": n_wires, "reason": str(exc)},
            ) from exc
        with self._cache_lock:
            self._pennylane_cache[key] = dev
        return dev

    def get_info(self) -> dict[str, Any]:
        """Current environment summary for diagnostics/telemetry."""
        info = BackendInfo(
            jax_platform=self._jax_platform,
            jax_devices=self._jax_devices,
            jax_forced_cpu=self._jax_forced_cpu,
            qiskit_default_method=AER_METHOD,
            precision_real=PRECISION_REAL,
            precision_complex=PRECISION_COMPLEX,
            default_shots=self._default_shots,
            available_memory_mb=self._available_memory_mb,
            ibmq_placeholder="IBMQ cloud provider integration placeholder",
        )
        return info.to_dict()

    def get_ibmq_provider_placeholder(self) -> None:
        """Reserved API for future cloud integration (IBMQ Runtime / Provider)."""
        logger.info("BackendManager: IBMQ provider integration is not implemented yet")
        return None


def get_backend_manager() -> BackendManager:
    return BackendManager()


def get_qiskit_backend(method: str | None = None) -> Any:
    return get_backend_manager().get_qiskit_backend(method=method)


def get_pennylane_device(wires: int, name: str = "default.qubit.jax") -> Any:
    return get_backend_manager().get_pennylane_device(wires=wires, name=name)


def get_info() -> dict[str, Any]:
    return get_backend_manager().get_info()


def aer_simulator(**kwargs: Any) -> AerSimulator:
    """Compatibility wrapper for direct ``AerSimulator`` construction."""
    return AerSimulator(**kwargs)


def statevector_simulator(**kwargs: Any) -> Any:
    """Compatibility wrapper for legacy API."""
    return get_backend_manager().get_qiskit_backend(method="statevector")


def unitary_simulator(**kwargs: Any) -> Any:
    from qiskit_aer import UnitarySimulator

    return UnitarySimulator(**kwargs)


def density_matrix_simulator(**kwargs: Any) -> Any:
    opts = {"method": "density_matrix", **kwargs}
    return AerSimulator(**opts)


def configure_shots(backend: AerSimulator, shots: int) -> None:
    """Set default shots on an Aer backend (in-place)."""
    backend.set_options(shots=int(shots))


__all__ = [
    "BackendInfo",
    "BackendManager",
    "aer_simulator",
    "configure_shots",
    "density_matrix_simulator",
    "get_backend_manager",
    "get_info",
    "get_pennylane_device",
    "get_qiskit_backend",
    "statevector_simulator",
    "unitary_simulator",
]
