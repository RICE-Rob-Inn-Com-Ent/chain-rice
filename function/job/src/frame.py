"""Polars — cykl życia DataFrame: eager/lazy, scan, sink, streaming."""

from __future__ import annotations

from collections.abc import Iterator
from pathlib import Path
from typing import Any

import polars as pl

# TODO:
# [ ] implement LazyFrame pipeline builder:
# [ ]     all operations lazy by default — collect() only at pipeline end
# [ ]     scan_parquet, scan_csv, scan_ndjson — path from env/config
# [ ] implement schema inference with validation:
# [ ]     infer schema → validate against expected Pydantic schema
# [ ]     on mismatch: raise SchemaError with column diff
# [ ] implement streaming collect for large datasets:
# [ ]     collect(streaming=True) when frame > RICE_STREAMING_THRESHOLD_MB
# [ ] implement partition operations: partition_by, group_by_dynamic
# [ ]     window duration from RICE_WINDOW_DURATION env var
# [ ] implement time series operations:
# [ ]     upsample, interpolate, rolling_mean, rolling_std, ewm_mean
# [ ]     all window sizes soft-coded via config
# [ ] implement categorical encoding: StringCache, Enum dtype
# [ ] implement Arrow IPC export: frame.write_ipc() for Mojo bridge
# [ ] implement Parquet export with compression:
# [ ]     compression from RICE_PARQUET_COMPRESSION env var (default: zstd)
# [ ] implement Delta Lake write when RICE_DELTA_ENABLED=true:
# [ ]     via polars-delta plugin


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
