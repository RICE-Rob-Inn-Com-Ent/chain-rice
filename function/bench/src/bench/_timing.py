"""Shared micro-benchmark helpers (``time.perf_counter``, no extra deps)."""

from __future__ import annotations

import math
import time
from collections.abc import Callable
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class TimingSample:
    """One benchmark: ``seconds_mean`` over ``iterations`` after ``warmup`` discarded runs."""

    name: str
    seconds_mean: float
    seconds_stdev: float
    iterations: int
    warmup: int
    note: str = ""

    @property
    def ms_mean(self) -> float:
        return self.seconds_mean * 1000.0


def bench_call(
    name: str,
    fn: Callable[[], object],
    *,
    repeat: int = 7,
    warmup: int = 2,
    note: str = "",
) -> TimingSample:
    """Time ``fn``; each iteration is one full call (amortize setup outside via closure)."""
    for _ in range(warmup):
        fn()
    times: list[float] = []
    for _ in range(repeat):
        t0 = time.perf_counter()
        fn()
        times.append(time.perf_counter() - t0)
    mean = sum(times) / len(times)
    if len(times) > 1:
        var = sum((x - mean) ** 2 for x in times) / (len(times) - 1)
        stdev = math.sqrt(var)
    else:
        stdev = 0.0
    return TimingSample(
        name=name,
        seconds_mean=mean,
        seconds_stdev=stdev,
        iterations=repeat,
        warmup=warmup,
        note=note,
    )


def format_table(samples: list[TimingSample]) -> str:
    """Fixed-width table for stdout / logs."""
    if not samples:
        return "(no samples)\n"
    name_w = max(len(s.name) for s in samples)
    lines = [
        f"{'benchmark':<{name_w}}  {'mean_ms':>10}  {'std_ms':>10}  note",
        f"{'-' * name_w}  {'-' * 10}  {'-' * 10}  ----",
    ]
    for s in samples:
        note = s.note or "-"
        lines.append(
            f"{s.name:<{name_w}}  {s.ms_mean:10.4f}  {s.seconds_stdev * 1000:10.4f}  {note}",
        )
    return "\n".join(lines) + "\n"
