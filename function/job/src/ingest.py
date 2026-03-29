"""Polars — wczytywanie: CSV, Parquet, JSON, NDJSON, skany lazy."""

from __future__ import annotations

from pathlib import Path
from typing import Any

import polars as pl

# TODO:
# [ ] implement multi-source ingestion:
# [ ]     CSV: scan_csv with schema_overrides from config
# [ ]     Parquet: scan_parquet with hive partitioning support
# [ ]     NDJSON: scan_ndjson for streaming log data
# [ ]     Arrow IPC: from_arrow for inter-process data
# [ ]     Database: read_database via ConnectorX (DB_URL from env)
# [ ] implement NATS stream consumer for real-time ingestion:
# [ ]     subscribe to NATS_INGEST_SUBJECT env var
# [ ]     batch accumulate until RICE_BATCH_SIZE or RICE_BATCH_TIMEOUT_S
# [ ] implement schema versioning: track source schema changes over time
# [ ] implement data quality checks on ingest:
# [ ]     null rate, cardinality, range validation per column
# [ ]     thresholds from RICE_DQ_* env vars
# [ ] implement retry on source failure via helper/retry.py


def read_csv(path: str | Path, **kwargs: Any) -> pl.DataFrame:
    return pl.read_csv(path, **kwargs)


def read_parquet(path: str | Path, **kwargs: Any) -> pl.DataFrame:
    return pl.read_parquet(path, **kwargs)


def read_json(path: str | Path, **kwargs: Any) -> pl.DataFrame:
    return pl.read_json(path, **kwargs)


def read_ndjson(path: str | Path, **kwargs: Any) -> pl.DataFrame:
    return pl.read_ndjson(path, **kwargs)


def scan_csv(path: str | Path, **kwargs: Any) -> pl.LazyFrame:
    return pl.scan_csv(path, **kwargs)


def scan_parquet(path: str | Path, **kwargs: Any) -> pl.LazyFrame:
    return pl.scan_parquet(path, **kwargs)


def scan_ndjson(path: str | Path, **kwargs: Any) -> pl.LazyFrame:
    return pl.scan_ndjson(path, **kwargs)


def scan_ipc(path: str | Path, **kwargs: Any) -> pl.LazyFrame:
    """Feather / IPC — lazy."""
    return pl.scan_ipc(path, **kwargs)
