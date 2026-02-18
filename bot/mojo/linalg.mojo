"""
Linear algebra kernels (from data/compute.py).
Entry points: dot, matrix_inv, linear_algebra_solve, eig, qr, svd, norm.
Python preserves the same API; this module is built as a library or called via simulate engine.
"""

fn norm_scalar(x: Float64) -> Float64:
    """Vector norm placeholder (single value). Extend to NDArray when wiring Python."""
    return x

fn dot_scalar(a: Float64, b: Float64) -> Float64:
    """Dot product placeholder. Extend to matrix multiply when using linalg/NDArray."""
    return a * b
