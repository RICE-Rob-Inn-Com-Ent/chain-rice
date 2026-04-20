"""SciPy — rozkłady, testy, statystyki opisowe."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import Any

import numpy as np
from numpy.typing import NDArray
from scipy import stats

# TODO:
# [ ] implement descriptive stats: mean, std, skewness, kurtosis, percentiles
# [ ]     output as Polars DataFrame for pipeline chaining
# [ ] implement hypothesis testing via scipy.stats:
# [ ]     t-test, chi-square, ANOVA, Mann-Whitney — test from config
# [ ]     alpha from RICE_STATS_ALPHA env var (default: 0.05)
# [ ] implement correlation analysis:
# [ ]     pearson, spearman, kendall — method from RICE_CORR_METHOD
# [ ]     output as correlation matrix Polars DataFrame
# [ ] implement distribution fitting:
# [ ]     fit scipy distributions to data columns
# [ ]     goodness-of-fit: KS test, AIC, BIC
# [ ] implement bootstrap confidence intervals:
# [ ]     n_iterations from RICE_BOOTSTRAP_N env var
# [ ] implement time series decomposition:
# [ ]     trend, seasonality, residual via scipy signal


def describe_sample(x: NDArray[np.floating]) -> Any:
    return stats.describe(x)


def ttest_ind_samples(
    a: NDArray[np.floating],
    b: NDArray[np.floating],
    *,
    equal_var: bool = True,
) -> Any:
    return stats.ttest_ind(a, b, equal_var=equal_var)


def normal_pdf(x: NDArray[np.floating], loc: float = 0.0, scale: float = 1.0) -> NDArray[np.floating]:
    return stats.norm.pdf(x, loc=loc, scale=scale)


def ks_2samp_test(
    a: NDArray[np.floating],
    b: NDArray[np.floating],
) -> Any:
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


def chi2_contingency(table: NDArray[Any]) -> tuple:
    return stats.chi2_contingency(table)


def mannwhitneyu_test(
    x: NDArray[np.floating],
    y: NDArray[np.floating],
) -> Any:
    return stats.mannwhitneyu(x, y)
