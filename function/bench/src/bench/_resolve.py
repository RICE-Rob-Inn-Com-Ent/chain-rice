"""Resolve SAGE packages in both flattened wheels and raw ``{pkg}/src`` namespace layouts."""

from __future__ import annotations

import importlib
from types import ModuleType


def _prefer_impl(root: ModuleType, name: str) -> ModuleType:
    marker = "parse_json" if name == "helper" else "linalg" if name == "job" else "RiceCircuit"
    if name == "vector":
        marker = "EmbeddingEngine"
    if name == "simulation":
        marker = "RiceCircuit"
    if name == "agent":
        marker = "ask_sage"
    if hasattr(root, marker):
        return root
    return importlib.import_module(f"{name}.src")


def helper_module() -> ModuleType:
    return _prefer_impl(importlib.import_module("helper"), "helper")


def job_module() -> ModuleType:
    return _prefer_impl(importlib.import_module("job"), "job")


def vector_module() -> ModuleType:
    return _prefer_impl(importlib.import_module("vector"), "vector")


def simulation_module() -> ModuleType:
    return _prefer_impl(importlib.import_module("simulation"), "simulation")


def agent_module() -> ModuleType:
    return _prefer_impl(importlib.import_module("agent"), "agent")
