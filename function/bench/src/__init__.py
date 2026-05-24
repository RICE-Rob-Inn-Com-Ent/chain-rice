"""Bench workspace root package ``src`` (use when ``function/bench`` is on ``PYTHONPATH``).

If only ``function/bench/src`` is on the path, import the implementation as ``import bench`` instead.

This barrel exists so ``from src import run_all`` matches the repo folder name ``bench/src``.
"""

from __future__ import annotations

from .bench import (
    TimingSample,
    bench_call,
    format_table,
    main,
    run_agent_benchmarks,
    run_all,
    run_helper_benchmarks,
    run_job_benchmarks,
    run_simulation_benchmarks,
    run_vector_benchmarks,
)

__all__ = [
    "TimingSample",
    "bench_call",
    "format_table",
    "main",
    "run_agent_benchmarks",
    "run_all",
    "run_helper_benchmarks",
    "run_job_benchmarks",
    "run_simulation_benchmarks",
    "run_vector_benchmarks",
]
