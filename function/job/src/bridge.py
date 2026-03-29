"""Most Python ↔ pakiety Mojo (`mojopkg`) / MAX Engine — dtype, ścieżki, fallback NumPy.

Kernels są czystym Mojo (`*.mojo`); ten moduł **nie** importuje runtime Mojo w CPython —
ładuje zbudowany artefakt lub udostępnia numeryczne odpowiedniki do testów offline.
"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path
from typing import Any

import numpy as np

# TODO:
# [ ] implement Python → Mojo data bridge:
# [ ]     numpy array → Arrow IPC → Mojo Tensor via MAX Engine Python API
# [ ]     dtype mapping: float32|float64|int32|int64 — configurable
# [ ] implement Mojo kernel dispatcher:
# [ ]     select kernel based on operation type and data shape
# [ ]     fallback to numpy when Mojo not available (RICE_MOJO_ENABLED=false)
# [ ] implement SIMD-aware data alignment:
# [ ]     align numpy arrays to RICE_SIMD_ALIGNMENT bytes (default: 64 for AVX-512)
# [ ] implement benchmark harness:
# [ ]     compare Mojo kernel vs numpy baseline for each operation
# [ ]     results emitted as OTel histogram: sage.mojo.speedup
# [ ] implement MAX Engine session management:
# [ ]     create/reuse MAX Engine InferenceSession
# [ ]     session config from RICE_MAX_* env vars

MOJO_PACKAGE_DIR: Path = Path(__file__).resolve().parent / "mojo"
# Katalog `function/` (root workspace); `mojo package job/src/mojo` z tego katalogu.
_FUNCTION_PROJECT_ROOT: Path = Path(__file__).resolve().parents[2]
BUILD_DIR = MOJO_PACKAGE_DIR / "build"
DEFAULT_MOJOPKG = BUILD_DIR / "sage.mojopkg"

NUMPY_TO_MOJO_DTYPE: dict[str, str] = {
    "float32": "float32",
    "float64": "float64",
    "int32": "int32",
    "int64": "int64",
    "uint32": "uint32",
    "uint64": "uint64",
}

MOJO_TO_NUMPY: dict[str, np.dtype[Any]] = {
    "float32": np.dtype(np.float32),
    "float64": np.dtype(np.float64),
    "int32": np.dtype(np.int32),
    "int64": np.dtype(np.int64),
    "uint32": np.dtype(np.uint32),
    "uint64": np.dtype(np.uint64),
}


def _which_mojo() -> str | None:
    import shutil

    return shutil.which("mojo")


def build_mojopkg(out: Path | None = None, *, cwd: Path | None = None) -> int:
    """`mojo package job/src/mojo -o <mojopkg>` z katalogu `function/` — wymaga CLI `mojo` w PATH."""
    pkg = out or DEFAULT_MOJOPKG
    pkg.parent.mkdir(parents=True, exist_ok=True)
    exe = _which_mojo()
    if not exe:
        return 127
    root = cwd or _FUNCTION_PROJECT_ROOT
    cmd = [exe, "package", str(MOJO_PACKAGE_DIR.relative_to(root)), "-o", str(pkg.resolve())]
    r = subprocess.run(cmd, cwd=root, check=False, capture_output=True, text=True)
    return r.returncode


class MojoKernelBridge:
    """Rejestr kerneli: po podłączeniu MAX Engine można mapować nazwy → callable."""

    def __init__(self, mojopkg: Path | None = None) -> None:
        self.mojopkg = mojopkg or DEFAULT_MOJOPKG
        self._loaded = False
        self._error: str | None = None

    def ensure_package(self) -> bool:
        if self.mojopkg.is_file():
            self._loaded = True
            return True
        self._error = f"Brak pliku mojopkg: {self.mojopkg} (uruchom build_mojopkg())"
        return False

    def numpy_dtype(self, name: str) -> np.dtype[Any]:
        return MOJO_TO_NUMPY.get(name, np.dtype(np.float32))

    def dot_f32x8_numpy(self, a: np.ndarray, b: np.ndarray) -> np.floating[Any]:
        """Odpowiednik `simd.dot_f32x8` — wektory długości 8."""
        aa = np.asarray(a, dtype=np.float32).ravel()[:8]
        bb = np.asarray(b, dtype=np.float32).ravel()[:8]
        return np.dot(aa, bb)


def max_engine_available() -> bool:
    """MAX Engine / `mojo` w PATH i opcjonalnie zmienna środowiskowa."""
    return bool(_which_mojo()) and os.getenv("MAX_ENGINE_DISABLED", "").lower() not in {"1", "true", "yes"}
