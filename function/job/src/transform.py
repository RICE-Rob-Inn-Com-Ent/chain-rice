"""Data transforms for :class:`frame.RiceFrame` / Polars — scaling, encoding, structure, optional Mojo."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import time
from collections.abc import Callable, Sequence
from typing import Any

import numpy as np
import polars as pl
from loguru import logger

from . import const
from .array import RiceArray
from .frame import HorizontalPartitionSpec, RiceFrame

FrameLike = RiceFrame | pl.DataFrame | pl.LazyFrame
ArrayLike = RiceArray | np.ndarray


def _inner(data: FrameLike) -> pl.DataFrame | pl.LazyFrame:
    return data.inner if isinstance(data, RiceFrame) else data


def _rice(inner: pl.DataFrame | pl.LazyFrame, *, partition: HorizontalPartitionSpec | None = None) -> RiceFrame:
    return RiceFrame(inner, partition=partition)


def _eager_df(data: FrameLike) -> pl.DataFrame:
    inner = _inner(data)
    if isinstance(inner, pl.LazyFrame):
        return inner.collect()
    return inner


def _preserve_partition(data: FrameLike) -> HorizontalPartitionSpec | None:
    return data.partition_spec if isinstance(data, RiceFrame) else None


def _log_transform(name: str, t0: float, *, rows: int | None = None, cols: int | None = None, extra: str = "") -> None:
    logger.info(
        "transform name={} wall_ms={:.2f} rows={} cols={} {}",
        name,
        (time.perf_counter() - t0) * 1000,
        rows,
        cols,
        extra,
    )


def _infer_numeric_columns(inner: pl.DataFrame | pl.LazyFrame) -> list[str]:
    sch = inner.collect_schema() if isinstance(inner, pl.LazyFrame) else inner.schema
    out: list[str] = []
    for name in sch:
        if sch[name].is_numeric():
            out.append(name)
    return out


# --- Scaling -----------------------------------------------------------------


def min_max_scale(
    data: FrameLike | ArrayLike,
    columns: Sequence[str] | None = None,
    *,
    feature_range: tuple[float, float] = (0.0, 1.0),
) -> FrameLike | ArrayLike:
    """Per-column min–max to ``feature_range`` (vectorized Polars or NumPy)."""
    t0 = time.perf_counter()
    lo, hi = feature_range
    if isinstance(data, RiceArray) or isinstance(data, np.ndarray):
        a = data.data if isinstance(data, RiceArray) else np.asarray(data, dtype=np.float64)
        amin, amax = np.nanmin(a), np.nanmax(a)
        span = amax - amin
        if span == 0 or not np.isfinite(span):
            out = np.full_like(a, lo, dtype=np.float64)
        else:
            out = (a.astype(np.float64) - amin) / span * (hi - lo) + lo
        ra = RiceArray(out) if isinstance(data, RiceArray) else out
        _log_transform("min_max_scale", t0, extra=f"array_shape={getattr(out, 'shape', ())}")
        return ra
    inner = _inner(data)
    cols = list(columns) if columns is not None else _infer_numeric_columns(inner)
    exprs: list[pl.Expr] = []
    for c in cols:
        mn = pl.col(c).min()
        mx = pl.col(c).max()
        span = mx - mn
        scaled = pl.when(span == 0).then(lo).otherwise((pl.col(c) - mn) / span * (hi - lo) + lo)
        exprs.append(scaled.alias(c))
    out_inner = inner.with_columns(exprs)
    part = _preserve_partition(data) if isinstance(data, RiceFrame) else None
    rf = _rice(out_inner, partition=part)
    _log_transform(
        "min_max_scale",
        t0,
        rows=rf.shape[0] if not rf.is_lazy else None,
        cols=len(cols),
    )
    return rf if isinstance(data, RiceFrame) else out_inner


def standardize(
    data: FrameLike | ArrayLike,
    columns: Sequence[str] | None = None,
) -> FrameLike | ArrayLike:
    """Z-score per column (lazy-safe global mean/std in Polars)."""
    t0 = time.perf_counter()
    if isinstance(data, RiceArray) or isinstance(data, np.ndarray):
        a = data.data if isinstance(data, RiceArray) else np.asarray(data, dtype=np.float64)
        m, s = float(np.nanmean(a)), float(np.nanstd(a))
        if s == 0 or not np.isfinite(s):
            out = np.zeros_like(a, dtype=np.float64)
        else:
            out = (a.astype(np.float64) - m) / s
        ra = RiceArray(out) if isinstance(data, RiceArray) else out
        _log_transform("standardize", t0, extra=f"array_shape={out.shape}")
        return ra
    inner = _inner(data)
    cols = list(columns) if columns is not None else _infer_numeric_columns(inner)
    exprs: list[pl.Expr] = []
    for c in cols:
        mu = pl.col(c).mean()
        sd = pl.col(c).std()
        exprs.append(pl.when(sd == 0).then(0.0).otherwise((pl.col(c) - mu) / sd).alias(c))
    out_inner = inner.with_columns(exprs)
    part = _preserve_partition(data) if isinstance(data, RiceFrame) else None
    rf = _rice(out_inner, partition=part)
    _log_transform("standardize", t0, cols=len(cols))
    return rf if isinstance(data, RiceFrame) else out_inner


def robust_scale(
    data: FrameLike | ArrayLike,
    columns: Sequence[str] | None = None,
    *,
    quantile_range: tuple[float, float] = (0.25, 0.75),
) -> FrameLike | ArrayLike:
    """Robust scaler: subtract median, divide by IQR (vectorized)."""
    t0 = time.perf_counter()
    q_lo, q_hi = quantile_range
    if isinstance(data, RiceArray) or isinstance(data, np.ndarray):
        a = data.data if isinstance(data, RiceArray) else np.asarray(data, dtype=np.float64)
        med = float(np.nanmedian(a))
        ql = float(np.nanquantile(a, q_lo))
        qh = float(np.nanquantile(a, q_hi))
        iqr = qh - ql
        if iqr == 0 or not np.isfinite(iqr):
            out = (a.astype(np.float64) - med)
        else:
            out = (a.astype(np.float64) - med) / iqr
        ra = RiceArray(out) if isinstance(data, RiceArray) else out
        _log_transform("robust_scale", t0, extra=f"array_shape={out.shape}")
        return ra
    inner = _inner(data)
    cols = list(columns) if columns is not None else _infer_numeric_columns(inner)
    exprs: list[pl.Expr] = []
    for c in cols:
        med = pl.col(c).median()
        ql = pl.col(c).quantile(q_lo)
        qh = pl.col(c).quantile(q_hi)
        iqr = qh - ql
        exprs.append(pl.when(iqr == 0).then(pl.col(c) - med).otherwise((pl.col(c) - med) / iqr).alias(c))
    out_inner = inner.with_columns(exprs)
    part = _preserve_partition(data) if isinstance(data, RiceFrame) else None
    rf = _rice(out_inner, partition=part)
    _log_transform("robust_scale", t0, cols=len(cols))
    return rf if isinstance(data, RiceFrame) else out_inner


# --- Mojo bridge -------------------------------------------------------------


def apply_custom(
    data: FrameLike,
    column: str,
    kernel_name: str,
    *,
    lib_name: str | None = None,
    n_buffers: int = 1,
) -> RiceFrame:
    """Run a Mojo kernel in-place on one numeric column (anchors host memory via :mod:`memory`).

    Requires a kernel ABI compatible with :func:`bridge.execute_kernel` (buffer + optional scalars).
    On failure, returns the frame unchanged and logs at WARNING.
    """
    t0 = time.perf_counter()
    from .bridge import KernelNotFoundError, execute_kernel, get_kernel
    from .memory import anchor, release

    df = _eager_df(data)
    if column not in df.columns:
        msg = f"column {column!r} not found"
        raise KeyError(msg)
    s = df.get_column(column)
    arr = s.to_numpy(writable=True, copy=True)
    arr = np.ascontiguousarray(arr)
    anchor(arr)
    try:
        lib = lib_name or const.RICE_MOJO_ARRAY_LIB
        fn = get_kernel(lib, kernel_name, n_buffers=n_buffers, restype=__import__("ctypes").c_int)
        execute_kernel(fn, arr)
    except KernelNotFoundError:
        logger.warning("apply_custom: kernel {} not found in {}", kernel_name, lib_name or const.RICE_MOJO_ARRAY_LIB)
        return _rice(df.lazy() if isinstance(_inner(data), pl.LazyFrame) else df, partition=_preserve_partition(data))
    except Exception:
        logger.exception("apply_custom: kernel {} failed", kernel_name)
        return _rice(df.lazy() if isinstance(_inner(data), pl.LazyFrame) else df, partition=_preserve_partition(data))
    finally:
        release(arr)
    new_df = df.with_columns(pl.Series(column, arr))
    out = new_df.lazy() if isinstance(_inner(data), pl.LazyFrame) else new_df
    _log_transform("apply_custom", t0, cols=df.width, extra=f"kernel={kernel_name}")
    return _rice(out, partition=_preserve_partition(data))


# --- Structure --------------------------------------------------------------


def pivot_table(df: pl.DataFrame | RiceFrame, **kwargs: Any) -> pl.DataFrame | RiceFrame:
    """Pivot — passes kwargs to :meth:`polars.DataFrame.pivot`."""
    t0 = time.perf_counter()
    base = df if isinstance(df, pl.DataFrame) else _eager_df(df)
    out = base.pivot(**kwargs)
    _log_transform("pivot_table", t0, rows=out.height, cols=out.width)
    return RiceFrame(out) if isinstance(df, RiceFrame) else out


def melt(df: pl.DataFrame | RiceFrame, **kwargs: Any) -> pl.DataFrame | RiceFrame:
    """Long format — wraps :meth:`polars.DataFrame.unpivot` / ``melt`` alias."""
    t0 = time.perf_counter()
    base = df if isinstance(df, pl.DataFrame) else _eager_df(df)
    out = base.unpivot(**kwargs)
    _log_transform("melt", t0, rows=out.height, cols=out.width)
    return RiceFrame(out) if isinstance(df, RiceFrame) else out


def explode(df: pl.DataFrame | RiceFrame, columns: str | Sequence[str], **kwargs: Any) -> pl.DataFrame | RiceFrame:
    """Explode list columns."""
    t0 = time.perf_counter()
    base = df if isinstance(df, pl.DataFrame) else _eager_df(df)
    out = base.explode(columns, **kwargs)
    _log_transform("explode", t0, rows=out.height, cols=out.width)
    return RiceFrame(out) if isinstance(df, RiceFrame) else out


def cast_types(data: FrameLike, schema_map: dict[str, pl.DataType]) -> RiceFrame | pl.DataFrame | pl.LazyFrame:
    """Batch-cast columns (Polars ``cast``)."""
    t0 = time.perf_counter()
    inner = _inner(data)
    out_inner = inner.cast(schema_map)
    _log_transform("cast_types", t0, cols=len(schema_map))
    if isinstance(data, RiceFrame):
        return _rice(out_inner, partition=_preserve_partition(data))
    return out_inner


# --- Vectorized encoding ------------------------------------------------------


def discretize(
    data: FrameLike,
    column: str,
    bins: list[float] | int,
    *,
    labels: list[str] | None = None,
) -> RiceFrame | pl.DataFrame | pl.LazyFrame:
    """Bin continuous ``column`` using :meth:`polars.Expr.cut` / bin edges.

    When ``labels`` is set, length must equal the number of intervals (``len(edges) - 1`` for
    numeric edges, or ``bins`` when ``bins`` is an integer bin count).
    """
    t0 = time.perf_counter()
    inner = _inner(data)
    if isinstance(bins, int):
        base = inner.collect() if isinstance(inner, pl.LazyFrame) else inner
        lo, hi = float(base[column].min()), float(base[column].max())
        if not np.isfinite(lo) or not np.isfinite(hi) or hi <= lo:
            edges = [lo, hi]
        else:
            edges = list(np.linspace(lo, hi, int(bins) + 1))
        n_intervals = max(len(edges) - 1, 1)
        if labels is not None and len(labels) == n_intervals:
            cut_expr = pl.col(column).cut(edges, labels=list(labels))
        elif labels is not None:
            logger.warning(
                "discretize: labels length {} != n_intervals {}; omitting labels",
                len(labels),
                n_intervals,
            )
            cut_expr = pl.col(column).cut(edges)
        else:
            cut_expr = pl.col(column).cut(edges)
    else:
        n_intervals = max(len(bins) - 1, 1)
        if labels is not None and len(labels) == n_intervals:
            cut_expr = pl.col(column).cut(bins, labels=list(labels))
        elif labels is not None:
            logger.warning(
                "discretize: labels length {} != n_intervals {}; omitting labels",
                len(labels),
                n_intervals,
            )
            cut_expr = pl.col(column).cut(bins)
        else:
            cut_expr = pl.col(column).cut(bins)
    out_inner = inner.with_columns(cut_expr.alias(f"{column}_bin"))
    part = _preserve_partition(data) if isinstance(data, RiceFrame) else None
    rf = _rice(out_inner, partition=part)
    _log_transform("discretize", t0, extra=f"col={column}")
    return rf if isinstance(data, RiceFrame) else out_inner


def one_hot_encode(data: FrameLike, columns: Sequence[str]) -> RiceFrame | pl.DataFrame | pl.LazyFrame:
    """Dummy columns for categoricals / discrete values (Polars ``to_dummies``)."""
    t0 = time.perf_counter()
    inner = _inner(data)
    if isinstance(inner, pl.LazyFrame):
        inner = inner.collect()
    cols = list(columns)
    try:
        out_df = inner.to_dummies(columns=cols)  # type: ignore[attr-defined]
    except AttributeError:
        dummies = [inner.select(pl.col(c).to_dummies()) for c in cols]
        out_df = inner.drop(cols)
        for d in dummies:
            out_df = out_df.hstack(d)
    part = _preserve_partition(data) if isinstance(data, RiceFrame) else None
    want_lazy = isinstance(_inner(data), pl.LazyFrame)
    out_inner = out_df.lazy() if want_lazy else out_df
    rf = _rice(out_inner, partition=part)
    _log_transform("one_hot_encode", t0, cols=len(cols), extra=f"out_width={out_df.width}")
    return rf if isinstance(data, RiceFrame) else out_inner


# --- Parallel partitions ------------------------------------------------------


def transform_partitions(
    data: RiceFrame,
    transform_fn: Callable[[pl.DataFrame], pl.DataFrame],
    *,
    parallel: bool = True,
) -> RiceFrame:
    """Apply ``transform_fn`` per physical partition when :attr:`RiceFrame.partition_spec` is set.

    Otherwise applies once on the whole (collected) frame. Uses :mod:`parallel` thread pool
    when ``parallel`` and multiple partitions exist.
    """
    t0 = time.perf_counter()
    spec = data.partition_spec
    df = _eager_df(data)
    if spec is None or not spec.keys:
        out = transform_fn(df)
        _log_transform("transform_partitions", t0, rows=out.height, extra="single_block")
        return _rice(out.lazy() if data.is_lazy else out, partition=None)

    parts = df.partition_by(list(spec.keys))
    if not parallel or len(parts) <= 1:
        merged = pl.concat([transform_fn(p) for p in parts], how="vertical")
        _log_transform("transform_partitions", t0, rows=merged.height, extra=f"n_parts={len(parts)} seq")
        return _rice(merged.lazy() if data.is_lazy else merged, partition=spec)

    from .parallel import default_executor

    ex = default_executor().thread_pool
    merged = pl.concat(list(ex.map(transform_fn, parts)), how="vertical")
    _log_transform("transform_partitions", t0, rows=merged.height, extra=f"n_parts={len(parts)} threads")
    return _rice(merged.lazy() if data.is_lazy else merged, partition=spec)


# --- Refinements -------------------------------------------------------------


def drop_nulls_adaptive(
    data: FrameLike,
    *,
    null_ratio_drop: float = 0.9,
    fill_numeric: bool = True,
) -> RiceFrame | pl.DataFrame | pl.LazyFrame:
    """Drop columns with null ratio ≥ ``null_ratio_drop``; fill remaining nulls on numeric columns."""
    t0 = time.perf_counter()
    df = _eager_df(data)
    n = max(df.height, 1)
    nc = df.null_count()
    drop_cols = [c for c in df.columns if int(nc[c][0]) / n >= null_ratio_drop]
    out = df.drop(drop_cols) if drop_cols else df
    if fill_numeric:
        exprs = []
        for c in out.columns:
            if out[c].dtype.is_numeric():
                exprs.append(pl.col(c).fill_null(pl.col(c).mean()))
        if exprs:
            out = out.with_columns(exprs)
    out_inner = out.lazy() if isinstance(_inner(data), pl.LazyFrame) else out
    part = _preserve_partition(data) if isinstance(data, RiceFrame) else None
    rf = _rice(out_inner, partition=part)
    _log_transform("drop_nulls_adaptive", t0, rows=out.height, extra=f"dropped={drop_cols!r}")
    return rf if isinstance(data, RiceFrame) else out_inner


def feature_cross(
    data: FrameLike,
    col_a: str,
    col_b: str,
    *,
    out_name: str | None = None,
    use_mojo: bool = False,
) -> RiceFrame | pl.DataFrame | pl.LazyFrame:
    """Interaction term ``col_a * col_b`` (numeric) or concatenation for strings."""
    t0 = time.perf_counter()
    inner = _inner(data)
    name = out_name or f"{col_a}_x_{col_b}"
    sch = inner.collect_schema() if isinstance(inner, pl.LazyFrame) else inner.schema
    da, db = sch[col_a], sch[col_b]  # type: ignore[index]
    if da.is_numeric() and db.is_numeric():
        expr = (pl.col(col_a) * pl.col(col_b)).alias(name)
    else:
        expr = (pl.col(col_a).cast(pl.Utf8) + pl.lit("_") + pl.col(col_b).cast(pl.Utf8)).alias(name)
    out_inner = inner.with_columns(expr)
    if use_mojo:
        logger.info("feature_cross use_mojo=True reserved — Polars expr used")
    part = _preserve_partition(data) if isinstance(data, RiceFrame) else None
    rf = _rice(out_inner, partition=part)
    _log_transform("feature_cross", t0, extra=name)
    return rf if isinstance(data, RiceFrame) else out_inner


# --- Legacy (Polars DataFrame / LazyFrame) ------------------------------------


def select_columns(df: pl.DataFrame | pl.LazyFrame, *cols: str) -> pl.DataFrame | pl.LazyFrame:
    return df.select(cols)


def filter_by_expr(df: pl.DataFrame | pl.LazyFrame, *predicates: pl.Expr) -> pl.DataFrame | pl.LazyFrame:
    """Filtr przez jedno lub więcej wyrażeń (`pl.col('a') > 0`)."""
    return df.filter(*predicates)


def group_agg(
    df: pl.DataFrame | pl.LazyFrame,
    by: str | list[str],
    aggs: list[pl.Expr],
) -> pl.DataFrame | pl.LazyFrame:
    return df.group_by(by).agg(aggs)


def join_inner(
    left: pl.DataFrame | pl.LazyFrame,
    right: pl.DataFrame | pl.LazyFrame,
    on: str | list[str],
    *,
    suffix: str = "_right",
) -> pl.DataFrame | pl.LazyFrame:
    return left.join(right, on=on, how="inner", suffix=suffix)


def join_left(
    left: pl.DataFrame | pl.LazyFrame,
    right: pl.DataFrame | pl.LazyFrame,
    on: str | list[str],
    *,
    suffix: str = "_right",
) -> pl.DataFrame | pl.LazyFrame:
    return left.join(right, on=on, how="left", suffix=suffix)


def melt_unpivot(df: pl.DataFrame, **kwargs: object) -> pl.DataFrame:
    """Długi format — przekaż argumenty zgodnie z `DataFrame.unpivot` w Twojej wersji Polars."""
    return df.unpivot(**kwargs)


def with_derived(df: pl.DataFrame | pl.LazyFrame, *exprs: pl.Expr) -> pl.DataFrame | pl.LazyFrame:
    return df.with_columns(exprs)


def sort_by(
    df: pl.DataFrame | pl.LazyFrame,
    *by: str | pl.Expr,
    descending: bool | list[bool] = False,
) -> pl.DataFrame | pl.LazyFrame:
    return df.sort(by, descending=descending)


__all__ = [
    "apply_custom",
    "cast_types",
    "discretize",
    "drop_nulls_adaptive",
    "explode",
    "feature_cross",
    "filter_by_expr",
    "group_agg",
    "join_inner",
    "join_left",
    "melt",
    "melt_unpivot",
    "min_max_scale",
    "one_hot_encode",
    "pivot_table",
    "robust_scale",
    "select_columns",
    "sort_by",
    "standardize",
    "transform_partitions",
    "with_derived",
]
