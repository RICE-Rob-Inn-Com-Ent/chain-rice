"""Wspólne fixtures, hooki pytest, konfiguracja asyncio dla `function/test/`."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

import pytest

# TODO:
# [ ] fixture: settings — returns SageSettings with test overrides
# [ ]     RICE_TEST_MODE=true, RICE_SKIP_HEALTH_CHECK=true
# [ ] fixture: mock_litellm — patches litellm.acompletion with canned response
# [ ] fixture: mock_qdrant — patches qdrant_client with in-memory fake
# [ ] fixture: mock_nats — patches nats.connect with mock connection
# [ ] fixture: mock_temporal — patches temporalio.client.Client with mock
# [ ] fixture: sample_dataframe — returns Polars DataFrame with synthetic data
# [ ]     n_rows from RICE_TEST_DF_ROWS env var (default: 100)
# [ ] fixture: sample_embeddings — returns numpy array of random embeddings
# [ ]     shape (RICE_TEST_EMBED_N, RICE_EMBEDDING_DIM) — all from settings
# [ ] fixture: event_loop — override for pytest-asyncio session scope
# [ ] implement pytest_configure: register all markers programmatically

_ROOT = Path(__file__).resolve().parents[1]


def pytest_configure(_config: pytest.Config) -> None:
    """Mapuje `<repo>/function/<member>/src` na `function.<member>` (importy w testach)."""
    if sys.modules.get("function", None) and getattr(
        sys.modules["function"], "_sage_namespace_registered", False
    ):
        return
    import types

    pkg = types.ModuleType("function")
    pkg.__path__ = []  # namespace package
    pkg._sage_namespace_registered = True  # type: ignore[attr-defined]
    sys.modules["function"] = pkg

    for name in ("agent", "helper", "job", "simulation", "vector"):
        src = _ROOT / name / "src"
        init_py = src / "__init__.py"
        if not init_py.is_file():
            continue
        mod_name = f"function.{name}"
        spec = importlib.util.spec_from_file_location(
            mod_name,
            init_py,
            submodule_search_locations=[str(src)],
        )
        if spec is None or spec.loader is None:
            continue
        mod = importlib.util.module_from_spec(spec)
        mod.__package__ = mod_name
        sys.modules[mod_name] = mod
        spec.loader.exec_module(mod)


@pytest.fixture
def mock_env(monkeypatch: pytest.MonkeyPatch) -> None:
    """Bezpieczne domyślne zmienne — bez prawdziwych kluczy API."""
    monkeypatch.setenv("LITELLM_API_KEY", "")
    monkeypatch.setenv("OPENAI_API_KEY", "")
    monkeypatch.setenv("ENABLE_AGENTS", "true")


@pytest.fixture
def tmp_data_dir(tmp_path: Path) -> Path:
    """Katalog roboczy na pliki tymczasowe testów."""
    d = tmp_path / "data"
    d.mkdir()
    return d


@pytest.fixture
def integration_enabled() -> bool:
    """`RUN_INTEGRATION=1` włącza testy integracyjne."""
    import os

    return os.getenv("RUN_INTEGRATION", "").lower() in {"1", "true", "yes"}
