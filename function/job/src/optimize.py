"""SciPy — optymalizacja: minimalizacja, dopasowanie krzywej, pierwiastki, LP."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from collections.abc import Callable
from typing import Any

import numpy as np
from numpy.typing import NDArray
from scipy import optimize

# TODO:
# [ ] implement scipy.optimize wrappers:
# [ ]     minimize: method from RICE_OPT_METHOD (default: L-BFGS-B)
# [ ]     minimize_scalar, curve_fit, least_squares
# [ ] implement JAX-based optimization:
# [ ]     jax.grad + optax optimizers (adam, sgd, adamw)
# [ ]     learning_rate from RICE_LR env var
# [ ]     n_steps from RICE_OPT_STEPS env var
# [ ] implement constraint optimization:
# [ ]     linear constraints via scipy.optimize.LinearConstraint
# [ ]     nonlinear constraints via scipy.optimize.NonlinearConstraint
# [ ] implement global optimization:
# [ ]     differential_evolution, dual_annealing, basinhopping
# [ ]     maxiter from RICE_GLOBAL_OPT_ITER env var
# [ ] implement Bayesian optimization via scikit-optimize or optuna
# [ ]     n_calls from RICE_BAYES_N_CALLS env var


def minimize_scalar_bounded(
    fun: Callable[[float], float],
    bounds: tuple[float, float],
    *,
    method: str = "bounded",
) -> optimize.OptimizeResult:
    return optimize.minimize_scalar(fun, bounds=bounds, method=method)


def minimize_vector(
    fun: Callable[[NDArray[np.floating]], float],
    x0: NDArray[np.floating],
    *,
    method: str | None = "BFGS",
    bounds: Any = None,
) -> optimize.OptimizeResult:
    return optimize.minimize(fun, x0, method=method, bounds=bounds)


def curve_fit_model(
    f: Callable[..., Any],
    xdata: NDArray[np.floating],
    ydata: NDArray[np.floating],
    p0: NDArray[np.floating] | None = None,
) -> tuple[NDArray[np.floating], NDArray[np.floating]]:
    popt, pcov = optimize.curve_fit(f, xdata, ydata, p0=p0)
    return popt, pcov


def find_root_scalar(
    fun: Callable[[float], float],
    bracket: tuple[float, float],
) -> Any:
    return optimize.root_scalar(fun, bracket=bracket)


def linprog_simple(
    c: NDArray[np.floating],
    *,
    Aub: NDArray[np.floating] | None = None,
    bub: NDArray[np.floating] | None = None,
    bounds: list[tuple[float | None, float | None]] | None = None,
) -> optimize.OptimizeResult:
    """Minimalizacja liniowa `c^T x` z ograniczeniami A_ub x <= b_ub."""
    return optimize.linprog(c, A_ub=Aub, b_ub=bub, bounds=bounds)
