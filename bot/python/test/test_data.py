"""Tests for data layer (Polars, DuckDB, Ibis): models, is_safe_query, run_sql."""

import pytest

from data.models import QueryResult, TableConfig
from data.query import is_safe_query, run_sql


def test_data_models() -> None:
    """Data models are importable."""
    c = TableConfig(name="t", columns={})
    assert c.name == "t"
    q = QueryResult(row_count=0, column_names=[], success=True)
    assert q.success


def test_is_safe_query() -> None:
    """Safe query accepts SELECT, rejects destructive."""
    assert is_safe_query("SELECT 1")[0] is True
    assert is_safe_query("DROP TABLE x")[0] is False


def test_run_sql() -> None:
    """run_sql executes read-only SQL and returns list[dict]."""
    rows = run_sql("SELECT 1 AS n")
    assert isinstance(rows, list)
    assert len(rows) == 1
    assert rows[0].get("n") == 1


def test_run_sql_blocks_destructive() -> None:
    """run_sql blocks DROP/DELETE."""
    with pytest.raises(ValueError, match="not allowed|Unsafe"):
        run_sql("DROP TABLE foo")
