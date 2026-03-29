"""Symulacja kwantowa: Qiskit / Aer, PennyLane, JAX."""

from __future__ import annotations

from . import backend, circuit, execute, grad, gradient, jit, kernel, noise, physics, qml, transpile
from . import random as jax_random
from .backend import aer_simulator, configure_shots, density_matrix_simulator, statevector_simulator, unitary_simulator
from .circuit import add_rotation_y, add_toffoli, barrier_all, bell_state_circuit, compose_circuits, empty_circuit
from .execute import (
    counts_from_result,
    run_shots,
    run_statevector,
    statevector_from_result,
    unitary_from_result,
)
from .grad import custom_vjp_stub, grad_scalar, hessian, jacobian, value_and_grad_fn
from .gradient import (
    metric_tensor_natural_gradient,
    parameter_shift_gradient,
    qaoa_layer_rx_mixer,
    value_and_grad_qnode,
    vqe_energy_qnode,
)
from .jit import block_until_ready, device_put, jit_compile, parallel_map, scan_loop, vectorize_axis0
from .kernel import (
    fidelity_between_states,
    kernel_matrix_from_fidelity,
    quantum_embedding_angle,
    svm_bridge_note,
)
from .noise import depolarizing_single_and_two_qubit, empty_noise_model, readout_error_matrix, thermal_relaxation_on_gate
from .physics import euler_step, evolve_state, harmonic_oscillator_rhs, rk4_step
from .qml import basic_entangler_layer, default_qubit_device, make_qnode, strong_entangler_layers
from .random import monte_carlo_mean, normal_sample, prng_key, split_key, uniform_sample
from .transpile import coupling_grid, default_basis_gates, transpile_circuit

# Alias modułu JAX PRNG (`simulation.random`), nie stdlib.
random = jax_random

__all__ = [
    "aer_simulator",
    "add_rotation_y",
    "add_toffoli",
    "backend",
    "barrier_all",
    "basic_entangler_layer",
    "bell_state_circuit",
    "block_until_ready",
    "circuit",
    "compose_circuits",
    "configure_shots",
    "counts_from_result",
    "coupling_grid",
    "custom_vjp_stub",
    "default_basis_gates",
    "default_qubit_device",
    "density_matrix_simulator",
    "depolarizing_single_and_two_qubit",
    "device_put",
    "empty_circuit",
    "empty_noise_model",
    "execute",
    "evolve_state",
    "euler_step",
    "fidelity_between_states",
    "grad",
    "grad_scalar",
    "gradient",
    "harmonic_oscillator_rhs",
    "hessian",
    "jacobian",
    "jit",
    "jit_compile",
    "kernel",
    "kernel_matrix_from_fidelity",
    "make_qnode",
    "metric_tensor_natural_gradient",
    "monte_carlo_mean",
    "noise",
    "normal_sample",
    "parameter_shift_gradient",
    "parallel_map",
    "physics",
    "prng_key",
    "qaoa_layer_rx_mixer",
    "qml",
    "quantum_embedding_angle",
    "random",
    "readout_error_matrix",
    "rk4_step",
    "run_shots",
    "run_statevector",
    "scan_loop",
    "split_key",
    "statevector_from_result",
    "statevector_simulator",
    "strong_entangler_layers",
    "svm_bridge_note",
    "thermal_relaxation_on_gate",
    "transpile",
    "transpile_circuit",
    "unitary_from_result",
    "unitary_simulator",
    "uniform_sample",
    "value_and_grad_fn",
    "value_and_grad_qnode",
    "vectorize_axis0",
    "vqe_energy_qnode",
]
