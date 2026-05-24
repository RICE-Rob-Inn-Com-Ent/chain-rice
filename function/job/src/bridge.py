"""Python ↔ Mojo shared libraries: `ctypes.CDLL`, kernel registry, async offload.

Loads compiled ``.so`` / ``.dylib`` artifacts (not the Mojo interpreter). Pointer
arguments are prepared via :mod:`job.src.memory` (zero-copy where possible).

C-level segmentation faults cannot be caught in Python; enable
``RICE_FAULTHANDLER=1`` for ``faulthandler`` traces on fatal signals.
"""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import asyncio
import ctypes
import faulthandler
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

import numpy as np
from loguru import logger

from . import const
from .memory import BufferMetadata, anchor, buffer_metadata, release

try:  # pragma: no cover
    import polars as pl
except ImportError:  # pragma: no cover
    pl = None  # type: ignore[assignment]

# ---------------------------------------------------------------------------
# Public paths (re-exported from const for backward compatibility)
# ---------------------------------------------------------------------------

MOJO_PACKAGE_DIR: Path = const.MOJO_PACKAGE_DIR
BUILD_DIR: Path = const.MOJO_BUILD_DIR
DEFAULT_MOJOPKG: Path = const.DEFAULT_MOJOPKG
_FUNCTION_PROJECT_ROOT: Path = Path(__file__).resolve().parents[2]

NUMPY_TO_MOJO_DTYPE: dict[str, str] = {
    "float32": "float32",
    "float64": "float64",
    "int32": "int32",
    "int64": "int64",
    "uint32": "uint32",
    "uint64": "uint64",
}

MOJO_TO_NUMPY: dict[str, np.dtype[Any]] = {
    "float32": np.dtype(np.float32),
    "float64": np.dtype(np.float64),
    "int32": np.dtype(np.int32),
    "int64": np.dtype(np.int64),
    "uint32": np.dtype(np.uint32),
    "uint64": np.dtype(np.uint64),
}


class KernelNotFoundError(AttributeError):
    """Raised when a shared library is missing or does not export the requested symbol."""


def _maybe_enable_faulthandler() -> None:
    if os.getenv("RICE_FAULTHANDLER", "").strip().lower() in {"1", "true", "yes"}:
        faulthandler.enable(all_threads=True)


_maybe_enable_faulthandler()


def _which_mojo() -> str | None:
    import shutil

    return shutil.which("mojo")


def build_mojopkg(out: Path | None = None, *, cwd: Path | None = None) -> int:
    """``mojo package job/src/mojo -o <mojopkg>`` from ``function/`` — requires ``mojo`` in PATH."""
    pkg = out or DEFAULT_MOJOPKG
    pkg.parent.mkdir(parents=True, exist_ok=True)
    exe = _which_mojo()
    if not exe:
        return 127
    root = cwd or _FUNCTION_PROJECT_ROOT
    cmd = [exe, "package", str(MOJO_PACKAGE_DIR.relative_to(root)), "-o", str(pkg.resolve())]
    r = subprocess.run(cmd, cwd=root, check=False, capture_output=True, text=True)
    return r.returncode


def max_engine_available() -> bool:
    """``mojo`` in PATH and optional ``MAX_ENGINE_DISABLED`` guard."""
    return bool(_which_mojo()) and os.getenv("MAX_ENGINE_DISABLED", "").lower() not in {"1", "true", "yes"}


def _shared_object_filenames(stem: str) -> list[str]:
    if sys.platform == "darwin":
        return [f"lib{stem}.dylib", f"{stem}.dylib"]
    if sys.platform == "win32":
        return [f"{stem}.dll", f"lib{stem}.dll"]
    return [f"lib{stem}.so", f"{stem}.so"]


def resolve_mojo_shared_library(lib_name: str) -> Path:
    """Return the first existing path for ``lib_name`` (stem) under :func:`const.mojo_library_search_paths`."""
    stem = lib_name.strip()
    if not stem:
        msg = "lib_name must be non-empty"
        raise ValueError(msg)
    for root in const.mojo_library_search_paths():
        if not root.exists():
            continue
        for name in _shared_object_filenames(stem):
            candidate = root / name
            if candidate.is_file():
                return candidate.resolve()
    searched = ", ".join(str(p) for p in const.mojo_library_search_paths())
    msg = f"No shared library found for stem {stem!r} under: {searched}"
    raise KernelNotFoundError(msg)


class KernelRegistry:
    """Singleton cache of loaded ``CDLL`` handles (avoids redundant disk I / dlopen)."""

    _instance: KernelRegistry | None = None

    def __init__(self) -> None:
        self._cdll_by_path: dict[str, ctypes.CDLL] = {}

    @classmethod
    def instance(cls) -> KernelRegistry:
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def load(self, path: Path | str) -> ctypes.CDLL:
        key = str(Path(path).resolve())
        if key not in self._cdll_by_path:
            try:
                self._cdll_by_path[key] = ctypes.CDLL(key)
            except OSError as e:
                logger.exception("Failed to load Mojo shared library path={}", key)
                msg = f"Could not load shared library: {key}"
                raise KernelNotFoundError(msg) from e
            logger.debug("Loaded Mojo shared library path={}", key)
        return self._cdll_by_path[key]

    def clear(self) -> None:
        """Drop cached handles (tests / hot reload)."""
        self._cdll_by_path.clear()


class MojoLibrary:
    """Thin handle around ``ctypes.CDLL`` for one on-disk artifact."""

    __slots__ = ("_cdll", "path")

    def __init__(self, path: Path | str) -> None:
        self.path = Path(path).resolve()
        self._cdll = KernelRegistry.instance().load(self.path)

    @classmethod
    def from_lib_name(cls, lib_name: str) -> MojoLibrary:
        return cls(resolve_mojo_shared_library(lib_name))

    @property
    def cdll(self) -> ctypes.CDLL:
        return self._cdll


def _standard_buffer_abi_types(n_buffers: int) -> list[type[Any]]:
    out: list[type[Any]] = []
    for _ in range(n_buffers):
        out.extend((ctypes.c_void_p, ctypes.c_size_t))
    return out


def get_kernel(
    lib_name: str,
    func_name: str,
    *,
    n_buffers: int = 1,
    extra_argtypes: tuple[type[Any], ...] = (),
    restype: Any = ctypes.c_int,
) -> ctypes._FuncPtr:
    """Resolve ``lib_name`` → ``CDLL`` and return ``func_name`` with ABI for :class:`BufferMetadata`.

    Default C ABI (per buffer column / tensor): ``void* ptr, size_t size`` — repeated
    ``n_buffers`` times, then optional scalar types in ``extra_argtypes``. Default
    ``restype`` is ``c_int`` (convention: ``0`` success).
    """
    lib = MojoLibrary.from_lib_name(lib_name)
    try:
        fn: ctypes._FuncPtr = getattr(lib.cdll, func_name)
    except AttributeError as e:
        logger.error("Kernel symbol missing lib={} func={}", lib.path, func_name)
        msg = f"Kernel not found: {func_name!r} in {lib.path}"
        raise KernelNotFoundError(msg) from e
    fn.argtypes = [*_standard_buffer_abi_types(n_buffers), *extra_argtypes]
    fn.restype = restype
    return fn


_BufferLike = Any  # ndarray, Polars frame/series, BufferMetadata


def _is_buffer_like(obj: Any) -> bool:
    if isinstance(obj, BufferMetadata):
        return True
    if isinstance(obj, np.ndarray):
        return True
    if pl is not None and isinstance(obj, (pl.DataFrame, pl.Series)):
        return True
    return hasattr(obj, "__array_interface__") and isinstance(getattr(obj, "__array_interface__", None), dict)


def _scalar_to_ctypes(x: Any) -> Any:
    if isinstance(x, bool):
        return ctypes.c_int(int(x))
    if isinstance(x, int):
        if -(2**31) <= x < 2**31:
            return ctypes.c_int(x)
        return ctypes.c_int64(x)
    if isinstance(x, float):
        return ctypes.c_double(x)
    return x


def _expand_kernel_arg(
    arg: Any,
    anchored: list[Any],
) -> list[Any]:
    """Convert one logical Python argument into ctypes values (pointer pairs for buffers)."""
    if isinstance(arg, BufferMetadata):
        return [ctypes.c_void_p(arg.ptr), ctypes.c_size_t(arg.size)]

    if isinstance(arg, np.ndarray):
        anchor(arg)
        anchored.append(arg)
        meta = buffer_metadata(arg)
        return [ctypes.c_void_p(meta.ptr), ctypes.c_size_t(meta.size)]

    if pl is not None:
        if isinstance(arg, pl.DataFrame):
            if arg.width == 0:
                msg = "empty DataFrame has no buffer for kernel"
                raise ValueError(msg)
            col0 = arg.to_series(0)
            anchor(col0)
            anchored.append(col0)
            meta = buffer_metadata(col0)
            return [ctypes.c_void_p(meta.ptr), ctypes.c_size_t(meta.size)]
        if isinstance(arg, pl.Series):
            anchor(arg)
            anchored.append(arg)
            meta = buffer_metadata(arg)
            return [ctypes.c_void_p(meta.ptr), ctypes.c_size_t(meta.size)]

    if _is_buffer_like(arg):
        anchor(arg)
        anchored.append(arg)
        meta = buffer_metadata(arg)
        return [ctypes.c_void_p(meta.ptr), ctypes.c_size_t(meta.size)]

    return [_scalar_to_ctypes(arg)]


def execute_kernel(func: ctypes._FuncPtr, *args: Any, **kwargs: Any) -> Any:
    """Call ``func`` with ``*args`` converted: buffer-likes → ``(void*, size_t)``, scalars → ctypes.

    Keeps buffer-owning Python objects pinned for the duration of the native call via
    :func:`memory.anchor` / :func:`memory.release`. ``BufferMetadata`` does not pin
    backing storage — keep the source object alive or pass the ndarray / frame instead.

    ``kwargs`` are forwarded only if ``func`` is a plain Python callable; otherwise they
    are ignored and logged once at debug level (ctypes functions do not accept kwargs).
    """
    if kwargs:
        logger.debug("execute_kernel ignoring kwargs keys={}", tuple(kwargs.keys()))

    anchored: list[Any] = []
    flat: list[Any] = []
    try:
        for a in args:
            flat.extend(_expand_kernel_arg(a, anchored))
        return func(*flat)
    except ctypes.ArgumentError:
        logger.exception("ctypes argument mismatch during kernel call")
        raise
    except Exception:
        logger.exception("Kernel execution error (Python-level); C segfaults are not catchable here")
        raise
    finally:
        for o in anchored:
            release(o)


async def execute_kernel_async(func: ctypes._FuncPtr, *args: Any, **kwargs: Any) -> Any:
    """Run :func:`execute_kernel` in a worker thread (non-blocking for asyncio)."""
    return await asyncio.to_thread(execute_kernel, func, *args, **kwargs)


def warmup(
    lib_name: str,
    *,
    func_name: str = "rice_job_warmup",
    n_buffers: int = 0,
    extra_argtypes: tuple[type[Any], ...] = (),
) -> bool:
    """Load ``lib_name`` and optionally call a no-arg / trivial kernel to warm JIT / I-cache.

    If ``func_name`` is missing, logs at INFO and returns ``False``. If ``n_buffers > 0``,
    you must supply a real kernel signature via :func:`get_kernel` instead of this helper.
    """
    path = resolve_mojo_shared_library(lib_name)
    KernelRegistry.instance().load(path)
    try:
        fn = get_kernel(lib_name, func_name, n_buffers=n_buffers, extra_argtypes=extra_argtypes)
    except KernelNotFoundError:
        logger.info("warmup: symbol {} not in {} — library load only", func_name, path)
        return False
    try:
        if n_buffers == 0 and not extra_argtypes:
            fn()
        else:
            logger.debug("warmup skipped call for {} (non-default ABI); loaded only", func_name)
        return True
    except Exception:
        logger.exception("warmup call failed lib={} func={}", path, func_name)
        raise


class MojoKernelBridge:
    """High-level façade: mojopkg presence check, dtype map, NumPy SIMD fallbacks."""

    def __init__(self, mojopkg: Path | None = None, *, shared_lib_stem: str | None = None) -> None:
        self.mojopkg = mojopkg or DEFAULT_MOJOPKG
        self._shared_lib_stem = shared_lib_stem
        self._loaded = False
        self._error: str | None = None

    def ensure_package(self) -> bool:
        if self.mojopkg.is_file():
            self._loaded = True
            return True
        self._error = f"Brak pliku mojopkg: {self.mojopkg} (uruchom build_mojopkg())"
        return False

    def numpy_dtype(self, name: str) -> np.dtype[Any]:
        return MOJO_TO_NUMPY.get(name, np.dtype(np.float32))

    def dot_f32x8_numpy(self, a: np.ndarray, b: np.ndarray) -> np.floating[Any]:
        """Odpowiednik ``simd.dot_f32x8`` — wektory długości 8."""
        aa = np.asarray(a, dtype=np.float32).ravel()[:8]
        bb = np.asarray(b, dtype=np.float32).ravel()[:8]
        return np.dot(aa, bb)

    def get_kernel(
        self,
        func_name: str,
        *,
        n_buffers: int = 1,
        extra_argtypes: tuple[type[Any], ...] = (),
        restype: Any = ctypes.c_int,
    ) -> ctypes._FuncPtr:
        stem = self._shared_lib_stem or self.mojopkg.stem
        return get_kernel(stem, func_name, n_buffers=n_buffers, extra_argtypes=extra_argtypes, restype=restype)


__all__ = [
    "BUILD_DIR",
    "DEFAULT_MOJOPKG",
    "KernelNotFoundError",
    "KernelRegistry",
    "MOJO_PACKAGE_DIR",
    "MOJO_TO_NUMPY",
    "MojoKernelBridge",
    "MojoLibrary",
    "NUMPY_TO_MOJO_DTYPE",
    "build_mojopkg",
    "execute_kernel",
    "execute_kernel_async",
    "get_kernel",
    "max_engine_available",
    "resolve_mojo_shared_library",
    "warmup",
]
