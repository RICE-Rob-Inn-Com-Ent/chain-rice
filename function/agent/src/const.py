"""SAGE agent — limity narzędzi i stałe integracyjne (.rice)."""

from __future__ import annotations

from typing import Final

from helper import IO_CHUNK_MAX_BYTES

# --- retry defaults -------------------------------------------------------------
MAX_RETRIES: Final[int] = 3
RETRY_MIN_WAIT_S: Final[float] = 1.0
RETRY_MAX_WAIT_S: Final[float] = 8.0
RETRY_EXPONENTIAL_MULTIPLIER: Final[float] = 1.0

# --- constrained generation defaults --------------------------------------------
CONSTRAIN_DEFAULT_MAX_TOKENS: Final[int] = 512
CONSTRAIN_DEFAULT_TEMPERATURE: Final[float] = 0.0
CONSTRAIN_DEFAULT_TIMEOUT_S: Final[float] = 60.0
CONSTRAIN_DEFAULT_MAX_RETRIES: Final[int] = 3

# --- safety / guardrails defaults ----------------------------------------------
GUARD_SAFE_MODE_DEFAULT: Final[bool] = True
GUARD_TOXICITY_THRESHOLD_DEFAULT: Final[float] = 0.6
GUARD_MAX_QUBITS: Final[int] = 64
GUARD_MIN_QUBITS: Final[int] = 1
GUARD_MIN_NOISE: Final[float] = 0.0
GUARD_MAX_NOISE: Final[float] = 1.0
GUARD_BLOCKED_CODE_PATTERNS: Final[tuple[str, ...]] = (
    r"\beval\s*\(",
    r"\bexec\s*\(",
    r"\bos\.remove\s*\(",
    r"\bsubprocess\.",
    r"\bshutil\.rmtree\s*\(",
    r"\b__import__\s*\(",
)

# --- vector / pamięć ------------------------------------------------------------
TOOL_MEMORY_TOP_K: Final[int] = 8
TOOL_SEARCH_QUERY_MAX_LEN: Final[int] = 4096

# --- symulacja / obwody ---------------------------------------------------------
TOOL_CIRCUIT_JSON_MAX_CHARS: Final[int] = 512_000

# --- odczyt kodu (chunkowanie jak w helper IO) -----------------------------------
TOOL_READ_CODE_MAX_BYTES: Final[int] = min(4 * IO_CHUNK_MAX_BYTES, 4 << 20)

# --- HDF5 / fizyka --------------------------------------------------------------
TOOL_PHYSICS_H5_MAX_BYTES: Final[int] = 32 << 20
TOOL_PHYSICS_H5_MAX_DATASETS: Final[int] = 64

__all__ = [
    "CONSTRAIN_DEFAULT_MAX_RETRIES",
    "CONSTRAIN_DEFAULT_MAX_TOKENS",
    "CONSTRAIN_DEFAULT_TEMPERATURE",
    "CONSTRAIN_DEFAULT_TIMEOUT_S",
    "MAX_RETRIES",
    "RETRY_EXPONENTIAL_MULTIPLIER",
    "RETRY_MAX_WAIT_S",
    "RETRY_MIN_WAIT_S",
    "GUARD_BLOCKED_CODE_PATTERNS",
    "GUARD_MAX_NOISE",
    "GUARD_MAX_QUBITS",
    "GUARD_MIN_NOISE",
    "GUARD_MIN_QUBITS",
    "GUARD_SAFE_MODE_DEFAULT",
    "GUARD_TOXICITY_THRESHOLD_DEFAULT",
    "TOOL_CIRCUIT_JSON_MAX_CHARS",
    "TOOL_MEMORY_TOP_K",
    "TOOL_PHYSICS_H5_MAX_DATASETS",
    "TOOL_PHYSICS_H5_MAX_BYTES",
    "TOOL_READ_CODE_MAX_BYTES",
    "TOOL_SEARCH_QUERY_MAX_LEN",
]
