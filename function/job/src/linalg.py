"""Linear algebra: NumPy/SciPy execution with optional Mojo routing and :class:`array.RiceArray` / :class:`frame.RiceFrame` inputs."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import os
import time
from typing import Any, cast

import numpy as np
from loguru import logger
from numpy.typing import NDArray

from . import const

try:
    import polars as pl
except ImportError:  # pragma: no cover
    pl = None  # type: ignore[assignment]

from .array import RiceArray
from .frame import RiceFrame

Tensorish = NDArray[Any] | RiceArray | RiceFrame


def _linalg_log(op: str, engine: str, *, shapes: str = "", extra: str = "") -> None:
    logger.info("linalg op={} engine={} shapes={} {}", op, engine, shapes, extra)


def _as_numpy(x: Tensorish, *, two_d: bool = False) -> NDArray[Any]:
    if isinstance(x, RiceArray):
        a = x.data
    elif isinstance(x, RiceFrame):
        if pl is None:
            msg = "polars is required for RiceFrame inputs"
            raise ImportError(msg)
        inner = x.inner
        if isinstance(inner, pl.LazyFrame):
            inner = inner.collect()
        if not isinstance(inner, pl.DataFrame):
            msg = "RiceFrame must materialize to DataFrame"
            raise TypeError(msg)
        a = inner.to_numpy()
    else:
        a = np.asarray(x)
    if two_d and a.ndim != 2:
        msg = f"expected 2-D array, got shape {a.shape}"
        raise ValueError(msg)
    return a


def _as_numpy_square(x: Tensorish) -> NDArray[Any]:
    a = _as_numpy(x, two_d=True)
    if a.shape[0] != a.shape[1]:
        msg = "expected square matrix"
        raise ValueError(msg)
    return a


def _matmul_flops(m: int, k: int, n: int) -> int:
    return int(m) * int(k) * int(n)


def _try_mojo_matmul(aa: NDArray[Any], bb: NDArray[Any]) -> NDArray[Any] | None:
    """Probe :mod:`bridge` for ``const.RICE_LINALG_MATMUL_SYMBOL``; execute when a 3-buffer ABI exists.

    Today most builds only export matmul-with-output via a separate symbol; until wired,
    this returns ``None`` so :func:`numpy.matmul` remains the safe path.
    """
    import ctypes

    from .bridge import KernelNotFoundError, get_kernel

    m, k = int(aa.shape[0]), int(aa.shape[1])
    k2, n = int(bb.shape[0]), int(bb.shape[1])
    if k != k2:
        return None
    try:
        get_kernel(
            const.RICE_MOJO_ARRAY_LIB,
            const.RICE_LINALG_MATMUL_SYMBOL,
            n_buffers=2,
            extra_argtypes=(ctypes.c_int64, ctypes.c_int64, ctypes.c_int64),
            restype=ctypes.c_int,
        )
    except KernelNotFoundError:
        return None
    logger.info(
        "linalg matmul: Mojo symbol {} loaded — NumPy fallback until out-buffer ABI is bound",
        const.RICE_LINALG_MATMUL_SYMBOL,
    )
    return None


def matmul(a: Tensorish, b: Tensorish, *, use_mojo: bool | None = None) -> NDArray[Any]:
    """Matrix multiply; may route to Mojo when FLOPs exceed :data:`const.RICE_LINALG_MOJO_MATMUL_FLOP_THRESHOLD`."""
    t0 = time.perf_counter()
    aa = np.ascontiguousarray(_as_numpy(a, two_d=True))
    bb = np.ascontiguousarray(_as_numpy(b, two_d=True))
    m, k = aa.shape
    k2, n = bb.shape
    if k != k2:
        msg = f"inner dimensions mismatch: {aa.shape} vs {bb.shape}"
        raise ValueError(msg)
    flops = _matmul_flops(m, k, n)
    th = const.RICE_LINALG_MOJO_MATMUL_FLOP_THRESHOLD
    want_mojo = (use_mojo is not False) and th > 0 and flops >= th
    if want_mojo and os.getenv("RICE_LINALG_MOJO_MATMUL_ENABLE", "0").lower() in {"1", "true", "yes"}:
        out = _try_mojo_matmul(aa, bb)
        if out is not None:
            _linalg_log("matmul", "mojo", shapes=f"{aa.shape}x{bb.shape}->{out.shape}")
            logger.debug("linalg matmul wall_s={:.4f}", time.perf_counter() - t0)
            return out
        _linalg_log("matmul", "numpy", shapes=f"{aa.shape}x{bb.shape}", extra="(mojo unavailable or ABI mismatch)")
    else:
        _linalg_log("matmul", "numpy", shapes=f"{aa.shape}x{bb.shape}", extra=f"flops={flops} th={th}")
    out = np.matmul(aa, bb)
    logger.debug("linalg matmul wall_s={:.4f}", time.perf_counter() - t0)
    return out


def transpose(a: Tensorish, *, axes: tuple[int, ...] | None = None) -> NDArray[Any]:
    t0 = time.perf_counter()
    x = _as_numpy(a)
    y = x.T if axes is None else np.transpose(x, axes=axes)
    _linalg_log("transpose", "numpy", shapes=str(x.shape))
    logger.debug("linalg transpose wall_s={:.4f}", time.perf_counter() - t0)
    return y


def inverse(a: Tensorish) -> NDArray[Any]:
    t0 = time.perf_counter()
    x = _as_numpy_square(a)
    y = np.linalg.inv(x)
    _linalg_log("inverse", "numpy", shapes=str(x.shape))
    logger.debug("linalg inverse wall_s={:.4f}", time.perf_counter() - t0)
    return y


def det(a: Tensorish) -> Any:
    t0 = time.perf_counter()
    x = _as_numpy_square(a)
    d = np.linalg.det(x)
    _linalg_log("det", "numpy", shapes=str(x.shape))
    logger.debug("linalg det wall_s={:.4f}", time.perf_counter() - t0)
    return d


def solve(a: Tensorish, b: Tensorish) -> NDArray[Any]:
    """Solve ``A x = b`` for square ``A`` (same as :func:`solve_linear`)."""
    return solve_linear(a, b)


def solve_linear(a: Tensorish, b: Tensorish) -> NDArray[Any]:
    t0 = time.perf_counter()
    aa = _as_numpy_square(a)
    bb = _as_numpy(b)
    x = np.linalg.solve(aa, bb)
    _linalg_log("solve", "numpy", shapes=f"A{aa.shape} b{bb.shape}")
    logger.debug("linalg solve wall_s={:.4f}", time.perf_counter() - t0)
    return x


def lstsq_overdetermined(a: NDArray[Any], b: NDArray[Any], rcond: float | None = None) -> tuple[Any, ...]:
    return np.linalg.lstsq(a, b, rcond=rcond)


def eigen(a: Tensorish) -> tuple[NDArray[Any], NDArray[Any]]:
    """Eigen-decomposition (dense); engine ``numpy``."""
    t0 = time.perf_counter()
    x = _as_numpy_square(a)
    w, v = np.linalg.eig(x)
    _linalg_log("eigen", "numpy", shapes=str(x.shape))
    logger.debug("linalg eigen wall_s={:.4f}", time.perf_counter() - t0)
    return w, v


def eig_decompose(a: NDArray[Any]) -> tuple[NDArray[Any], NDArray[Any]]:
    return eigen(a)


def svd(
    a: Tensorish,
    *,
    full_matrices: bool = True,
) -> tuple[NDArray[Any], NDArray[Any], NDArray[Any]]:
    t0 = time.perf_counter()
    x = _as_numpy(a, two_d=True)
    u, s, vh = np.linalg.svd(x, full_matrices=full_matrices)
    _linalg_log("svd", "numpy", shapes=str(x.shape))
    logger.debug("linalg svd wall_s={:.4f}", time.perf_counter() - t0)
    return u, s, vh


def svd_decompose(
    a: NDArray[Any],
    *,
    full_matrices: bool = True,
) -> tuple[NDArray[Any], NDArray[Any], NDArray[Any]]:
    return svd(a, full_matrices=full_matrices)


def eigvalsh_symmetric(a: NDArray[Any]) -> NDArray[Any]:
    """Eigenvalues of a symmetric (Hermitian) matrix."""
    return np.linalg.eigvalsh(a)


def norm_vector(x: NDArray[Any], *, ord: float | None = None) -> Any:
    return np.linalg.norm(x, ord=ord)


def matrix_rank(a: NDArray[Any], *, tol: float | None = None) -> int:
    return int(np.linalg.matrix_rank(a, tol=tol))


def dot(a: NDArray[Any], b: NDArray[Any]) -> NDArray[Any]:
    return np.dot(a, b)


def is_symmetric(
    a: Tensorish,
    *,
    rtol: float | None = None,
    atol: float | None = None,
) -> bool:
    aa = _as_numpy_square(a)
    rt = const.RICE_LINALG_RTOL if rtol is None else rtol
    at = const.RICE_LINALG_ATOL if atol is None else atol
    return bool(np.allclose(aa, aa.T, rtol=rt, atol=at))


def is_positive_definite(
    a: Tensorish,
    *,
    rtol: float | None = None,
    atol: float | None = None,
) -> bool:
    """Symmetric ``A`` is PD iff all eigenvalues are strictly positive (within ``atol``)."""
    at = const.RICE_LINALG_ATOL if atol is None else atol
    if not is_symmetric(a, rtol=rtol, atol=atol):
        return False
    aa = _as_numpy_square(a)
    w = np.linalg.eigvalsh(aa)
    return bool(np.all(w > at))


def batched_matmul(
    a: Tensorish,
    b: Tensorish,
    *,
    parallel_batches: bool = True,
    min_batches_for_parallel: int = 4,
) -> NDArray[Any]:
    """Batched ``matmul`` for leading stack dimension ``(B, M, K) @ (B, K, N)``."""
    t0 = time.perf_counter()
    aa = _as_numpy(a)
    bb = _as_numpy(b)
    if aa.ndim != 3 or bb.ndim != 3:
        msg = "batched_matmul expects 3-D tensors (B, M, K) and (B, K, N)"
        raise ValueError(msg)
    b, m, k = aa.shape
    b2, k2, n = bb.shape
    if b != b2 or k != k2:
        msg = f"batch/shape mismatch: {aa.shape} vs {bb.shape}"
        raise ValueError(msg)
    if parallel_batches and b >= min_batches_for_parallel:
        from .parallel import default_executor

        def _one(i: int) -> NDArray[Any]:
            return np.matmul(aa[i], bb[i])

        ex = default_executor().thread_pool
        parts = list(ex.map(_one, range(b)))
        out = np.stack(parts, axis=0)
    else:
        out = np.matmul(aa, bb)
    eng = "numpy+threads" if parallel_batches and b >= min_batches_for_parallel else "numpy"
    _linalg_log("batched_matmul", eng, shapes=f"{aa.shape}x{bb.shape}")
    logger.debug("linalg batched_matmul wall_s={:.4f}", time.perf_counter() - t0)
    return cast(NDArray[Any], out)


__all__ = [
    "batched_matmul",
    "det",
    "dot",
    "eig_decompose",
    "eigen",
    "eigvalsh_symmetric",
    "inverse",
    "is_positive_definite",
    "is_symmetric",
    "lstsq_overdetermined",
    "matmul",
    "matrix_rank",
    "norm_vector",
    "solve",
    "solve_linear",
    "svd",
    "svd_decompose",
    "transpose",
]
