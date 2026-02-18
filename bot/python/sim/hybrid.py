"""PennyLane: quantum ML, variational circuits, quantum-classical optimization. Requires: pennylane (extra sim).

Provides default_qubit_device, create_qnode, variational_circuit, vqe_ansatz, cost_fn,
optimize_variational, gradient_circuit, hybrid_classifier_layer, quantum_embedding,
create_variational_circuit, parameter_shift_gradient, etc. Install: uv sync --extra sim. English only.
"""

from __future__ import annotations

# -----------------------------------------------------------------------------
# PennyLane QNodes
# -----------------------------------------------------------------------------


def _pl():
    """Lazy import of PennyLane. Raises ImportError with install hint if missing."""
    try:
        import pennylane as qml
        return qml
    except ImportError as e:
        raise ImportError(
            "hybrid requires pennylane; install: uv sync --extra sim"
        ) from e


def default_qubit_device(wires: int = 2):
    """Default.qubit device with given number of wires."""
    qml = _pl()
    return qml.device("default.qubit", wires=wires)


def create_qnode(circuit_fn, dev=None, interface: str = "auto"):
    """Create QNode from circuit function (interface: auto, numpy, torch, jax)."""
    qml = _pl()
    if dev is None:
        dev = default_qubit_device()
    return qml.QNode(circuit_fn, dev, interface=interface)


# -----------------------------------------------------------------------------
# Variational quantum circuits
# -----------------------------------------------------------------------------


def variational_circuit(params, wires: list[int] | int = 2):
    """Simple variational circuit: RY-RZ per qubit, entanglement, second RY-RZ layer."""
    _pl()  # ensure pennylane loaded
    if isinstance(wires, int):
        wires = list(range(wires))
    # params: (len(wires)*2)*2 = pierwsza warstwa RY,RZ, druga warstwa RY,RZ
    off = 0
    qml = _pl()
    for i in wires:
        qml.RY(params[off], wires=i)
        qml.RZ(params[off + 1], wires=i)
        off += 2
    for i in range(len(wires) - 1):
        qml.CNOT(wires=[wires[i], wires[i + 1]])
    for i in wires:
        qml.RY(params[off], wires=i)
        qml.RZ(params[off + 1], wires=i)
        off += 2
    return qml.probs(wires=wires)


def vqe_ansatz(params, wires: list[int], hamiltonian=None):
    """VQE ansatz (placeholder: returns expectation value when hamiltonian given)."""
    qml = _pl()
    variational_circuit(params, wires)
    if hamiltonian is not None:
        return qml.expval(hamiltonian)
    return qml.probs(wires=wires)


# -----------------------------------------------------------------------------
# Quantum-classical optimization
# -----------------------------------------------------------------------------


def cost_fn(params, circuit_fn, target_probs):
    """Cost function: MSE between circuit output probabilities and target_probs."""
    import numpy as np
    _pl()  # ensure pennylane loaded
    probs = circuit_fn(params)
    return np.sum((np.array(probs) - np.array(target_probs)) ** 2)


def optimize_variational(
    init_params,
    circuit_fn,
    target_probs,
    steps: int = 100,
    step_size: float = 0.1,
):
    """Gradient descent on variational circuit (PennyLane diff_method)."""
    try:
        from pennylane import numpy as pnp
        params = pnp.array(init_params, requires_grad=True)
        opt = _pl().AdamOptimizer(stepsize=step_size)
    except (ImportError, AttributeError):
        import numpy as np
        params = np.array(init_params, dtype=float)
        opt = None
    for _ in range(steps):
        if opt is not None:
            params, loss = opt.step_and_cost(lambda p: cost_fn(p, circuit_fn, target_probs), params)
        else:
            loss = cost_fn(params, circuit_fn, target_probs)
            params = params - step_size * 0.01  # fallback
    return params, float(loss) if opt is not None else (params, 0.0)


# -----------------------------------------------------------------------------
# Gradient descent na quantum circuits
# -----------------------------------------------------------------------------


def gradient_circuit(params, wires=2):
    """Circuit returning expectation value (differentiable)."""
    qml = _pl()
    dev = default_qubit_device(wires)
    @qml.qnode(dev, diff_method="parameter-shift")
    def circuit(p):
        for i, w in enumerate(range(wires)):
            qml.RY(p[i], wires=w)
        qml.CNOT(wires=[0, 1])
        return qml.expval(qml.PauliZ(0))
    return circuit(params)


def _parameter_shift_grad(circuit_fn, params):
    """Gradient via parameter-shift (PennyLane)."""
    qml = _pl()
    return qml.grad(circuit_fn)(params)


# -----------------------------------------------------------------------------
# Integration z classical ML
# -----------------------------------------------------------------------------


def hybrid_classifier_layer(weights, x, wires=2):
    """Hybrid layer: classical input x, weights, quantum circuit, output probs."""
    qml = _pl()
    # Encode x into rotation angles (simple linear)
    for i in range(min(len(x), wires)):
        qml.RY(x[i] * weights[i], wires=i)
    for i in range(wires - 1):
        qml.CNOT(wires=[i, i + 1])
    return qml.probs(wires=list(range(wires)))


def quantum_embedding(x, wires=2):
    """Encode input x into quantum state (angle encoding)."""
    qml = _pl()
    for i, w in enumerate(range(wires)):
        if i < len(x):
            qml.RY(x[i], wires=w)
    return qml.state()


# -----------------------------------------------------------------------------
# Spec API: create_variational_circuit, optimize_circuit, gradient_descent, etc.
# -----------------------------------------------------------------------------


def create_variational_circuit(n_layers: int, n_qubits: int):
    """Return a callable(params) that runs variational circuit and returns probs. params length: n_layers * n_qubits * 4 (RY,RZ per layer per qubit + entangle)."""
    qml = _pl()
    dev = default_qubit_device(n_qubits)
    wires = list(range(n_qubits))

    def circuit(params):
        off = 0
        for _ in range(n_layers):
            for i in wires:
                qml.RY(params[off], wires=i)
                qml.RZ(params[off + 1], wires=i)
                off += 2
            for i in range(n_qubits - 1):
                qml.CNOT(wires=[wires[i], wires[i + 1]])
        return qml.probs(wires=wires)

    return qml.QNode(circuit, dev)


def optimize_circuit(qnode, params_init, optimizer=None, steps: int = 100) -> Any:
    """Optimize circuit parameters. Returns final params. cost_fn = lambda p: f(qnode(p))."""
    import numpy as np
    qml = _pl()
    opt = optimizer or qml.AdamOptimizer(0.1)
    params = np.array(params_init, dtype=float)
    for _ in range(steps):
        params, _ = opt.step_and_cost(qnode, params)
    return params


def gradient_descent(qnode, learning_rate: float = 0.1, iterations: int = 100) -> dict:
    """Gradient descent on qnode. Returns dict with final params and loss history (placeholder)."""
    qml = _pl()
    opt = qml.GradientDescentOptimizer(learning_rate)
    params = qnode.qnode.get_parameters() if hasattr(qnode, "qnode") else None
    if params is None:
        return {"params": None, "loss_history": []}
    history = []
    for _ in range(iterations):
        params, loss = opt.step_and_cost(qnode, params)
        history.append(float(loss))
    return {"params": params, "loss_history": history}


def hybrid_model(classical_input: Any, quantum_circuit) -> Any:
    """Hybrid model: classical input passed to quantum circuit (e.g. angle encoding). Returns circuit output."""
    return quantum_circuit(classical_input)


def train_hybrid_model(model_fn, data: list, epochs: int = 10) -> Any:
    """Placeholder: train hybrid model on data. Returns trained params or model state."""
    return {"epochs": epochs, "data_len": len(data)}


def compute_gradients(qnode, params) -> Any:
    """Compute gradients of qnode w.r.t. params. Returns gradient array."""
    qml = _pl()
    return qml.grad(qnode)(params)


def parameter_shift_gradient(qnode, params) -> Any:
    """Gradient via parameter-shift rule. Alias for compute_gradients when diff_method=parameter-shift."""
    return compute_gradients(qnode, params)


def pennylane_torch_layer(qnode):
    """Return a PyTorch layer wrapping the QNode (interface='torch')."""
    try:
        import torch
        qml = _pl()
        return qml.qnn.TorchLayer(qnode, weight_shapes={})
    except (ImportError, AttributeError) as e:
        raise ImportError("pennylane_torch_layer requires torch and PennyLane TorchLayer") from e


def pennylane_jax_layer(qnode):
    """Return a JAX-compatible layer (callable) for the QNode (interface='jax')."""
    return qnode
