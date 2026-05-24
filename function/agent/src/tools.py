"""SAGE — rejestr narzędzi .rice (@rice_tool), LiteLLM schemas, integracja vector/simulation."""

from __future__ import annotations

import asyncio
import contextvars
import json
import time
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from helper import SchemaBase, logger
from langchain_core.tools import StructuredTool, tool
from langgraph.prebuilt import ToolNode
from pydantic import Field, model_validator

from .const import (
    TOOL_CIRCUIT_JSON_MAX_CHARS,
    TOOL_MEMORY_TOP_K,
    TOOL_PHYSICS_H5_MAX_DATASETS,
    TOOL_PHYSICS_H5_MAX_BYTES,
    TOOL_READ_CODE_MAX_BYTES,
    TOOL_SEARCH_QUERY_MAX_LEN,
)
from .typed import ToolResult

# Kontekst LiteLLM/LangGraph: ustaw na czas wywołania narzędzia, jeśli znasz tool_call_id.
rice_tool_call_id: contextvars.ContextVar[str] = contextvars.ContextVar(
    "rice_tool_call_id",
    default="",
)


# --- Pydantic args (Instructor / walidacja wejścia) ------------------------------


class SearchMemoryArgs(SchemaBase):
    """Argumenty search_memory — zapytanie do vector search."""

    query: str = Field(
        min_length=1,
        max_length=TOOL_SEARCH_QUERY_MAX_LEN,
        description="Zapytanie semantyczne do pamięci wektorowej projektu.",
    )


class RunQuantumSimulationArgs(SchemaBase):
    """Uruchomienie obwodu lub odpytanie statusu zadania długotrwałego."""

    circuit_json: str = Field(
        default="",
        max_length=TOOL_CIRCUIT_JSON_MAX_CHARS,
        description="OpenQASM 2 lub JSON z polem qasm/qasm2/openqasm/source.",
    )
    job_id: str | None = Field(
        default=None,
        description="Identyfikator zadania z backendu; gdy ustawiony, pomija wykonanie obwodu.",
    )
    dry_run: bool = Field(
        default=False,
        description="Jeśli true i podano circuit_json — tylko estymacja zasobów (dry_run).",
    )

    @model_validator(mode="after")
    def _circuit_or_job(self) -> RunQuantumSimulationArgs:
        jid = (self.job_id or "").strip()
        cj = self.circuit_json.strip()
        if not jid and not cj:
            raise ValueError("Podaj circuit_json albo job_id")
        return self


class ReadCodeArgs(SchemaBase):
    """Ścieżka względna lub absolutna do pliku w dozwolonym workspace .rice."""

    file_path: str = Field(
        min_length=1,
        max_length=4096,
        description="Ścieżka do pliku źródłowego (np. agent/src/state.py).",
    )


class AnalyzePhysicsArgs(SchemaBase):
    """Ścieżka do pliku HDF5 z surowymi danymi symulacji."""

    data_h5: str = Field(
        min_length=1,
        max_length=4096,
        description="Ścieżka do pliku .h5/.hdf5 z datasetami (wektory stanu, itd.).",
    )


# --- Runtime (vector searcher, backend Qiskit, fetcher jobów) --------------------


@dataclass
class RiceToolRuntime:
    """Konfiguracja IO dla narzędzi — ustaw w aplikacji przed invoke grafu."""

    vector_searcher: Any | None = None
    quantum_backend: Any | None = None
    simulation_job_fetcher: Callable[[str], Any] | None = None
    workspace_roots: tuple[Path, ...] = field(default_factory=tuple)

    def resolved_workspace_roots(self) -> tuple[Path, ...]:
        if self.workspace_roots:
            return tuple(Path(p).resolve() for p in self.workspace_roots)
        return default_workspace_roots()


_RUNTIME = RiceToolRuntime()


def get_rice_tool_runtime() -> RiceToolRuntime:
    return _RUNTIME


def configure_rice_tools(
    *,
    vector_searcher: Any | None = None,
    quantum_backend: Any | None = None,
    simulation_job_fetcher: Callable[[str], Any] | None = None,
    workspace_roots: tuple[Path, ...] | None = None,
) -> None:
    """Ustaw globalny runtime narzędzi (wstrzykiwanie z warstwy serwisowej)."""
    global _RUNTIME
    r = RiceToolRuntime(
        vector_searcher=vector_searcher
        if vector_searcher is not None
        else _RUNTIME.vector_searcher,
        quantum_backend=quantum_backend
        if quantum_backend is not None
        else _RUNTIME.quantum_backend,
        simulation_job_fetcher=simulation_job_fetcher
        if simulation_job_fetcher is not None
        else _RUNTIME.simulation_job_fetcher,
        workspace_roots=workspace_roots
        if workspace_roots is not None
        else _RUNTIME.workspace_roots,
    )
    _RUNTIME = r


def default_workspace_roots() -> tuple[Path, ...]:
    """Katalogi function/* (SAGE=agent, przyszłe BARD/SMITH + współdzielone moduły)."""
    here = Path(__file__).resolve()
    # agent/src/tools.py → parents[2] == function/
    function_root = here.parents[2]
    names = (
        "agent",
        "vector",
        "simulation",
        "helper",
        "job",
        "bard",
        "smith",
    )
    roots = [function_root / n for n in names if (function_root / n).is_dir()]
    return tuple(p.resolve() for p in roots)


def _tool_call_id() -> str:
    raw = rice_tool_call_id.get()
    return raw.strip() if raw.strip() else "rice-tool"


def _resolve_workspace_path(file_path: str, *, suffixes: tuple[str, ...] = ()) -> Path:
    """Rozwiąż ścieżkę względem CWD lub korzeni workspace; opcjonalnie filtruj rozszerzenia."""
    roots = get_rice_tool_runtime().resolved_workspace_roots()
    if not roots:
        raise RuntimeError("Brak workspace_roots — nie można zweryfikować ścieżki.")
    raw = Path(file_path).expanduser()
    candidates: list[Path] = []
    if raw.is_absolute():
        candidates.append(raw.resolve())
    else:
        candidates.append((Path.cwd() / raw).resolve())
        for root in roots:
            candidates.append((root / raw).resolve())
    allowed_ext = {s.lower() for s in suffixes} if suffixes else None
    for path in candidates:
        under = False
        for root in roots:
            try:
                path.relative_to(root)
            except ValueError:
                continue
            else:
                under = True
                break
        if not under:
            continue
        if path.is_file():
            if allowed_ext is not None and path.suffix.lower() not in allowed_ext:
                raise ValueError(f"Dozwolone rozszerzenia: {suffixes}; otrzymano {path.suffix!r}")
            return path
    raise FileNotFoundError(file_path)


def _result_json(tr: ToolResult) -> str:
    return tr.model_dump_json()


# --- Rejestr @rice_tool -----------------------------------------------------------


@dataclass(frozen=True, slots=True)
class RiceToolSpec:
    name: str
    description: str
    args_model: type[SchemaBase]
    handler: Callable[..., Awaitable[Any]]


_RICE_REGISTRY: list[RiceToolSpec] = []


def rice_tool(
    args_model: type[SchemaBase],
    *,
    name: str | None = None,
    description: str | None = None,
) -> Callable[[Callable[..., Awaitable[Any]]], Callable[..., Awaitable[Any]]]:
    """Dekorator rejestrujący narzędzie async z modelem argumentów Pydantic."""

    def _decorator(
        fn: Callable[..., Awaitable[Any]],
    ) -> Callable[..., Awaitable[Any]]:
        tname = name or fn.__name__
        tdesc = (description or (fn.__doc__ or "")).strip() or tname
        _RICE_REGISTRY.append(
            RiceToolSpec(
                name=tname,
                description=tdesc,
                args_model=args_model,
                handler=fn,
            ),
        )
        return fn

    return _decorator


def list_rice_tool_specs() -> list[RiceToolSpec]:
    return list(_RICE_REGISTRY)


def get_tool_schemas() -> list[dict[str, Any]]:
    """Słowniki zgodne z parametrem ``tools`` LiteLLM (OpenAI function calling)."""
    out: list[dict[str, Any]] = []
    for spec in _RICE_REGISTRY:
        schema = spec.args_model.model_json_schema()
        out.append(
            {
                "type": "function",
                "function": {
                    "name": spec.name,
                    "description": spec.description,
                    "parameters": schema,
                },
            },
        )
    return out


class ToolDiscovery:
    """Tekstowy katalog narzędzi do wstrzyknięcia w system prompt (``src.prompt``)."""

    @staticmethod
    def tool_names() -> list[str]:
        return [s.name for s in _RICE_REGISTRY]

    @staticmethod
    def describe(spec: RiceToolSpec) -> str:
        fields = []
        try:
            props = spec.args_model.model_json_schema().get("properties") or {}
            for k, meta in props.items():
                t = meta.get("type", "any")
                desc = meta.get("description", "")
                fields.append(f"  - {k} ({t}): {desc}".strip())
        except Exception:
            fields.append("  - (schema unavailable)")
        body = "\n".join(fields) if fields else "  (no fields)"
        return f"- **{spec.name}**: {spec.description}\n{body}"

    @classmethod
    def catalog_markdown(cls) -> str:
        lines = ["## Dostępne narzędzia SAGE (.rice)", ""]
        for spec in _RICE_REGISTRY:
            lines.append(cls.describe(spec))
            lines.append("")
        return "\n".join(lines).strip()

    @classmethod
    def catalog_plain(cls) -> str:
        return cls.catalog_markdown().replace("**", "")


# --- Implementacje narzędzi ------------------------------------------------------


@rice_tool(SearchMemoryArgs, description="Wyszukuje kontekst projektu w pamięci wektorowej (vector).")
async def search_memory(query: str) -> str:
    rt = get_rice_tool_runtime()
    if rt.vector_searcher is None:
        raise RuntimeError(
            "VectorSearcher nie jest skonfigurowany — wywołaj configure_rice_tools(vector_searcher=...).",
        )
    rows = await rt.vector_searcher.search_dense(query, top_k=TOOL_MEMORY_TOP_K)
    payload = [r.to_api_dict() if hasattr(r, "to_api_dict") else r for r in rows]
    return json.dumps(payload, ensure_ascii=False)


def _parse_circuit_from_json(circuit_json: str) -> Any:
    s = circuit_json.strip()
    if s.upper().startswith("OPENQASM"):
        from qiskit.qasm2 import loads

        return loads(s)
    data = json.loads(s)
    if isinstance(data, str):
        return _parse_circuit_from_json(data)
    if isinstance(data, dict):
        for key in ("qasm", "qasm2", "openqasm", "source"):
            v = data.get(key)
            if isinstance(v, str) and v.strip().upper().startswith("OPENQASM"):
                from qiskit.qasm2 import loads

                return loads(v)
    raise ValueError("Oczekiwano OpenQASM 2 (tekst lub pole qasm w JSON)")


@rice_tool(
    RunQuantumSimulationArgs,
    description="Symulacja kwantowa: wykonaj obwód (Qiskit) lub odpytaj status po job_id.",
)
async def run_quantum_simulation(
    circuit_json: str = "",
    job_id: str | None = None,
    dry_run: bool = False,
) -> str:
    rt = get_rice_tool_runtime()
    jid = (job_id or "").strip()
    if jid:
        fetch = rt.simulation_job_fetcher
        if fetch is None:
            return json.dumps(
                {
                    "job_id": jid,
                    "status": "unknown",
                    "message": "Brak simulation_job_fetcher — podłącz callback (np. Temporal/IBM API) "
                    "przez configure_rice_tools(simulation_job_fetcher=...).",
                },
                ensure_ascii=False,
            )
        if asyncio.iscoroutinefunction(fetch):
            out = await fetch(jid)
        else:
            out = await asyncio.to_thread(fetch, jid)
        return json.dumps(out, ensure_ascii=False, default=str)

    try:
        from simulation.execute import dry_run as sim_dry_run
        from simulation.execute import execute_circuit_async
    except ImportError as exc:
        raise RuntimeError(
            "Pakiet simulation nie jest dostępny — dołącz go do środowiska (workspace / pip).",
        ) from exc

    circuit = _parse_circuit_from_json(circuit_json)
    backend = rt.quantum_backend
    if backend is None:
        try:
            from qiskit_aer import AerSimulator

            backend = AerSimulator()
        except Exception as exc:
            raise RuntimeError(
                "Brak quantum_backend i nie udało się utworzyć domyślnego AerSimulator.",
            ) from exc

    if dry_run:
        meta = sim_dry_run(circuit, shots=None)
        return json.dumps({"dry_run": True, "estimate": meta}, ensure_ascii=False, default=str)

    result = await execute_circuit_async(circuit, backend)
    if hasattr(result, "model_dump"):
        return json.dumps(result.model_dump(mode="json"), ensure_ascii=False)
    return json.dumps(result, ensure_ascii=False, default=str)


@rice_tool(ReadCodeArgs, description="Bezpieczny odczyt pliku źródłowego z workspace function/*.")
async def read_code(file_path: str) -> str:
    path = _resolve_workspace_path(file_path, suffixes=())

    size = path.stat().st_size
    if size > TOOL_READ_CODE_MAX_BYTES:
        raise OSError(
            f"Plik za duży ({size} B > limit {TOOL_READ_CODE_MAX_BYTES} B): {path}",
        )

    data = path.read_bytes()[:TOOL_READ_CODE_MAX_BYTES]
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        return data.decode("utf-8", errors="replace")


@rice_tool(
    AnalyzePhysicsArgs,
    description="Analiza pliku HDF5: metadane datasetów + proste metryki (simulation.physics).",
)
async def analyze_physics(data_h5: str) -> str:
    try:
        import h5py
    except ImportError as exc:
        raise RuntimeError("Pakiet h5py jest wymagany do analyze_physics.") from exc

    path = _resolve_workspace_path(data_h5, suffixes=(".h5", ".hdf5"))
    if path.stat().st_size > TOOL_PHYSICS_H5_MAX_BYTES:
        raise OSError("Plik HDF5 przekracza TOOL_PHYSICS_H5_MAX_BYTES")

    try:
        from simulation import physics as sim_physics
    except ImportError as exc:
        raise RuntimeError(
            "Pakiet simulation nie jest dostępny — wymagany do analyze_physics.",
        ) from exc

    summary: dict[str, Any] = {"file": str(path), "datasets": []}

    def _visit(name: str, obj: Any) -> None:
        if len(summary["datasets"]) >= TOOL_PHYSICS_H5_MAX_DATASETS:
            return
        if isinstance(obj, h5py.Dataset):
            shape = list(obj.shape)
            dtype = str(obj.dtype)
            entry: dict[str, Any] = {"name": name, "shape": shape, "dtype": dtype}
            if obj.size > 0 and obj.size <= 65536 and len(shape) == 1:
                try:
                    import math

                    import jax.numpy as jnp

                    arr = obj[()]
                    flat = [complex(x) for x in arr.reshape(-1).tolist()][:4096]
                    if flat:
                        n = len(flat)
                        n_qubits = max(1, int(round(math.log2(n))) if n > 1 else 1)
                        psi = jnp.asarray(flat, dtype=jnp.complex128)
                        psi = psi / (jnp.linalg.norm(psi) + 1e-20)
                        z0 = sim_physics.pauli_kron("Z" + "I" * (n_qubits - 1))
                        exp_z = sim_physics.expectation_value(psi, z0)
                        entry["physics"] = {
                            "n_amplitudes": n,
                            "n_qubits_guess": n_qubits,
                            "expectation_Z0": {"real": exp_z.real, "imag": exp_z.imag},
                        }
                except Exception as phys_exc:
                    entry["physics_error"] = str(phys_exc)
            summary["datasets"].append(entry)

    await asyncio.to_thread(
        lambda: _scan_h5(path, _visit),
    )
    return json.dumps(summary, ensure_ascii=False)


def _scan_h5(path: Path, visitor: Callable[[str, Any], None]) -> None:
    import h5py

    with h5py.File(path, "r") as f:
        f.visititems(visitor)


# --- Obudowa wykonania + StructuredTool ------------------------------------------


async def _execute_spec(spec: RiceToolSpec, kwargs: dict[str, Any]) -> str:
    tcid = _tool_call_id()
    t0 = time.perf_counter()
    logger.info("rice_tool.start | name={} args={}", spec.name, kwargs)
    try:
        validated = spec.args_model.model_validate(kwargs)
        payload = validated.model_dump(mode="python")
        raw_out = await spec.handler(**payload)
        elapsed_ms = (time.perf_counter() - t0) * 1000.0
        logger.info("rice_tool.ok | name={} elapsed_ms={:.2f}", spec.name, elapsed_ms)
        content: str
        if isinstance(raw_out, ToolResult):
            content = raw_out.model_dump_json()
        else:
            content = str(raw_out)
        return _result_json(
            ToolResult(
                tool_call_id=tcid,
                name=spec.name,
                content=content,
                is_error=False,
                metadata={"elapsed_ms": elapsed_ms},
            ),
        )
    except Exception as exc:
        elapsed_ms = (time.perf_counter() - t0) * 1000.0
        logger.exception(
            "rice_tool.error | name={} elapsed_ms={:.2f} err={!r}",
            spec.name,
            elapsed_ms,
            exc,
        )
        return _result_json(
            ToolResult(
                tool_call_id=tcid,
                name=spec.name,
                content=str(exc),
                is_error=True,
                metadata={"elapsed_ms": elapsed_ms, "error_type": type(exc).__name__},
            ),
        )


def _make_structured_tool(spec: RiceToolSpec) -> StructuredTool:
    async def _runner(**kwargs: Any) -> str:
        return await _execute_spec(spec, kwargs)

    return StructuredTool.from_function(
        name=spec.name,
        description=spec.description,
        args_schema=spec.args_model,
        coroutine=_runner,
    )


def build_rice_structured_tools() -> list[StructuredTool]:
    return [_make_structured_tool(s) for s in _RICE_REGISTRY]


@tool
def echo_text(text: str) -> str:
    """Zwraca ten sam tekst — placeholder pod testy i ścieżkę narzędzi."""
    return text


@tool
def now_iso() -> str:
    """Aktualny czas ISO 8601 (UTC) — lekki tool bez IO."""
    from datetime import UTC, datetime

    return datetime.now(tz=UTC).isoformat()


def default_sage_tools() -> list[Any]:
    """Domyślny zestaw: narzędzia .rice + lekkie placeholdery."""
    return [*build_rice_structured_tools(), echo_text, now_iso]


def build_tool_node(tools: list[Any] | None = None) -> ToolNode:
    """`ToolNode` z listy narzędzi LangChain (`StructuredTool` / `@tool`)."""
    return ToolNode(tools or default_sage_tools())


async def invoke_rice_tool(
    name: str,
    arguments: dict[str, Any],
    *,
    tool_call_id: str,
) -> ToolResult:
    """Bezpośrednie wywołanie (np. Instructor) z jawym ``tool_call_id``."""
    token = rice_tool_call_id.set(tool_call_id)
    try:
        spec = next((s for s in _RICE_REGISTRY if s.name == name), None)
        if spec is None:
            return ToolResult(
                tool_call_id=tool_call_id,
                name=name,
                content=f"Unknown tool: {name}",
                is_error=True,
            )
        raw = await _execute_spec(spec, arguments)
        return ToolResult.model_validate_json(raw)
    finally:
        rice_tool_call_id.reset(token)


__all__ = [
    "AnalyzePhysicsArgs",
    "ReadCodeArgs",
    "RiceToolRuntime",
    "RiceToolSpec",
    "RunQuantumSimulationArgs",
    "SearchMemoryArgs",
    "ToolDiscovery",
    "build_rice_structured_tools",
    "build_tool_node",
    "configure_rice_tools",
    "default_sage_tools",
    "default_workspace_roots",
    "echo_text",
    "get_rice_tool_runtime",
    "get_tool_schemas",
    "invoke_rice_tool",
    "list_rice_tool_specs",
    "now_iso",
    "rice_tool",
    "rice_tool_call_id",
]
