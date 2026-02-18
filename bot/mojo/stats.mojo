"""
Statistics kernels (from data/compute.py).
Entry points: calculate_stats (mean, std, min, max, quantiles), correlation_matrix, moving_average.
"""

fn mean_scalar(a: Float64, b: Float64) -> Float64:
    """Mean of two values. Extend to NDArray for full calculate_stats."""
    return (a + b) / 2.0
