"""High-throughput ingestion → :class:`frame.RiceFrame` / :class:`array.RiceArray` (lazy-first)."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import io
import time
from collections.abc import Mapping
from pathlib import Path
from typing import Any, Union

import polars as pl
from loguru import logger

from . import const
from .array import RiceArray
from .frame import RiceFrame

IngestResult = Union[RiceFrame, RiceArray]


def _file_size(path: Path) -> int:
    try:
        return int(path.stat().st_size)
    except OSError:
        return 0


def _ingest_metrics(label: str, source: str, nbytes: int, t0: float) -> None:
    dt = max(time.perf_counter() - t0, 1e-9)
    mb_s = (nbytes / (1024 * 1024)) / dt
    logger.info(
        "ingest label={} source={} nbytes={} wall_s={:.3f} throughput_mib_s={:.2f}",
        label,
        source,
        nbytes,
        dt,
        mb_s,
    )


def _suffix(path: Path) -> str:
    s = path.suffix.lower()
    if s == ".gz" and len(path.suffixes) >= 2:
        s = path.suffixes[-2].lower()
    return s


def auto_schema_inference(
    source: str | Path | pl.LazyFrame | pl.DataFrame,
    *,
    overrides: Mapping[str, pl.DataType] | None = None,
) -> dict[str, pl.DataType]:
    """Infer Polars dtypes; merge ``overrides`` then :data:`const.RICE_FRAME_DEFAULT_EXPECTED_SCHEMA` (by name)."""
    if isinstance(source, pl.LazyFrame):
        sch = source.collect_schema()
    elif isinstance(source, pl.DataFrame):
        sch = source.schema
    else:
        rf = smart_load(source, eager=False, memory_map=const.RICE_INGEST_MEMORY_MAP_DEFAULT)
        inner = rf.inner if isinstance(rf, RiceFrame) else None
        if inner is None:
            msg = "auto_schema_inference requires a tabular source"
            raise TypeError(msg)
        sch = inner.collect_schema() if isinstance(inner, pl.LazyFrame) else inner.schema
    out: dict[str, pl.DataType] = {k: sch[k] for k in sch}
    base = dict(const.RICE_FRAME_DEFAULT_EXPECTED_SCHEMA)
    for name, dt_name in base.items():
        if name in out and hasattr(pl, dt_name.strip()):
            out[name] = getattr(pl, dt_name.strip())  # type: ignore[arg-type]
    if overrides:
        out.update(dict(overrides))
    return out


def from_arrow_ipc(buffer: bytes | bytearray | memoryview, *, rechunk: bool = False) -> RiceFrame:
    """Decode Arrow IPC stream / file bytes into a :class:`RiceFrame` (Polars + Arrow zero-copy where possible)."""
    t0 = time.perf_counter()
    bio = io.BytesIO(bytes(buffer))
    df: pl.DataFrame
    try:
        reader = getattr(pl, "read_ipc_stream", None)
        if reader is not None:
            df = reader(bio, rechunk=rechunk)
        else:
            raise AttributeError("read_ipc_stream")
    except Exception:
        bio.seek(0)
        df = pl.read_ipc(bio, rechunk=rechunk)
    nbytes = len(buffer)
    _ingest_metrics("from_arrow_ipc", "memory", nbytes, t0)
    return RiceFrame(df)


def stream_from_url(
    url: str,
    *,
    format: str | None = None,
    memory_map: bool | None = None,
    storage_options: dict[str, Any] | None = None,
) -> RiceFrame:
    """Lazy-open remote Parquet/CSV/IPC via Polars (URL passed through to ``scan_*``).

    For ``s3://`` / ``https://`` backends, install the matching object-store stack
    (e.g. ``fsspec``, ``s3fs``, ``pyarrow`` extras) so Polars can stream without a
    full local download.
    """
    t0 = time.perf_counter()
    mmap = const.RICE_INGEST_MEMORY_MAP_DEFAULT if memory_map is None else memory_map
    so = storage_options or {}
    fmt = (format or "").lower().strip()
    if not fmt:
        ul = url.lower().split("?", 1)[0]
        if ul.endswith((".parquet", ".pq")):
            fmt = "parquet"
        elif ul.endswith(".csv"):
            fmt = "csv"
        elif ul.endswith((".ipc", ".arrow")):
            fmt = "ipc"
        else:
            fmt = "parquet"

    nbytes = 0
    try:
        if fmt == "parquet":
            lf = pl.scan_parquet(url, storage_options=so)
        elif fmt == "csv":
            lf = pl.scan_csv(url, low_memory=True, memory_map=mmap, storage_options=so)
        elif fmt == "ipc":
            lf = pl.scan_ipc(url, storage_options=so)
        else:
            msg = f"unsupported stream format: {fmt!r}"
            raise ValueError(msg)
    except Exception:
        logger.exception(
            "stream_from_url failed url={} fmt={} — install cloud extras (e.g. fsspec, s3fs) "
            "and ensure Polars object-store support for this URL",
            url,
            fmt,
        )
        raise
    _ingest_metrics("stream_from_url", url, nbytes, t0)
    return RiceFrame(lf)


def smart_load(
    source: str | Path,
    *,
    eager: bool = False,
    memory_map: bool | None = None,
    pre_filter: pl.Expr | None = None,
    schema_overrides: dict[str, pl.DataType] | None = None,
    infer_schema_length: int | None = 10000,
    hdf5_dataset: str | None = None,
) -> IngestResult:
    """Detect format by suffix and return a lazy :class:`RiceFrame` (or :class:`RiceArray` for ``.npy``)."""
    t0 = time.perf_counter()
    mmap = const.RICE_INGEST_MEMORY_MAP_DEFAULT if memory_map is None else memory_map
    src_s = str(source)
    is_remote = src_s.startswith(("http://", "https://", "s3://"))

    if is_remote:
        rf = stream_from_url(src_s, memory_map=mmap)
        inner = rf.inner
        if pre_filter is not None:
            inner = inner.filter(pre_filter) if isinstance(inner, pl.LazyFrame) else inner.lazy().filter(pre_filter)
            rf = RiceFrame(inner)
        if eager:
            return rf.compute()
        return rf

    p = Path(source).expanduser().resolve()
    if not p.exists():
        msg = f"path not found: {p}"
        raise FileNotFoundError(msg)
    nbytes = _file_size(p)
    suf = _suffix(p)

    inner: pl.LazyFrame | pl.DataFrame | None = None
    arr: RiceArray | None = None

    if suf in {".parquet", ".pq"}:
        inner = pl.scan_parquet(p, schema_overrides=schema_overrides)
    elif suf == ".csv":
        inner = pl.scan_csv(
            p,
            low_memory=True,
            memory_map=mmap,
            infer_schema_length=infer_schema_length,
            schema_overrides=schema_overrides,
        )
    elif suf in {".ipc", ".arrow"}:
        inner = pl.scan_ipc(p)
    elif suf in {".ndjson", ".jsonl"}:
        inner = pl.scan_ndjson(p, infer_schema_length=infer_schema_length)
    elif suf == ".json":
        inner = pl.read_json(p, infer_schema_length=infer_schema_length)
    elif suf in {".npy"}:
        arr = RiceArray(_load_npy_mmap(p, mmap=mmap))
    elif suf in {".h5", ".hdf5"}:
        inner = _load_hdf5_skeleton(p, dataset=hdf5_dataset)
    else:
        msg = f"unsupported file type for smart_load: {suf!r} ({p})"
        raise ValueError(msg)

    if arr is not None:
        if pre_filter is not None:
            msg = "pre_filter is not supported for .npy sources (use RiceFrame after to_frame)"
            raise ValueError(msg)
        _ingest_metrics("smart_load", str(p), nbytes, t0)
        return arr

    assert inner is not None
    if pre_filter is not None:
        inner = inner.filter(pre_filter) if isinstance(inner, pl.LazyFrame) else inner.lazy().filter(pre_filter)
    if eager:
        df = inner.collect() if isinstance(inner, pl.LazyFrame) else inner
        rf = RiceFrame(df)
    else:
        rf = RiceFrame(inner if isinstance(inner, pl.LazyFrame) else inner.lazy())
    _ingest_metrics("smart_load", str(p), nbytes, t0)
    return rf


def _load_npy_mmap(path: Path, *, mmap: bool) -> Any:
    import numpy as np

    if mmap:
        return np.load(path, mmap_mode="r", allow_pickle=False)
    return np.load(path, allow_pickle=False)


def _load_hdf5_skeleton(path: Path, *, dataset: str | None) -> pl.DataFrame:
    try:
        import h5py
    except ImportError as e:
        msg = "HDF5 ingestion requires h5py — pip install h5py"
        raise ImportError(msg) from e
    with h5py.File(path, "r") as h:
        keys = list(h.keys())
        if not keys:
            msg = "empty HDF5 file"
            raise ValueError(msg)
        name = dataset or keys[0]
        if name not in h:
            msg = f"HDF5 dataset {name!r} not found; available: {keys[:8]}"
            raise KeyError(msg)
        d = h[name][()]
    import numpy as np

    a = np.ascontiguousarray(d)
    if a.ndim == 1:
        return pl.DataFrame({"v0": a})
    if a.ndim == 2:
        return pl.DataFrame(a)
    msg = f"HDF5 dataset {name!r} must be 1D or 2D for tabular ingest, got shape {a.shape}"
    raise ValueError(msg)


async def smart_load_async(
    source: str | Path,
    **kwargs: Any,
) -> IngestResult:
    """Non-blocking :func:`smart_load` via :func:`parallel.run_async` (use from asyncio)."""
    from .parallel import run_async

    return await run_async(lambda: smart_load(source, **kwargs))


def batch_loader(
    directory: str | Path,
    *,
    pattern: str | None = None,
    eager_union: bool = False,
) -> RiceFrame:
    """Load many tabular files under ``directory`` and concatenate (thread-parallel open)."""
    from .parallel import default_executor

    d = Path(directory).expanduser().resolve()
    if not d.is_dir():
        msg = f"not a directory: {d}"
        raise NotADirectoryError(msg)
    pat = pattern or const.RICE_INGEST_BATCH_GLOB
    paths = sorted(d.glob(pat))
    paths = [p for p in paths if p.is_file() and _suffix(p) not in {".npy"}]
    if not paths:
        msg = f"no ingestible tabular files matched {pat!r} in {d}"
        raise FileNotFoundError(msg)

    ex = default_executor().thread_pool

    def _one(pp: Path) -> pl.LazyFrame:
        rf = smart_load(pp, eager=False, memory_map=const.RICE_INGEST_MEMORY_MAP_DEFAULT)
        if not isinstance(rf, RiceFrame):
            msg = f"batch_loader skips non-tabular file {pp}"
            raise TypeError(msg)
        inner = rf.inner
        return inner if isinstance(inner, pl.LazyFrame) else inner.lazy()

    lfs = list(ex.map(_one, paths))
    out = RiceFrame(pl.concat(lfs, how="vertical"))
    if eager_union:
        return out.compute()
    return out


async def batch_loader_async(
    directory: str | Path,
    *,
    pattern: str | None = None,
    eager_union: bool = False,
) -> RiceFrame:
    from .parallel import run_async

    return await run_async(lambda: batch_loader(directory, pattern=pattern, eager_union=eager_union))


# --- Legacy thin wrappers (existing call sites) -----------------------


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


__all__ = [
    "IngestResult",
    "auto_schema_inference",
    "batch_loader",
    "batch_loader_async",
    "from_arrow_ipc",
    "read_csv",
    "read_json",
    "read_ndjson",
    "read_parquet",
    "scan_csv",
    "scan_ipc",
    "scan_ndjson",
    "scan_parquet",
    "smart_load",
    "smart_load_async",
    "stream_from_url",
]
