"""Polars — zapis: Parquet, CSV, Delta, bazy danych."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from pathlib import Path
from typing import Any

import polars as pl
from loguru import logger

# TODO:
# [ ] implement multi-format export:
# [ ]     Parquet: write_parquet with RICE_PARQUET_COMPRESSION
# [ ]     CSV: write_csv with RICE_CSV_DELIMITER, RICE_CSV_QUOTE
# [ ]     Arrow IPC: write_ipc for inter-process exchange
# [ ]     NDJSON: write_ndjson for streaming output
# [ ]     Delta Lake: when RICE_DELTA_ENABLED=true
# [ ] implement partitioned export:
# [ ]     partition_by columns from RICE_EXPORT_PARTITION_COLS
# [ ]     output path pattern from RICE_EXPORT_PATH_PATTERN
# [ ] implement export metadata:
# [ ]     write sidecar .json with schema, row_count, export_time, checksum
# [ ] implement export to NATS:
# [ ]     publish Arrow IPC chunks to NATS subject exports.sage.{job_id}
# [ ]     chunk_size from RICE_NATS_EXPORT_CHUNK_BYTES env var


def write_parquet(df: pl.DataFrame, path: str | Path, **kwargs: Any) -> None:
    df.write_parquet(path, **kwargs)


def write_csv(df: pl.DataFrame, path: str | Path, **kwargs: Any) -> None:
    df.write_csv(path, **kwargs)


def write_delta(df: pl.DataFrame, target: str | Path, **kwargs: Any) -> None:
    """Zapis Delta Lake — wymaga pakietu `deltalake` / kompatybilnego backendu."""
    write = getattr(df, "write_delta", None)
    if write is None:
        msg = "write_delta: użyj Polars z obsługą Delta lub zapisz Parquet i konwertuj zewnętrznie"
        raise RuntimeError(msg)
    try:
        write(target, **kwargs)
    except Exception as exc:  # noqa: BLE001
        logger.warning("write_delta failed: {}", exc)
        raise


def write_database(df: pl.DataFrame, connection: str, table_name: str, **kwargs: Any) -> None:
    """Zapis do SQL — argumenty jak w `DataFrame.write_database` (URI + engine)."""
    df.write_database(table_name=table_name, connection=connection, **kwargs)
