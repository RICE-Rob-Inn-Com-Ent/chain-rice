"""
Simulation engine (from sim/simulate.py and sim/compute.py).
Statevector/expectation hot path, particle step, ODE step.
Built as bin/sim_engine via: pixi run mojo build mojo/simulate.mojo -o bin/sim_engine
"""

fn physics_step_scalar(state: Float64, dt: Float64) -> Float64:
    """Single physics step placeholder. Extend for particle/ODE integration."""
    return state + dt

fn expectation_scalar(state: Float64, observable: Float64) -> Float64:
    """Expectation value placeholder. Extend for <state|observable|state> with vectors."""
    return state * observable * state

fn main():
    """Entry point for sim_engine binary. Python calls via subprocess or FFI."""
    print("sim_engine (physics_step):", physics_step_scalar(1.0, 0.01))
    print("sim_engine (expectation):", expectation_scalar(1.0, 2.0))
