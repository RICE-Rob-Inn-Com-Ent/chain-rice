"""Descriptive stats, inference, distributions — Polars (lazy where possible) + SciPy."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import time
from collections.abc import Sequence
from typing import Any, Literal, TypeAlias, cast

import numpy as np
import polars as pl
from loguru import logger
from numpy.typing import NDArray
from scipy import stats

from .array import RiceArray
from .frame import RiceFrame

FrameLike: TypeAlias = RiceFrame | pl.DataFrame | pl.LazyFrame
ArrayLike: TypeAlias = RiceArray | NDArray[Any]
HypothesisResult: TypeAlias = Any  # scipy ``_`` result objects or dict


def _log_stats(name: str, t0: float, *, rows: int | None = None, cols: int | None = None, extra: str = "") -> None:
    logger.info(
        "stats op={} wall_ms={:.2f} rows={} cols={} {}",
        name,
        (time.perf_counter() - t0) * 1000,
        rows,
        cols,
        extra,
    )


def _rice(inner: pl.DataFrame | pl.LazyFrame, *, like: FrameLike | None) -> RiceFrame | pl.DataFrame | pl.LazyFrame:
    if isinstance(like, RiceFrame):
        return RiceFrame(inner, partition=like.partition_spec)
    return inner


def _to_lazy_frame(data: FrameLike | ArrayLike) -> pl.LazyFrame:
    if isinstance(data, RiceFrame):
        inner = data.inner
        return inner.lazy() if isinstance(inner, pl.DataFrame) else inner
    if isinstance(data, pl.DataFrame):
        return data.lazy()
    if isinstance(data, pl.LazyFrame):
        return data
    if isinstance(data, RiceArray):
        a = data.data
        if a.ndim == 1:
            return pl.DataFrame({"v0": a}).lazy()
        return pl.DataFrame(a).lazy()
    arr = np.asarray(data)
    if arr.ndim == 1:
        return pl.DataFrame({"v0": arr}).lazy()
    return pl.DataFrame(arr).lazy()


def _numeric_columns(lf: pl.LazyFrame) -> list[str]:
    sch = lf.collect_schema()
    return [n for n in sch if sch[n].is_numeric()]


def _eager_numeric(data: FrameLike | ArrayLike) -> pl.DataFrame:
    lf = _to_lazy_frame(data)
    cols = _numeric_columns(lf)
    if not cols:
        msg = "no numeric columns for correlation / matrix operation"
        raise ValueError(msg)
    return lf.select(cols).collect()


# --- Descriptive ---------------------------------------------------------------------


def summary(
    data: FrameLike | ArrayLike,
    *,
    columns: Sequence[str] | None = None,
    eager: bool = False,
) -> pl.DataFrame | pl.LazyFrame | RiceFrame:
    """Per-column mean, median, std, variance, skewness, kurtosis (Polars; lazy by default)."""
    t0 = time.perf_counter()
    lf = _to_lazy_frame(data)
    cols = list(columns) if columns is not None else _numeric_columns(lf)
    if not cols:
        msg = "summary requires at least one numeric column"
        raise ValueError(msg)
    lf = lf.select(cols)
    parts: list[pl.Expr] = []
    for c in cols:
        parts.extend(
            [
                pl.col(c).mean().alias(f"{c}__mean"),
                pl.col(c).median().alias(f"{c}__median"),
                pl.col(c).std().alias(f"{c}__std"),
                pl.col(c).var().alias(f"{c}__var"),
                pl.col(c).skew().alias(f"{c}__skew"),
                pl.col(c).kurtosis().alias(f"{c}__kurtosis"),
            ]
        )
    out = lf.select(parts)
    _log_stats("summary", t0, cols=len(cols), extra="lazy" if not eager else "eager")
    if eager:
        mat = out.collect()
        return _rice(mat, like=data if isinstance(data, RiceFrame) else None)
    return _rice(out, like=data if isinstance(data, RiceFrame) else None)


def quantile_analysis(
    data: FrameLike | ArrayLike,
    *,
    columns: Sequence[str] | None = None,
    quantiles: Sequence[float] = (0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99),
    eager: bool = False,
) -> pl.DataFrame | pl.LazyFrame | RiceFrame:
    """Percentiles plus IQR (Q3 − Q1) per numeric column for outlier screening."""
    t0 = time.perf_counter()
    lf = _to_lazy_frame(data)
    cols = list(columns) if columns is not None else _numeric_columns(lf)
    if not cols:
        msg = "quantile_analysis requires at least one numeric column"
        raise ValueError(msg)
    lf = lf.select(cols)
    exprs: list[pl.Expr] = []
    for c in cols:
        for q in quantiles:
            exprs.append(pl.col(c).quantile(q).alias(f"{c}__q_{q}"))
        q1 = pl.col(c).quantile(0.25)
        q3 = pl.col(c).quantile(0.75)
        exprs.append((q3 - q1).alias(f"{c}__iqr"))
    out = lf.select(exprs)
    _log_stats("quantile_analysis", t0, cols=len(cols), extra=f"n_q={len(quantiles)}")
    if eager:
        return _rice(out.collect(), like=data if isinstance(data, RiceFrame) else None)
    return _rice(out, like=data if isinstance(data, RiceFrame) else None)


# --- Hypothesis testing --------------------------------------------------------------


def t_test(
    a: NDArray[Any] | RiceArray | pl.Series,
    b: NDArray[Any] | RiceArray | pl.Series,
    *,
    paired: bool = False,
    equal_var: bool = True,
    alternative: Literal["two-sided", "less", "greater"] = "two-sided",
) -> HypothesisResult:
    """Two-sample or paired *t*-test (SciPy)."""
    t0 = time.perf_counter()
    aa = a.to_numpy() if isinstance(a, pl.Series) else (a.data if isinstance(a, RiceArray) else np.asarray(a))
    bb = b.to_numpy() if isinstance(b, pl.Series) else (b.data if isinstance(b, RiceArray) else np.asarray(b))
    aa = np.asarray(aa, dtype=np.float64).ravel()
    bb = np.asarray(bb, dtype=np.float64).ravel()
    if paired:
        res = stats.ttest_rel(aa, bb, alternative=alternative)
    else:
        res = stats.ttest_ind(aa, bb, equal_var=equal_var, alternative=alternative)
    _log_stats(
        "t_test",
        t0,
        rows=len(aa),
        extra=f"paired={paired} pvalue={getattr(res, 'pvalue', float('nan'))!r}",
    )
    return res


def chi2_contingency(table: NDArray[Any] | RiceArray, **kwargs: Any) -> tuple[Any, ...]:
    obs = table.data if isinstance(table, RiceArray) else np.asarray(table)
    return stats.chi2_contingency(obs, **kwargs)


def chi_square(table: NDArray[Any] | RiceArray, **kwargs: Any) -> tuple[Any, ...]:
    """Chi-square test of independence on a contingency ``table`` (logs via :func:`_log_stats`)."""
    t0 = time.perf_counter()
    out = chi2_contingency(table, **kwargs)
    _log_stats("chi_square", t0, extra=f"statistic={out[0]!r} pvalue={out[1]!r}")
    return out


def anova(*groups: NDArray[Any] | RiceArray) -> HypothesisResult:
    """One-way ANOVA (:func:`scipy.stats.f_oneway`) across numeric groups."""
    t0 = time.perf_counter()
    arrs = [(g.data if isinstance(g, RiceArray) else np.asarray(g, dtype=np.float64)) for g in groups]
    res = stats.f_oneway(*arrs)
    _log_stats("anova", t0, extra=f"ngroups={len(groups)} pvalue={getattr(res, 'pvalue', float('nan'))!r}")
    return res


def p_value_check(result: HypothesisResult, *, alpha: float = 0.05) -> dict[str, Any]:
    """Return significance flag from a SciPy result object, mapping, or ``(stat, p)`` tuple."""
    p: float | None = None
    if hasattr(result, "pvalue"):
        p = float(cast(Any, result).pvalue)
    elif isinstance(result, dict) and "pvalue" in result:
        p = float(result["pvalue"])
    elif isinstance(result, (tuple, list)) and len(result) >= 2:
        p = float(result[1])
    if p is None or not np.isfinite(p):
        msg = "could not extract p-value from result"
        raise TypeError(msg)
    sig = bool(p < alpha)
    out = {"significant": sig, "pvalue": p, "alpha": alpha}
    logger.info("stats p_value_check significant={} pvalue={} alpha={}", sig, p, alpha)
    return out


# --- Distributions -------------------------------------------------------------------


_DIST_ALIASES: dict[str, type[Any]] = {
    "norm": stats.norm,
    "normal": stats.norm,
    "poisson": stats.poisson,
    "lognorm": stats.lognorm,
    "lognormal": stats.lognorm,
    "expon": stats.expon,
    "exponential": stats.expon,
    "gamma": stats.gamma,
    "beta": stats.beta,
    "uniform": stats.uniform,
}


def fit_distribution(
    data: NDArray[Any] | RiceArray | pl.Series,
    dist_name: str,
    *,
    floc: float | None = None,
    fscale: float | None = None,
) -> tuple[Any, tuple[float, ...]]:
    """MLE fit via SciPy ``fit``; ``dist_name`` is one of ``norm``, ``poisson``, ``lognorm``, …"""
    t0 = time.perf_counter()
    x = data.to_numpy() if isinstance(data, pl.Series) else (data.data if isinstance(data, RiceArray) else np.asarray(data))
    x = np.asarray(x, dtype=np.float64).ravel()
    key = dist_name.strip().lower()
    if key not in _DIST_ALIASES:
        msg = f"unknown dist_name {dist_name!r}; allowed: {sorted(_DIST_ALIASES)!r}"
        raise ValueError(msg)
    dist = _DIST_ALIASES[key]
    params = dist.fit(x, floc=floc, fscale=fscale)
    _log_stats("fit_distribution", t0, rows=len(x), extra=f"dist={dist_name!r}")
    return dist, params


def sampling(
    dist: str,
    params: Sequence[float] | dict[str, float],
    n: int,
    *,
    random_state: int | np.random.Generator | None = None,
) -> NDArray[np.floating]:
    """Draw ``n`` samples from a named SciPy distribution (``params`` as shape/loc/scale order per dist)."""
    t0 = time.perf_counter()
    if n < 0:
        msg = "n must be non-negative"
        raise ValueError(msg)
    key = dist.strip().lower()
    if key not in _DIST_ALIASES:
        msg = f"unknown dist {dist!r}"
        raise ValueError(msg)
    d = _DIST_ALIASES[key]
    rng = np.random.default_rng(random_state) if random_state is not None else None
    if isinstance(params, dict):
        kw = {k: float(v) for k, v in params.items()}
        samples = d.rvs(size=n, random_state=rng, **kw)
    else:
        samples = d.rvs(size=n, random_state=rng, *map(float, params))
    arr = np.asarray(samples, dtype=np.float64)
    _log_stats("sampling", t0, rows=n, extra=f"dist={dist!r}")
    return cast(NDArray[np.floating], arr)


# --- Correlation & rolling -----------------------------------------------------------


def correlation_matrix(
    data: FrameLike | ArrayLike,
    *,
    method: Literal["pearson", "spearman", "kendall"] = "pearson",
) -> pl.DataFrame:
    """Full numeric correlation matrix (Polars ``corr`` when available; else SciPy / NumPy)."""
    t0 = time.perf_counter()
    df = _eager_numeric(data)
    cols = df.columns
    try:
        out = df.corr(method=method)
        _log_stats("correlation_matrix", t0, rows=out.height, cols=out.width, extra=f"method={method!r} polars")
        return out
    except (TypeError, ValueError, AttributeError):
        mat = df.to_numpy()
        if method == "pearson":
            c = np.corrcoef(mat, rowvar=False)
            c = np.nan_to_num(c, nan=0.0)
        elif method == "spearman":
            c, _ = stats.spearmanr(mat, nan_policy="omit")
            c = np.asarray(c, dtype=np.float64)
            if c.ndim == 0:
                c = np.array([[1.0]])
        else:
            n = mat.shape[1]
            c = np.eye(n, dtype=np.float64)
            for i in range(n):
                for j in range(i + 1, n):
                    tau, _ = stats.kendalltau(mat[:, i], mat[:, j], nan_policy="omit")
                    c[i, j] = c[j, i] = float(tau) if np.isfinite(tau) else 0.0
        out = pl.DataFrame(c, schema=cols)
        _log_stats("correlation_matrix", t0, rows=out.height, cols=out.width, extra=f"method={method!r} scipy")
        return out


def rolling_stats(
    data: FrameLike | ArrayLike,
    window: int,
    *,
    columns: Sequence[str] | None = None,
    volatility: bool = True,
    eager: bool = False,
) -> pl.DataFrame | pl.LazyFrame | RiceFrame:
    """Rolling mean per numeric column; optional rolling std as ``{col}__roll_vol``."""
    t0 = time.perf_counter()
    if window < 1:
        msg = "window must be >= 1"
        raise ValueError(msg)
    lf = _to_lazy_frame(data)
    cols = list(columns) if columns is not None else _numeric_columns(lf)
    if not cols:
        msg = "rolling_stats requires numeric columns"
        raise ValueError(msg)
    exprs: list[pl.Expr] = []
    for c in cols:
        exprs.append(pl.col(c).rolling_mean(window).alias(f"{c}__roll_mean"))
        if volatility:
            exprs.append(pl.col(c).rolling_std(window).alias(f"{c}__roll_vol"))
    out = lf.with_columns(exprs)
    _log_stats("rolling_stats", t0, cols=len(cols), extra=f"w={window}")
    if eager:
        return _rice(out.collect(), like=data if isinstance(data, RiceFrame) else None)
    return _rice(out, like=data if isinstance(data, RiceFrame) else None)


# --- Refinements ---------------------------------------------------------------------


def z_score_normalization(
    data: FrameLike | ArrayLike,
    *,
    columns: Sequence[str] | None = None,
    eager: bool = False,
) -> pl.DataFrame | pl.LazyFrame | RiceFrame:
    """Per-column z-score using global mean/std (Polars; lazy by default)."""
    t0 = time.perf_counter()
    lf = _to_lazy_frame(data)
    cols = list(columns) if columns is not None else _numeric_columns(lf)
    if not cols:
        msg = "z_score_normalization requires numeric columns"
        raise ValueError(msg)
    exprs: list[pl.Expr] = []
    for c in cols:
        mu = pl.col(c).mean()
        sd = pl.col(c).std()
        exprs.append(
            pl.when(sd == 0).then(0.0).otherwise((pl.col(c) - mu) / sd).alias(f"{c}__z")
        )
    out = lf.with_columns(exprs)
    _log_stats("z_score_normalization", t0, cols=len(cols), extra="lazy" if not eager else "eager")
    if eager:
        return _rice(out.collect(), like=data if isinstance(data, RiceFrame) else None)
    return _rice(out, like=data if isinstance(data, RiceFrame) else None)


def monte_carlo_summary(
    samples: NDArray[Any] | RiceArray | dict[str, Any],
    *,
    alpha: float = 0.05,
    value_key: str = "values",
) -> dict[str, Any]:
    """Summarize Monte Carlo draws (NumPy path; hook for ``monte.mojo`` payloads).

    If ``samples`` is a mapping, reads ``samples[value_key]`` (1-D array-like) or
    ``samples["paths"]`` / ``samples["draws"]`` when present.
    """
    t0 = time.perf_counter()
    if isinstance(samples, dict):
        if value_key in samples:
            x = np.asarray(samples[value_key], dtype=np.float64).ravel()
        elif "paths" in samples:
            x = np.asarray(samples["paths"], dtype=np.float64).ravel()
        elif "draws" in samples:
            x = np.asarray(samples["draws"], dtype=np.float64).ravel()
        else:
            msg = f"dict samples must contain {value_key!r}, 'paths', or 'draws'"
            raise KeyError(msg)
    else:
        x = samples.data if isinstance(samples, RiceArray) else np.asarray(samples, dtype=np.float64).ravel()
    if x.size == 0:
        msg = "empty sample vector"
        raise ValueError(msg)
    lo, hi = np.quantile(x, [alpha / 2, 1.0 - alpha / 2])
    out = {
        "mean": float(np.mean(x)),
        "std": float(np.std(x, ddof=1)),
        "median": float(np.median(x)),
        "ci_low": float(lo),
        "ci_high": float(hi),
        "n": int(x.size),
        "alpha": float(alpha),
    }
    _log_stats(
        "monte_carlo_summary",
        t0,
        rows=out["n"],
        extra=f"mean={out['mean']:.6g} std={out['std']:.6g} ci=[{out['ci_low']:.6g},{out['ci_high']:.6g}] monte.mojo",
    )
    return out


# --- Legacy / thin SciPy wrappers ----------------------------------------------------


def describe_sample(x: NDArray[np.floating]) -> Any:
    return stats.describe(x)


def ttest_ind_samples(
    a: NDArray[np.floating],
    b: NDArray[np.floating],
    *,
    equal_var: bool = True,
) -> HypothesisResult:
    """Alias of :func:`t_test` for independent samples (backward compatible name)."""
    return t_test(a, b, paired=False, equal_var=equal_var)


def normal_pdf(x: NDArray[np.floating], loc: float = 0.0, scale: float = 1.0) -> NDArray[np.floating]:
    return stats.norm.pdf(x, loc=loc, scale=scale)


def ks_2samp_test(
    a: NDArray[np.floating],
    b: NDArray[np.floating],
) -> HypothesisResult:
    return stats.ks_2samp(a, b)


def pearsonr_corr(
    x: NDArray[np.floating],
    y: NDArray[np.floating],
) -> tuple[float, float]:
    r, p = stats.pearsonr(x, y)
    return float(r), float(p)


def spearmanr_corr(
    x: NDArray[np.floating],
    y: NDArray[np.floating],
) -> tuple[float, float]:
    r, p = stats.spearmanr(x, y)
    return float(r), float(p)


def mannwhitneyu_test(
    x: NDArray[np.floating],
    y: NDArray[np.floating],
) -> HypothesisResult:
    return stats.mannwhitneyu(x, y)


__all__ = [
    "anova",
    "chi2_contingency",
    "chi_square",
    "correlation_matrix",
    "describe_sample",
    "fit_distribution",
    "ks_2samp_test",
    "mannwhitneyu_test",
    "monte_carlo_summary",
    "normal_pdf",
    "p_value_check",
    "pearsonr_corr",
    "quantile_analysis",
    "rolling_stats",
    "sampling",
    "spearmanr_corr",
    "summary",
    "t_test",
    "ttest_ind_samples",
    "z_score_normalization",
]
