"""SAGE ``bench`` — micro-benchmarks for ``helper``, ``agent``, ``job``, ``vector``, ``simulation``.

Layout note: benchmarks live under the ``bench`` package inside ``function/bench/src/bench/`` so
filenames like ``helper.py`` do **not** shadow the real ``helper`` library on ``PYTHONPATH``.

Run all suites::

    python -m bench

Or import selectively::

    from bench import run_helper_benchmarks, format_table
"""

from __future__ import annotations

import argparse
import sys
from collections.abc import Callable
from typing import TextIO

from ._timing import TimingSample, bench_call, format_table

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


def run_helper_benchmarks(*, repeat: int = 7, warmup: int = 2) -> list[TimingSample]:
    from .helper import run_helper_benchmarks as _run

    return _run(repeat=repeat, warmup=warmup)


def run_agent_benchmarks(*, repeat: int = 7, warmup: int = 2) -> list[TimingSample]:
    from .agent import run_agent_benchmarks as _run

    return _run(repeat=repeat, warmup=warmup)


def run_job_benchmarks(*, repeat: int = 7, warmup: int = 2) -> list[TimingSample]:
    from .job import run_job_benchmarks as _run

    return _run(repeat=repeat, warmup=warmup)


def run_vector_benchmarks(*, repeat: int = 5, warmup: int = 1) -> list[TimingSample]:
    from .vector import run_vector_benchmarks as _run

    return _run(repeat=repeat, warmup=warmup)


def run_simulation_benchmarks(*, repeat: int = 7, warmup: int = 2) -> list[TimingSample]:
    from .simulation import run_simulation_benchmarks as _run

    return _run(repeat=repeat, warmup=warmup)


def run_all(*, repeat: int = 7, warmup: int = 2) -> list[TimingSample]:
    """Execute every suite in a fixed order; concatenates :class:`TimingSample` rows."""
    out: list[TimingSample] = []
    out.extend(run_helper_benchmarks(repeat=repeat, warmup=warmup))
    out.extend(run_agent_benchmarks(repeat=repeat, warmup=warmup))
    out.extend(run_job_benchmarks(repeat=repeat, warmup=warmup))
    out.extend(run_vector_benchmarks(repeat=max(3, repeat // 2), warmup=max(1, warmup // 2)))
    out.extend(run_simulation_benchmarks(repeat=repeat, warmup=warmup))
    return out


def main(argv: list[str] | None = None, *, stream: TextIO | None = None) -> int:
    parser = argparse.ArgumentParser(description="SAGE micro-benchmarks")
    parser.add_argument("--repeat", type=int, default=7, help="timed iterations per benchmark")
    parser.add_argument("--warmup", type=int, default=2, help="discarded iterations before timing")
    parser.add_argument(
        "--suite",
        choices=("all", "helper", "agent", "job", "vector", "simulation"),
        default="all",
    )
    args = parser.parse_args(argv)
    out = stream or sys.stdout

    runners: dict[str, Callable[..., list[TimingSample]]] = {
        "all": run_all,
        "helper": run_helper_benchmarks,
        "agent": run_agent_benchmarks,
        "job": run_job_benchmarks,
        "vector": run_vector_benchmarks,
        "simulation": run_simulation_benchmarks,
    }
    samples = runners[args.suite](repeat=args.repeat, warmup=args.warmup)

    out.write(format_table(samples))
    return 0
