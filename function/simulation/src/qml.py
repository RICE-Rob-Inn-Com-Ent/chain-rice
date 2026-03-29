"""PennyLane — QNode, urządzenia, obwody wariacyjne, warstwy kwantowe."""

from __future__ import annotations

from collections.abc import Callable
from typing import Any

import pennylane as qml

# TODO:
# [ ] implement VQE (Variational Quantum Eigensolver):
# [ ]     ansatz circuit from circuit.py, optimizer from optimize in job/
# [ ]     hamiltonian from RICE_QML_HAMILTONIAN config
# [ ] implement QAOA for combinatorial optimization
# [ ]     n_layers from RICE_QAOA_LAYERS env var
# [ ] implement QNN (Quantum Neural Network) via PennyLane:
# [ ]     qml.qnn.TorchLayer or JAXLayer
# [ ] implement quantum kernel methods: kernel matrix for SVM
# [ ] implement data encoding circuits:
# [ ]     amplitude, angle, IQP — encoding from RICE_QML_ENCODING env var


def default_qubit_device(wires: int, *, shots: int | None = None) -> Any:
    """Domyślne `default.qubit` (bez szumu; `shots=None` = dokładny stan)."""
    return qml.device("default.qubit", wires=wires, shots=shots)


def make_qnode(
    func: Callable[..., Any],
    device: Any,
    *,
    interface: str = "auto",
    diff_method: str | None = "best",
) -> Any:
    """Owrapowanie funkcji w `qml.QNode`."""
    return qml.QNode(func, device, interface=interface, diff_method=diff_method)


def strong_entangler_layers(weights: Any, wires: range | list[int]) -> None:
    from pennylane.templates import StronglyEntanglingLayers

    StronglyEntanglingLayers(weights=weights, wires=wires)


def basic_entangler_layer(theta: Any, wires: list[int]) -> None:
    """Jedna warstwa: RX + CNOT łańcuch."""
    for i, w in enumerate(wires):
        qml.RX(theta[i], wires=w)
    for i in range(len(wires) - 1):
        qml.CNOT(wires=[wires[i], wires[i + 1]])
