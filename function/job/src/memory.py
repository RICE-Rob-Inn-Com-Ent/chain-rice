"""Zero-copy pointer extraction and lifetime anchoring for Mojo / SIMD kernels.

Hot paths (`get_raw_address`, `check_alignment`, `is_contiguous`) avoid logging,
copying, and optional heavy imports where possible.
"""

from __future__ import annotations

import ctypes
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Any, Generator

from loguru import logger

# --- Optional Arrow (Polars Series/DataFrame native path) -----------------------------
try:  # pragma: no cover - import surface
    import pyarrow as pa
except ImportError:  # pragma: no cover
    pa = None  # type: ignore[assignment]

try:  # pragma: no cover
    import polars as pl
except ImportError:  # pragma: no cover
    pl = None  # type: ignore[assignment]

try:  # pragma: no cover
    import numpy as np
except ImportError:  # pragma: no cover
    np = None  # type: ignore[assignment]


@dataclass(frozen=True, slots=True)
class BufferMetadata:
    """Immutable view of a host buffer handed to native code."""

    ptr: int
    size: int
    dtype: str
    shape: tuple[int, ...]


def as_c_void_p(ptr: int) -> ctypes.c_void_p:
    """Wrap a raw integer address as ``ctypes.c_void_p`` (no copy)."""
    return ctypes.c_void_p(ptr)


def as_c_array_ptr(ptr: int, length: int, item_type: Any) -> Any:
    """Reinterpret ``ptr`` as a length-``length`` array of ``item_type`` (zero-copy view)."""
    return (item_type * length).from_address(ptr)


def check_alignment(address: int, alignment: int = 64) -> bool:
    """Return True if ``address`` is a multiple of ``alignment`` (e.g. 64 for AVX-512 cache lines)."""
    return alignment > 0 and (address % alignment) == 0


def _numpy_interface_ptr(obj: Any) -> int:
    iface = getattr(obj, "__array_interface__", None)
    if not isinstance(iface, dict):
        msg = "object has no __array_interface__"
        raise TypeError(msg)
    data = iface.get("data")
    if not isinstance(data, (tuple, list)) or len(data) < 1:
        msg = "__array_interface__['data'] missing or invalid"
        raise TypeError(msg)
    ptr = int(data[0])
    if ptr < 0:
        msg = "negative pointer from __array_interface__"
        raise ValueError(msg)
    return ptr


def _memoryview_ptr(mv: memoryview) -> int:
    if mv.ndim > 1 and not mv.contiguous:
        msg = "non-contiguous memoryview cannot expose a single base address"
        raise ValueError(msg)
    try:
        return int(ctypes.addressof(ctypes.c_char.from_buffer(mv)))
    except TypeError as e:
        msg = (
            "cannot take zero-copy address of read-only memoryview with ctypes; "
            "anchor the source object and use a writable view or NumPy array"
        )
        raise TypeError(msg) from e


def _arrow_chunk_values_ptr(chunk: Any) -> int:
    """Base byte address of primitive fixed-width values (Arrow C layout)."""
    bufs = chunk.buffers()
    if not bufs:
        msg = "Arrow chunk has no buffers"
        raise ValueError(msg)
    # [0] optional validity bitmap; [1] values for fixed-width numeric types
    data_buf = bufs[1] if len(bufs) > 1 and bufs[1] is not None else bufs[0]
    if data_buf is None:
        msg = "Arrow values buffer is None"
        raise ValueError(msg)
    try:
        elem = chunk.type.bit_width // 8
    except Exception:
        elem = 1
    off = int(getattr(chunk, "offset", 0))
    return int(data_buf.address) + off * elem


def get_raw_address(obj: Any) -> int:
    """Return the first host byte address for ``obj``'s primary payload (zero-copy).

    Supported:

    - ``numpy.ndarray`` — ``__array_interface__`` (data pointer).
    - ``memoryview`` / buffer protocol — ``memoryview`` then ``ctypes`` address
      (writable buffers only for ``memoryview``).
    - ``polars.Series`` / ``polars.DataFrame`` — Arrow values buffer via PyArrow
      when installed; otherwise a zero-copy NumPy view when Polars allows it.
    """
    # NumPy ndarray (and objects exposing array interface with tuple data)
    if np is not None and isinstance(obj, np.ndarray):
        return _numpy_interface_ptr(obj)
    iface = getattr(obj, "__array_interface__", None)
    if isinstance(iface, dict) and isinstance(iface.get("data"), (tuple, list)):
        return _numpy_interface_ptr(obj)

    if isinstance(obj, memoryview):
        return _memoryview_ptr(obj)

    # Generic buffer protocol
    try:
        mv = memoryview(obj)
    except TypeError:
        mv = None
    if mv is not None:
        try:
            return _memoryview_ptr(mv)
        finally:
            mv.release()

    if pl is not None:
        if isinstance(obj, pl.Series):
            return _polars_series_ptr(obj)
        if isinstance(obj, pl.DataFrame):
            if obj.width == 0:
                msg = "empty DataFrame has no buffer address"
                raise ValueError(msg)
            return _polars_series_ptr(obj.to_series(0))

    msg = f"unsupported type for get_raw_address: {type(obj).__name__}"
    raise TypeError(msg)


def _polars_series_ptr(s: Any) -> int:
    if pa is not None:
        arr = s.to_arrow()
        chunk = arr.chunk(0) if isinstance(arr, pa.ChunkedArray) else arr
        return _arrow_chunk_values_ptr(chunk)
    if np is None:
        msg = "NumPy required when PyArrow is not installed for Polars pointer extraction"
        raise ImportError(msg)
    arr = s.to_numpy(writable=False)
    return _numpy_interface_ptr(arr)


def is_contiguous(obj: Any) -> bool:
    """True if ``obj`` is laid out as a single C-contiguous slab usable by strided kernels."""
    if np is not None and isinstance(obj, np.ndarray):
        return bool(obj.flags.c_contiguous)

    if isinstance(obj, memoryview):
        return bool(obj.c_contiguous)

    iface = getattr(obj, "__array_interface__", None)
    if isinstance(iface, dict):
        strides = iface.get("strides")
        shape = iface.get("shape")
        if strides is None:
            return True
        if not shape:
            return True
        itemsize = int(iface.get("typestr", "|O")[2:] or 1) if len(str(iface.get("typestr", ""))) > 2 else 1
        # Best-effort: compare to C-contiguous strides
        if np is not None:
            try:
                dtype = np.dtype(iface.get("typestr", "|O"))
                itemsize = int(dtype.itemsize)
            except Exception:
                pass
        nd = len(shape)
        exp = itemsize
        for dim in reversed(shape):
            if dim == 0:
                return True
            if strides[nd - 1] != exp:
                return False
            exp *= int(dim)
        return True

    if pl is not None:
        if isinstance(obj, pl.Series):
            if pa is not None:
                arr = obj.to_arrow()
                if isinstance(arr, pa.ChunkedArray):
                    if len(arr.chunks) != 1:
                        return False
                    chunk = arr.chunk(0)
                    return int(chunk.offset) == 0
                chunk = arr
                return int(chunk.offset) == 0
            if np is not None:
                try:
                    a = obj.to_numpy(writable=False)
                except Exception:
                    return False
                return bool(a.flags.c_contiguous)
            return False
        if isinstance(obj, pl.DataFrame):
            if obj.width <= 1:
                return is_contiguous(obj.to_series(0)) if obj.width == 1 else True
            # Columnar multi-column: not one C-contiguous tensor
            return False

    try:
        mv = memoryview(obj)
    except TypeError:
        return False
    try:
        return bool(mv.c_contiguous)
    finally:
        mv.release()


def _canonical_dtype_str(obj: Any) -> str:
    if np is not None and isinstance(obj, np.ndarray):
        return str(obj.dtype)
    iface = getattr(obj, "__array_interface__", None)
    if isinstance(iface, dict) and "typestr" in iface:
        return str(iface["typestr"])
    if isinstance(obj, memoryview):
        return obj.format
    if pl is not None:
        if isinstance(obj, pl.Series):
            return str(obj.dtype)
        if isinstance(obj, pl.DataFrame):
            return "dataframe"
    return "unknown"


def _shape_tuple(obj: Any) -> tuple[int, ...]:
    if np is not None and isinstance(obj, np.ndarray):
        return tuple(int(x) for x in obj.shape)
    iface = getattr(obj, "__array_interface__", None)
    if isinstance(iface, dict) and iface.get("shape") is not None:
        return tuple(int(x) for x in iface["shape"])
    if isinstance(obj, memoryview):
        return tuple(int(x) for x in obj.shape)
    if pl is not None:
        if isinstance(obj, pl.Series):
            return (int(len(obj)),)
        if isinstance(obj, pl.DataFrame):
            return (int(obj.height), int(obj.width))
    return ()


def _buffer_size_bytes(obj: Any) -> int:
    if np is not None and isinstance(obj, np.ndarray):
        return int(obj.nbytes)
    iface = getattr(obj, "__array_interface__", None)
    if isinstance(iface, dict):
        shape = iface.get("shape") or ()
        typestr = iface.get("typestr", "|O")
        item = 8
        if isinstance(typestr, str) and len(typestr) >= 3 and typestr[1] in ("=", "<", ">", "|"):
            if np is not None:
                try:
                    item = int(np.dtype(typestr).itemsize)
                except Exception:
                    item = 8
        n = 1
        for dim in shape:
            n *= int(dim)
        return n * item
    if isinstance(obj, memoryview):
        return int(obj.nbytes)
    if pl is not None:
        if isinstance(obj, pl.Series):
            dt = obj.dtype
            item = getattr(dt, "item_size", None)
            if callable(item):
                try:
                    ib = int(item())
                    if ib > 0:
                        return int(len(obj)) * ib
                except Exception:
                    pass
            if np is not None:
                return int(obj.to_numpy(writable=False).nbytes)
            return int(len(obj)) * 8
        if isinstance(obj, pl.DataFrame):
            return sum(_buffer_size_bytes(obj[col]) for col in obj.columns)
    return 0


def buffer_metadata(obj: Any) -> BufferMetadata:
    """Build :class:`BufferMetadata` for ``obj`` (uses :func:`get_raw_address`; no copy)."""
    ptr = get_raw_address(obj)
    return BufferMetadata(
        ptr=ptr,
        size=_buffer_size_bytes(obj),
        dtype=_canonical_dtype_str(obj),
        shape=_shape_tuple(obj),
    )


class MemoryAnchor:
    """Pin Python objects so backing storage stays alive across native calls.

    A :class:`weakref.WeakValueDictionary` cannot pin its *values* (values are held
    weakly), so this registry uses a plain ``dict[int, Any]`` keyed by ``id(obj)``
    plus a refcount so nested :func:`shared_buffer` / paired :func:`anchor` calls
    stay balanced. When the last :func:`release` runs, the object becomes eligible
    for GC again.
    """

    _pinned: dict[int, Any] = {}
    _refcount: dict[int, int] = {}

    @classmethod
    def anchor(cls, obj: Any) -> None:
        key = id(obj)
        n = cls._refcount.get(key, 0) + 1
        cls._refcount[key] = n
        if n == 1:
            cls._pinned[key] = obj

    @classmethod
    def release(cls, obj: Any) -> None:
        key = id(obj)
        c = cls._refcount.get(key, 0)
        if c <= 1:
            cls._refcount.pop(key, None)
            cls._pinned.pop(key, None)
        else:
            cls._refcount[key] = c - 1


def anchor(obj: Any) -> None:
    """Pin ``obj`` so its buffers cannot be collected until :func:`release`."""
    MemoryAnchor.anchor(obj)


def release(obj: Any) -> None:
    """Release one pin acquired by :func:`anchor` (refcounted)."""
    MemoryAnchor.release(obj)


@contextmanager
def shared_buffer(obj: Any) -> Generator[BufferMetadata, None, None]:
    """Context manager: pin ``obj``, yield :class:`BufferMetadata`, then unpin.

    Logs pointer and 64-byte alignment at DEBUG (not on the inner hot path of
    :func:`get_raw_address`).
    """
    MemoryAnchor.anchor(obj)
    try:
        meta = buffer_metadata(obj)
        aligned = check_alignment(meta.ptr, 64)
        logger.debug(
            "shared_buffer ptr={ptr:#x} size={size} dtype={dtype} shape={shape} aligned_64={al}",
            ptr=meta.ptr,
            size=meta.size,
            dtype=meta.dtype,
            shape=meta.shape,
            al=aligned,
        )
        yield meta
    finally:
        MemoryAnchor.release(obj)


__all__ = [
    "BufferMetadata",
    "MemoryAnchor",
    "anchor",
    "as_c_array_ptr",
    "as_c_void_p",
    "buffer_metadata",
    "check_alignment",
    "get_raw_address",
    "is_contiguous",
    "release",
    "shared_buffer",
]
