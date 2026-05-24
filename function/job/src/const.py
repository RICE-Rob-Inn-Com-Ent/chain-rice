"""Immutable paths and defaults for `job` (Mojo package dir, build output, native libs)."""

from __future__ import annotations

import os
from collections.abc import Mapping
from pathlib import Path
from types import MappingProxyType
from typing import Final

# `.../job/src`
JOB_SRC_DIR: Final[Path] = Path(__file__).resolve().parent

# `.../job/` (wheel / project root next to pyproject.toml)
JOB_MODULE_ROOT: Final[Path] = JOB_SRC_DIR.parent

# Mojo sources / `mojo package` input tree (`job/src/mojo`).
MOJO_PACKAGE_DIR: Final[Path] = JOB_SRC_DIR / "mojo"

# Compiled artifacts (`mojo package -o`, shared objects produced by the toolchain).
MOJO_BUILD_DIR: Final[Path] = MOJO_PACKAGE_DIR / "build"

DEFAULT_MOJOPKG: Final[Path] = MOJO_BUILD_DIR / "sage.mojopkg"

# Optional override: directory containing `lib*.so` / `*.dylib` for CDLL.
MOJO_LIB_DIR_ENV: Final[str] = "RICE_MOJO_LIB_DIR"

# Extra search roots (colon-separated list of directories) after defaults.
MOJO_LIB_PATH_ENV: Final[str] = "RICE_MOJO_LIB_PATH"


def mojo_library_search_paths() -> tuple[Path, ...]:
    """Ordered roots used to resolve `lib{name}.so` / `lib{name}.dylib`."""
    extra: list[Path] = []
    raw = os.getenv(MOJO_LIB_DIR_ENV, "").strip()
    if raw:
        extra.append(Path(raw).expanduser().resolve())
    path_raw = os.getenv(MOJO_LIB_PATH_ENV, "").strip()
    if path_raw:
        for part in path_raw.split(os.pathsep):
            p = part.strip()
            if p:
                extra.append(Path(p).expanduser().resolve())
    return (*extra, MOJO_BUILD_DIR, MOJO_PACKAGE_DIR)


# ---------------------------------------------------------------------------
# [PARALLEL] — worker counts, chunking (orchestration in `parallel.py`)
# ---------------------------------------------------------------------------

# Cores reserved for the asyncio event loop, OS, and UI (BARD).
PARALLEL_CPU_RESERVE: Final[int] = max(0, int(os.getenv("RICE_PARALLEL_CPU_RESERVE", "1")))

# Optional caps (0 = derive from CPU only).
PARALLEL_MAX_THREAD_WORKERS: Final[int] = max(0, int(os.getenv("RICE_JOB_THREAD_WORKERS", "0")))
PARALLEL_MAX_PROCESS_WORKERS: Final[int] = max(0, int(os.getenv("RICE_JOB_PROCESS_WORKERS", "0")))

# Default row/chunk size for `parallel_map` batching.
PARALLEL_DEFAULT_CHUNK_SIZE: Final[int] = max(1, int(os.getenv("RICE_PARALLEL_CHUNK_SIZE", "4096")))


def optimal_thread_workers() -> int:
    """Thread pool size: all logical CPUs minus reserve, clamped by env cap."""
    n = os.cpu_count() or 2
    w = max(1, n - PARALLEL_CPU_RESERVE)
    if PARALLEL_MAX_THREAD_WORKERS > 0:
        w = min(w, PARALLEL_MAX_THREAD_WORKERS)
    return w


def optimal_process_workers() -> int:
    """Process pool size: same heuristic as threads (separate cap)."""
    n = os.cpu_count() or 2
    w = max(1, n - PARALLEL_CPU_RESERVE)
    if PARALLEL_MAX_PROCESS_WORKERS > 0:
        w = min(w, PARALLEL_MAX_PROCESS_WORKERS)
    return w


# ---------------------------------------------------------------------------
# [RICE_FRAME] — schema hints for :class:`frame.RiceFrame.validate_schema`
# ---------------------------------------------------------------------------

# Preferred SIMD-friendly float column type name (``str(pl.Float32)``-style labels).
RICE_FRAME_MOJO_PREFERRED_FLOAT: Final[str] = "Float32"

# Allowed numeric dtype names for strict Mojo-oriented validation (no strings/objects).
RICE_FRAME_MOJO_ALLOWED_FLOATS: Final[frozenset[str]] = frozenset({"Float32", "Float64"})
RICE_FRAME_MOJO_ALLOWED_INTEGERS: Final[frozenset[str]] = frozenset({
    "Int8",
    "Int16",
    "Int32",
    "Int64",
    "UInt8",
    "UInt16",
    "UInt32",
    "UInt64",
})

# Optional project-wide default expected schema: column name → Polars dtype name string.
RICE_FRAME_DEFAULT_EXPECTED_SCHEMA: Final[Mapping[str, str]] = MappingProxyType({})


# ---------------------------------------------------------------------------
# [RICE_ARRAY] — default tensor dtype / Mojo layout rules
# ---------------------------------------------------------------------------

# Default element type for new :class:`array.RiceArray` instances (SIMD-friendly).
RICE_ARRAY_DEFAULT_DTYPE_STR: Final[str] = os.getenv("RICE_DEFAULT_ARRAY_DTYPE", "float32").strip().lower()

# When true, :meth:`array.RiceArray.as_buffer` raises if the backing array is not C-contiguous.
_RICE_AC = os.getenv("RICE_ARRAY_MOJO_REQUIRE_C_CONTIGUOUS", "1").strip().lower()
RICE_ARRAY_MOJO_REQUIRE_C_CONTIGUOUS: Final[bool] = _RICE_AC not in {"0", "false", "no", "off"}

# Optional: try ``bridge.get_kernel`` for ``RICE_MOJO_ARRAY_LIB`` / ``RICE_MOJO_ARRAY_DOT``.
RICE_MOJO_ARRAY_LIB: Final[str] = os.getenv("RICE_MOJO_ARRAY_LIB", "sage").strip() or "sage"
RICE_MOJO_ARRAY_DOT: Final[str] = os.getenv("RICE_MOJO_ARRAY_DOT", "rice_array_dot").strip() or "rice_array_dot"


def default_array_dtype() -> str:
    """Canonical numpy dtype string for new dense tensors (e.g. ``\"float32\"``)."""
    return RICE_ARRAY_DEFAULT_DTYPE_STR


# ---------------------------------------------------------------------------
# [INGEST] — defaults for :mod:`ingest` (mmap, schema hints)
# ---------------------------------------------------------------------------

_ING_MMAP = os.getenv("RICE_INGEST_MEMORY_MAP", "1").strip().lower()
RICE_INGEST_MEMORY_MAP_DEFAULT: Final[bool] = _ING_MMAP not in {"0", "false", "no", "off"}

# Optional glob for :func:`ingest.batch_loader` when ``pattern`` is omitted.
RICE_INGEST_BATCH_GLOB: Final[str] = os.getenv("RICE_INGEST_BATCH_GLOB", "*").strip() or "*"


# ---------------------------------------------------------------------------
# [LINALG] — Mojo routing thresholds, tolerances (:mod:`linalg`)
# ---------------------------------------------------------------------------

# Minimum FLOPs (``m*k*n`` for ``(m,k)@(k,n)``) before attempting a Mojo matmul kernel.
RICE_LINALG_MOJO_MATMUL_FLOP_THRESHOLD: Final[int] = max(
    0,
    int(os.getenv("RICE_LINALG_MOJO_MATMUL_FLOP_THRESHOLD", str(2**20))),
)

RICE_LINALG_MATMUL_SYMBOL: Final[str] = (
    os.getenv("RICE_LINALG_MATMUL_SYMBOL", "matrix_mul_simd").strip() or "matrix_mul_simd"
)

_RRT = os.getenv("RICE_LINALG_RTOL", "1e-8").strip()
_RAT = os.getenv("RICE_LINALG_ATOL", "1e-10").strip()
RICE_LINALG_RTOL: Final[float] = float(_RRT or "1e-8")
RICE_LINALG_ATOL: Final[float] = float(_RAT or "1e-10")
