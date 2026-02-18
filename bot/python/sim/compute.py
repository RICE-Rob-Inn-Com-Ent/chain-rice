"""JAX: arrays, JIT, grad, vmap, GPU physics, XLA. Requires: jax (extra sim).

Provides jax_array, jax_zeros, jit, jit_fun, grad_fun, vmap_fun, value_and_grad,
physics_step, quantum_expectation, configure_jax, check_gpu_availability, compute_gradient,
expectation_value, etc. Install with: uv sync --extra sim. English only.

Simulation hot path (statevector/expectation, particle step, ODE) can be offloaded
to Mojo kernels in .devcontainer/bot/mojo/simulate.mojo (binary: bin/sim_engine).
Set RICE_USE_MOJO_KERNELS=1 when built to use Mojo where wired.
"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path
from typing import Any

# -----------------------------------------------------------------------------
# Mojo kernel wiring (sim_engine from bot/mojo/simulate.mojo)
# -----------------------------------------------------------------------------


def _mojo_bin_dir() -> Path | None:
    """Path to bot/bin (Mojo-built sim_engine). None if not under bot layout."""
    try:
        here = Path(__file__).resolve()
        if "bot" in here.parts:
            idx = list(here.parts).index("bot")
            bot_root = Path(*here.parts[: idx + 1])
            return bot_root / "bin"
    except (OSError, ValueError, IndexError):
        pass
    return None


def _use_mojo_kernels() -> bool:
    """True if Mojo sim_engine should be used (env + binary present)."""
    if os.environ.get("RICE_USE_MOJO_KERNELS", "").strip() != "1":
        return False
    bin_dir = _mojo_bin_dir()
    if bin_dir is None:
        return False
    return (bin_dir / "sim_engine").exists()


def _run_sim_engine() -> dict[str, float] | None:
    """Run bin/sim_engine and parse stdout for numeric results. Returns None on failure."""
    if not _use_mojo_kernels():
        return None
    bin_dir = _mojo_bin_dir()
    if bin_dir is None:
        return None
    exe = bin_dir / "sim_engine"
    if not exe.exists():
        return None
    try:
        out = subprocess.run(
            [str(exe)],
            capture_output=True,
            text=True,
            timeout=5,
            cwd=bin_dir.parent,
            check=False,
        )
        if out.returncode != 0:
            return None
        # Parse "sim_engine (key): value" lines for future use
        result: dict[str, float] = {}
        for line in out.stdout.strip().splitlines():
            if ":" in line and "(" in line:
                part = line.split(":", 1)[1].strip()
                try:
                    result["value"] = float(part)
                except ValueError:
                    pass
        return result if result else None
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return None


# -----------------------------------------------------------------------------
# JAX arrays i transformations
# -----------------------------------------------------------------------------


def _jax():
    """Lazy import of JAX. Raises ImportError with install hint if missing."""
    try:
        import jax.numpy as jnp
        import jax

        return jax, jnp
    except ImportError as e:
        raise ImportError("compute requires jax; install: uv sync --extra sim") from e


def jax_array(x):
    """Convert to JAX array."""
    _, jnp = _jax()
    return jnp.array(x)


def jax_zeros(shape, dtype=None):
    """JAX array of zeros."""
    _, jnp = _jax()
    return jnp.zeros(shape, dtype=dtype)


# -----------------------------------------------------------------------------
# JIT compilation jobs
# -----------------------------------------------------------------------------


def jit(fun):
    """JIT-compile function (XLA)."""
    jax, _ = _jax()
    return jax.jit(fun)


def jit_fun(fun, *args, **kwargs):
    """Run function under JIT (first call compiles)."""
    return jit(fun)(*args, **kwargs)


# -----------------------------------------------------------------------------
# Gradient computations (grad, vmap)
# -----------------------------------------------------------------------------


def grad_fun(fun, argnums=0):
    """Gradient of function (jax.grad)."""
    jax, _ = _jax()
    return jax.grad(fun, argnums=argnums)


def vmap_fun(fun, in_axes=0, out_axes=0):
    """Vectorization (jax.vmap)."""
    jax, _ = _jax()
    return jax.vmap(fun, in_axes=in_axes, out_axes=out_axes)


def value_and_grad(fun, argnums=0):
    """Value and gradient (jax.value_and_grad)."""
    jax, _ = _jax()
    return jax.value_and_grad(fun, argnums=argnums)


# -----------------------------------------------------------------------------
# GPU-accelerated physics sims
# -----------------------------------------------------------------------------


def physics_step(state, dt: float, step_fn):
    """Single physics simulation step: (state, dt) -> step_fn(state, dt). step_fn is JIT-compiled."""
    return jit(step_fn)(state, dt)


# -----------------------------------------------------------------------------
# Integration z quantum simulations
# -----------------------------------------------------------------------------


def quantum_expectation(state, observable):
    """Expectation value <state|observable|state> (placeholder)."""
    jax, jnp = _jax()
    return jnp.real(jnp.sum(jnp.conj(state) * (observable @ state)))


# -----------------------------------------------------------------------------
# XLA optimization
# -----------------------------------------------------------------------------


def xla_compile(fun):
    """XLA compilation (jax.jit)."""
    return jit(fun)


def lower_to_hlo(fun, *args):
    """Lower function to HLO (for inspection). Returns compiled result."""
    return jit(fun)(*args)


# -----------------------------------------------------------------------------
# Spec API: configure_jax, check_gpu_availability, jit_compile, etc.
# -----------------------------------------------------------------------------


def configure_jax(platform: str = "cpu") -> None:
    """Set JAX platform (cpu, gpu, tpu)."""
    try:
        import jax
        jax.config.update("jax_platform_name", platform)
    except (ImportError, AttributeError):
        pass


def check_gpu_availability() -> bool:
    """Return True if JAX can use GPU."""
    try:
        import jax
        return str(jax.devices()[0].platform) == "gpu"
    except Exception:
        return False


def jit_compile(fun):
    """JIT-compile function. Alias for jit."""
    return jit(fun)


def vectorize_function(fun, batch_axis: int = 0):
    """Vectorize function along batch axis. Alias for vmap_fun."""
    return vmap_fun(fun, in_axes=batch_axis, out_axes=batch_axis)


def compute_gradient(fun, argnums: int | tuple = 0):
    """Gradient of function w.r.t. argnums. Alias for grad_fun."""
    return grad_fun(fun, argnums=argnums)


def simulate_particle_dynamics(params: dict, steps: int) -> Any:
    """Simple particle dynamics (Euler step). params: {x, v, dt}. Returns trajectory list."""
    jax, jnp = _jax()
    x = jnp.array(params.get("x", [0.0, 0.0]))
    v = jnp.array(params.get("v", [1.0, 0.0]))
    dt = float(params.get("dt", 0.01))
    traj = [x]
    for _ in range(steps - 1):
        x = x + v * dt
        traj.append(x)
    return traj


def solve_differential_equation(func, y0: Any, t_span: tuple, num_steps: int = 100) -> Any:
    """Euler ODE solver: dy/dt = func(t, y). Returns (t_points, y_points)."""
    jax, jnp = _jax()
    t0, t1 = t_span
    ts = jnp.linspace(t0, t1, num_steps)
    dt = (t1 - t0) / num_steps
    y = jnp.array(y0)
    ys = [y]
    for i in range(1, num_steps):
        y = y + dt * func(ts[i], y)
        ys.append(y)
    return ts, ys


def expectation_value(state: Any, operator: Any) -> float:
    """Expectation <state|operator|state>. Alias for quantum_expectation."""
    return float(quantum_expectation(state, operator))


def pauli_expectation(circuit: Any, observable: Any) -> float:
    """Pauli expectation (placeholder: use quantum_expectation with state from circuit)."""
    return 0.0
