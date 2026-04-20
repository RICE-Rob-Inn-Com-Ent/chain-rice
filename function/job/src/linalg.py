"""NumPy — algebra liniowa: macierze, dekompozycje, iloczyny skalarne."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import Any

import numpy as np
from numpy.typing import NDArray

# TODO:
# [ ] implement matrix operations via numpy.linalg:
# [ ]     inv, pinv, solve, lstsq, norm, det, matrix_rank
# [ ] implement eigendecomposition: eig, eigh, svd
# [ ]     full_matrices from RICE_SVD_FULL env var
# [ ] implement Cholesky decomposition for positive definite matrices
# [ ] implement QR decomposition: qr with mode=reduced|complete|r
# [ ] implement matrix condition number monitoring:
# [ ]     warn when condition > RICE_COND_THRESHOLD env var
# [ ] implement batched matrix ops via numpy broadcasting
# [ ] dispatch to Mojo kernels for large matrices:
# [ ]     threshold: matrix size > RICE_MOJO_LINALG_THRESHOLD env var


def matmul(a: NDArray[Any], b: NDArray[Any]) -> NDArray[Any]:
    return np.matmul(a, b)


def dot(a: NDArray[Any], b: NDArray[Any]) -> NDArray[Any]:
    return np.dot(a, b)


def solve_linear(a: NDArray[Any], b: NDArray[Any]) -> NDArray[Any]:
    """Rozwiązuje `a x = b` dla kwadratowej `a`."""
    return np.linalg.solve(a, b)


def lstsq_overdetermined(a: NDArray[Any], b: NDArray[Any], rcond: float | None = None) -> tuple:
    return np.linalg.lstsq(a, b, rcond=rcond)


def svd_decompose(
    a: NDArray[Any],
    *,
    full_matrices: bool = True,
) -> tuple[NDArray[Any], NDArray[Any], NDArray[Any]]:
    return np.linalg.svd(a, full_matrices=full_matrices)


def eig_decompose(a: NDArray[Any]) -> tuple[NDArray[Any], NDArray[Any]]:
    return np.linalg.eig(a)


def eigvalsh_symmetric(a: NDArray[Any]) -> NDArray[Any]:
    """Wartości własne macierzy symetrycznej (Hermitowskiej)."""
    return np.linalg.eigvalsh(a)


def norm_vector(x: NDArray[Any], *, ord: float | None = None) -> Any:
    return np.linalg.norm(x, ord=ord)


def matrix_rank(a: NDArray[Any], *, tol: float | None = None) -> int:
    return int(np.linalg.matrix_rank(a, tol=tol))
