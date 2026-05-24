"""Polars lifecycle + :class:`RiceFrame` — eager/lazy, Mojo buffers, schema, telemetry."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import ctypes
import time
from collections.abc import Iterator, Sequence
from dataclasses import dataclass, field, replace
from pathlib import Path
from typing import Any, Self

import numpy as np
import polars as pl
from loguru import logger

from . import const
from .memory import BufferMetadata, anchor, buffer_metadata


class SchemaValidationError(ValueError):
    """Raised when :meth:`RiceFrame.validate_schema` finds a mismatch."""


@dataclass(frozen=True, slots=True)
class HorizontalPartitionSpec:
    """Marker for orchestration (e.g. :mod:`parallel`) — partition keys + optional target count."""

    keys: tuple[str, ...]
    partitions: int | None = None


def _parse_dtype_name(s: str) -> pl.DataType:
    """Map a simple dtype label (``Float32``, ``Int64``, …) to a Polars dtype."""
    t = s.strip()
    if hasattr(pl, t):
        return getattr(pl, t)
    msg = f"unknown dtype name: {s!r}"
    raise ValueError(msg)


def _dtype_name(dt: pl.DataType) -> str:
    return str(dt).split("(")[0].rstrip("]")


def _is_mojo_numeric_name(name: str) -> bool:
    return name in const.RICE_FRAME_MOJO_ALLOWED_FLOATS or name in const.RICE_FRAME_MOJO_ALLOWED_INTEGERS


@dataclass(slots=True)
class RiceFrame:
    """Primary .rice table: wraps ``DataFrame`` or ``LazyFrame`` with a fluent API."""

    _inner: pl.DataFrame | pl.LazyFrame
    _partition: HorizontalPartitionSpec | None = None

    def __post_init__(self) -> None:
        if not isinstance(self._inner, (pl.DataFrame, pl.LazyFrame)):
            msg = "RiceFrame requires polars.DataFrame or polars.LazyFrame"
            raise TypeError(msg)

    @property
    def inner(self) -> pl.DataFrame | pl.LazyFrame:
        return self._inner

    @property
    def is_lazy(self) -> bool:
        return isinstance(self._inner, pl.LazyFrame)

    @property
    def partition_spec(self) -> HorizontalPartitionSpec | None:
        return self._partition

    @property
    def shape(self) -> tuple[int, int]:
        if isinstance(self._inner, pl.DataFrame):
            return (self._inner.height, self._inner.width)
        sch = self._inner.collect_schema()
        return (0, len(sch))

    def _telemetry(self, op: str, t0: float, **fields: Any) -> None:
        dt_ms = (time.perf_counter() - t0) * 1000
        logger.info(
            "RiceFrame op={} wall_ms={:.2f} shape={} lazy={} {}",
            op,
            dt_ms,
            self.shape,
            self.is_lazy,
            " ".join(f"{k}={v!r}" for k, v in fields.items()),
        )

    def estimated_memory_mb(self) -> float | None:
        """Eager: rough footprint; lazy: ``None`` until :meth:`compute`."""
        if isinstance(self._inner, pl.LazyFrame):
            return None
        df = self._inner
        try:
            b = df.estimated_size()
            return float(b) / (1024 * 1024)
        except Exception:
            pass
        try:
            return float(df.estimated_size("mb"))
        except Exception:
            return None

    # --- Fluent Polars -------------------------------------------------

    def select(self, *exprs: Any, **kwargs: Any) -> Self:
        return replace(self, _inner=self._inner.select(*exprs, **kwargs))

    def filter(self, *predicates: Any, **kwargs: Any) -> Self:
        return replace(self, _inner=self._inner.filter(*predicates, **kwargs))

    def sort(self, *args: Any, **kwargs: Any) -> Self:
        return replace(self, _inner=self._inner.sort(*args, **kwargs))

    def with_columns(self, *exprs: Any, **kwargs: Any) -> Self:
        return replace(self, _inner=self._inner.with_columns(*exprs, **kwargs))

    def join(
        self,
        other: RiceFrame | pl.DataFrame | pl.LazyFrame,
        on: str | Sequence[str] | None = None,
        how: str = "inner",
        **kwargs: Any,
    ) -> Self:
        t0 = time.perf_counter()
        right = other.inner if isinstance(other, RiceFrame) else other
        out = replace(self, _inner=self._inner.join(right, on=on, how=how, **kwargs))
        self._telemetry("join", t0, how=how, on=on, shape=out.shape)
        return out

    def group_by(self, *by: Any, **kwargs: Any) -> RiceGroupBy:
        return RiceGroupBy(self, by, dict(kwargs))

    # --- Materialization ------------------------------------------------

    def compute(self, *, streaming: bool | None = None) -> RiceFrame:
        """Run the Polars optimizer (lazy) or return a concrete eager frame."""
        t0 = time.perf_counter()
        if isinstance(self._inner, pl.LazyFrame):
            try:
                if streaming is not None:
                    df = self._inner.collect(streaming=streaming)
                else:
                    df = self._inner.collect()
            except TypeError:
                df = self._inner.collect()
            out = replace(self, _inner=df)
            self._telemetry("compute", t0, shape=out.shape, mem_est_mb=out.estimated_memory_mb())
            return out
        self._telemetry("compute", t0, shape=self.shape, mem_est_mb=self.estimated_memory_mb())
        return self

    def _eager(self) -> pl.DataFrame:
        if isinstance(self._inner, pl.LazyFrame):
            msg = "operation requires an eager frame — call compute() first"
            raise pl.exceptions.InvalidOperationError(msg)
        return self._inner

    def _schema(self) -> pl.Schema:
        if isinstance(self._inner, pl.LazyFrame):
            return self._inner.collect_schema()
        return self._inner.schema

    # --- Schema & casts -------------------------------------------------

    def validate_schema(
        self,
        expected: dict[str, pl.DataType] | None = None,
        *,
        strict_mojo: bool = False,
    ) -> Self:
        """Validate dtypes; ``strict_mojo`` uses :mod:`const` allowed numeric dtype names."""
        t0 = time.perf_counter()
        schema = self._schema()
        errs: list[str] = []

        exp = expected
        if exp is None and const.RICE_FRAME_DEFAULT_EXPECTED_SCHEMA:
            exp = {
                k: _parse_dtype_name(v) for k, v in const.RICE_FRAME_DEFAULT_EXPECTED_SCHEMA.items()
            }
        if exp:
            for col, want in exp.items():
                if col not in schema:
                    errs.append(f"missing column {col!r}")
                    continue
                got = schema[col]
                if got != want:
                    errs.append(f"column {col!r}: expected {want}, got {got}")

        if strict_mojo:
            for col in schema:
                dt = schema[col]
                name = _dtype_name(dt)
                if not _is_mojo_numeric_name(name):
                    errs.append(f"column {col!r}: dtype {name!r} not Mojo-numeric per const")

        if errs:
            raise SchemaValidationError("; ".join(errs))
        self._telemetry("validate_schema", t0, ok=True)
        return self

    def cast_optimized(self) -> Self:
        """Shrink Float64→Float32; Int64/UInt64→32-bit when value range allows."""
        t0 = time.perf_counter()
        inner = self._inner
        if isinstance(inner, pl.LazyFrame):
            inner = RiceFrame._cast_optimized_lazy(inner)
        else:
            inner = RiceFrame._cast_optimized_dataframe(inner)
        out = replace(self, _inner=inner)
        self._telemetry("cast_optimized", t0, shape=out.shape, mem_est_mb=out.estimated_memory_mb())
        return out

    @staticmethod
    def _cast_optimized_dataframe(df: pl.DataFrame) -> pl.DataFrame:
        casts: dict[str, pl.DataType] = {}
        for c in df.columns:
            dt = df[c].dtype
            if dt == pl.Float64:
                casts[c] = pl.Float32
            elif dt == pl.Int64:
                s = df[c]
                try:
                    if s.min() >= np.iinfo(np.int32).min and s.max() <= np.iinfo(np.int32).max:
                        casts[c] = pl.Int32
                except Exception:
                    pass
            elif dt == pl.UInt64:
                try:
                    if df[c].max() <= np.iinfo(np.uint32).max:
                        casts[c] = pl.UInt32
                except Exception:
                    pass
        return df.cast(casts) if casts else df

    @staticmethod
    def _cast_optimized_lazy(lf: pl.LazyFrame) -> pl.LazyFrame:
        sch = lf.collect_schema()
        exprs: list[pl.Expr] = []
        for name in sch:
            dt = sch[name]
            if dt == pl.Float64:
                exprs.append(pl.col(name).cast(pl.Float32, strict=False))
            else:
                exprs.append(pl.col(name))
        try:
            return lf.select(exprs)
        except Exception:
            return lf

    # --- Mojo / memory --------------------------------------------------

    def to_buffer(
        self,
        *,
        columns: Sequence[str] | None = None,
        anchor_columns: bool = True,
    ) -> list[tuple[str, BufferMetadata]]:
        """Per-column :class:`~memory.BufferMetadata` for Mojo (eager only).

        When ``anchor_columns`` is True, pins each ``pl.Series`` returned by
        ``get_column`` — call :func:`memory.release` on those same series objects after
        native work finishes (``MemoryAnchor`` is process-local; do not ship ``ptr`` to
        other processes).
        """
        t0 = time.perf_counter()
        df = self._eager()
        cols = list(columns) if columns is not None else df.columns
        out: list[tuple[str, BufferMetadata]] = []
        for c in cols:
            s = df.get_column(c)
            if anchor_columns:
                anchor(s)
            out.append((c, buffer_metadata(s)))
        self._telemetry("to_buffer", t0, columns=len(out), mem_est_mb=self.estimated_memory_mb())
        return out

    def sync_from_pointer(
        self,
        ptr: int,
        *,
        column: str,
        shape: tuple[int, ...],
        dtype: str | np.dtype[Any] | pl.DataType,
        size_bytes: int | None = None,
    ) -> RiceFrame:
        """Rebuild ``column`` from a raw address (kernel wrote in-place).

        **Unsafe:** ``ptr`` must remain valid and match ``shape`` / ``dtype``. Prefer
        keeping a single writable NumPy view and :meth:`from_numpy` / :meth:`with_columns`
        instead of raw pointers when possible.
        """
        t0 = time.perf_counter()
        df = self._eager()
        if isinstance(dtype, pl.DataType):
            dt = np.dtype(pl.Series("_", [0], dtype=dtype).to_numpy().dtype)
        elif isinstance(dtype, np.dtype):
            dt = dtype
        else:
            dt = np.dtype(dtype)
        item = int(np.dtype(dt).itemsize)
        n = int(np.prod(shape)) if shape else 0
        nbytes = item * n
        if size_bytes is not None and int(size_bytes) != nbytes:
            msg = f"size_bytes {size_bytes} != computed {nbytes}"
            raise ValueError(msg)
        buf = (ctypes.c_byte * nbytes).from_address(ptr)
        arr = np.ndarray(shape, dtype=dt, buffer=memoryview(buf))
        s = pl.Series(column, arr)
        new_df = df.with_columns(s)
        out = replace(self, _inner=new_df)
        self._telemetry("sync_from_pointer", t0, column=column, shape=shape)
        return out

    # --- BARD / scaling / NumPy ---------------------------------------

    def preview(self, n: int = 8, *, max_string: int = 64) -> dict[str, Any]:
        """Small structural sample for BARD (shape, schema, head rows, partition hint)."""
        sch = self._schema()
        dtypes = {name: str(sch[name]) for name in sch}
        sample: dict[str, Any] = {
            "shape": list(self.shape),
            "is_lazy": self.is_lazy,
            "dtypes": dtypes,
            "partition": {"keys": self._partition.keys, "partitions": self._partition.partitions}
            if self._partition
            else None,
            "estimated_memory_mb": self.estimated_memory_mb(),
        }
        if isinstance(self._inner, pl.DataFrame):
            h = min(n, self._inner.height)
            sample["head"] = self._inner.head(h).to_dicts()
        else:
            try:
                sample["head"] = self._inner.head(n).collect().to_dicts()
            except Exception:
                sample["head"] = []
        sample["max_string"] = max_string
        return sample

    def mark_horizontal_scale(
        self,
        keys: str | Sequence[str],
        *,
        partitions: int | None = None,
    ) -> RiceFrame:
        """Attach :class:`HorizontalPartitionSpec` for downstream parallel runners."""
        ks = (keys,) if isinstance(keys, str) else tuple(keys)
        spec = HorizontalPartitionSpec(keys=ks, partitions=partitions)
        return replace(self, _partition=spec)

    def to_numpy(self, **kwargs: Any) -> np.ndarray:
        """Eager matrix view — passes kwargs to :meth:`polars.DataFrame.to_numpy`."""
        return self._eager().to_numpy(**kwargs)

    @classmethod
    def from_numpy(cls, arr: np.ndarray, *, columns: list[str] | None = None) -> RiceFrame:
        """2D array → eager :class:`RiceFrame` (``array.py`` interop)."""
        a = np.ascontiguousarray(arr)
        if columns is not None:
            if a.ndim != 2 or len(columns) != a.shape[1]:
                msg = "columns length must match array width"
                raise ValueError(msg)
            df = pl.DataFrame(a, schema=columns)
        else:
            df = pl.DataFrame(a)
        return cls(df)

    @classmethod
    def from_polars(cls, obj: pl.DataFrame | pl.LazyFrame) -> RiceFrame:
        return cls(obj)

    def __repr__(self) -> str:
        kind = "lazy" if self.is_lazy else "eager"
        return f"RiceFrame({kind}, shape={self.shape}, partition={self._partition!r})"


@dataclass
class RiceGroupBy:
    """Fluent tail after :meth:`RiceFrame.group_by` — call :meth:`agg`."""

    _owner: RiceFrame
    _by: tuple[Any, ...]
    _kwargs: dict[str, Any] = field(default_factory=dict)

    def agg(self, *aggs: Any, **kwargs: Any) -> RiceFrame:
        t0 = time.perf_counter()
        inner = self._owner._inner
        gb = inner.group_by(*self._by, **self._kwargs)
        out = replace(self._owner, _inner=gb.agg(*aggs, **kwargs))
        self._owner._telemetry("group_by.agg", t0, shape=out.shape, mem_est_mb=out.estimated_memory_mb())
        return out


def as_rice(obj: pl.DataFrame | pl.LazyFrame | RiceFrame) -> RiceFrame:
    if isinstance(obj, RiceFrame):
        return obj
    return RiceFrame(obj)


# --- Legacy module API (unchanged call sites) -------------------------


def empty_frame(schema: dict[str, pl.DataType] | None = None) -> pl.DataFrame:
    """Pusty `DataFrame`, opcjonalnie ze schematem."""
    if schema:
        return pl.DataFrame(schema=schema)
    return pl.DataFrame()


def from_rows(rows: list[dict[str, Any]], *, infer_schema_length: int | None = 1000) -> pl.DataFrame:
    """Słowniki wierszy → DataFrame."""
    return pl.DataFrame(rows, infer_schema_length=infer_schema_length)


def scan_parquet_lazy(path: str | Path) -> pl.LazyFrame:
    """Skanowanie Parquet (lazy)."""
    return pl.scan_parquet(path)


def scan_csv_lazy(path: str | Path, **kwargs: Any) -> pl.LazyFrame:
    """Skanowanie CSV (lazy)."""
    return pl.scan_csv(path, **kwargs)


def scan_ndjson_lazy(path: str | Path, **kwargs: Any) -> pl.LazyFrame:
    """NDJSON / JSON lines (lazy)."""
    return pl.scan_ndjson(path, **kwargs)


def collect_lazy(lf: pl.LazyFrame, *, streaming: bool = False) -> pl.DataFrame:
    """Materializacja lazy frame (`streaming` gdy silnik wspiera)."""
    try:
        return lf.collect(streaming=streaming)
    except TypeError:
        return lf.collect()


def sink_parquet_lazy(lf: pl.LazyFrame, path: str | Path, **kwargs: Any) -> pl.DataFrame | None:
    """Zapis bez pełnego `collect` w pamięci (Polars ≥ 0.19). Zwraca None jeśli użyto wyłącznie sink."""
    sink = getattr(lf, "sink_parquet", None)
    if sink is None:
        collect_lazy(lf).write_parquet(path, **kwargs)
        return None
    sink(path, **kwargs)
    return None


def iter_batches(df: pl.DataFrame, batch_size: int) -> Iterator[pl.DataFrame]:
    """Strumieniowanie po kawałkach wierszy (eager)."""
    n = df.height
    for start in range(0, n, batch_size):
        yield df.slice(start, min(batch_size, n - start))


def concat_vertical(dfs: list[pl.DataFrame], *, rechunk: bool = True) -> pl.DataFrame:
    """Sklejanie wierszy."""
    return pl.concat(dfs, how="vertical", rechunk=rechunk)


__all__ = [
    "HorizontalPartitionSpec",
    "RiceFrame",
    "RiceGroupBy",
    "SchemaValidationError",
    "as_rice",
    "collect_lazy",
    "concat_vertical",
    "empty_frame",
    "from_rows",
    "iter_batches",
    "scan_csv_lazy",
    "scan_ndjson_lazy",
    "scan_parquet_lazy",
    "sink_parquet_lazy",
]
