"""Parallel orchestration: thread/process pools, async offload, batch map, task queue.

`MemoryAnchor` pins objects **in-process only**. For :class:`concurrent.futures.ProcessPoolExecutor`,
pass picklable payloads (copies or :mod:`multiprocessing.shared_memory` views)—never raw pointers
from another process.
"""

from __future__ import annotations

import asyncio
import itertools
import multiprocessing
import os
import pickle
import resource
import threading
import time
import uuid
from collections.abc import Callable, Sequence
from concurrent.futures import Future, ProcessPoolExecutor, ThreadPoolExecutor
from dataclasses import dataclass, field
from enum import IntEnum
from functools import partial
from multiprocessing import shared_memory
from typing import Any, Generic, TypeVar

import numpy as np
from loguru import logger

from . import const
from .memory import buffer_metadata

try:  # pragma: no cover
    import psutil
except ImportError:  # pragma: no cover
    psutil = None  # type: ignore[assignment]

T = TypeVar("T")
R = TypeVar("R")


class CircuitOpenError(RuntimeError):
    """Raised when the circuit breaker is open and new parallel work is rejected."""


class TaskPriority(IntEnum):
    """Lower value = scheduled sooner."""

    CRITICAL = 0
    NORMAL = 50
    BACKGROUND = 100


class CircuitBreaker:
    """Trip after repeated failures (including OOM) to protect the host."""

    __slots__ = (
        "_failure_threshold",
        "_failures",
        "_lock",
        "_opened_at",
        "_reset_timeout_s",
        "_state",
    )

    def __init__(self, *, failure_threshold: int = 5, reset_timeout_s: float = 60.0) -> None:
        self._failure_threshold = max(1, failure_threshold)
        self._reset_timeout_s = max(1.0, reset_timeout_s)
        self._failures = 0
        self._state = "closed"
        self._opened_at: float | None = None
        self._lock = threading.Lock()

    def check(self) -> None:
        with self._lock:
            if self._state == "open":
                assert self._opened_at is not None
                if time.monotonic() - self._opened_at >= self._reset_timeout_s:
                    self._state = "half_open"
                    logger.warning("circuit_breaker half_open after reset_timeout_s={}", self._reset_timeout_s)
                else:
                    msg = "parallel circuit breaker is open (workers unhealthy)"
                    raise CircuitOpenError(msg)

    def record_success(self) -> None:
        with self._lock:
            self._failures = 0
            if self._state != "closed":
                logger.info("circuit_breaker closed after success")
            self._state = "closed"
            self._opened_at = None

    def record_failure(self, exc: BaseException) -> None:
        oom = isinstance(exc, MemoryError) or (
            isinstance(exc, OSError) and getattr(exc, "errno", None) in {12, 122}  # ENOMEM / Linux EDQUOT
        )
        with self._lock:
            self._failures += 1
            if oom:
                self._failures += self._failure_threshold  # trip fast on OOM
            logger.error(
                "circuit_breaker failure n={} oom_hint={} exc={!r}",
                self._failures,
                oom,
                exc,
            )
            if self._failures >= self._failure_threshold and self._state != "open":
                self._state = "open"
                self._opened_at = time.monotonic()
                logger.critical(
                    "circuit_breaker OPEN — parallel queue stopped (failures={}, threshold={})",
                    self._failures,
                    self._failure_threshold,
                )


def _thread_cpu_seconds() -> float:
    try:
        u = resource.getrusage(resource.RUSAGE_THREAD)
    except (AttributeError, ValueError, OSError):
        return -1.0
    return float(u.ru_utime + u.ru_stime)


def _process_cpu_percent_sample() -> float | None:
    if psutil is None:
        return None
    try:
        return float(psutil.Process(os.getpid()).cpu_percent(interval=None))
    except Exception:
        return None


@dataclass(slots=True)
class JobExecutor:
    """Pools for CPU-bound work: threads (default, Mojo/ctypes-safe) and optional processes."""

    max_threads: int = field(default_factory=const.optimal_thread_workers)
    max_processes: int = field(default_factory=const.optimal_process_workers)
    _threads: ThreadPoolExecutor | None = None
    _processes: ProcessPoolExecutor | None = None
    _lock: threading.Lock = field(default_factory=threading.Lock, repr=False)

    def __post_init__(self) -> None:
        self.max_threads = max(1, int(self.max_threads))
        self.max_processes = max(1, int(self.max_processes))

    @property
    def thread_pool(self) -> ThreadPoolExecutor:
        with self._lock:
            if self._threads is None:
                self._threads = ThreadPoolExecutor(
                    max_workers=self.max_threads,
                    thread_name_prefix="rice-job",
                )
                logger.info("JobExecutor thread_pool max_workers={}", self.max_threads)
            return self._threads

    @property
    def process_pool(self) -> ProcessPoolExecutor:
        with self._lock:
            if self._processes is None:
                # spawn avoids fork + threads / CDLL issues on Linux and matches Windows.
                self._processes = ProcessPoolExecutor(
                    max_workers=self.max_processes,
                    mp_context=multiprocessing.get_context("spawn"),
                )
                logger.info("JobExecutor process_pool max_workers={}", self.max_processes)
            return self._processes

    async def run_async(self, func: Callable[..., R], /, *args: Any, **kwargs: Any) -> R:
        """Offload sync ``func`` to the thread pool (non-blocking for asyncio)."""
        loop = asyncio.get_running_loop()
        t0 = time.perf_counter()
        cpu0 = _thread_cpu_seconds()
        proc_cpu0 = _process_cpu_percent_sample()

        def _call() -> R:
            return func(*args, **kwargs)

        try:
            out = await loop.run_in_executor(self.thread_pool, _call)
        except Exception:
            logger.exception("run_async task failed func={}", getattr(func, "__name__", repr(func)))
            raise
        dt = time.perf_counter() - t0
        cpu1 = _thread_cpu_seconds()
        dcpu = (cpu1 - cpu0) if cpu0 >= 0 and cpu1 >= 0 else -1.0
        proc_cpu1 = _process_cpu_percent_sample()
        extra = ""
        if proc_cpu0 is not None and proc_cpu1 is not None:
            extra = f" proc_cpu%≈{proc_cpu1:.1f}"
        logger.debug(
            "run_async done func={} wall_ms={:.2f} thread_cpu_delta_s={:.4f}{}",
            getattr(func, "__name__", repr(func)),
            dt * 1000,
            dcpu,
            extra,
        )
        return out

    def run_in_thread_pool(self, func: Callable[..., R], /, *args: Any, **kwargs: Any) -> Future[R]:
        """Schedule sync work; returns a concurrent.futures.Future (thread-safe)."""
        return self.thread_pool.submit(func, *args, **kwargs)

    def run_in_process_pool(self, func: Callable[..., R], /, *args: Any, **kwargs: Any) -> Future[R]:
        """Schedule picklable work in a child process."""
        if kwargs:
            return self.process_pool.submit(partial(func, **kwargs), *args)
        return self.process_pool.submit(func, *args)

    def shutdown(self, *, wait: bool = True, cancel_futures: bool = False) -> None:
        with self._lock:
            if self._threads is not None:
                self._threads.shutdown(wait=wait, cancel_futures=cancel_futures)
                self._threads = None
            if self._processes is not None:
                self._processes.shutdown(wait=wait, cancel_futures=cancel_futures)
                self._processes = None


_default_executor: JobExecutor | None = None
_default_lock = threading.Lock()


def default_executor() -> JobExecutor:
    global _default_executor
    with _default_lock:
        if _default_executor is None:
            _default_executor = JobExecutor()
        return _default_executor


async def run_async(func: Callable[..., R], /, *args: Any, **kwargs: Any) -> R:
    """Offload ``func`` on the package-default :class:`JobExecutor` thread pool."""
    return await default_executor().run_async(func, *args, **kwargs)


def _chunk_indices(n: int, chunk_size: int) -> list[tuple[int, int]]:
    return [(i, min(i + chunk_size, n)) for i in range(0, n, chunk_size)]


def _parallel_map_thread_chunk(
    func: Callable[[Sequence[T]], R],
    chunk: Sequence[T],
) -> R:
    return func(chunk)


def _parallel_map_process_chunk(
    func: Callable[[Sequence[T]], R],
    chunk: Sequence[T],
) -> R:
    return func(chunk)


def _shm_map_worker(payload: tuple[str, tuple[int, ...], str, bytes]) -> Any:
    """Top-level for pickling: ``(shm_name, shape, dtype_str, pickled_func)``."""
    shm_name, shape, dtype_s, pickled = payload
    fn = pickle.loads(pickled)
    shm = shared_memory.SharedMemory(name=shm_name)
    try:
        arr = np.ndarray(shape, dtype=np.dtype(dtype_s), buffer=shm.buf)
        return fn(arr)
    finally:
        shm.close()


async def parallel_map(
    func: Callable[[Sequence[T]], R],
    data_list: Sequence[T],
    *,
    executor: JobExecutor | None = None,
    chunk_size: int | None = None,
    use_processes: bool = False,
    use_shared_memory_numpy: bool = False,
) -> list[R]:
    """Split ``data_list`` into chunks and run ``func(chunk)`` concurrently.

    - **Threads** (default): safe with in-process :mod:`memory` anchors / Mojo CDLL.
    - **Processes** (``use_processes=True``): ``func`` must be picklable; do **not** pass ctypes
      pointers—reload kernels in the child or use pure NumPy.
    - **Shared memory** (``use_shared_memory_numpy=True``): each chunk is copied into a
      :class:`multiprocessing.shared_memory.SharedMemory` slab so children map a NumPy view
      without pickling large arrays (still not the parent's :class:`MemoryAnchor`).
    """
    ex = executor or default_executor()
    cs = chunk_size or const.PARALLEL_DEFAULT_CHUNK_SIZE
    n = len(data_list)
    if n == 0:
        return []
    spans = _chunk_indices(n, max(1, cs))
    loop = asyncio.get_running_loop()
    t0 = time.perf_counter()
    results: list[R | None] = [None] * len(spans)

    async def _one(i: int, lo: int, hi: int) -> None:
        chunk = data_list[lo:hi]
        try:
            if use_shared_memory_numpy:
                if not isinstance(chunk, np.ndarray):
                    msg = "use_shared_memory_numpy requires data_list to be a numpy ndarray"
                    raise TypeError(msg)
                arr = np.ascontiguousarray(chunk)
                shm = shared_memory.SharedMemory(create=True, size=int(arr.nbytes))
                try:
                    dst = np.ndarray(arr.shape, dtype=arr.dtype, buffer=shm.buf)
                    dst[...] = arr
                    blob = pickle.dumps(func, protocol=pickle.HIGHEST_PROTOCOL)
                    payload = (shm.name, tuple(int(x) for x in arr.shape), str(arr.dtype), blob)
                    if use_processes:
                        fut = ex.process_pool.submit(_shm_map_worker, payload)
                        results[i] = await loop.run_in_executor(ex.thread_pool, partial(fut.result))
                    else:
                        results[i] = await ex.run_async(_shm_map_worker, payload)
                finally:
                    shm.close()
                    try:
                        shm.unlink()
                    except FileNotFoundError:
                        pass
            elif use_processes:
                fut = ex.process_pool.submit(_parallel_map_process_chunk, func, chunk)
                results[i] = await loop.run_in_executor(ex.thread_pool, partial(fut.result))
            else:
                results[i] = await ex.run_async(_parallel_map_thread_chunk, func, chunk)
        except Exception:
            logger.exception("parallel_map chunk failed i={} lo={} hi={}", i, lo, hi)
            raise

    await asyncio.gather(*(_one(i, lo, hi) for i, (lo, hi) in enumerate(spans)))
    logger.info(
        "parallel_map completed chunks={} items={} wall_ms={:.2f} processes={} shm_numpy={}",
        len(spans),
        n,
        (time.perf_counter() - t0) * 1000,
        use_processes,
        use_shared_memory_numpy,
    )
    return list(results)


@dataclass
class Heartbeat:
    """Periodic progress pulses for BARD / long-running jobs."""

    interval_s: float = 5.0
    job_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    on_pulse: Callable[[dict[str, Any]], None] | None = None

    def pulse(self, **fields: Any) -> None:
        payload: dict[str, Any] = {"job_id": self.job_id, "ts": time.time(), **fields}
        if self.on_pulse is not None:
            self.on_pulse(payload)
        else:
            logger.info("heartbeat {}", payload)


async def heartbeat_loop(
    heartbeat: Heartbeat,
    *,
    stop: asyncio.Event,
    progress: Callable[[], dict[str, Any]] | None = None,
) -> None:
    """Until ``stop`` is set, emit :meth:`Heartbeat.pulse` every ``heartbeat.interval_s``."""
    while not stop.is_set():
        try:
            await asyncio.wait_for(stop.wait(), timeout=heartbeat.interval_s)
        except TimeoutError:
            fields = progress() if progress else {}
            heartbeat.pulse(**fields)


class TaskQueue(Generic[R]):
    """Async priority queue: ``CRITICAL`` tasks run before ``BACKGROUND``."""

    __slots__ = ("_breaker", "_counter", "_executor", "_queue", "_runner", "_started")

    def __init__(self, executor: JobExecutor | None = None, *, breaker: CircuitBreaker | None = None) -> None:
        self._executor = executor or default_executor()
        self._breaker = breaker or CircuitBreaker()
        self._queue: asyncio.PriorityQueue[tuple[int, int, asyncio.Future[R], Callable[..., R], tuple[Any, ...], dict[str, Any]]] = asyncio.PriorityQueue()
        self._counter = itertools.count()
        self._runner: asyncio.Task[None] | None = None
        self._started = False

    @property
    def circuit_breaker(self) -> CircuitBreaker:
        return self._breaker

    def _ensure_runner(self) -> None:
        if self._started:
            return
        self._started = True
        loop = asyncio.get_running_loop()
        self._runner = loop.create_task(self._consume(), name="rice-task-queue")

    async def _consume(self) -> None:
        while True:
            prio, _seq, fut, fn, args, kwargs = await self._queue.get()
            self._breaker.check()
            t0 = time.perf_counter()
            try:
                result = await self._executor.run_async(fn, *args, **kwargs)
            except asyncio.CancelledError:
                raise
            except Exception as exc:
                self._breaker.record_failure(exc)
                if not fut.done():
                    fut.set_exception(exc)
                logger.exception("TaskQueue task failed prio={} func={}", prio, getattr(fn, "__name__", fn))
            else:
                self._breaker.record_success()
                if not fut.done():
                    fut.set_result(result)
                logger.debug(
                    "TaskQueue ok prio={} func={} wall_ms={:.2f}",
                    prio,
                    getattr(fn, "__name__", fn),
                    (time.perf_counter() - t0) * 1000,
                )

    async def submit(
        self,
        fn: Callable[..., R],
        /,
        *args: Any,
        priority: TaskPriority = TaskPriority.NORMAL,
        **kwargs: Any,
    ) -> asyncio.Future[R]:
        """Enqueue ``fn``; result is delivered on the returned Future."""
        self._ensure_runner()
        self._breaker.check()
        loop = asyncio.get_running_loop()
        fut: asyncio.Future[R] = loop.create_future()
        seq = next(self._counter)
        await self._queue.put((int(priority), seq, fut, fn, args, kwargs))
        return fut

    async def shutdown(self) -> None:
        if self._runner is not None:
            self._runner.cancel()
            try:
                await self._runner
            except asyncio.CancelledError:
                pass
            self._runner = None
            self._started = False


def anchor_payload_for_thread(obj: Any) -> tuple[int, int, str, tuple[int, ...]]:
    """Return ``(ptr, size, dtype, shape)`` for logs / handoffs between **threads** (same process).

    Does **not** call :func:`memory.anchor`. For thread-pool tasks, call
    :func:`memory.anchor` in the submitter before scheduling and :func:`memory.release`
    after the future completes. Never send raw ``ptr`` to another **process**.
    """
    meta = buffer_metadata(obj)
    return (meta.ptr, meta.size, meta.dtype, meta.shape)


__all__ = [
    "CircuitBreaker",
    "CircuitOpenError",
    "Heartbeat",
    "JobExecutor",
    "TaskPriority",
    "TaskQueue",
    "anchor_payload_for_thread",
    "default_executor",
    "heartbeat_loop",
    "parallel_map",
    "run_async",
]
