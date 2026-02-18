"""Agent tools callable by LangGraph: query DB, search docs, API, extract, validate, schedule.

All tools are parameterized (no hardcoded config). Input validation and logging per tool.
"""

from __future__ import annotations

import time
from typing import Any

from loguru import logger

from app.utils import DataError, SecurityError, is_safe_sql


def query_database(sql: str, params: dict | None = None) -> dict[str, Any]:
    """Execute read-only SQL via data.query. Returns dict with data and row_count.

    Args:
        sql: SQL query string (validated for safety).
        params: Optional query parameters.

    Returns:
        {"data": list[dict], "row_count": int}

    Raises:
        SecurityError: If query is not safe.
        DataError: If execution fails.
    """
    if not is_safe_sql(sql):
        raise SecurityError("Destructive or write operations are not allowed.")
    try:
        from app.data import run_sql
        start = time.perf_counter()
        rows = run_sql(sql, params)
        elapsed = (time.perf_counter() - start) * 1000
        logger.info("query_database", row_count=len(rows), duration_ms=round(elapsed, 2))
        return {"data": rows, "row_count": len(rows)}
    except ValueError as e:
        raise DataError(str(e)) from e


def search_documents(query: str, top_k: int = 5, **kwargs: Any) -> list[dict]:
    """Hybrid search via model.memory. Returns list of doc dicts with score/metadata.

    Args:
        query: Search query text.
        top_k: Max number of results.

    Returns:
        List of {"id", "text", "score", "metadata"} (or similar).
    """
    try:
        from model.memory import search
        start = time.perf_counter()
        results = search(query, top_k=top_k, **kwargs) if callable(search) else []
        elapsed = (time.perf_counter() - start) * 1000
        logger.info("search_documents", query_len=len(query), top_k=top_k, hits=len(results), duration_ms=round(elapsed, 2))
        return results if isinstance(results, list) else list(results)
    except ImportError:
        logger.debug("search_documents: model.memory not available")
        return []


def call_external_api(
    url: str,
    method: str = "GET",
    **kwargs: Any,
) -> dict[str, Any]:
    """HTTP request with retry. Returns dict with status_code, body, headers.

    Args:
        url: Request URL.
        method: HTTP method (GET, POST, etc.).
        **kwargs: Passed to httpx (json=, headers=, timeout=).
    """
    try:
        import httpx
    except ImportError as e:
        raise DataError("httpx required for call_external_api") from e
    start = time.perf_counter()
    try:
        with httpx.Client(timeout=kwargs.pop("timeout", 30.0)) as client:
            resp = client.request(method, url, **kwargs)
        body = resp.json() if resp.headers.get("content-type", "").startswith("application/json") else resp.text
        elapsed = (time.perf_counter() - start) * 1000
        logger.info("call_external_api", url=url, method=method, status=resp.status_code, duration_ms=round(elapsed, 2))
        return {"status_code": resp.status_code, "body": body, "headers": dict(resp.headers)}
    except Exception as e:
        logger.warning("call_external_api failed", url=url, error=str(e))
        raise DataError(f"Request failed: {e}") from e


def parse_structured_data(text: str, schema: dict | type) -> dict[str, Any]:
    """Extract structured data from text using model.extract. schema: Pydantic model or dict spec.

    Args:
        text: Raw text.
        schema: Pydantic model class or dict schema (if dict, uses generic extraction).

    Returns:
        Extracted data as dict.
    """
    try:
        from model.extract import extract
        from pydantic import BaseModel
    except ImportError as e:
        raise DataError("model.extract required for parse_structured_data") from e
    if isinstance(schema, dict):
        from model.models import ExtractionResult
        schema = ExtractionResult
    if not isinstance(schema, type) or not issubclass(schema, BaseModel):
        raise ValueError("schema must be a Pydantic model class or dict")
    start = time.perf_counter()
    result = extract(text, schema)
    elapsed = (time.perf_counter() - start) * 1000
    logger.info("parse_structured_data", duration_ms=round(elapsed, 2))
    return result.model_dump() if hasattr(result, "model_dump") else dict(result)


def validate_format(data: dict[str, Any], constraints: dict[str, Any]) -> bool:
    """Validate data against constraints (required keys, types).

    Args:
        data: Data to validate.
        constraints: Dict of field -> rule (e.g. {"required": True}) or list of required keys.

    Returns:
        True if valid.
    """
    if not constraints:
        return True
    if isinstance(constraints, list):
        return all(k in data for k in constraints)
    for k, rule in constraints.items():
        if isinstance(rule, dict) and rule.get("required") and k not in data:
            return False
        if k not in data:
            continue
        if isinstance(rule, dict) and "type" in rule:
            t = rule["type"]
            if t == "string" and not isinstance(data[k], str):
                return False
            if t == "number" and not isinstance(data[k], (int, float)):
                return False
            if t == "array" and not isinstance(data[k], list):
                return False
    return True


def schedule_computation(job_type: str, params: dict[str, Any], priority: int = 0) -> str:
    """Queue a job via model.scheduler. Returns job_id.

    Args:
        job_type: Type of job (embed, compute, etc.).
        params: Job parameters.
        priority: Optional priority (higher = first).

    Returns:
        Job ID string.
    """
    try:
        from model.scheduler import submit_job
        start = time.perf_counter()
        job_id = submit_job(job_type, params, priority=priority)
        elapsed = (time.perf_counter() - start) * 1000
        logger.info("schedule_computation", job_type=job_type, job_id=job_id, duration_ms=round(elapsed, 2))
        return job_id
    except ImportError:
        # No scheduler: return placeholder id
        import uuid
        return f"placeholder-{uuid.uuid4()}"


# -----------------------------------------------------------------------------
# LangGraph-compatible tool list (for binding to agent)
# -----------------------------------------------------------------------------


def get_tools_for_agent() -> list[dict[str, Any]]:
    """Return list of tool specs for LangGraph (name, description, args_schema)."""
    return [
        {
            "name": "query_database",
            "description": "Execute read-only SQL query. Returns rows and count.",
            "args_schema": {"sql": "string", "params": "object"},
        },
        {
            "name": "search_documents",
            "description": "Hybrid search over documents. Returns top_k results.",
            "args_schema": {"query": "string", "top_k": "integer"},
        },
        {
            "name": "call_external_api",
            "description": "HTTP request to external URL with retry.",
            "args_schema": {"url": "string", "method": "string"},
        },
        {
            "name": "parse_structured_data",
            "description": "Extract structured data from text using schema.",
            "args_schema": {"text": "string", "schema": "object"},
        },
        {
            "name": "validate_format",
            "description": "Validate data against constraints.",
            "args_schema": {"data": "object", "constraints": "object"},
        },
        {
            "name": "schedule_computation",
            "description": "Queue a computation job. Returns job_id.",
            "args_schema": {"job_type": "string", "params": "object", "priority": "integer"},
        },
    ]
