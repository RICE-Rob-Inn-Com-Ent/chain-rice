"""Polars — transformacje: select, filter, group_by, join, pivot, melt, wyrażenia."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import polars as pl

# TODO:
# [ ] implement type casting pipeline:
# [ ]     safe_cast with null handling for all Polars dtypes
# [ ] implement normalization: min-max, z-score, robust scaler
# [ ]     scaler params saved to RICE_SCALER_PATH for inference reuse
# [ ] implement feature engineering:
# [ ]     polynomial features, interaction terms, log transforms
# [ ]     feature list from RICE_FEATURE_CONFIG env var or config file
# [ ] implement missing value imputation:
# [ ]     strategies: mean, median, mode, forward-fill, backward-fill, model-based
# [ ]     strategy per column from config — not hardcoded
# [ ] implement outlier detection and handling:
# [ ]     IQR, Z-score, Isolation Forest — method from RICE_OUTLIER_METHOD
# [ ]     on outlier: clip|drop|flag — from RICE_OUTLIER_ACTION
# [ ] implement window functions: rolling, expanding, ewm
# [ ]     all window params soft-coded


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


def pivot_table(df: pl.DataFrame, **kwargs: object) -> pl.DataFrame:
    """`DataFrame.pivot` — parametry zgodnie z wersją Polars (on, index, values, aggregate_function, ...)."""
    return df.pivot(**kwargs)


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
