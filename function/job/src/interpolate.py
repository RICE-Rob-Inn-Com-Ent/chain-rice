"""SciPy — interpolacja: splajny, griddata, RBF."""

from __future__ import annotations

import numpy as np
from numpy.typing import NDArray
from scipy.interpolate import RBFInterpolator, griddata, interp1d

# TODO:
# [ ] implement 1D interpolation via scipy.interpolate:
# [ ]     interp1d, CubicSpline, Akima1DInterpolator, PCHIP
# [ ]     method from RICE_INTERP_METHOD env var
# [ ] implement 2D interpolation: RectBivariateSpline, griddata
# [ ] implement ND interpolation: RegularGridInterpolator
# [ ] implement extrapolation control:
# [ ]     bounds_error, fill_value from config — never hardcoded
# [ ] implement time series resampling via interpolation:
# [ ]     target frequency from RICE_RESAMPLE_FREQ env var


def interp_1d_linear(
    x: NDArray[np.floating],
    y: NDArray[np.floating],
    xnew: NDArray[np.floating],
) -> NDArray[np.floating]:
    """Interpolacja 1D (kind='linear')."""
    f = interp1d(x, y, kind="linear", bounds_error=False, fill_value="extrapolate")
    return f(xnew)


def griddata_points(
    points: NDArray[np.floating],
    values: NDArray[np.floating],
    xi: tuple[NDArray[np.floating], ...] | NDArray[np.floating],
    *,
    method: str = "linear",
) -> NDArray[np.floating]:
    """Interpolacja na siatce (2D/ND)."""
    return griddata(points, values, xi, method=method)


def rbf_interpolate(
    points: NDArray[np.floating],
    values: NDArray[np.floating],
    *,
    kernel: str = "thin_plate_spline",
    epsilon: float | None = None,
) -> RBFInterpolator:
    """`points` (n, dim), `values` (n,) lub (n, k) — predykcja: `instance(xnew)`."""
    return RBFInterpolator(points, values, kernel=kernel, epsilon=epsilon)
