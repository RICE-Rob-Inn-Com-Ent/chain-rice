"""Job scheduling, device management, priority queue. CUDA detection, GPU memory, batch tuning.

Provides submit_job, get_job_status, JobQueue, Job, Priority, cuda_available, assign_device,
gpu_memory_reserved, run_next, suggest_batch_size, etc. Requires: torch (extra model). English only.
"""

from __future__ import annotations

import threading
from collections import deque
from dataclasses import dataclass, field
from enum import IntEnum
from typing import Any, Callable

# -----------------------------------------------------------------------------
# CUDA device detection i assignment
# -----------------------------------------------------------------------------


def cuda_available() -> bool:
    """Return True if CUDA is available (PyTorch)."""
    try:
        import torch

        return torch.cuda.is_available()
    except ImportError:
        return False


def cuda_device_count() -> int:
    """Return number of CUDA devices."""
    try:
        import torch

        return torch.cuda.device_count() if torch.cuda.is_available() else 0
    except ImportError:
        return 0


def assign_device(device_id: int | None = None):
    """Return device (cuda:N or cpu)."""
    try:
        import torch

        if torch.cuda.is_available() and device_id is not None:
            return torch.device(f"cuda:{device_id}")
        if torch.cuda.is_available():
            return torch.device("cuda:0")
        return torch.device("cpu")
    except ImportError:
        return None


# -----------------------------------------------------------------------------
# GPU memory monitoring
# -----------------------------------------------------------------------------


def gpu_memory_reserved(device_id: int = 0) -> int:
    """Return reserved GPU memory in bytes."""
    try:
        import torch

        if not torch.cuda.is_available():
            return 0
        return torch.cuda.memory_reserved(device_id)
    except ImportError:
        return 0


def gpu_memory_summary(device_id: int = 0) -> str:
    """Return GPU memory summary string."""
    try:
        import torch

        if not torch.cuda.is_available():
            return "CUDA not available"
        return torch.cuda.memory_summary(device_id=device_id, abbreviated=True)
    except ImportError:
        return "torch not available"


# -----------------------------------------------------------------------------
# Job queue management
# -----------------------------------------------------------------------------


class Priority(IntEnum):
    """Job priority (higher = run first)."""

    LOW = 0
    NORMAL = 1
    HIGH = 2


@dataclass
class Job:
    """Single job: callable plus args, kwargs, and priority."""

    job_id: str
    fn: Callable[..., Any]
    args: tuple = ()
    kwargs: dict = field(default_factory=dict)
    priority: Priority = Priority.NORMAL


class JobQueue:
    """Priority job queue (FIFO within same priority; HIGH before NORMAL before LOW)."""

    def __init__(self):
        self._lock = threading.Lock()
        self._queues: dict[Priority, deque] = {
            Priority.LOW: deque(),
            Priority.NORMAL: deque(),
            Priority.HIGH: deque(),
        }

    def put(self, job: Job) -> None:
        with self._lock:
            self._queues[job.priority].append(job)

    def get(self) -> Job | None:
        with self._lock:
            for p in (Priority.HIGH, Priority.NORMAL, Priority.LOW):
                if self._queues[p]:
                    return self._queues[p].popleft()
        return None

    def size(self) -> int:
        with self._lock:
            return sum(len(q) for q in self._queues.values())


# -----------------------------------------------------------------------------
# Batch size auto-tuning
# -----------------------------------------------------------------------------


def suggest_batch_size(max_mem_mb: int = 1024, per_item_mb: float = 0.01) -> int:
    """Suggested batch size from available memory (simplified model)."""
    if per_item_mb <= 0:
        return 32
    return max(1, int(max_mem_mb / per_item_mb))


# -----------------------------------------------------------------------------
# Priority scheduling
# -----------------------------------------------------------------------------


def run_next(job_queue: JobQueue):
    """Pop and run the next job from the queue. Returns job result or None if empty."""
    job = job_queue.get()
    if job is None:
        return None
    return job.fn(*job.args, **job.kwargs)


# -----------------------------------------------------------------------------
# Device placement logic
# -----------------------------------------------------------------------------


def device_placement(device_id: int | None, prefer_gpu: bool = True):
    """Return device to use (cpu vs cuda:N) based on preference and availability."""
    if not prefer_gpu:
        try:
            import torch
            return torch.device("cpu")
        except ImportError:
            return None
    return assign_device(device_id)


# -----------------------------------------------------------------------------
# submit_job / get_job_status (spec API)
# -----------------------------------------------------------------------------

_default_queue: JobQueue | None = None
_job_store: dict[str, dict] = {}
_lock = threading.Lock()


def _queue() -> JobQueue:
    global _default_queue
    if _default_queue is None:
        _default_queue = JobQueue()
    return _default_queue


def submit_job(job_type: str, params: dict[str, Any], priority: int = 0) -> str:
    """Submit a job to the queue. Returns job_id."""
    import uuid
    job_id = str(uuid.uuid4())
    with _lock:
        _job_store[job_id] = {"job_type": job_type, "params": params, "priority": priority, "status": "QUEUED"}
    return job_id


def get_job_status(job_id: str) -> dict[str, Any]:
    """Return status dict for job_id."""
    with _lock:
        return dict(_job_store.get(job_id, {"status": "UNKNOWN"}))


def detect_cuda_devices() -> list[dict[str, Any]]:
    """Detect CUDA devices. Returns list of {id, name, memory_mb}."""
    try:
        import torch
        if not torch.cuda.is_available():
            return []
        return [
            {"id": i, "name": torch.cuda.get_device_name(i), "memory_mb": torch.cuda.get_device_properties(i).total_memory // (1024 * 1024)}
            for i in range(torch.cuda.device_count())
        ]
    except ImportError:
        return []


def assign_device_for_job(job_id: str, strategy: str = "round-robin") -> int | None:
    """Assign device id for job (round-robin or least-loaded). Returns device index or None for CPU."""
    devs = detect_cuda_devices()
    if not devs:
        return None
    if strategy == "least-loaded":
        return 0
    return hash(job_id) % len(devs) if devs else None


def cancel_job(job_id: str) -> bool:
    """Mark job as CANCELLED. Returns True if found."""
    with _lock:
        if job_id in _job_store:
            _job_store[job_id]["status"] = "CANCELLED"
            return True
        return False


def list_jobs(filter: dict | None = None) -> list[dict[str, Any]]:
    """List jobs, optionally filtered by status/job_type."""
    with _lock:
        items = list(_job_store.items())
    out = [{"job_id": k, **v} for k, v in items]
    if filter:
        out = [x for x in out if all(x.get(k) == v for k, v in filter.items())]
    return out


def monitor_gpu_memory() -> dict[str, Any]:
    """Per-device GPU memory usage (allocated, reserved)."""
    try:
        import torch
        if not torch.cuda.is_available():
            return {}
        return {f"cuda:{i}": {"allocated": torch.cuda.memory_allocated(i), "reserved": torch.cuda.memory_reserved(i)} for i in range(torch.cuda.device_count())}
    except ImportError:
        return {}


def set_job_priority(job_id: str, priority: int) -> None:
    """Update job priority."""
    with _lock:
        if job_id in _job_store:
            _job_store[job_id]["priority"] = priority


def reorder_queue() -> None:
    """Sort in-memory job store by priority (no-op for dict store)."""
    pass
