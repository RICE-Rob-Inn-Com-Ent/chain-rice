"""Data layer facade for app module.

Re-exports key functions from data/ to avoid direct imports across modules.
This maintains clean dependency boundaries. All data operations go through
this facade when used by app (main, tools, agent).
"""

from __future__ import annotations

from data.compute import calculate_stats, run_optimization
from data.query import is_safe_query, run_sql
from data.tables import load_parquet, process_ipc_stream, save_parquet

__all__ = [
    "run_sql",
    "is_safe_query",
    "load_parquet",
    "save_parquet",
    "process_ipc_stream",
    "calculate_stats",
    "run_optimization",
]
