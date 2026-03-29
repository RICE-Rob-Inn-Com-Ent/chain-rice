"""Unit: `function/job` — Polars, scipy stats, optimize."""

from __future__ import annotations

import numpy as np
import polars as pl
import pytest

from function.job.frame import empty_frame, from_rows
from function.job.stats import describe_sample
from function.job.optimize import minimize_scalar_bounded

# TODO:
# [ ] test frame lazy evaluation: LazyFrame not collected until .collect()
# [ ] test ingest CSV: returns expected schema and row count
# [ ] test transform normalization: min=0, max=1 after min-max scaling
# [ ] test stats descriptive: mean, std within expected range for synthetic data
# [ ] test pipeline composition: Pipeline(source).transform(f).export(sink) runs end-to-end
# [ ] test export parquet: written file readable with correct schema
# [ ] test bridge: numpy array passed to Mojo kernel, result returned as numpy
# [ ] benchmark(mojo): Mojo matrix multiply faster than numpy for n>RICE_MOJO_THRESHOLD
# [ ] test signal FFT: fft(ifft(x)) ≈ x within tolerance
# [ ] test optimize minimize: finds minimum of convex function


def test_empty_frame() -> None:
    df = empty_frame({"a": pl.Float64, "b": pl.Int32})
    assert df.height == 0
    assert df.columns == ["a", "b"]


def test_from_rows() -> None:
    df = from_rows([{"a": 1, "b": 2}, {"a": 3, "b": 4}])
    assert df.height == 2


def test_describe_sample() -> None:
    d = describe_sample(np.array([1.0, 2.0, 3.0, 4.0], dtype=np.float64))
    assert d.mean == pytest.approx(2.5)


def test_minimize_scalar_bounded() -> None:
    res = minimize_scalar_bounded(lambda x: (x - 2.0) ** 2, bounds=(0.0, 5.0))
    assert res.success
    assert abs(res.x - 2.0) < 0.01
