# --- Quantum experiments notebook (Marimo .py) ---
# Build/run circuits, visualize. Run with: marimo edit quantum_experiments.py
# Requires: uv sync --extra sim. Uses sim.circuits (create_bell_state), sim.simulate (run_simulation, get_counts),
# sim.hybrid (create_variational_circuit). English only.


def __get_mo():
    try:
        import marimo as mo

        return mo
    except ImportError:
        return None


mo = __get_mo()

# Circuit: Bell state (when sim extra installed)
try:
    from sim.circuits import create_bell_state
    from sim.simulate import run_simulation, get_counts

    qc = create_bell_state()
    result = run_simulation(qc, shots=1024)
    counts = get_counts(result)
    print("Bell state counts:", counts)
except ImportError as e:
    print("Quantum experiments require: uv sync --extra sim", e)

# Variational circuit (PennyLane)
try:
    from sim.hybrid import create_variational_circuit

    n_qubits = 2
    n_layers = 1
    qnode = create_variational_circuit(n_layers, n_qubits)
    import numpy as np

    params = np.random.randn(n_layers * n_qubits * 4) * 0.1
    probs = qnode(params)
    print("Probs shape:", np.shape(probs))
except ImportError:
    print("PennyLane optional for variational circuits")

if mo and hasattr(mo, "ui"):
    n_q = mo.ui.slider(2, 5, value=2, label="Qubits")
else:
    n_q = 2
