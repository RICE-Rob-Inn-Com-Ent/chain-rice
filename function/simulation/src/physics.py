"""JAX — ewolucja Schrödingera, proste symulacje hamiltonowskie, kroki dynamiki."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import Any

import jax.numpy as jnp
from jax.scipy.linalg import expm as jax_expm

# TODO:
# [ ] implement classical physics simulations via JAX:
# [ ]     N-body gravitational simulation — n_bodies from config
# [ ]     molecular dynamics — n_particles, timestep from config
# [ ] implement PDE solvers via JAX:
# [ ]     finite difference heat equation, wave equation
# [ ]     grid_size, dt from RICE_PDE_* env vars
# [ ] implement Monte Carlo path integral simulation
# [ ] implement Hamiltonian dynamics: leapfrog integrator via JAX scan


def evolve_state(
    hamiltonian: Any,
    psi0: Any,
    t: float,
) -> Any:
    """|ψ(t)⟩ = exp(-i H t) |ψ(0)⟩ dla małych układów (macierz H)."""
    u = jax_expm(-1j * hamiltonian * t)
    return u @ psi0


def euler_step(
    rhs: Any,
    y: Any,
    dt: float,
) -> Any:
    """Jeden krok Eulera dla dy/dt = rhs(y)."""
    return y + dt * rhs(y)


def rk4_step(
    rhs: Any,
    y: Any,
    dt: float,
) -> Any:
    """Jeden krok RK4."""
    k1 = rhs(y)
    k2 = rhs(y + 0.5 * dt * k1)
    k3 = rhs(y + 0.5 * dt * k2)
    k4 = rhs(y + dt * k3)
    return y + (dt / 6.0) * (k1 + 2 * k2 + 2 * k3 + k4)


def harmonic_oscillator_rhs(m: float, k: float) -> Any:
    """rhs dla (x, p): dx/dt = p/m, dp/dt = -k x."""

    def rhs(state: Any) -> Any:
        x, p = state[0], state[1]
        return jnp.stack([p / m, -k * x])

    return rhs
