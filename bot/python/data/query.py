"""Ibis: SQL-like API, query building, DuckDB backend.

Provides run_sql (read-only), is_safe_query, Ibis expression API. Requires:
ibis-framework[duckdb] (extra data), duckdb (core). All queries are validated
to block destructive/write operations (DROP, DELETE, UPDATE, etc.).
"""

from __future__ import annotations

import re

import duckdb
import polars as pl

DUCKDB_MEMORY = ":memory:"

# Query validation: block destructive/write SQL keywords
_BLOCKED_SQL = re.compile(
    r"\b(ALTER|CREATE|DELETE|DROP|EXEC|EXECUTE|INSERT|TRUNCATE|UPDATE|GRANT|REVOKE)\b",
    re.I,
)


def is_safe_query(sql: str) -> tuple[bool, str | None]:
    """Return (True, None) if query is read-only; (False, reason) otherwise."""
    sql = (sql or "").strip()
    if not sql:
        return False, "Empty query."
    if _BLOCKED_SQL.search(sql):
        return False, "Destructive or write operations are not allowed."
    return True, None


# -----------------------------------------------------------------------------
# DuckDB backend connection
# -----------------------------------------------------------------------------


def duckdb_connect(path: str = DUCKDB_MEMORY) -> duckdb.DuckDBPyConnection:
    """Return DuckDB connection (default: in-memory)."""
    return duckdb.connect(path)


def _get_duckdb_path() -> str:
    """DuckDB path from env or default (avoids importing app.config)."""
    import os
    return os.getenv("DUCKDB_PATH", DUCKDB_MEMORY)


def run_sql(
    query: str,
    params: dict | None = None,
) -> list[dict]:
    """Execute read-only SQL on DuckDB. Returns rows as list of dicts.

    Args:
        query: SQL string (SELECT only; validated by is_safe_query).
        params: Optional named parameters for the query.

    Returns:
        List of dicts, one per row (keys = column names).

    Raises:
        ValueError: If query is not safe (write/destructive).
    """
    ok, err = is_safe_query(query)
    if not ok:
        raise ValueError(err or "Unsafe query.")
    path = _get_duckdb_path()
    conn = duckdb.connect(path)
    if params:
        result = conn.execute(query, params)
    else:
        result = conn.execute(query)
    df = result.pl()
    return df.to_dicts() if hasattr(df, "to_dicts") else [dict(zip(df.columns, row, strict=True)) for row in df.iter_rows()]


def run_sql_dataframe(sql: str, params: dict | None = None) -> pl.DataFrame:
    """Execute read-only SQL; returns Polars DataFrame (legacy)."""
    ok, err = is_safe_query(sql)
    if not ok:
        raise ValueError(err or "Unsafe query.")
    path = _get_duckdb_path()
    conn = duckdb.connect(path)
    if params:
        return conn.execute(sql, params).pl()
    return conn.execute(sql).pl()


# -----------------------------------------------------------------------------
# Ibis expression API (optional: extra data)
# -----------------------------------------------------------------------------


def ibis_duckdb_connect(path: str = DUCKDB_MEMORY):
    """Return Ibis backend for DuckDB. Requires: uv sync --extra data."""
    try:
        import ibis

        return ibis.duckdb.connect(path)
    except ImportError as e:
        raise ImportError(
            "ibis_duckdb_connect requires ibis-framework[duckdb]; uv sync --extra data"
        ) from e


def ibis_table(con, name: str):
    """Return Ibis table from connection by name."""
    return con.table(name)


# -----------------------------------------------------------------------------
# Table operations (select, filter, join, aggregate)
# -----------------------------------------------------------------------------


def ibis_select(table, *columns):
    """Select columns (Ibis expression)."""
    return table.select(*columns)


def ibis_filter(table, predicate):
    """Filter (WHERE): predicate is an Ibis expression."""
    return table.filter(predicate)


def ibis_join(left, right, predicates, how: str = "inner"):
    """Join two Ibis tables. how: inner, left, right, outer."""
    return left.join(right, predicates, how=how)


def ibis_aggregate(table, group_by, metrics):
    """Group by and aggregate (metrics: dict name -> expression)."""
    if not isinstance(metrics, dict):
        metrics = {}
    return table.group_by(group_by).aggregate(**metrics)


# -----------------------------------------------------------------------------
# SQL generation
# -----------------------------------------------------------------------------


def ibis_to_sql(expr) -> str:
    """Compile Ibis expression to SQL string."""
    return str(expr.compile())


# -----------------------------------------------------------------------------
# Window functions
# -----------------------------------------------------------------------------


def ibis_window(_table, order_by, window_preceding=None, window_following=None):
    """Window spec for Ibis (order_by and preceding/following). Table not used in ibis.window()."""
    import ibis

    return ibis.window(
        order_by=order_by, preceding=window_preceding, following=window_following
    )


def ibis_row_number(tbl, order_by):
    """Row number by order_by."""
    return tbl.order_by(order_by).row_number()


# -----------------------------------------------------------------------------
# Ibis expression execution and builders (extra: data)
# -----------------------------------------------------------------------------


def execute_ibis_expr(expr) -> list[dict]:
    """Compile Ibis expression to SQL and execute; return list[dict]."""
    sql = str(expr.compile())
    return run_sql(sql)


def build_select(table, columns, filters=None):
    """Build Ibis select with optional filter. columns: list of column refs or names."""
    t = table.select(*columns) if columns else table
    if filters is not None:
        t = t.filter(filters)
    return t


def build_join(left, right, on, how: str = "inner"):
    """Build Ibis join. on: column name(s) or predicate expression."""
    return left.join(right, on, how=how)


def build_aggregate(table, group_by, agg_funcs: dict):
    """Build Ibis aggregate: group_by list, agg_funcs dict name -> expression."""
    return table.group_by(group_by).aggregate(**agg_funcs)
