"""Marimo: symulacja — `marimo edit function/test/notebook/explore_sim.py`."""

from __future__ import annotations

from typing import Any

import marimo

# TODO:
# [ ] marimo cell: quantum circuit builder — add gates interactively
# [ ] marimo cell: run circuit on AerSimulator — show probability histogram
# [ ] marimo cell: noise model comparison — ideal vs noisy
# [ ] marimo cell: JAX JIT compilation time vs eager time
# [ ] marimo cell: VQE convergence plot — energy vs iteration

__generated_with = "0.10.0"
app = marimo.App()


@app.cell
def intro() -> Any:
    import marimo as mo

    return mo.md("# Simulation / JAX")


@app.cell
def run_sim() -> Any:
    import jax.numpy as jnp

    from function.simulation.circuit import bell_state_circuit
    from function.simulation.physics import evolve_state

    assert bell_state_circuit(measure=False).num_qubits == 2
    h = jnp.eye(2, dtype=jnp.complex128)
    psi = jnp.array([1.0, 0.0], dtype=jnp.complex128)
    return evolve_state(h, psi, 0.01)
