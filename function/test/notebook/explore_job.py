"""Marimo: Polars — `marimo edit function/test/notebook/explore_job.py`."""

from __future__ import annotations

from typing import Any

import marimo

# TODO:
# [ ] marimo cell: load synthetic Polars DataFrame, show schema
# [ ] marimo cell: interactive pipeline builder — add/remove transforms
# [ ] marimo cell: benchmark Mojo kernel vs numpy — bar chart
# [ ] marimo cell: FFT visualization — signal + spectrum side by side
# [ ] marimo cell: optimization convergence plot

__generated_with = "0.10.0"
app = marimo.App()


@app.cell
def intro() -> Any:
    import marimo as mo

    return mo.md("# Job / Polars")


@app.cell
def run_frame() -> Any:
    import polars as pl

    from function.job.frame import from_rows

    df = from_rows([{"x": 1}, {"x": 2}])
    return df.select(pl.col("x").sum())
