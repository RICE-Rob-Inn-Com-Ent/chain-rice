"""SciPy optimization — scalar/vector minimization, curve fit, roots, LP/NLP, optional Mojo hooks."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import time
from collections.abc import Callable, Iterable, Sequence
from dataclasses import dataclass, field
from typing import Any, Literal, TypeAlias

import numpy as np
from loguru import logger
from numpy.typing import NDArray
from scipy import optimize

from . import const
from .array import RiceArray

ObjectiveFn: TypeAlias = Callable[[NDArray[np.floating]], float]
VectorFn: TypeAlias = Callable[[NDArray[np.floating]], NDArray[np.floating]]

_OBJECTIVES: dict[str, ObjectiveFn] = {}


def register_objective(name: str, fn: ObjectiveFn) -> None:
    """Register a named scalar objective ``f(x) -> float`` for :func:`minimize_func`."""
    _OBJECTIVES[name.strip()] = fn


def _as_vec(x: RiceArray | NDArray[np.floating]) -> NDArray[np.floating]:
    return x.data if isinstance(x, RiceArray) else np.asarray(x, dtype=np.float64).ravel()


def _rice_vec(x: NDArray[np.floating]) -> RiceArray:
    return RiceArray(np.ascontiguousarray(x, dtype=np.float64), copy=False)


def minimized_parameters(result: optimize.OptimizeResult) -> RiceArray:
    """Wrap ``OptimizeResult.x`` as a :class:`RiceArray` after :func:`minimize_func` / :func:`minimize_nlp`."""
    return _rice_vec(np.asarray(result.x, dtype=np.float64))


def _log_opt(
    op: str,
    t0: float,
    *,
    success: bool | None = None,
    nit: int | None = None,
    fun: float | None = None,
    message: str = "",
    extra: str = "",
) -> None:
    logger.info(
        "optimize op={} wall_ms={:.2f} success={} nit={} fun={} {} {}",
        op,
        (time.perf_counter() - t0) * 1000,
        success,
        nit,
        fun,
        message,
        extra,
    )


def _maybe_mojo_eval_vector(
    kernel_hint: str | None,
    x: NDArray[np.floating],
    *,
    lib: str | None = None,
) -> None:
    """Probe ``bridge.get_kernel`` for an objective/gradient symbol (execution ABI TBD)."""
    if not kernel_hint:
        return
    try:
        from .bridge import KernelNotFoundError, get_kernel

        get_kernel(lib or const.RICE_MOJO_ARRAY_LIB, kernel_hint, n_buffers=1)
    except KernelNotFoundError:
        logger.debug("optimize Mojo kernel {} not registered", kernel_hint)
        return
    logger.info(
        "Mojo kernel {} present for n={} — native loop offload not wired; SciPy evaluates on host",
        kernel_hint,
        x.size,
    )


# --- Minimization ---------------------------------------------------------------------


@dataclass(slots=True)
class EarlyStoppingConfig:
    """Tighten SciPy tolerances / iteration caps (practical early-stop control for ``minimize``)."""

    ftol: float = 1e-9
    gtol: float = 1e-8
    maxiter: int = 500


def early_stopping(*, ftol: float = 1e-9, gtol: float = 1e-8, maxiter: int = 500) -> dict[str, Any]:
    """Return ``options`` dict to merge into :func:`scipy.optimize.minimize` ``options``."""
    return {"ftol": ftol, "gtol": gtol, "maxiter": maxiter}


def minimize_func(
    func_name: str,
    x0: RiceArray | NDArray[np.floating],
    *,
    fun: ObjectiveFn | None = None,
    method: Literal["L-BFGS-B", "Nelder-Mead", "BFGS", "SLSQP", "trust-constr"] = "L-BFGS-B",
    jac: VectorFn | None = None,
    hess: Any = None,
    bounds: Sequence[tuple[float | None, float | None]] | None = None,
    constraints: Sequence[dict[str, Any] | Any] | None = None,
    options: dict[str, Any] | None = None,
    early: EarlyStoppingConfig | None = None,
    parallel_starts: int = 0,
    x0_batch: Sequence[RiceArray | NDArray[np.floating]] | None = None,
    mojo_objective_kernel: str | None = None,
) -> optimize.OptimizeResult:
    """Minimize a named or inline objective; optional multi-start via :mod:`parallel` thread pool."""
    t0 = time.perf_counter()
    objective = fun if fun is not None else _OBJECTIVES.get(func_name.strip())
    if objective is None:
        msg = f"unknown objective {func_name!r}; pass ``fun=`` or call register_objective"
        raise KeyError(msg)

    def wrapped(x: NDArray[np.floating], *_a: Any, **_kw: Any) -> float:
        xv = np.asarray(x, dtype=np.float64).ravel()
        _maybe_mojo_eval_vector(mojo_objective_kernel, xv)
        return float(objective(xv))

    x_init = _as_vec(x0)
    merged = dict(options or {})
    if early:
        merged = {**early_stopping(ftol=early.ftol, gtol=early.gtol, maxiter=early.maxiter), **merged}
    opt = merged

    def _one_start(x_start: NDArray[np.floating]) -> optimize.OptimizeResult:
        return optimize.minimize(
            wrapped,
            x_start,
            method=method,
            jac=jac,
            hess=hess,
            bounds=bounds,
            constraints=constraints,
            options=opt or None,
        )

    if parallel_starts > 0 and x0_batch is not None and len(x0_batch) > 1:
        from .parallel import default_executor

        n_starts = min(int(parallel_starts), len(x0_batch))
        xs = [_as_vec(z) for z in x0_batch[:n_starts]]
        pool = default_executor().thread_pool
        results = list(pool.map(_one_start, xs))
        best = min(results, key=lambda r: float(r.fun))
        _log_opt(
            "minimize_func",
            t0,
            success=bool(best.success),
            nit=int(best.nit) if getattr(best, "nit", None) is not None else None,
            fun=float(best.fun),
            message=str(best.message),
            extra=f"method={method!r} multi_start={len(results)}",
        )
        return best

    res = _one_start(x_init)
    _log_opt(
        "minimize_func",
        t0,
        success=bool(res.success),
        nit=int(res.nit) if getattr(res, "nit", None) is not None else None,
        fun=float(res.fun),
        message=str(res.message),
        extra=f"method={method!r} name={func_name!r}",
    )
    return res


# --- Curve fitting --------------------------------------------------------------------


def fit_model(
    model_func: Callable[..., NDArray[np.floating]],
    x: RiceArray | NDArray[np.floating],
    y: RiceArray | NDArray[np.floating],
    *,
    p0: RiceArray | NDArray[np.floating] | None = None,
    use_mojo: bool = False,
    mojo_residual_kernel: str | None = None,
    **curve_fit_kw: Any,
) -> tuple[RiceArray, RiceArray]:
    """Non-linear least squares parameter fit; returns ``(popt, sigma_1d)`` as :class:`RiceArray`."""
    t0 = time.perf_counter()
    xd = np.asarray(_as_vec(x), dtype=np.float64).ravel()
    yd = np.asarray(_as_vec(y), dtype=np.float64).ravel()
    if xd.shape != yd.shape:
        msg = "x and y must broadcast to the same length"
        raise ValueError(msg)
    p0v = None if p0 is None else _as_vec(p0)
    if use_mojo or mojo_residual_kernel:
        _maybe_mojo_eval_vector(mojo_residual_kernel or "rice_opt_residual", xd)

    popt, pcov = optimize.curve_fit(
        lambda t, *p: np.asarray(model_func(t, *p), dtype=np.float64).ravel(),
        xd,
        yd,
        p0=p0v,
        **curve_fit_kw,
    )
    sigma = np.sqrt(np.maximum(np.diag(pcov), 0.0))
    _log_opt(
        "fit_model",
        t0,
        success=True,
        nit=None,
        fun=float(
            np.sum((np.asarray(model_func(xd, *popt), dtype=np.float64).ravel() - yd) ** 2),
        ),
        message="curve_fit",
        extra=f"p={len(popt)}",
    )
    return _rice_vec(np.asarray(popt, dtype=np.float64)), _rice_vec(np.asarray(sigma, dtype=np.float64))


# --- Root finding ---------------------------------------------------------------------


def find_root(
    func: Callable[[float], float] | Callable[[NDArray[np.floating]], NDArray[np.floating]],
    bracket: tuple[float, float] | tuple[NDArray[np.floating], NDArray[np.floating]],
    *,
    method: str = "brentq",
    x0: RiceArray | NDArray[np.floating] | None = None,
) -> Any:
    """Scalar root on an interval (``root_scalar``) or vector ``root`` when ``x0`` is given."""
    t0 = time.perf_counter()
    if x0 is not None:
        x_init = _as_vec(x0)
        res = optimize.root(lambda z: np.asarray(func(z), dtype=np.float64).ravel(), x_init)
        _log_opt("find_root", t0, success=bool(res.success), nit=res.nit, fun=float(np.linalg.norm(res.fun)), message=str(res.message), extra="vector")
        return res
    a, b = bracket[0], bracket[1]
    if isinstance(a, np.ndarray) or isinstance(b, np.ndarray):
        msg = "scalar bracket requires two floats unless x0 is provided for vector root"
        raise TypeError(msg)
    res = optimize.root_scalar(func, bracket=(float(a), float(b)), method=method)
    _log_opt(
        "find_root",
        t0,
        success=bool(getattr(res, "converged", True)),
        nit=getattr(res, "iterations", None),
        fun=float(res.function_calls) if hasattr(res, "function_calls") else None,
        message=str(res.flag),
        extra="scalar",
    )
    return res


# --- Constraints (NLP / LP skeleton) ------------------------------------------------


@dataclass
class ConstraintSet:
    """Collect bounds / inequalities for :func:`scipy.optimize.minimize` (``SLSQP`` / ``trust-constr``)."""

    _entries: list[tuple[str, Any]] = field(default_factory=list)

    def add_constraint(self, typ: Literal["bound", "linear_ineq", "linear_eq", "nonlinear_ineq", "nonlinear_eq"], formula: Any) -> ConstraintSet:
        """Append a constraint specification.

        - ``bound``: ``(var_index, low, high)`` per coordinate of ``x``.
        - ``linear_ineq``: ``(A_ub, b_ub)`` with ``A_ub @ x <= b_ub``.
        - ``linear_eq``: ``(A_eq, b_eq)``.
        - ``nonlinear_*``: SciPy dict ``{'type': 'ineq'|'eq', 'fun': callable}``-compatible mapping.
        """
        self._entries.append((typ, formula))
        return self

    def to_bounds(self, n: int) -> list[tuple[float | None, float | None]] | None:
        bds: list[tuple[float | None, float | None]] = [(None, None)] * n
        found = False
        for typ, formula in self._entries:
            if typ != "bound":
                continue
            i, lo, hi = formula
            found = True
            ii = int(i)
            bds[ii] = (lo, hi)
        return bds if found else None

    def to_minimize_constraints(self) -> list[dict[str, Any]]:
        out: list[dict[str, Any]] = []
        for typ, formula in self._entries:
            if typ == "linear_ineq":
                a, b = formula
                out.append({"type": "ineq", "fun": lambda x, A=np.asarray(a), bb=np.asarray(b): bb - A @ x})
            elif typ == "linear_eq":
                a, b = formula
                out.append({"type": "eq", "fun": lambda x, A=np.asarray(a), bb=np.asarray(b): A @ x - bb})
            elif typ.startswith("nonlinear"):
                if isinstance(formula, dict):
                    out.append(formula)
        return out


def add_constraint(
    cs: ConstraintSet,
    typ: Literal["bound", "linear_ineq", "linear_eq", "nonlinear_ineq", "nonlinear_eq"],
    formula: Any,
) -> ConstraintSet:
    """Functional façade over :meth:`ConstraintSet.add_constraint` (fluent chaining)."""
    return cs.add_constraint(typ, formula)


def minimize_nlp(
    fun: ObjectiveFn,
    x0: RiceArray | NDArray[np.floating],
    *,
    constraints: ConstraintSet | None = None,
    method: Literal["SLSQP", "trust-constr"] = "SLSQP",
    jac: VectorFn | None = None,
    options: dict[str, Any] | None = None,
) -> optimize.OptimizeResult:
    """Non-linear program with optional :class:`ConstraintSet` (converted to SciPy dict constraints)."""
    t0 = time.perf_counter()
    xv = _as_vec(x0)
    n = xv.size
    bds = constraints.to_bounds(n) if constraints else None
    cons_list = constraints.to_minimize_constraints() if constraints else []
    res = optimize.minimize(
        fun,
        xv,
        method=method,
        bounds=bds,
        constraints=cons_list if cons_list else None,
        jac=jac,
        options=options,
    )
    _log_opt("minimize_nlp", t0, success=bool(res.success), nit=getattr(res, "nit", None), fun=float(res.fun), message=str(res.message), extra=method)
    return res


def linprog_simple(
    c: NDArray[np.floating] | RiceArray,
    *,
    Aub: NDArray[np.floating] | RiceArray | None = None,
    bub: NDArray[np.floating] | RiceArray | None = None,
    bounds: list[tuple[float | None, float | None]] | None = None,
) -> optimize.OptimizeResult:
    """Linear program: minimize ``c @ x`` subject to ``A_ub x <= b_ub`` (skeleton)."""
    t0 = time.perf_counter()
    cc = _as_vec(c) if isinstance(c, RiceArray) else np.asarray(c, dtype=np.float64).ravel()
    aub = None if Aub is None else (Aub.data if isinstance(Aub, RiceArray) else np.asarray(Aub, dtype=np.float64))
    bubv = None if bub is None else (bub.data if isinstance(bub, RiceArray) else np.asarray(bub, dtype=np.float64).ravel())
    res = optimize.linprog(cc, A_ub=aub, b_ub=bubv, bounds=bounds)
    _log_opt("linprog_simple", t0, success=bool(res.success), nit=res.nit, fun=float(res.fun), message=str(res.message), extra="LP")
    return res


# --- Refinements ----------------------------------------------------------------------


def stochastic_optimizer(
    loss_fn: Callable[[RiceArray, NDArray[np.floating]], float],
    x0: RiceArray,
    data_batches: Iterable[NDArray[np.floating]],
    *,
    learning_rate: float = 0.01,
    epochs: int = 5,
    finite_diff_eps: float = 1e-5,
    seed: int | None = 0,
) -> RiceArray:
    """Minimal SGD-style loop with coordinate finite-difference gradients (skeleton for AI workloads)."""
    t0 = time.perf_counter()
    x = _as_vec(x0).copy()
    rng = np.random.default_rng(seed)
    batches = list(data_batches)
    if not batches:
        msg = "data_batches must be non-empty"
        raise ValueError(msg)
    rng.shuffle(batches)
    for _ in range(epochs):
        for batch in batches:
            b = np.asarray(batch, dtype=np.float64)
            grad = np.zeros_like(x)
            base = float(loss_fn(_rice_vec(x), b))
            for i in range(x.size):
                xp = x.copy()
                xp[i] += finite_diff_eps
                grad[i] = (float(loss_fn(_rice_vec(xp), b)) - base) / finite_diff_eps
            x -= learning_rate * grad
    _log_opt("stochastic_optimizer", t0, success=True, nit=epochs * len(batches), fun=None, message="SGD skeleton", extra=f"dim={x.size}")
    return _rice_vec(x)


# --- Legacy ---------------------------------------------------------------------------


def minimize_scalar_bounded(
    fun: Callable[[float], float],
    bounds: tuple[float, float],
    *,
    method: str = "bounded",
) -> optimize.OptimizeResult:
    t0 = time.perf_counter()
    res = optimize.minimize_scalar(fun, bounds=bounds, method=method)
    _log_opt("minimize_scalar_bounded", t0, success=bool(res.success), nit=getattr(res, "nit", None), fun=float(res.fun), message="", extra=method)
    return res


def minimize_vector(
    fun: Callable[[NDArray[np.floating]], float],
    x0: NDArray[np.floating] | RiceArray,
    *,
    method: str | None = "BFGS",
    bounds: Any = None,
) -> optimize.OptimizeResult:
    t0 = time.perf_counter()
    xv = _as_vec(x0) if isinstance(x0, RiceArray) else np.asarray(x0, dtype=np.float64).ravel()
    m = method or "BFGS"
    res = optimize.minimize(fun, xv, method=m, bounds=bounds)
    _log_opt(
        "minimize_vector",
        t0,
        success=bool(res.success),
        nit=getattr(res, "nit", None),
        fun=float(res.fun),
        message=str(res.message),
        extra=f"method={m!r}",
    )
    return res


def curve_fit_model(
    f: Callable[..., Any],
    xdata: NDArray[np.floating],
    ydata: NDArray[np.floating],
    p0: NDArray[np.floating] | None = None,
) -> tuple[NDArray[np.floating], NDArray[np.floating]]:
    """Legacy ndarray return type; prefer :func:`fit_model` + :class:`RiceArray`."""
    popt, pcov = optimize.curve_fit(f, xdata, ydata, p0=p0)
    return popt, pcov


def find_root_scalar(
    fun: Callable[[float], float],
    bracket: tuple[float, float],
) -> Any:
    return find_root(fun, bracket)


__all__ = [
    "ConstraintSet",
    "EarlyStoppingConfig",
    "add_constraint",
    "minimized_parameters",
    "curve_fit_model",
    "early_stopping",
    "find_root",
    "find_root_scalar",
    "fit_model",
    "linprog_simple",
    "minimize_func",
    "minimize_nlp",
    "minimize_scalar_bounded",
    "minimize_vector",
    "register_objective",
    "stochastic_optimizer",
]
