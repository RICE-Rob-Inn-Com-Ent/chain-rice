"""Interpolation & smoothing — SciPy / NumPy core, optional Mojo offload via :mod:`bridge`.

Primary APIs return :class:`array.RiceArray` or :class:`frame.RiceFrame` for downstream chaining.
Legacy helpers (:func:`interp_1d_linear`, :func:`griddata_points`, :func:`rbf_interpolate`) remain
available; new names are preferred.
"""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import os
import time
from typing import Any, Literal, TypeAlias

import numpy as np
import polars as pl
from loguru import logger
from numpy.typing import NDArray
from scipy.interpolate import (
    CubicSpline,
    RBFInterpolator,
    RegularGridInterpolator,
    griddata,
    interp1d,
)

from . import const
from .array import RiceArray
from .frame import RiceFrame

FrameLike: TypeAlias = RiceFrame | pl.DataFrame | pl.LazyFrame

_MOJO_LIB = os.getenv("RICE_MOJO_INTERP_LIB", const.RICE_MOJO_ARRAY_LIB).strip() or const.RICE_MOJO_ARRAY_LIB
_MOJO_BATCH_SYM = os.getenv("RICE_MOJO_INTERP_BATCH_SYMBOL", "rice_interp_batch").strip() or "rice_interp_batch"


def _mojo_interp_enabled() -> bool:
    return os.getenv("RICE_MOJO_INTERP_ENABLE", "").strip().lower() in {"1", "true", "yes", "on"}


def _log_interp(
    op: str,
    t0: float,
    *,
    n_in: int | None = None,
    n_out: int | None = None,
    rms: float | None = None,
    backend: str = "scipy",
    extra: str = "",
) -> None:
    logger.info(
        "interpolate op={} wall_ms={:.2f} n_in={} n_out={} rms={} backend={} {}",
        op,
        (time.perf_counter() - t0) * 1000,
        n_in,
        n_out,
        rms,
        backend,
        extra,
    )


def _as_np(a: NDArray[Any] | RiceArray) -> NDArray[Any]:
    return a.data if isinstance(a, RiceArray) else np.asarray(a)


def _rice1d(arr: NDArray[Any]) -> RiceArray:
    return RiceArray(np.ascontiguousarray(arr, dtype=np.float64), copy=False)


def _eager_frame(data: FrameLike) -> pl.DataFrame:
    inner = data.inner if isinstance(data, RiceFrame) else data
    return inner.collect() if isinstance(inner, pl.LazyFrame) else inner


def _maybe_mojo_batch(points: NDArray[np.floating], values: NDArray[np.floating], queries: NDArray[np.floating]) -> None:
    """Reserved batch hook: loads ``RICE_MOJO_INTERP_BATCH_SYMBOL`` if present (ABI TBD)."""
    if not _mojo_interp_enabled():
        return
    try:
        from .bridge import KernelNotFoundError, get_kernel

        get_kernel(_MOJO_LIB, _MOJO_BATCH_SYM, n_buffers=3)
    except KernelNotFoundError:
        logger.debug("interpolate Mojo batch symbol {} not in {}", _MOJO_BATCH_SYM, _MOJO_LIB)
        return
    logger.info(
        "RICE_MOJO_INTERP_ENABLE: kernel {} present — execution ABI not wired; SciPy path used (n={})",
        _MOJO_BATCH_SYM,
        points.shape[0],
    )


def _sort_xy(
    x: NDArray[np.floating],
    y: NDArray[np.floating],
) -> tuple[NDArray[np.floating], NDArray[np.floating]]:
    x = np.asarray(x, dtype=np.float64).ravel()
    y = np.asarray(y, dtype=np.float64).ravel()
    if x.shape != y.shape:
        msg = "x and y must have the same shape"
        raise ValueError(msg)
    order = np.argsort(x)
    return x[order], y[order]


def _rms(y_true: NDArray[np.floating], y_hat: NDArray[np.floating]) -> float:
    d = np.asarray(y_true, dtype=np.float64).ravel() - np.asarray(y_hat, dtype=np.float64).ravel()
    return float(np.sqrt(np.mean(d * d))) if d.size else float("nan")


# --- 1D -----------------------------------------------------------------------------


def linear_interp(
    x: NDArray[np.floating] | RiceArray,
    y: NDArray[np.floating] | RiceArray,
    x_new: NDArray[np.floating] | RiceArray,
    *,
    y_ref: NDArray[np.floating] | RiceArray | None = None,
    x_ref: NDArray[np.floating] | RiceArray | None = None,
) -> RiceArray:
    """Piecewise linear interpolation (``np.interp`` on sorted knots)."""
    t0 = time.perf_counter()
    xs, ys = _sort_xy(_as_np(x), _as_np(y))
    xn = np.asarray(_as_np(x_new), dtype=np.float64).ravel()
    out = np.interp(xn, xs, ys)
    rms: float | None = None
    if y_ref is not None and x_ref is not None:
        rms = _rms(_as_np(y_ref), np.interp(np.asarray(_as_np(x_ref), dtype=np.float64).ravel(), xs, ys))
    _log_interp("linear_interp", t0, n_in=len(xs), n_out=len(xn), rms=rms, backend="numpy")
    return _rice1d(out)


def spline_interp(
    x: NDArray[np.floating] | RiceArray,
    y: NDArray[np.floating] | RiceArray,
    x_new: NDArray[np.floating] | RiceArray,
    *,
    kind: Literal["linear", "cubic", "quadratic", "cubic_legacy"] = "cubic",
    y_ref: NDArray[np.floating] | RiceArray | None = None,
    x_ref: NDArray[np.floating] | RiceArray | None = None,
) -> RiceArray:
    """Spline / piecewise polynomial via :class:`scipy.interpolate.CubicSpline` or ``interp1d``."""
    t0 = time.perf_counter()
    xs, ys = _sort_xy(_as_np(x), _as_np(y))
    xn = np.asarray(_as_np(x_new), dtype=np.float64).ravel()
    if kind == "cubic" and len(xs) >= 4:
        cs = CubicSpline(xs, ys, extrapolate=True)
        out = cs(xn)
        backend = "CubicSpline"
    elif kind == "cubic_legacy":
        f = interp1d(xs, ys, kind="cubic", bounds_error=False, fill_value="extrapolate")
        out = np.asarray(f(xn), dtype=np.float64)
        backend = "interp1d"
    else:
        k = "linear" if kind == "cubic" and len(xs) < 4 else kind
        f = interp1d(xs, ys, kind=k, bounds_error=False, fill_value="extrapolate")
        out = np.asarray(f(xn), dtype=np.float64)
        backend = "interp1d"
    rms: float | None = None
    if y_ref is not None and x_ref is not None:
        xr = np.asarray(_as_np(x_ref), dtype=np.float64).ravel()
        if kind == "cubic" and len(xs) >= 4:
            hat = CubicSpline(xs, ys, extrapolate=True)(xr)
        else:
            kk = "cubic" if kind == "cubic_legacy" else ("linear" if kind == "cubic" and len(xs) < 4 else kind)
            hat = np.asarray(interp1d(xs, ys, kind=kk, bounds_error=False, fill_value="extrapolate")(xr), dtype=np.float64)
        rms = _rms(_as_np(y_ref), hat)
    _log_interp("spline_interp", t0, n_in=len(xs), n_out=len(xn), rms=rms, backend=backend, extra=f"kind={kind!r}")
    return _rice1d(out)


# --- Grid / ND ----------------------------------------------------------------------


def grid_interp(
    points: NDArray[np.floating] | RiceArray,
    values: NDArray[np.floating] | RiceArray,
    query_points: NDArray[np.floating] | RiceArray,
    *,
    method: Literal["linear", "nearest", "cubic"] = "linear",
    structured: bool = False,
    grid_axes: tuple[NDArray[np.floating] | RiceArray, ...] | None = None,
) -> RiceArray:
    """Unstructured ``(n, d)`` samples via :func:`scipy.interpolate.griddata`, or structured *d*-D grid.

    When ``structured=True``, pass ``grid_axes`` as a tuple of 1-D monotone coordinates
    (lengths matching ``values`` shape); ``values`` is a dense ``(n1, n2, …)`` tensor and
    ``query_points`` is ``(m, d)``.
    """
    t0 = time.perf_counter()
    vals = np.asarray(_as_np(values), dtype=np.float64)
    q = np.asarray(_as_np(query_points), dtype=np.float64)
    if q.ndim != 2:
        msg = "query_points must be 2-D (m, d)"
        raise ValueError(msg)
    pts: NDArray[np.floating]
    if structured:
        if grid_axes is None:
            msg = "structured=True requires grid_axes"
            raise ValueError(msg)
        axes = [np.asarray(_as_np(ax), dtype=np.float64).ravel() for ax in grid_axes]
        if len(axes) != vals.ndim:
            msg = "values.ndim must match len(grid_axes)"
            raise ValueError(msg)
        rgi = RegularGridInterpolator(axes, vals, method=method, bounds_error=False, fill_value=np.nan)
        out = np.asarray(rgi(q), dtype=np.float64)
        pts = np.zeros((1, q.shape[1]), dtype=np.float64)
    else:
        pts = np.asarray(_as_np(points), dtype=np.float64)
        if pts.ndim != 2 or pts.shape[0] != vals.size:
            msg = "points must be (n, d) and values length n"
            raise ValueError(msg)
        out = griddata(pts, vals.ravel(), q, method=method)
        if np.any(np.isnan(out)):
            logger.warning("grid_interp: NaN in output (hull / method); check query locations")
    _maybe_mojo_batch(pts, vals.ravel(), q)
    _log_interp("grid_interp", t0, n_in=int(vals.size), n_out=len(out), backend="scipy", extra=f"method={method!r}")
    return _rice1d(out)


# --- Alignment / RBF / refinements ----------------------------------------------------


def align_series(
    frame_a: FrameLike,
    frame_b: FrameLike,
    *,
    time_col: str,
    prefix_a: str = "a__",
    prefix_b: str = "b__",
) -> RiceFrame:
    """Linearly interpolate both frames onto the sorted union of ``time_col`` values."""
    t0 = time.perf_counter()
    da = _eager_frame(frame_a)
    db = _eager_frame(frame_b)
    if time_col not in da.columns or time_col not in db.columns:
        msg = f"time_col {time_col!r} must exist in both frames"
        raise KeyError(msg)
    ta = np.asarray(da[time_col].to_numpy(), dtype=np.float64)
    tb = np.asarray(db[time_col].to_numpy(), dtype=np.float64)
    t_common = np.sort(np.unique(np.concatenate([ta, tb])))
    cols_a = [c for c in da.columns if c != time_col and da[c].dtype.is_numeric()]
    cols_b = [c for c in db.columns if c != time_col and db[c].dtype.is_numeric()]
    out: dict[str, Any] = {time_col: t_common}
    for c in cols_a:
        ya = np.asarray(da[c].to_numpy(), dtype=np.float64)
        oa = np.argsort(ta)
        out[prefix_a + c] = np.interp(t_common, ta[oa], ya[oa])
    for c in cols_b:
        yb = np.asarray(db[c].to_numpy(), dtype=np.float64)
        ob = np.argsort(tb)
        out[prefix_b + c] = np.interp(t_common, tb[ob], yb[ob])
    pdf = pl.DataFrame(out)
    part = frame_a.partition_spec if isinstance(frame_a, RiceFrame) else None
    if isinstance(frame_b, RiceFrame) and part is None:
        part = frame_b.partition_spec
    rf = RiceFrame(pdf, part)
    _log_interp("align_series", t0, n_in=len(ta) + len(tb), n_out=len(t_common), backend="polars", extra=time_col)
    return rf


def extrapolate(
    x: NDArray[np.floating] | RiceArray,
    y: NDArray[np.floating] | RiceArray,
    x_new: NDArray[np.floating] | RiceArray,
    *,
    mode: Literal["clip_domain", "linear_trend", "constant"] = "clip_domain",
    margin: float = 0.0,
    fill_outside: tuple[float, float] | None = None,
) -> RiceArray:
    """Controlled behaviour outside ``[min(x), max(x)]``: clip domain, edge constant, or linear trend."""
    t0 = time.perf_counter()
    xs, ys = _sort_xy(_as_np(x), _as_np(y))
    xn = np.asarray(_as_np(x_new), dtype=np.float64).ravel()
    lo, hi = float(xs[0]), float(xs[-1])
    if mode == "clip_domain":
        xc = np.clip(xn, lo, hi)
        out = np.interp(xc, xs, ys)
    elif mode == "constant":
        out = np.interp(np.clip(xn, lo, hi), xs, ys)
        fv_lo, fv_hi = (fill_outside if fill_outside is not None else (float(ys[0]), float(ys[-1])))
        out = np.where(xn < lo, fv_lo, np.where(xn > hi, fv_hi, out))
    else:
        if len(xs) < 2:
            msg = "linear_trend needs at least two samples"
            raise ValueError(msg)
        left_slope = (ys[1] - ys[0]) / (xs[1] - xs[0] + 1e-15)
        right_slope = (ys[-1] - ys[-2]) / (xs[-1] - xs[-2] + 1e-15)
        core = np.interp(np.clip(xn, lo, hi), xs, ys)
        out = np.where(
            xn < lo,
            ys[0] + left_slope * (xn - lo) * (1.0 / (1.0 + margin * np.abs(xn - lo))),
            np.where(
                xn > hi,
                ys[-1] + right_slope * (xn - hi) * (1.0 / (1.0 + margin * np.abs(xn - hi))),
                core,
            ),
        )
    yb_lo, yb_hi = float(np.min(ys)), float(np.max(ys))
    out = np.clip(out, yb_lo - abs(margin), yb_hi + abs(margin))
    _log_interp("extrapolate", t0, n_in=len(xs), n_out=len(xn), backend="numpy", extra=f"mode={mode!r}")
    return _rice1d(out)


def missing_data_filler(
    frame: RiceFrame,
    *,
    time_col: str,
    columns: list[str] | None = None,
    method: Literal["linear"] = "linear",
) -> RiceFrame:
    """Fill NaNs in numeric ``columns`` using ``time_col`` as the independent axis (eager Polars)."""
    t0 = time.perf_counter()
    pdf = _eager_frame(frame)
    if time_col not in pdf.columns:
        msg = f"time_col {time_col!r} not found"
        raise KeyError(msg)
    cols = columns or [c for c in pdf.columns if c != time_col and pdf[c].dtype.is_numeric()]
    t = pdf[time_col].to_numpy()
    out_pdf = pdf
    for c in cols:
        s = pdf[c].to_numpy()
        if not np.any(np.isnan(s)):
            continue
        valid = ~np.isnan(s)
        if np.sum(valid) < 2:
            logger.warning("missing_data_filler: column {} has <2 finite points", c)
            continue
        tv, yv = t[valid], s[valid]
        order = np.argsort(tv)
        tv, yv = tv[order], yv[order]
        s_new = np.where(np.isnan(s), np.interp(t, tv, yv), s)
        out_pdf = out_pdf.with_columns(pl.Series(c, s_new))
    _log_interp("missing_data_filler", t0, n_in=pdf.height, n_out=out_pdf.height, backend="polars", extra=method)
    return RiceFrame(out_pdf, frame.partition_spec)


def rbf_interp(
    points: NDArray[np.floating] | RiceArray,
    values: NDArray[np.floating] | RiceArray,
    query_points: NDArray[np.floating] | RiceArray,
    *,
    kernel: str = "thin_plate_spline",
    epsilon: float | None = None,
    smoothing: float = 0.0,
) -> RiceArray:
    """Fit :class:`scipy.interpolate.RBFInterpolator` and evaluate at ``query_points``."""
    t0 = time.perf_counter()
    pts = np.asarray(_as_np(points), dtype=np.float64)
    vals = np.asarray(_as_np(values), dtype=np.float64).ravel()
    q = np.asarray(_as_np(query_points), dtype=np.float64)
    if pts.ndim != 2 or pts.shape[0] != vals.size:
        msg = "points must be (n, d) matching len(values)"
        raise ValueError(msg)
    _maybe_mojo_batch(pts, vals, q)
    rbf = RBFInterpolator(pts, vals, kernel=kernel, epsilon=epsilon, smoothing=smoothing)
    pred = np.asarray(rbf(q), dtype=np.float64)
    rms = _rms(vals, rbf(pts))
    _log_interp("rbf_interp", t0, n_in=pts.shape[0], n_out=q.shape[0], rms=rms, backend="scipy", extra=f"kernel={kernel!r}")
    return _rice1d(pred)


# --- Legacy -------------------------------------------------------------------------


def interp_1d_linear(
    x: NDArray[np.floating],
    y: NDArray[np.floating],
    xnew: NDArray[np.floating],
) -> RiceArray:
    """Backward-compatible name for :func:`linear_interp`."""
    return linear_interp(x, y, xnew)


def griddata_points(
    points: NDArray[np.floating],
    values: NDArray[np.floating],
    xi: tuple[NDArray[np.floating], ...] | NDArray[np.floating],
    *,
    method: str = "linear",
) -> RiceArray:
    """Legacy ``griddata`` wrapper — ``xi`` as mesh tuple is stacked to ``(m, d)`` queries."""
    if isinstance(xi, tuple):
        grids = np.meshgrid(*xi, indexing="ij")
        q = np.stack([g.ravel() for g in grids], axis=1)
    else:
        q = np.asarray(xi, dtype=np.float64)
        if q.ndim == 1:
            q = q.reshape(-1, 1)
    return grid_interp(points, values, q, method=method)  # type: ignore[arg-type]


def rbf_interpolate(
    points: NDArray[np.floating],
    values: NDArray[np.floating],
    *,
    kernel: str = "thin_plate_spline",
    epsilon: float | None = None,
) -> RBFInterpolator:
    """Return a callable :class:`scipy.interpolate.RBFInterpolator` (no query evaluation)."""
    pts = np.asarray(points, dtype=np.float64)
    vals = np.asarray(values, dtype=np.float64)
    return RBFInterpolator(pts, vals.ravel(), kernel=kernel, epsilon=epsilon)


__all__ = [
    "align_series",
    "extrapolate",
    "grid_interp",
    "griddata_points",
    "interp_1d_linear",
    "linear_interp",
    "missing_data_filler",
    "rbf_interp",
    "rbf_interpolate",
    "spline_interp",
]
