"""Pydantic models for API requests and responses.

Generic field names (text, query, params, options) so any frontend/domain can consume.
All fields use Field(..., description=...) and Config.json_schema_extra where useful.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field


# -----------------------------------------------------------------------------
# Health
# -----------------------------------------------------------------------------


class HealthResponse(BaseModel):
    """Health check response for load balancers and readiness probes."""

    status: str = Field(default="ok", description="Service status: ok or error")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Server UTC time")
    version: str = Field(default="1.0.0", description="API version")

    model_config = {"json_schema_extra": {"examples": [{"status": "ok", "version": "1.0.0"}]}}


# -----------------------------------------------------------------------------
# Chat (LLM)
# -----------------------------------------------------------------------------


class ChatRequest(BaseModel):
    """Request body for chat endpoint. Generic message + optional context/options."""

    message: str = Field(..., description="User message or prompt")
    context: Optional[dict[str, Any]] = Field(default=None, description="Optional context for RAG or state")
    options: Optional[dict[str, Any]] = Field(default=None, description="Optional model/behavior options")

    model_config = {"json_schema_extra": {"examples": [{"message": "What is 2+2?", "context": {}, "options": {}}]}}


class ChatResponse(BaseModel):
    """Response from chat endpoint."""

    response: str = Field(..., description="Model reply text")
    metadata: dict[str, Any] = Field(default_factory=dict, description="Tokens, model, latency, etc.")

    model_config = {"json_schema_extra": {"examples": [{"response": "4", "metadata": {"model": "gpt-4o-mini"}}]}}


# -----------------------------------------------------------------------------
# Query (SQL / data)
# -----------------------------------------------------------------------------


class QueryRequest(BaseModel):
    """Request for SQL/data query endpoint."""

    query: str = Field(..., description="SQL query (read-only) or query identifier")
    params: Optional[dict[str, Any]] = Field(default=None, description="Optional query parameters")

    model_config = {"json_schema_extra": {"examples": [{"query": "SELECT 1 AS n", "params": {}}]}}


class QueryResponse(BaseModel):
    """Response with query results as rows + schema info."""

    data: list[dict[str, Any]] = Field(default_factory=list, description="Rows as list of dicts")
    schema: dict[str, Any] = Field(default_factory=dict, description="Column names and types")
    row_count: int = Field(default=0, description="Number of rows returned")

    model_config = {"json_schema_extra": {"examples": [{"data": [{"n": 1}], "schema": {"n": "INTEGER"}, "row_count": 1}]}}


# -----------------------------------------------------------------------------
# Simulation (quantum)
# -----------------------------------------------------------------------------


class SimulationRequest(BaseModel):
    """Request for quantum simulation endpoint."""

    circuit_type: str = Field(..., description="Circuit type: bell, ghz, qft, custom")
    params: dict[str, Any] = Field(default_factory=dict, description="Circuit parameters (e.g. n_qubits, gates)")

    model_config = {"json_schema_extra": {"examples": [{"circuit_type": "bell", "params": {}}]}}


class SimulationResponse(BaseModel):
    """Response from simulation with results and timing."""

    results: dict[str, Any] = Field(default_factory=dict, description="Counts, statevector, or other results")
    execution_time: float = Field(default=0.0, description="Execution time in seconds")

    model_config = {"json_schema_extra": {"examples": [{"results": {"00": 512, "11": 512}, "execution_time": 0.1}]}}


# -----------------------------------------------------------------------------
# Embeddings (GPU)
# -----------------------------------------------------------------------------


class EmbeddingRequest(BaseModel):
    """Request for embedding endpoint."""

    texts: list[str] = Field(..., description="List of texts to embed")
    model: Optional[str] = Field(default=None, description="Optional model name override")

    model_config = {"json_schema_extra": {"examples": [{"texts": ["hello world"], "model": None}]}}


class EmbeddingResponse(BaseModel):
    """Response with embedding vectors."""

    embeddings: list[list[float]] = Field(default_factory=list, description="List of embedding vectors")
    dimensions: int = Field(default=0, description="Embedding dimension")

    model_config = {"json_schema_extra": {"examples": [{"embeddings": [[0.1, -0.2]], "dimensions": 384}]}}


# -----------------------------------------------------------------------------
# Extract (structured extraction)
# -----------------------------------------------------------------------------


class ExtractRequest(BaseModel):
    """Request for structured extraction endpoint."""

    text: str = Field(..., description="Raw text to extract from")
    schema_name: Optional[str] = Field(default=None, description="Named schema or JSON schema")
    options: Optional[dict[str, Any]] = Field(default=None, description="Extraction options")

    model_config = {"json_schema_extra": {"examples": [{"text": "John bought 2 apples.", "schema_name": "entities", "options": {}}]}}


class ExtractResponse(BaseModel):
    """Response with extracted structured data."""

    data: dict[str, Any] = Field(default_factory=dict, description="Extracted fields")
    schema_used: Optional[str] = Field(default=None, description="Schema identifier used")

    model_config = {"json_schema_extra": {"examples": [{"data": {"entities": ["John"], "quantity": 2}, "schema_used": "entities"}]}}


# -----------------------------------------------------------------------------
# Config (sanitized)
# -----------------------------------------------------------------------------


class ConfigResponse(BaseModel):
    """Sanitized config for GET /config. No API keys or secrets."""

    app_title: str = Field(default="rice-bot", description="Application title")
    app_version: str = Field(default="1.0.0", description="Version")
    app_env: str = Field(default="development", description="Environment")
    enable_agents: bool = Field(default=False, description="Agents feature enabled")
    enable_quantum: bool = Field(default=False, description="Quantum feature enabled")
    enable_data: bool = Field(default=True, description="Data feature enabled")
    enable_gpu: bool = Field(default=False, description="GPU feature enabled")
    litellm_model: str = Field(default="gpt-4o-mini", description="Configured LLM model (key hidden)")
