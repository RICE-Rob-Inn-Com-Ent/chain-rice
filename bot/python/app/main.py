"""FastAPI application and all HTTP endpoints.

Generic backend: health, chat, query, simulate, embed, extract, config.
Feature flags (ENABLE_*) control which endpoints are registered.
Run: uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
"""

from __future__ import annotations

import time
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from loguru import logger

from app.config import get_settings
from app.models import (
    ChatRequest,
    ChatResponse,
    ConfigResponse,
    EmbeddingRequest,
    EmbeddingResponse,
    ExtractRequest,
    ExtractResponse,
    HealthResponse,
    QueryRequest,
    QueryResponse,
    SimulationRequest,
    SimulationResponse,
)
from app.utils import (
    AppError,
    ConfigurationError,
    DataError,
    LLMError,
    SecurityError,
    format_error_response,
    generate_request_id,
    setup_logger,
)


# -----------------------------------------------------------------------------
# Lifespan and startup
# -----------------------------------------------------------------------------


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup: configure logger, log feature flags. Shutdown: nothing."""
    settings = get_settings()
    setup_logger(
        level=settings.LOG_LEVEL,
        format_type=settings.LOG_FORMAT,
        file_path=settings.LOG_FILE_PATH,
    )
    logger.info(
        "rice-bot starting",
        version=settings.APP_VERSION,
        enable_agents=settings.ENABLE_AGENTS,
        enable_quantum=settings.ENABLE_QUANTUM,
        enable_data=settings.ENABLE_DATA,
        enable_gpu=settings.ENABLE_GPU,
    )
    yield
    logger.info("rice-bot shutdown")


# -----------------------------------------------------------------------------
# App and middleware
# -----------------------------------------------------------------------------

_settings = get_settings()
app = FastAPI(
    title=_settings.APP_TITLE,
    version=_settings.APP_VERSION,
    description="Universal AI/data/quantum backend service. Generic API for any frontend.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_settings.cors_origin_list(),
    allow_credentials=_settings.CORS_ALLOW_CREDENTIALS,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def request_logging(request: Request, call_next):
    """Log request method/path and duration; inject request_id into state."""
    request_id = generate_request_id()
    request.state.request_id = request_id
    start = time.perf_counter()
    response = await call_next(request)
    duration_ms = (time.perf_counter() - start) * 1000
    logger.info(
        "request",
        request_id=request_id,
        method=request.method,
        path=request.url.path,
        status=response.status_code,
        duration_ms=round(duration_ms, 2),
    )
    return response


# -----------------------------------------------------------------------------
# Exception handlers
# -----------------------------------------------------------------------------


@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    """Return consistent JSON for application errors."""
    code = status.HTTP_400_BAD_REQUEST
    if isinstance(exc, (SecurityError, ConfigurationError)):
        code = status.HTTP_403_FORBIDDEN
    elif isinstance(exc, LLMError):
        code = status.HTTP_502_BAD_GATEWAY
    elif isinstance(exc, DataError):
        code = status.HTTP_422_UNPROCESSABLE_ENTITY
    return JSONResponse(status_code=code, content=format_error_response(exc))


@app.exception_handler(ValueError)
async def value_error_handler(request: Request, exc: ValueError):
    """Treat ValueError as 422."""
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=format_error_response(exc),
    )


@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    """Log and return 500 for unhandled exceptions."""
    logger.exception("Unhandled exception: %s", exc)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=format_error_response(exc),
    )


# -----------------------------------------------------------------------------
# Endpoints: health and config (always)
# -----------------------------------------------------------------------------


@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check for load balancers and readiness probes."""
    settings = get_settings()
    return HealthResponse(
        status="ok",
        timestamp=datetime.now(timezone.utc),
        version=settings.APP_VERSION,
    )


@app.get("/config", response_model=ConfigResponse)
async def get_config():
    """Return sanitized config (no API keys or secrets)."""
    s = get_settings()
    return ConfigResponse(
        app_title=s.APP_TITLE,
        app_version=s.APP_VERSION,
        app_env=s.APP_ENV,
        enable_agents=s.ENABLE_AGENTS,
        enable_quantum=s.ENABLE_QUANTUM,
        enable_data=s.ENABLE_DATA,
        enable_gpu=s.ENABLE_GPU,
        litellm_model=s.LITELLM_MODEL,
    )


# -----------------------------------------------------------------------------
# Chat (if ENABLE_AGENTS)
# -----------------------------------------------------------------------------


if get_settings().ENABLE_AGENTS:

    @app.post("/chat", response_model=ChatResponse)
    async def chat_endpoint(body: ChatRequest):
        """LLM chat. Uses context and options if provided."""
        from app.llm import chat

        messages = [{"role": "user", "content": body.message}]
        if body.context:
            # Optional: prepend context as system or previous turns
            pass
        response_text = await chat(messages)
        return ChatResponse(response=response_text, metadata={"model": get_settings().LITELLM_MODEL})
# -----------------------------------------------------------------------------
# Query (if ENABLE_DATA)
# -----------------------------------------------------------------------------


if get_settings().ENABLE_DATA:

    @app.post("/query", response_model=QueryResponse)
    async def query_endpoint(body: QueryRequest):
        """Execute read-only SQL query. Returns rows and schema info."""
        from app.data import is_safe_query, run_sql
        from app.utils import DataError

        ok, err = is_safe_query(body.query)
        if not ok:
            raise DataError(err or "Unsafe query")
        rows = run_sql(body.query, params=body.params)
        schema: dict = {}
        if rows:
            schema = {k: type(v).__name__ for k, v in rows[0].items()}
        return QueryResponse(data=rows, schema=schema, row_count=len(rows))


# -----------------------------------------------------------------------------
# Simulate (if ENABLE_QUANTUM)
# -----------------------------------------------------------------------------


if get_settings().ENABLE_QUANTUM:

    @app.post("/simulate", response_model=SimulationResponse)
    async def simulate_endpoint(body: SimulationRequest):
        """Run quantum circuit simulation. circuit_type: bell, ghz, qft, custom."""
        import time as t

        try:
            from sim.circuits import create_bell_state, create_custom_circuit, create_ghz_state, create_qft
            from sim.simulate import run_simulation
        except ImportError as e:
            raise ConfigurationError("Quantum simulation requires sim extra: uv sync --extra sim") from e

        circuit_type = (body.circuit_type or "bell").lower()
        params = body.params or {}
        if circuit_type == "bell":
            circuit = create_bell_state()
        elif circuit_type == "ghz":
            n = params.get("n_qubits", 3)
            circuit = create_ghz_state(n)
        elif circuit_type == "qft":
            n = params.get("n_qubits", 3)
            circuit = create_qft(n)
        elif circuit_type == "custom":
            gates = params.get("gates", [])
            circuit = create_custom_circuit(gates)
        else:
            circuit = create_bell_state()
        start = t.perf_counter()
        result = run_simulation(circuit, shots=params.get("shots", 1024))
        elapsed = t.perf_counter() - start
        from sim.simulate import get_counts
        counts = get_counts(result)
        return SimulationResponse(results={"counts": counts}, execution_time=elapsed)


# -----------------------------------------------------------------------------
# Embed (if ENABLE_GPU)
# -----------------------------------------------------------------------------


if get_settings().ENABLE_GPU:

    @app.post("/embed", response_model=EmbeddingResponse)
    async def embed_endpoint(body: EmbeddingRequest):
        """Generate embeddings for texts (requires model extra: torch)."""
        try:
            from model.embeddings import generate_embeddings_batch, load_model
        except ImportError as e:
            raise ConfigurationError("Embeddings require model extra: uv sync --extra model") from e

        model_name = body.model or None
        model = load_model(model_name) if model_name else load_model()
        emb = generate_embeddings_batch(body.texts, model=model)
        if hasattr(emb, "shape") and len(emb.shape) > 1:
            dim = int(emb.shape[1])
        elif emb and len(emb) > 0:
            dim = len(emb[0])
        else:
            dim = 0
        list_emb = emb.tolist() if hasattr(emb, "tolist") else list(emb)
        return EmbeddingResponse(embeddings=list_emb, dimensions=dim)


# -----------------------------------------------------------------------------
# Extract (if ENABLE_AGENTS)
# -----------------------------------------------------------------------------


if get_settings().ENABLE_AGENTS:

    @app.post("/extract", response_model=ExtractResponse)
    async def extract_endpoint(body: ExtractRequest):
        """Structured data extraction from text (model extra)."""
        try:
            from model.extract import extract
        except ImportError as e:
            raise ConfigurationError("Extract requires model extra: uv sync --extra model") from e

        from pydantic import BaseModel

        # Generic schema: extract to dict; schema_name can drive which schema to use
        class GenericExtract(BaseModel):
            summary: str = ""
            entities: list[str] = []
            data: dict = {}

        schema_used = body.schema_name or "generic"
        extracted = extract(body.text, GenericExtract)
        if hasattr(extracted, "model_dump"):
            data = extracted.model_dump()
        else:
            data = {"summary": getattr(extracted, "summary", ""), "entities": getattr(extracted, "entities", [])}
        return ExtractResponse(data=data, schema_used=schema_used)
