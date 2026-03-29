"""NumPy — ndarray: operacje, broadcasting, indeksowanie, stack, reshape."""

from __future__ import annotations

from typing import Any

import numpy as np
from numpy.typing import ArrayLike, NDArray

# TODO:
# [ ] implement numpy array factory with dtype control:
# [ ]     dtype from RICE_DEFAULT_DTYPE env var (default: float32 for GPU compat)
# [ ] implement memory-mapped arrays: np.memmap for large datasets
# [ ]     path from RICE_ARRAY_CACHE_DIR env var
# [ ] implement structured arrays for mixed-type data
# [ ] implement array validation: shape, dtype, NaN/Inf check
# [ ] implement chunked array processing:
# [ ]     chunk_size from RICE_CHUNK_SIZE env var
# [ ]     yield chunks as generator — never load all into memory
# [ ] implement array serialization: npy, npz, Arrow, msgpack


def as_float64(x: ArrayLike) -> NDArray[np.float64]:
    return np.asarray(x, dtype=np.float64)


def broadcast_add(a: NDArray[np.floating], b: NDArray[np.floating]) -> NDArray[np.floating]:
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
