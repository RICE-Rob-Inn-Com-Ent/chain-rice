"""Dense tensors (:class:`RiceArray`), sparse CSR/CSC → Mojo buffers, NumPy/SciPy bridge."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import ctypes
import os
import time
from dataclasses import dataclass
from typing import Any, Literal, cast

import numpy as np
from loguru import logger
from numpy.typing import ArrayLike, DTypeLike, NDArray
from scipy import sparse as sp

from . import const
from .frame import RiceFrame
from .memory import BufferMetadata, buffer_metadata

_ALLOWED_DTYPES: tuple[np.dtype[Any], ...] = (
    np.dtype(np.float32),
    np.dtype(np.float64),
    np.dtype(np.int32),
    np.dtype(np.int64),
    np.dtype(np.complex64),
)


class NonContiguousArrayError(ValueError):
    """Raised when a Mojo handoff requires C-contiguous storage."""


@dataclass(frozen=True, slots=True)
class TensorBufferInfo:
    """Dense tensor payload for Mojo: base pointer metadata plus strides / layout."""

    metadata: BufferMetadata
    strides: tuple[int, ...]
    itemsize: int
    c_contiguous: bool


@dataclass(frozen=True, slots=True)
class SparseMojoBuffers:
    """CSR/CSC arrays exposed as separate buffers (``data``, ``indices``, ``indptr``)."""

    data: TensorBufferInfo
    indices: TensorBufferInfo
    indptr: TensorBufferInfo
    shape: tuple[int, int]
    nnz: int
    format: Literal["csr", "csc"]


def _np_dtype_from_const() -> np.dtype[Any]:
    return np.dtype(const.default_array_dtype())


def _dtype_allowed(d: np.dtype[Any]) -> bool:
    return any(d == a for a in _ALLOWED_DTYPES)


def _normalize_dtype(dt: DTypeLike) -> np.dtype[Any]:
    d = np.dtype(dt)
    if not _dtype_allowed(d):
        msg = f"dtype {d!r} not in supported SIMD-oriented set {tuple(str(x) for x in _ALLOWED_DTYPES)}"
        raise TypeError(msg)
    return d


def _tensor_info_from_ndarray(arr: np.ndarray, *, require_c_contiguous: bool = True) -> TensorBufferInfo:
    a = arr if arr.flags.c_contiguous else np.ascontiguousarray(arr)
    if require_c_contiguous and not a.flags.c_contiguous:
        msg = "could not make array C-contiguous"
        raise NonContiguousArrayError(msg)
    meta = buffer_metadata(a)
    strides = tuple(int(s) for s in a.strides)
    return TensorBufferInfo(
        metadata=meta,
        strides=strides,
        itemsize=int(a.dtype.itemsize),
        c_contiguous=bool(a.flags.c_contiguous),
    )


def _telemetry(op: str, t0: float, **fields: Any) -> None:
    logger.info(
        "RiceArray op={} wall_ms={:.2f} {}",
        op,
        (time.perf_counter() - t0) * 1000,
        " ".join(f"{k}={v!r}" for k, v in fields.items()),
    )


class RiceArray:
    """High-performance dense view over ``numpy.ndarray`` (SIMD-oriented dtypes)."""

    __slots__ = ("_data",)

    @classmethod
    def _from_ndarray(cls, arr: NDArray[Any]) -> RiceArray:
        _normalize_dtype(arr.dtype)
        self = cls.__new__(cls)
        self._data = arr
        return self

    def __init__(
        self,
        data: ArrayLike,
        *,
        dtype: DTypeLike | None = None,
        order: Literal["K", "A", "C", "F"] = "K",
        copy: bool | None = None,
    ) -> None:
        t0 = time.perf_counter()
        base = data._data if isinstance(data, RiceArray) else data
        if dtype is None and not isinstance(base, np.ndarray):
            want = _np_dtype_from_const()
        elif dtype is not None:
            want = _normalize_dtype(dtype)
        else:
            want = None
        self._data = np.array(base, dtype=want, copy=copy, order=order)
        if want is not None and self._data.dtype != want:
            self._data = self._data.astype(want, copy=False)
        _normalize_dtype(self._data.dtype)
        nbytes = int(self._data.nbytes)
        logger.debug(
            "RiceArray alloc shape={} dtype={} nbytes={} c_contig={}",
            self._data.shape,
            self._data.dtype,
            nbytes,
            bool(self._data.flags.c_contiguous),
        )
        _telemetry("__init__", t0, shape=self._data.shape, dtype=str(self._data.dtype), nbytes=nbytes)

    @property
    def data(self) -> NDArray[Any]:
        return self._data

    @property
    def shape(self) -> tuple[int, ...]:
        return tuple(int(x) for x in self._data.shape)

    @property
    def dtype(self) -> np.dtype[Any]:
        return self._data.dtype

    @property
    def ndim(self) -> int:
        return int(self._data.ndim)

    @classmethod
    def from_pointer(
        cls,
        ptr: int,
        shape: tuple[int, ...],
        dtype: DTypeLike,
        *,
        readonly: bool = True,
        size_bytes: int | None = None,
    ) -> RiceArray:
        """Zero-copy view from a host address (caller owns lifetime / alignment)."""
        t0 = time.perf_counter()
        dt = _normalize_dtype(dtype)
        item = int(dt.itemsize)
        n = int(np.prod(shape, dtype=np.int64)) if shape else 0
        nbytes = item * int(n)
        if size_bytes is not None and int(size_bytes) != nbytes:
            msg = f"size_bytes {size_bytes} != computed {nbytes}"
            raise ValueError(msg)
        buf = (ctypes.c_byte * nbytes).from_address(ptr)
        arr = np.ndarray(shape, dtype=dt, buffer=memoryview(buf))
        arr.setflags(write=not readonly)
        out = cls._from_ndarray(arr)
        _telemetry("from_pointer", t0, shape=shape, dtype=str(dt), readonly=readonly)
        return out

    def shared_view(self) -> RiceArray:
        """Read-only alias safe to share across threads (same process, same storage)."""
        t0 = time.perf_counter()
        v = self._data.view()
        v.setflags(write=False)
        out = RiceArray._from_ndarray(v)
        _telemetry("shared_view", t0, shape=out.shape, readonly=True)
        return out

    def ensure_c_contiguous(self, *, copy: bool = True) -> RiceArray:
        """Return ``self`` if C-contiguous, else a contiguous copy (or raise if ``copy=False``)."""
        if self._data.flags.c_contiguous:
            return self
        if not copy:
            msg = "array is not C-contiguous and copy=False"
            raise NonContiguousArrayError(msg)
        return RiceArray._from_ndarray(np.ascontiguousarray(self._data))

    def as_buffer(self, *, require_c_contiguous: bool | None = None) -> TensorBufferInfo:
        """Mojo buffer view: :class:`BufferMetadata` plus strides and item size."""
        req = const.RICE_ARRAY_MOJO_REQUIRE_C_CONTIGUOUS if require_c_contiguous is None else require_c_contiguous
        if req and not self._data.flags.c_contiguous:
            msg = "RiceArray.as_buffer requires C-contiguous storage (use ensure_c_contiguous())"
            raise NonContiguousArrayError(msg)
        return _tensor_info_from_ndarray(self._data, require_c_contiguous=req)

    def reshape(self, *shape: int, order: Literal["C", "F", "A"] = "C") -> RiceArray:
        t0 = time.perf_counter()
        out = RiceArray._from_ndarray(self._data.reshape(shape, order=order))
        _telemetry("reshape", t0, shape=out.shape)
        return out

    def transpose(self, *axes: int) -> RiceArray:
        t0 = time.perf_counter()
        if not axes:
            arr = self._data.T if self._data.ndim == 2 else np.transpose(self._data)
        else:
            arr = np.transpose(self._data, axes=axes)
        out = RiceArray._from_ndarray(arr)
        _telemetry("transpose", t0, shape=out.shape)
        return out

    def dot(self, other: ArrayLike | RiceArray, *, use_mojo: bool = False) -> RiceArray:
        """Matrix/vector product; ``use_mojo`` probes :mod:`bridge` when ``RICE_MOJO_ARRAY_DOT_ENABLE`` is set."""
        t0 = time.perf_counter()
        b = other.data if isinstance(other, RiceArray) else np.asarray(other)
        if use_mojo and os.getenv("RICE_MOJO_ARRAY_DOT_ENABLE", "").lower() in {"1", "true", "yes"}:
            done = _try_mojo_dot(self, b)
            if done is not None:
                _telemetry("dot", t0, backend="mojo", shape=done.shape)
                return done
        out = RiceArray(np.asarray(np.dot(self._data, b)), copy=False)
        _telemetry("dot", t0, backend="numpy", shape=out.shape)
        return out

    def norm(self, ord: float | None = None, axis: int | tuple[int, ...] | None = None, keepdims: bool = False) -> Any:
        t0 = time.perf_counter()
        r = np.linalg.norm(self._data, ord=ord, axis=axis, keepdims=keepdims)
        _telemetry("norm", t0, axis=axis)
        return r

    def to_frame(self, *, columns: list[str] | None = None) -> RiceFrame:
        """Eager :class:`frame.RiceFrame` (2D columns or 1D as single column)."""
        t0 = time.perf_counter()
        a = np.ascontiguousarray(self._data)
        if a.ndim == 1:
            mat = a.reshape(-1, 1)
            cols = columns if columns is not None else ["v0"]
        elif a.ndim == 2:
            mat = a
            if columns is not None and len(columns) != mat.shape[1]:
                msg = "columns length must match width"
                raise ValueError(msg)
            cols = columns
        else:
            msg = "to_frame requires 1D or 2D array"
            raise ValueError(msg)
        frame = RiceFrame.from_numpy(mat, columns=cols)
        _telemetry("to_frame", t0, shape=mat.shape)
        return frame

    def __array__(self, dtype: DTypeLike | None = None) -> NDArray[Any]:
        if dtype is None:
            return self._data
        return self._data.astype(dtype, copy=False)

    def __repr__(self) -> str:
        return f"RiceArray(shape={self.shape}, dtype={self.dtype!s}, c_contiguous={self._data.flags.c_contiguous})"


def _try_mojo_dot(a: RiceArray, b: np.ndarray) -> RiceArray | None:
    """Reserved hook: load kernel name from const; execution needs a fixed ABI."""
    try:
        from .bridge import KernelNotFoundError, get_kernel
    except ImportError:
        return None
    try:
        get_kernel(
            const.RICE_MOJO_ARRAY_LIB,
            const.RICE_MOJO_ARRAY_DOT,
            n_buffers=2,
            restype=ctypes.c_int,
        )
    except KernelNotFoundError:
        logger.debug("Mojo dot kernel {} not found", const.RICE_MOJO_ARRAY_DOT)
        return None
    logger.info(
        "RICE_MOJO_ARRAY_DOT_ENABLE: kernel symbol present but execution ABI is not wired — using NumPy"
    )
    return None


def sparse_csr_to_mojo_buffers(A: sp.csr_matrix) -> SparseMojoBuffers:
    """Pack CSR components as :class:`TensorBufferInfo` triples for Mojo index kernels."""
    if not isinstance(A, sp.csr_matrix):
        msg = "expected scipy.sparse.csr_matrix"
        raise TypeError(msg)
    A.sort_indices()
    A.sum_duplicates()
    data = np.ascontiguousarray(A.data)
    indices = np.ascontiguousarray(A.indices)
    indptr = np.ascontiguousarray(A.indptr)
    return SparseMojoBuffers(
        data=_tensor_info_from_ndarray(data),
        indices=_tensor_info_from_ndarray(indices),
        indptr=_tensor_info_from_ndarray(indptr),
        shape=(int(A.shape[0]), int(A.shape[1])),
        nnz=int(A.nnz),
        format="csr",
    )


def sparse_csc_to_mojo_buffers(A: sp.csc_matrix) -> SparseMojoBuffers:
    if not isinstance(A, sp.csc_matrix):
        msg = "expected scipy.sparse.csc_matrix"
        raise TypeError(msg)
    A.sort_indices()
    A.sum_duplicates()
    data = np.ascontiguousarray(A.data)
    indices = np.ascontiguousarray(A.indices)
    indptr = np.ascontiguousarray(A.indptr)
    return SparseMojoBuffers(
        data=_tensor_info_from_ndarray(data),
        indices=_tensor_info_from_ndarray(indices),
        indptr=_tensor_info_from_ndarray(indptr),
        shape=(int(A.shape[0]), int(A.shape[1])),
        nnz=int(A.nnz),
        format="csc",
    )


@dataclass(slots=True)
class RiceSparse:
    """Thin wrapper around ``scipy.sparse`` CSR/CSC for conversion + telemetry."""

    matrix: sp.spmatrix

    def __post_init__(self) -> None:
        if not isinstance(self.matrix, (sp.csr_matrix, sp.csc_matrix)):
            msg = "RiceSparse only supports csr_matrix and csc_matrix"
            raise TypeError(msg)

    def to_mojo_buffers(self) -> SparseMojoBuffers:
        t0 = time.perf_counter()
        if isinstance(self.matrix, sp.csr_matrix):
            out = sparse_csr_to_mojo_buffers(self.matrix)
        else:
            out = sparse_csc_to_mojo_buffers(cast(sp.csc_matrix, self.matrix))
        _telemetry("RiceSparse.to_mojo_buffers", t0, nnz=out.nnz, fmt=out.format)
        return out

    def todense(self) -> RiceArray:
        return RiceArray(self.matrix.toarray(), order="C")


# --- Legacy helpers ---------------------------------------------------------


def as_float64(x: ArrayLike) -> NDArray[np.float64]:
    return np.asarray(x, dtype=np.float64)


def broadcast_add(a: NDArray[np.floating[Any]], b: NDArray[np.floating[Any]]) -> NDArray[np.floating[Any]]:
    return np.add(a, b)


def stack_axis0(*arrays: NDArray[Any]) -> NDArray[Any]:
    return np.stack(arrays, axis=0)


def reshape_fortran(x: NDArray[Any], *shape: int) -> NDArray[Any]:
    return np.reshape(x, shape, order="F")


def slice_columns(x: NDArray[Any], start: int, end: int) -> NDArray[Any]:
    return x[:, start:end]


def pad_constant(
    x: NDArray[Any],
    pad_width: tuple[tuple[int, int], ...] | int,
    *,
    constant_values: float = 0.0,
) -> NDArray[Any]:
    return np.pad(x, pad_width, mode="constant", constant_values=constant_values)


def einsum_subscript(subscripts: str, *operands: ArrayLike) -> Any:
    return np.einsum(subscripts, *operands)


def clip_range(x: NDArray[Any], low: float, high: float) -> NDArray[Any]:
    return np.clip(x, low, high)


__all__ = [
    "NonContiguousArrayError",
    "RiceArray",
    "RiceSparse",
    "SparseMojoBuffers",
    "TensorBufferInfo",
    "as_float64",
    "broadcast_add",
    "clip_range",
    "einsum_subscript",
    "pad_constant",
    "reshape_fortran",
    "slice_columns",
    "sparse_csc_to_mojo_buffers",
    "sparse_csr_to_mojo_buffers",
    "stack_axis0",
]
