"""Benchmarks for the ``job`` package (NumPy linear algebra paths)."""

from __future__ import annotations

import importlib

import numpy as np

from ._resolve import job_module
from ._timing import TimingSample, bench_call

_j = job_module()
_linalg = importlib.import_module(f"{_j.__name__}.linalg")


def run_job_benchmarks(*, repeat: int = 7, warmup: int = 2) -> list[TimingSample]:
    rng = np.random.default_rng(0)
    a = rng.standard_normal((256, 256), dtype=np.float64)
    b = rng.standard_normal((256, 256), dtype=np.float64)
    v = rng.standard_normal(256, dtype=np.float64)

    def dot_mv() -> None:
        _linalg.dot(a, v)

    def matmul_nn() -> None:
        _linalg.matmul(a, b)

    return [
        bench_call("job.linalg.dot (256x256 · 256)", dot_mv, repeat=repeat, warmup=warmup),
        bench_call("job.linalg.matmul (256³)", matmul_nn, repeat=repeat, warmup=warmup),
    ]
