"""NumPy + SciPy: numerical computing, math, stats, optimization, signal.

Provides array operations, linear algebra, statistics, optimization (minimize,
curve_fit), FFT, convolution, interpolation. Requires: numpy, scipy (extra data).
Install with: uv sync --extra data

Heavy kernels are implemented in .devcontainer/bot/mojo/ (linalg, stats, fft,
optimize, simulate). Build with: pixi run build-kernels (from bot dir). When
RICE_USE_MOJO_KERNELS=1 and bin/sim_engine (and future libs) exist, hot paths
will call into Mojo-built artifacts; otherwise NumPy/SciPy are used.
"""

from __future__ import annotations

import os
from pathlib import Path

# -----------------------------------------------------------------------------
# Mojo kernel wiring (mise + pixi from .tool-versions; kernels under bot/mojo)
# -----------------------------------------------------------------------------


def _mojo_bin_dir() -> Path | None:
    """Path to bot/bin (Mojo-built binaries). None if not under bot layout."""
    try:
        # Resolve bot root: this file is bot/data/compute.py
        here = Path(__file__).resolve()
        if "bot" in here.parts:
            idx = list(here.parts).index("bot")
            bot_root = Path(*here.parts[: idx + 1])
            return bot_root / "bin"
    except (OSError, ValueError, IndexError):
        pass
    return None


def _use_mojo_kernels() -> bool:
    """True if Mojo kernels should be used (env + bin/sim_engine present)."""
    if os.environ.get("RICE_USE_MOJO_KERNELS", "").strip() != "1":
        return False
    bin_dir = _mojo_bin_dir()
    if bin_dir is None:
        return False
    return (bin_dir / "sim_engine").exists()


# -----------------------------------------------------------------------------
# NumPy array operations
# -----------------------------------------------------------------------------


def _np():
    """Lazy import of numpy. Raises ImportError with install hint if missing."""
    try:
        import numpy as np
        return np
    except ImportError as e:
        raise ImportError(
            "compute requires numpy; install: uv sync --extra data"
        ) from e


def _scipy():
    """Lazy import of scipy. Raises ImportError with install hint if missing."""
    try:
        import scipy
        return scipy
    except ImportError as e:
        raise ImportError(
            "compute (scipy) requires scipy; install: uv sync --extra data"
        ) from e


def zeros(shape, dtype=None):
    """Return array of zeros with given shape and optional dtype."""
    return _np().zeros(shape, dtype=dtype)


def norm(x, order=None, axis=None):
    """Vector or matrix norm (order: np.inf, -np.inf, 1, 2, 'fro', etc.)."""
    return _np().linalg.norm(x, ord=order, axis=axis)


def dot(a, b):
    """Dot product or matrix multiplication."""
    return _np().dot(a, b)


def matrix_inv(a):
    """Matrix inverse."""
    return _np().linalg.inv(a)


# -----------------------------------------------------------------------------
# SciPy scientific functions (stats, optimization, linear algebra)
# -----------------------------------------------------------------------------


def stats_mean(x, axis=None):
    """Mean along axis (numpy/scipy)."""
    np = _np()
    return np.mean(x, axis=axis)


def stats_std(x, axis=None, ddof=0):
    """Standard deviation along axis (ddof: delta degrees of freedom)."""
    np = _np()
    return np.std(x, axis=axis, ddof=ddof)


def optimize_minimize(fun, x0, method: str = "BFGS", **kwargs):
    """Minimize scalar function (scipy.optimize.minimize). Returns OptimizeResult."""
    from scipy.optimize import minimize
    return minimize(fun, x0, method=method, **kwargs)


def linear_algebra_solve(a, b):
    """Solve linear system a @ x = b. Returns x."""
    np = _np()
    return np.linalg.solve(a, b)


def eig(a):
    """Eigenvalues and eigenvectors of matrix."""
    np = _np()
    return np.linalg.eig(a)


# -----------------------------------------------------------------------------
# Matrix computations
# -----------------------------------------------------------------------------


def qr(a):
    """QR decomposition of matrix."""
    np = _np()
    return np.linalg.qr(a)


def svd(a, full_matrices=True):
    """Singular value decomposition."""
    np = _np()
    return np.linalg.svd(a, full_matrices=full_matrices)


# -----------------------------------------------------------------------------
# Signal processing
# -----------------------------------------------------------------------------


def fft(x, axis=-1):
    """Fast Fourier transform (numpy)."""
    np = _np()
    return np.fft.fft(x, axis=axis)


def fftfreq(n, d=1.0):
    """FFT frequency bins for length n and sample spacing d."""
    np = _np()
    return np.fft.fftfreq(n, d=d)


def convolve(a, v, mode="full"):
    """1D convolution (numpy). mode: full, valid, same."""
    np = _np()
    return np.convolve(a, v, mode=mode)


# -----------------------------------------------------------------------------
# Interpolation and curve fitting
# -----------------------------------------------------------------------------


def interp1d(x, y, kind="linear", fill_value="extrapolate"):
    """1D interpolation (scipy.interpolate.interp1d). Returns callable interpolator."""
    from scipy.interpolate import interp1d as scipy_interp1d
    return scipy_interp1d(x, y, kind=kind, fill_value=fill_value)


def curve_fit(f, xdata, ydata, p0=None, **kwargs):
    """Curve fitting (scipy.optimize.curve_fit). f: model function, p0: initial params."""
    from scipy.optimize import curve_fit as scipy_curve_fit
    return scipy_curve_fit(f, xdata, ydata, p0=p0, **kwargs)


# -----------------------------------------------------------------------------
# Custom numerical algorithms (finite-difference gradient)
# -----------------------------------------------------------------------------


def numerical_gradient(f, x, eps=1e-7):
    """Numerical gradient via central finite difference. Returns gradient array."""
    np = _np()
    x = np.asarray(x, dtype=float)
    g = np.zeros_like(x)
    for i in range(x.size):
        x_plus = x.copy()
        x_plus.flat[i] += eps
        x_minus = x.copy()
        x_minus.flat[i] -= eps
        g.flat[i] = (f(x_plus) - f(x_minus)) / (2 * eps)
    return g


# -----------------------------------------------------------------------------
# Summary statistics and time series (calculate_stats, moving_average, etc.)
# -----------------------------------------------------------------------------


def calculate_stats(array) -> dict:
    """Compute summary statistics for array: mean, std, quantiles, min, max, count."""
    np = _np()
    arr = np.asarray(array, dtype=float).ravel()
    if arr.size == 0:
        return {"count": 0, "mean": None, "std": None, "min": None, "max": None, "q25": None, "q50": None, "q75": None}
    return {
        "count": int(arr.size),
        "mean": float(np.mean(arr)),
        "std": float(np.std(arr)),
        "min": float(np.min(arr)),
        "max": float(np.max(arr)),
        "q25": float(np.quantile(arr, 0.25)),
        "q50": float(np.quantile(arr, 0.5)),
        "q75": float(np.quantile(arr, 0.75)),
    }


def correlation_matrix(data) -> "np.ndarray":
    """Compute correlation matrix of 2D array (rows = vars, cols = obs) or list of 1D arrays."""
    np = _np()
    arr = np.asarray(data)
    if arr.ndim == 1:
        arr = arr.reshape(1, -1)
    return np.corrcoef(arr)


def moving_average(series, window: int):
    """Moving average of 1D series with given window size. Returns numpy array."""
    np = _np()
    s = np.asarray(series, dtype=float).ravel()
    if window <= 0 or len(s) < window:
        return s
    return np.convolve(s, np.ones(window) / window, mode="valid")


def minimize_function(fun, x0, bounds=None, method: str = "BFGS", **kwargs):
    """Minimize scalar function. Wrapper for scipy.optimize.minimize. Returns OptimizeResult."""
    from scipy.optimize import minimize
    return minimize(fun, x0, method=method, bounds=bounds, **kwargs)


def solve_linear_system(A, b):
    """Solve A @ x = b. Returns x."""
    return linear_algebra_solve(A, b)


def eigendecomposition(matrix) -> tuple:
    """Eigendecomposition: (eigenvalues, eigenvectors)."""
    evals, evecs = eig(matrix)
    return evals, evecs


def fft_transform(signal, axis: int = -1):
    """FFT of signal. Returns complex array."""
    return fft(signal, axis=axis)


def filter_signal(signal, cutoff_freq: float, method: str = "lowpass", sampling_freq: float = 1.0):
    """Simple 1D filter (moving average as lowpass). For full filter use scipy.signal."""
    np = _np()
    s = np.asarray(signal, dtype=float).ravel()
    if method == "lowpass" and cutoff_freq > 0 and sampling_freq > 0:
        # Approximate: window size ~ sampling_freq / cutoff_freq
        window = max(1, int(sampling_freq / cutoff_freq))
        return moving_average(s, window)
    return s


def interpolate_1d(x, y, x_new, kind: str = "linear"):
    """Interpolate y at x_new from (x, y). kind: linear, cubic, etc."""
    from scipy.interpolate import interp1d as scipy_interp1d
    f = scipy_interp1d(x, y, kind=kind, fill_value="extrapolate")
    return f(x_new)


def run_optimization(fun, x0, method: str = "BFGS", bounds=None, **kwargs):
    """Run optimization (minimize). Returns OptimizeResult."""
    return minimize_function(fun, x0, bounds=bounds, method=method, **kwargs)
