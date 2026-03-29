"""JAX — PRNG, próbkowanie, Monte Carlo."""

from __future__ import annotations

from typing import Any

import jax
import jax.numpy as jnp

# TODO:
# [ ] implement JAX PRNG key management:
# [ ]     functional PRNG — never mutate key, always split
# [ ]     seed from RICE_JAX_SEED env var
# [ ] implement reproducible random sequences:
# [ ]     store key state to enable replay
# [ ] implement quantum random number generation via Qiskit:
# [ ]     measure Hadamard circuit for true randomness
# [ ]     fallback to JAX PRNG when quantum backend unavailable


def prng_key(seed: int) -> Any:
    return jax.random.PRNGKey(seed)


def split_key(key: Any, num: int = 2) -> Any:
    return jax.random.split(key, num)


def normal_sample(key: Any, shape: tuple[int, ...], *, loc: float = 0.0, scale: float = 1.0) -> Any:
    return loc + scale * jax.random.normal(key, shape)


def uniform_sample(key: Any, shape: tuple[int, ...], *, minval: float = 0.0, maxval: float = 1.0) -> Any:
    return jax.random.uniform(key, shape, minval=minval, maxval=maxval)


def monte_carlo_mean(key: Any, sampler: Any, n: int) -> Any:
    """Średnia z `n` próbek `sampler(subkey)` — `sampler` przyjmuje jeden PRNG key."""
    keys = jax.random.split(key, n)
    samples = jax.vmap(sampler)(keys)
    return jnp.mean(samples, axis=0)
