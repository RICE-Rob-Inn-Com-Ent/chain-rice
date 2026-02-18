"""PyArrow: columnar data, zero-copy ops, IPC, Parquet, schema.

Provides Arrow tables/arrays, Parquet read/write, IPC streaming (e.g. from Go),
memory-mapped files, CSV, and conversions to Polars/pandas. Requires: pyarrow (extra data).
Install with: uv sync --extra data
"""

from __future__ import annotations

from io import BytesIO
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    import pyarrow as pa

# -----------------------------------------------------------------------------
# PyArrow Tables and Arrays
# -----------------------------------------------------------------------------


def _pa():
    """Lazy import of pyarrow. Raises ImportError with install hint if missing."""
    try:
        import pyarrow as pa
        return pa
    except ImportError as e:
        raise ImportError(
            "tables requires pyarrow; install: uv sync --extra data"
        ) from e


def empty_table(schema=None):
    """Return empty Arrow table with optional schema."""
    pa = _pa()
    if schema is None:
        schema = pa.schema([])
    return pa.table({}, schema=schema)


def table_from_arrays(columns: dict[str, "pyarrow.Array"]) -> "pyarrow.Table":
    """Build Arrow table from dict of column name -> Array (zero-copy where possible)."""
    pa = _pa()
    return pa.table(columns)


def array_from_list(data: list, type=None):
    """Create Arrow Array from list. type: pa.int64(), pa.string(), etc. (optional)."""
    pa = _pa()
    return pa.array(data, type=type)


# -----------------------------------------------------------------------------
# Schema definitions
# -----------------------------------------------------------------------------


def schema_from_dict(fields: dict[str, str]) -> "pyarrow.Schema":
    """Build Arrow schema from dict name -> type ('int64', 'float64', 'string', 'bool')."""
    pa = _pa()
    type_map = {
        "int64": pa.int64(),
        "float64": pa.float64(),
        "string": pa.string(),
        "bool": pa.bool_(),
        "timestamp": pa.timestamp("us"),
        "binary": pa.binary(),
    }
    return pa.schema({name: type_map.get(t, pa.string()) for name, t in fields.items()})


# -----------------------------------------------------------------------------
# Parquet read/write
# -----------------------------------------------------------------------------


def read_parquet(path: str, **kwargs: Any) -> "pa.Table":
    """Read Parquet file into Arrow Table."""
    pa = _pa()
    import pyarrow.parquet as pq
    return pq.read_table(path, **kwargs)


def load_parquet(path: str, **kwargs: Any) -> "pa.Table":
    """Alias for read_parquet. Load Parquet file into Arrow Table."""
    return read_parquet(path, **kwargs)


def write_parquet(table: "pa.Table", path: str, compression: str = "snappy", **kwargs: Any) -> None:
    """Write Arrow Table to Parquet file."""
    _pa()
    import pyarrow.parquet as pq
    pq.write_table(table, path, compression=compression, **kwargs)


def save_parquet(table: "pa.Table", path: str, compression: str = "snappy", **kwargs: Any) -> None:
    """Alias for write_parquet. Save Arrow Table to Parquet."""
    write_parquet(table, path, compression=compression, **kwargs)


# -----------------------------------------------------------------------------
# Zero-copy conversions
# -----------------------------------------------------------------------------


def table_to_polars(table: "pyarrow.Table"):
    """Arrow Table -> Polars DataFrame (zero-copy gdzie możliwe)."""
    try:
        import polars as pl
        return pl.from_arrow(table)
    except ImportError as e:
        raise ImportError("table_to_polars wymaga polars") from e


def polars_to_table(df) -> "pyarrow.Table":
    """Polars DataFrame -> Arrow Table."""
    if hasattr(df, "to_arrow"):
        return df.to_arrow()
    pa = _pa()
    return pa.table({}, schema=pa.schema([]))


# -----------------------------------------------------------------------------
# IPC streaming
# -----------------------------------------------------------------------------


def open_ipc_stream(buffer: bytes) -> "pa.Table":
    """Read Arrow IPC stream from buffer (e.g. from Go). Returns single Table."""
    pa = _pa()
    reader = pa.ipc.open_stream(buffer)
    return reader.read_all()


def process_ipc_stream(stream: bytes | BytesIO) -> "pa.Table":
    """Read Arrow IPC stream from bytes or BytesIO; returns Arrow Table."""
    pa = _pa()
    if isinstance(stream, bytes):
        reader = pa.ipc.open_stream(stream)
    else:
        reader = pa.ipc.open_stream(stream.read())
    return reader.read_all()


def send_ipc_stream(table: "pa.Table") -> bytes:
    """Serialize Arrow Table to IPC stream bytes (zero-copy)."""
    buf = BytesIO()
    pa = _pa()
    with pa.ipc.new_stream(buf, table.schema) as writer:
        writer.write_table(table)
    return buf.getvalue()


def process_go_payload(buffer: bytes):
    """Read Arrow IPC stream from Go service; returns Polars DataFrame (zero-copy)."""
    table = open_ipc_stream(buffer)
    return table_to_polars(table)


def write_ipc_stream(table: "pa.Table", sink: Any) -> None:
    """Write Table to IPC stream (sink: file or BytesIO)."""
    pa = _pa()
    writer = pa.ipc.new_stream(sink, table.schema)
    writer.write_table(table)
    writer.close()


# -----------------------------------------------------------------------------
# Memory-mapped files
# -----------------------------------------------------------------------------


def memory_map_arrow(path: str) -> "pyarrow.Table":
    """Read Arrow file via memory mapping (read-only, zero-copy)."""
    pa = _pa()
    with pa.ipc.open_file(pa.memory_map(path)) as reader:
        return reader.read_all()


def read_feather(path: str, **kwargs: Any) -> "pa.Table":
    """Read Feather (Arrow on disk)."""
    pa = _pa()
    with pa.ipc.open_file(path, **kwargs) as reader:
        return reader.read_all()


# -----------------------------------------------------------------------------
# CSV and schema helpers
# -----------------------------------------------------------------------------


def load_csv(path: str, schema: "pa.Schema | None" = None, **kwargs: Any) -> "pa.Table":
    """Load CSV into Arrow Table. Optional schema for column types."""
    pa = _pa()
    import pyarrow.csv as csv
    opts = kwargs.copy()
    if schema is not None:
        opts["schema"] = schema
    return csv.read_csv(path, **opts)


def save_csv(table: "pa.Table", path: str, **kwargs: Any) -> None:
    """Write Arrow Table to CSV file."""
    pa = _pa()
    import pyarrow.csv as csv
    csv.write_csv(table, path, **kwargs)


def infer_schema(data: list[dict[str, Any]]) -> "pa.Schema":
    """Infer Arrow schema from list of dicts (first row keys + types)."""
    pa = _pa()
    if not data:
        return pa.schema([])
    first = data[0]
    arrays = {}
    for key, val in first.items():
        col = [row.get(key) for row in data]
        arrays[key] = pa.array(col)
    return pa.table(arrays).schema


def validate_schema(table: "pa.Table", expected_schema: "pa.Schema") -> bool:
    """Return True if table schema matches expected (field names and types)."""
    pa = _pa()
    if table.schema.names != expected_schema.names:
        return False
    for a, b in zip(table.schema.types, expected_schema.types, strict=True):
        if a != b:
            return False
    return True


def to_pandas(table: "pa.Table", zero_copy: bool = True):  # noqa: ANN201
    """Convert Arrow Table to pandas DataFrame (zero-copy where possible)."""
    return table.to_pandas(zero_copy=zero_copy)


def to_polars(table: "pa.Table"):
    """Arrow Table to Polars DataFrame (alias for table_to_polars)."""
    return table_to_polars(table)


def to_numpy(column: "pa.Array"):
    """Extract Arrow column to numpy array."""
    return column.to_numpy(zero_copy=False)
