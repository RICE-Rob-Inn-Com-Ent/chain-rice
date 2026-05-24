"""High-throughput export — Parquet, Arrow IPC, CSV, NumPy, SQL, remote URLs, with safety + telemetry."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import io
import json
import os
import tempfile
import time
from collections.abc import Callable, Sequence
from pathlib import Path
from typing import Any, Literal, TypeAlias

import numpy as np
import polars as pl
from loguru import logger

from .array import RiceArray
from .frame import RiceFrame
from .memory import MemoryAnchor

try:  # pragma: no cover
    import fsspec
except ImportError:  # pragma: no cover
    fsspec = None  # type: ignore[assignment]

FrameLike: TypeAlias = RiceFrame | pl.DataFrame | pl.LazyFrame
ArrayLike: TypeAlias = RiceArray | np.ndarray


def _default_parquet_compression() -> str:
    return os.getenv("RICE_EXPORT_PARQUET_COMPRESSION", "zstd").strip().lower() or "zstd"


def _log_export(
    op: str,
    t0: float,
    path: str | Path,
    *,
    nbytes: int | None = None,
    ratio: float | None = None,
    extra: str = "",
) -> None:
    mb = (nbytes / (1024 * 1024)) if nbytes is not None else None
    logger.info(
        "export op={} wall_ms={:.2f} path={} size_mb={} compression_ratio={} {}",
        op,
        (time.perf_counter() - t0) * 1000,
        path,
        f"{mb:.3f}" if mb is not None else None,
        ratio,
        extra,
    )


def _eager_frame(data: FrameLike) -> pl.DataFrame:
    inner = data.inner if isinstance(data, RiceFrame) else data
    if isinstance(inner, pl.LazyFrame):
        return inner.collect()
    return inner


def _as_numpy(data: ArrayLike) -> np.ndarray:
    return data.data if isinstance(data, RiceArray) else np.asarray(data)


def _maybe_anchor(obj: Any) -> bool:
    if isinstance(obj, (RiceArray, RiceFrame, np.ndarray, pl.DataFrame, pl.Series)):
        MemoryAnchor.anchor(obj)
        return True
    return False


def _maybe_release(obj: Any, *, anchored: bool) -> None:
    if anchored and obj is not None:
        MemoryAnchor.release(obj)


def check_path_integrity(
    path: str | Path,
    *,
    create_parents: bool = True,
    check_writable: bool = True,
) -> Path:
    """Ensure parent directory exists and is writable (creates parents when ``create_parents``)."""
    p = Path(path).expanduser().resolve()
    parent = p.parent
    if create_parents:
        parent.mkdir(parents=True, exist_ok=True)
    if not parent.is_dir():
        msg = f"parent is not a directory: {parent}"
        raise FileNotFoundError(msg)
    if check_writable and not os.access(parent, os.W_OK):
        msg = f"no write permission on directory: {parent}"
        raise PermissionError(msg)
    return p


def atomic_write(
    dest: Path | str,
    writer: Callable[[Path], None],
    *,
    temp_suffix: str = ".tmp",
) -> None:
    """Write via ``writer(tmp_path)`` then atomically replace ``dest`` (same-parent ``os.replace``)."""
    dest = Path(dest).expanduser().resolve()
    check_path_integrity(dest, create_parents=True, check_writable=True)
    parent = dest.parent
    fd, tmp_name = tempfile.mkstemp(prefix=".export_", suffix=temp_suffix, dir=str(parent))
    os.close(fd)
    tmp = Path(tmp_name)
    try:
        writer(tmp)
        os.replace(tmp, dest)
    except BaseException:
        tmp.unlink(missing_ok=True)
        raise


def to_parquet(
    data: FrameLike,
    path: str | Path,
    *,
    compression: str | None = None,
    atomic: bool = True,
    **kwargs: Any,
) -> None:
    """Primary analytics sink — Snappy / Zstd / … via Polars (``compression`` overrides env default)."""
    t0 = time.perf_counter()
    df = _eager_frame(data)
    comp = compression or _default_parquet_compression()
    anchored = _maybe_anchor(data if isinstance(data, (RiceFrame, RiceArray)) else df)
    raw_est = None
    try:
        try:
            raw_est = int(df.estimated_size())
        except Exception:
            raw_est = None

        def _write(tmp: Path) -> None:
            df.write_parquet(tmp, compression=comp, **kwargs)

        if atomic:
            atomic_write(path, _write)
        else:
            p = check_path_integrity(path, create_parents=True)
            df.write_parquet(p, compression=comp, **kwargs)
        nbytes = Path(path).expanduser().resolve().stat().st_size
        ratio = (nbytes / raw_est) if raw_est and raw_est > 0 else None
        _log_export("to_parquet", t0, path, nbytes=nbytes, ratio=ratio, extra=f"compression={comp!r}")
    finally:
        _maybe_release(data if isinstance(data, (RiceFrame, RiceArray)) else df, anchored=anchored)


def to_arrow(
    data: FrameLike,
    path: str | Path,
    *,
    atomic: bool = True,
    **kwargs: Any,
) -> None:
    """Arrow IPC file (fast IPC / interchange)."""
    t0 = time.perf_counter()
    df = _eager_frame(data)
    anchored = _maybe_anchor(data if isinstance(data, RiceFrame) else df)
    try:
        if not hasattr(df, "write_ipc"):
            msg = "write_ipc not available on this Polars build"
            raise AttributeError(msg)

        def _write(tmp: Path) -> None:
            df.write_ipc(tmp, **kwargs)

        if atomic:
            atomic_write(path, _write)
        else:
            p = check_path_integrity(path, create_parents=True)
            df.write_ipc(p, **kwargs)
        nbytes = Path(path).expanduser().resolve().stat().st_size
        _log_export("to_arrow", t0, path, nbytes=nbytes, extra="ipc")
    finally:
        _maybe_release(data if isinstance(data, RiceFrame) else df, anchored=anchored)


def to_csv(
    data: FrameLike,
    path: str | Path,
    *,
    atomic: bool = True,
    **kwargs: Any,
) -> None:
    """CSV export for broad compatibility."""
    t0 = time.perf_counter()
    df = _eager_frame(data)
    anchored = _maybe_anchor(data if isinstance(data, RiceFrame) else df)
    try:

        def _write(tmp: Path) -> None:
            df.write_csv(tmp, **kwargs)

        if atomic:
            atomic_write(path, _write)
        else:
            p = check_path_integrity(path, create_parents=True)
            df.write_csv(p, **kwargs)
        nbytes = Path(path).expanduser().resolve().stat().st_size
        _log_export("to_csv", t0, path, nbytes=nbytes, extra="")
    finally:
        _maybe_release(data if isinstance(data, RiceFrame) else df, anchored=anchored)


def to_numpy(
    data: ArrayLike,
    path: str | Path,
    *,
    atomic: bool = True,
) -> None:
    """Persist a dense vector / matrix as ``.npy``."""
    t0 = time.perf_counter()
    arr = np.ascontiguousarray(_as_numpy(data))
    anchored = _maybe_anchor(data if isinstance(data, RiceArray) else arr)
    try:

        def _write(tmp: Path) -> None:
            np.save(tmp, arr, allow_pickle=False)

        if atomic:
            atomic_write(path, _write, temp_suffix=".npy")
        else:
            p = check_path_integrity(path, create_parents=True)
            np.save(p, arr, allow_pickle=False)
        nbytes = Path(path).expanduser().resolve().stat().st_size
        _log_export("to_numpy", t0, path, nbytes=nbytes, extra=f"shape={arr.shape}")
    finally:
        _maybe_release(data if isinstance(data, RiceArray) else arr, anchored=anchored)


def to_url(
    data: FrameLike,
    url: str,
    *,
    format: Literal["parquet", "csv", "arrow"] = "parquet",
    compression: str | None = None,
    **kwargs: Any,
) -> None:
    """Stream export to a remote URL via ``fsspec`` (S3 / Azure / GCS style URLs)."""
    t0 = time.perf_counter()
    if fsspec is None:
        msg = "fsspec is required for to_url — pip install fsspec"
        raise RuntimeError(msg)
    df = _eager_frame(data)
    anchored = _maybe_anchor(data if isinstance(data, RiceFrame) else df)
    nbytes = 0
    try:
        buf = io.BytesIO()
        if format == "parquet":
            comp = compression or _default_parquet_compression()
            df.write_parquet(buf, compression=comp, **kwargs)
        elif format == "csv":
            df.write_csv(buf, **kwargs)
        else:
            if not hasattr(df, "write_ipc"):
                msg = "write_ipc not available"
                raise AttributeError(msg)
            df.write_ipc(buf, **kwargs)
        payload = buf.getvalue()
        nbytes = len(payload)
        with fsspec.open(url, "wb") as f:
            f.write(payload)
        _log_export("to_url", t0, url, nbytes=nbytes or None, extra=f"format={format!r}")
    finally:
        _maybe_release(data if isinstance(data, RiceFrame) else df, anchored=anchored)


def to_sql(
    data: FrameLike,
    table_name: str,
    connection_string: str,
    *,
    engine: Literal["sqlalchemy", "adbc", "auto"] = "auto",
    **kwargs: Any,
) -> None:
    """Write tabular data to SQL (Polars ``write_database`` when available; ADBC/SQLAlchemy via engine)."""
    t0 = time.perf_counter()
    df = _eager_frame(data)
    anchored = _maybe_anchor(data if isinstance(data, RiceFrame) else df)
    try:
        if not hasattr(df, "write_database"):
            msg = "write_database not available on this Polars build"
            raise AttributeError(msg)
        eng = None if engine == "auto" else engine
        df.write_database(table_name=table_name, connection=connection_string, engine=eng, **kwargs)
        _log_export("to_sql", t0, f"{table_name!r}", nbytes=None, extra=f"engine={engine!r}")
    finally:
        _maybe_release(data if isinstance(data, RiceFrame) else df, anchored=anchored)


def schema_export(
    data: FrameLike,
    path: str | Path,
    *,
    atomic: bool = True,
    extra_meta: dict[str, Any] | None = None,
) -> None:
    """Write Polars schema + optional metadata as JSON next to datasets (ingestion aid)."""
    t0 = time.perf_counter()
    inner = data.inner if isinstance(data, RiceFrame) else data
    schema = inner.collect_schema() if isinstance(inner, pl.LazyFrame) else inner.schema
    payload: dict[str, Any] = {
        "columns": {name: str(dtype) for name, dtype in schema.items()},
        "n_columns": len(schema),
    }
    if extra_meta:
        payload["meta"] = extra_meta
    anchored = _maybe_anchor(data) if isinstance(data, RiceFrame) else False
    try:
        text = json.dumps(payload, indent=2)

        def _write(tmp: Path) -> None:
            tmp.write_text(text, encoding="utf-8")

        if atomic:
            atomic_write(path, _write)
        else:
            p = check_path_integrity(path, create_parents=True)
            p.write_text(text, encoding="utf-8")
        nbytes = Path(path).expanduser().resolve().stat().st_size
        _log_export("schema_export", t0, path, nbytes=nbytes, extra="json")
    finally:
        _maybe_release(data if isinstance(data, RiceFrame) else None, anchored=anchored)


def partitioned_export(
    data: FrameLike,
    base_path: str | Path,
    *,
    by: Sequence[str],
    filename: str = "part.parquet",
    compression: str | None = None,
    atomic: bool = True,
    write_schema: bool = True,
) -> list[Path]:
    """Hive-style folders under ``base_path`` / ``col=val`` / … / ``filename`` per partition."""
    t0 = time.perf_counter()
    df = _eager_frame(data)
    anchored = _maybe_anchor(data if isinstance(data, RiceFrame) else df)
    out_paths: list[Path] = []
    comp = compression or _default_parquet_compression()
    root = Path(base_path).expanduser().resolve()
    root.mkdir(parents=True, exist_ok=True)
    try:
        parts = df.partition_by(list(by), as_dict=False)
        for part in parts:
            if part.height == 0:
                continue
            sub = root
            for c in by:
                v = part[c][0]
                safe = str(v).replace(os.sep, "_")
                sub = sub / f"{c}={safe}"
            sub.mkdir(parents=True, exist_ok=True)
            dest = sub / filename

            def _make_writer(p: pl.DataFrame) -> Callable[[Path], None]:
                def _w(tmp: Path) -> None:
                    p.write_parquet(tmp, compression=comp)

                return _w

            if atomic:
                atomic_write(dest, _make_writer(part))
            else:
                part.write_parquet(dest, compression=comp)
            out_paths.append(dest)
            if write_schema:
                schema_export(part, dest.with_suffix(dest.suffix + ".schema.json"), atomic=atomic)
        _log_export(
            "partitioned_export",
            t0,
            root,
            nbytes=sum(p.stat().st_size for p in out_paths) if out_paths else 0,
            extra=f"n_parts={len(out_paths)} by={list(by)!r}",
        )
        return out_paths
    finally:
        _maybe_release(data if isinstance(data, RiceFrame) else df, anchored=anchored)


# --- Legacy thin wrappers ------------------------------------------------------------


def write_parquet(df: pl.DataFrame, path: str | Path, **kwargs: Any) -> None:
    to_parquet(df, path, **kwargs)


def write_csv(df: pl.DataFrame, path: str | Path, **kwargs: Any) -> None:
    to_csv(df, path, **kwargs)


def write_delta(df: pl.DataFrame, target: str | Path, **kwargs: Any) -> None:
    """Delta Lake — requires Polars Delta support / ``deltalake`` stack."""
    t0 = time.perf_counter()
    write = getattr(df, "write_delta", None)
    if write is None:
        msg = "write_delta: use Polars with Delta support or export Parquet and convert externally"
        raise RuntimeError(msg)
    try:
        write(target, **kwargs)
        nbytes = Path(target).expanduser().resolve().stat().st_size if Path(target).exists() else None
        _log_export("write_delta", t0, target, nbytes=nbytes, extra="delta")
    except Exception as exc:  # noqa: BLE001
        logger.warning("write_delta failed: {}", exc)
        raise


def write_database(df: pl.DataFrame, connection: str, table_name: str, **kwargs: Any) -> None:
    """Alias of :func:`to_sql` for eager ``DataFrame``."""
    to_sql(df, table_name, connection, **kwargs)


__all__ = [
    "atomic_write",
    "check_path_integrity",
    "partitioned_export",
    "schema_export",
    "to_arrow",
    "to_csv",
    "to_numpy",
    "to_parquet",
    "to_sql",
    "to_url",
    "write_csv",
    "write_database",
    "write_delta",
    "write_parquet",
]
