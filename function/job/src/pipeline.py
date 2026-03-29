"""Polars + NumPy — potok od surowych danych do cech (feature engineering)."""

from __future__ import annotations

from pathlib import Path
from typing import Any

import numpy as np
import polars as pl

from . import array, export, frame, ingest, transform

# TODO:
# [ ] implement composable pipeline via function chaining:
# [ ]     Pipeline(source).transform(f1).transform(f2).export(sink)
# [ ]     each step is a LazyFrame → LazyFrame function
# [ ] implement pipeline DAG: track step dependencies via petgraph (via base/mint)
# [ ]     visualize DAG in test/notebook/explore_job.py
# [ ] implement parallel pipeline execution:
# [ ]     independent branches → asyncio.gather
# [ ]     branch count from RICE_PIPELINE_WORKERS env var
# [ ] implement pipeline checkpointing:
# [ ]     save intermediate results to Parquet at RICE_CHECKPOINT_DIR
# [ ]     resume from checkpoint when RICE_RESUME_CHECKPOINT=true
# [ ] implement Temporal activity wrapping:
# [ ]     each pipeline step → Temporal activity with retry policy
# [ ]     timeout per step from RICE_STEP_TIMEOUT_S env var
# [ ] implement OTel tracing per step:
# [ ]     span per pipeline step, record input/output row count and latency


def numeric_feature_pipeline(
    path: str | Path,
    *,
    value_col: str,
    group_col: str,
    out_parquet: str | Path | None = None,
) -> pl.DataFrame:
    """Przykład: wczytanie Parquet → agregacje grupowe → numpy (z-score w grupie) → z powrotem do Polars."""
    df = ingest.read_parquet(path)
    g = transform.group_agg(
        df,
        group_col,
        [
            pl.col(value_col).mean().alias("mean_v"),
            pl.col(value_col).std().alias("std_v"),
            pl.col(value_col).count().alias("n"),
        ],
    )
    merged = df.join(g, on=group_col, how="left")
    arr = merged[value_col].to_numpy().astype(np.float64)
    means = merged["mean_v"].to_numpy().astype(np.float64)
    stds = merged["std_v"].to_numpy().astype(np.float64)
    stds = np.where(stds > 1e-12, stds, 1.0)
    z = array.clip_range((arr - means) / stds, -10.0, 10.0)
    out = merged.with_columns(pl.Series("zscore", z))
    if out_parquet is not None:
        export.write_parquet(out, out_parquet)
    return out


def lazy_aggregate_then_collect(
    parquet_glob: str,
    *,
    key: str,
    streaming: bool = False,
) -> pl.DataFrame:
    """Skan lazy wielu plików → grupowanie → collect (opcjonalnie streaming)."""
    lf = pl.scan_parquet(parquet_glob).group_by(key).agg(pl.len().alias("cnt"))
    return frame.collect_lazy(lf, streaming=streaming)
