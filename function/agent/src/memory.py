"""Persistence layer for SAGE: LangGraph checkpointers + session utilities + memory summarization."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import asyncio
import json
import os
import sqlite3
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

from helper import RiceError, logger
from langgraph.checkpoint.memory import MemorySaver
from langgraph.store.memory import InMemoryStore

try:
    from langgraph.checkpoint.sqlite import SqliteSaver
except ImportError:  # opcjonalny pakiet `langgraph-checkpoint-sqlite`
    SqliteSaver = None  # type: ignore[misc, assignment]

try:  # optional package
    from langgraph.checkpoint.sqlite.aio import AsyncSqliteSaver  # type: ignore[attr-defined]
except Exception:
    AsyncSqliteSaver = None  # type: ignore[misc, assignment]

try:  # optional package
    from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver  # type: ignore[attr-defined]
except Exception:
    AsyncPostgresSaver = None  # type: ignore[misc, assignment]

from .state import AgentState

_CHECKPOINTER_BACKEND = os.getenv("RICE_CHECKPOINTER_BACKEND", "sqlite").strip().lower()
_CHECKPOINTER_PATH = os.getenv("RICE_CHECKPOINTER_PATH", os.getenv("SAGE_CHECKPOINT_SQLITE", "sage_checkpoints.sqlite"))
_POSTGRES_DSN = os.getenv("RICE_POSTGRES_DSN", os.getenv("DATABASE_URL", ""))
_SESSION_PREFIX = os.getenv("RICE_THREAD_PREFIX", "sage")
_EXPORT_DIR = os.getenv("RICE_SESSION_EXPORT_DIR", "session_exports")
_MEMORY_TTL_DAYS = int(os.getenv("RICE_MEMORY_TTL_DAYS", "30"))


def _utcnow() -> datetime:
    return datetime.now(tz=UTC)


def _state_minimal_validate(raw: dict[str, Any]) -> AgentState:
    """Runtime sanity checks for recovered AgentState payload."""
    required = ("messages", "context", "simulation_results", "next_step", "metadata", "status")
    missing = [k for k in required if k not in raw]
    if missing:
        raise RiceError(
            "Recovered state is missing required fields",
            error_code="MEMORY_STATE_INVALID",
            details={"missing": missing},
        )
    # Preserve metadata/message payload exactly to avoid losing module/source info.
    return raw  # type: ignore[return-value]


def get_thread_config(session_id: str) -> dict[str, dict[str, str]]:
    """LangGraph config wrapper for thread/session ID."""
    sid = str(session_id).strip()
    if not sid:
        raise ValueError("session_id cannot be empty")
    thread_id = f"{_SESSION_PREFIX}:{sid}"
    return {"configurable": {"thread_id": thread_id}}


async def get_checkpointer() -> Any:
    """Factory for async checkpointer where available; fallback to in-memory saver."""
    backend = _CHECKPOINTER_BACKEND
    if backend == "postgres":
        if not _POSTGRES_DSN:
            raise RiceError(
                "Postgres checkpointer selected but DSN is missing",
                error_code="MEMORY_POSTGRES_DSN_MISSING",
            )
        if AsyncPostgresSaver is None:
            raise RiceError(
                "AsyncPostgresSaver unavailable (install langgraph postgres checkpoint package)",
                error_code="MEMORY_POSTGRES_UNAVAILABLE",
            )
        cp = await AsyncPostgresSaver.from_conn_string(_POSTGRES_DSN)  # type: ignore[call-arg]
        logger.info("checkpointer ready | backend=postgres")
        return cp

    # sqlite default
    if AsyncSqliteSaver is not None:
        cp = await AsyncSqliteSaver.from_conn_string(_CHECKPOINTER_PATH)  # type: ignore[call-arg]
        logger.info("checkpointer ready | backend=sqlite_async path={}", _CHECKPOINTER_PATH)
        return cp
    if SqliteSaver is not None:
        cp = SqliteSaver.from_conn_string(_CHECKPOINTER_PATH)
        logger.info("checkpointer ready | backend=sqlite_sync path={}", _CHECKPOINTER_PATH)
        return cp
    logger.warning("sqlite checkpoint package unavailable; falling back to MemorySaver")
    return MemorySaver()


def build_memory_saver() -> MemorySaver:
    """Checkpointer w RAM — dev, testy, brak persystencji między restartami."""
    return MemorySaver()


def build_sqlite_saver(db_path: str | None = None):
    """Checkpointer SQLite — persystencja wątków (checkpointy) na dysku.

    Wymaga: ``pip install langgraph-checkpoint-sqlite``.
    """
    if SqliteSaver is None:
        msg = "SqliteSaver: zainstaluj pakiet `langgraph-checkpoint-sqlite`"
        raise RuntimeError(msg)
    path = db_path or os.getenv("SAGE_CHECKPOINT_SQLITE", "sage_checkpoints.sqlite")
    logger.info("SqliteSaver path: {}", path)
    return SqliteSaver.from_conn_string(path)


def build_cross_thread_store() -> InMemoryStore:
    """Store na dane dzielone między wątkami (np. fakty użytkownika)."""
    return InMemoryStore()


async def _cp_get_tuple(checkpointer: Any, config: dict[str, Any]) -> Any:
    if hasattr(checkpointer, "aget_tuple"):
        return await checkpointer.aget_tuple(config)
    if hasattr(checkpointer, "get_tuple"):
        return await asyncio.to_thread(checkpointer.get_tuple, config)
    raise RiceError("checkpointer does not support get_tuple", error_code="MEMORY_GET_UNSUPPORTED")


async def _cp_list(checkpointer: Any, config: dict[str, Any] | None = None) -> list[Any]:
    cfg = config or {}
    if hasattr(checkpointer, "alist"):
        rows = []
        async for item in checkpointer.alist(cfg):
            rows.append(item)
        return rows
    if hasattr(checkpointer, "list"):
        rows = checkpointer.list(cfg)
        return list(rows)
    return []


async def _cp_delete_thread(checkpointer: Any, thread_id: str) -> None:
    cfg = {"configurable": {"thread_id": thread_id}}
    if hasattr(checkpointer, "adelete_thread"):
        await checkpointer.adelete_thread(cfg)
        return
    if hasattr(checkpointer, "delete_thread"):
        await asyncio.to_thread(checkpointer.delete_thread, cfg)
        return
    # sqlite fallback: best-effort direct cleanup
    if _CHECKPOINTER_PATH and Path(_CHECKPOINTER_PATH).exists():
        _sqlite_delete_thread(_CHECKPOINTER_PATH, thread_id)
        return
    raise RiceError("checkpointer does not support delete_thread", error_code="MEMORY_DELETE_UNSUPPORTED")


def _extract_thread_id(item: Any) -> str | None:
    if isinstance(item, dict):
        cfg = item.get("config") or item.get("checkpoint_config") or {}
        if isinstance(cfg, dict):
            c = cfg.get("configurable", {})
            if isinstance(c, dict):
                tid = c.get("thread_id")
                if tid:
                    return str(tid)
        tid = item.get("thread_id")
        if tid:
            return str(tid)
    cfg = getattr(item, "config", None) or getattr(item, "checkpoint_config", None)
    if isinstance(cfg, dict):
        c = cfg.get("configurable", {})
        if isinstance(c, dict) and c.get("thread_id"):
            return str(c["thread_id"])
    tid = getattr(item, "thread_id", None)
    return str(tid) if tid else None


async def list_active_sessions(checkpointer: Any | None = None) -> list[str]:
    """Return distinct thread IDs present in checkpoint storage."""
    cp = checkpointer if checkpointer is not None else await get_checkpointer()
    items = await _cp_list(cp, {})
    out: set[str] = set()
    for row in items:
        tid = _extract_thread_id(row)
        if tid:
            out.add(tid)
    sessions = sorted(out)
    logger.info("memory list_active_sessions | count={}", len(sessions))
    return sessions


async def load_checkpoint(thread_id: str, checkpointer: Any | None = None) -> AgentState:
    """Load latest checkpoint state for a thread and validate core AgentState shape."""
    cp = checkpointer if checkpointer is not None else await get_checkpointer()
    cfg = {"configurable": {"thread_id": thread_id}}
    row = await _cp_get_tuple(cp, cfg)
    if row is None:
        raise RiceError(
            "Checkpoint not found",
            error_code="MEMORY_CHECKPOINT_NOT_FOUND",
            details={"thread_id": thread_id},
        )
    raw = None
    if isinstance(row, dict):
        raw = row.get("checkpoint") or row.get("state") or row.get("values")
    else:
        raw = getattr(row, "checkpoint", None) or getattr(row, "state", None) or getattr(row, "values", None)
    if raw is None or not isinstance(raw, dict):
        raise RiceError(
            "Checkpoint payload has unexpected format",
            error_code="MEMORY_CHECKPOINT_INVALID",
            details={"thread_id": thread_id},
        )
    state = _state_minimal_validate(raw)
    logger.info("memory load_checkpoint | thread_id={}", thread_id)
    return state


async def delete_history(thread_id: str, checkpointer: Any | None = None) -> None:
    """Delete all checkpoint history for a thread ID."""
    cp = checkpointer if checkpointer is not None else await get_checkpointer()
    await _cp_delete_thread(cp, thread_id)
    logger.info("memory delete_history | thread_id={}", thread_id)


def _sqlite_delete_thread(db_path: str, thread_id: str) -> None:
    con = sqlite3.connect(db_path)
    try:
        cur = con.cursor()
        # Known table names across langgraph sqlite implementations.
        for table in ("checkpoints", "checkpoint", "langgraph_checkpoints"):
            try:
                cur.execute(f"DELETE FROM {table} WHERE thread_id = ?", (thread_id,))
            except sqlite3.Error:
                continue
        con.commit()
    finally:
        con.close()


async def export_session_data(
    thread_id: str,
    *,
    output_dir: str | None = None,
    checkpointer: Any | None = None,
) -> str:
    """Export checkpoint state and key metadata to JSON for .rice portability."""
    state = await load_checkpoint(thread_id, checkpointer=checkpointer)
    out_dir = Path(output_dir or _EXPORT_DIR)
    out_dir.mkdir(parents=True, exist_ok=True)
    stamp = _utcnow().strftime("%Y%m%dT%H%M%SZ")
    out_path = out_dir / f"{thread_id.replace(':', '_')}-{stamp}.json"
    payload = {
        "thread_id": thread_id,
        "exported_at": _utcnow().isoformat(),
        "state": state,
    }
    out_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2, default=str), encoding="utf-8")
    logger.info("memory export_session_data | thread_id={} path={}", thread_id, out_path)
    return str(out_path)


async def cleanup_policy(
    *,
    max_age_days: int = _MEMORY_TTL_DAYS,
    checkpointer: Any | None = None,
) -> dict[str, Any]:
    """Archive/delete sessions older than ``max_age_days`` (best-effort by metadata timestamp)."""
    cp = checkpointer if checkpointer is not None else await get_checkpointer()
    rows = await _cp_list(cp, {})
    cutoff = _utcnow() - timedelta(days=max_age_days)
    deleted: list[str] = []
    skipped: int = 0
    for row in rows:
        tid = _extract_thread_id(row)
        if not tid:
            continue
        ts = None
        if isinstance(row, dict):
            ts = row.get("created_at") or row.get("ts") or row.get("updated_at")
        else:
            ts = getattr(row, "created_at", None) or getattr(row, "ts", None) or getattr(row, "updated_at", None)
        dt = None
        if isinstance(ts, datetime):
            dt = ts.astimezone(UTC)
        elif isinstance(ts, str):
            try:
                dt = datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone(UTC)
            except ValueError:
                dt = None
        if dt is None:
            skipped += 1
            continue
        if dt < cutoff:
            await delete_history(tid, checkpointer=cp)
            deleted.append(tid)
    out = {"deleted": deleted, "deleted_count": len(deleted), "skipped": skipped, "cutoff": cutoff.isoformat()}
    logger.info("memory cleanup_policy | {}", out)
    return out


async def memory_summary_node(state: AgentState) -> dict[str, Any]:
    """Summarize long conversations and store summary in vector memory to control context growth."""
    msgs = list(state.get("messages", []))
    threshold = int(os.getenv("RICE_MEMORY_SUMMARY_THRESHOLD_MESSAGES", "30"))
    if len(msgs) < threshold:
        return {}

    # Keep latest window; summarize older context.
    keep_last = int(os.getenv("RICE_MEMORY_SUMMARY_KEEP_LAST", "12"))
    head = msgs[:-keep_last] if keep_last > 0 else msgs
    if not head:
        return {}

    lines: list[str] = []
    for m in head:
        if isinstance(m, dict):
            role = str(m.get("role") or "unknown")
            content = str(m.get("content") or "")
        else:
            role = str(getattr(m, "role", "unknown"))
            content = str(getattr(m, "content", "") or "")
        if content.strip():
            lines.append(f"[{role}] {content.strip()}")
    if not lines:
        return {}

    summary_text = (
        "Session summary:\n"
        + "\n".join(lines[:200])
    )

    # Store summary in vector memory (best effort).
    try:
        from vector.pipeline import VectorPipeline

        pipe = await VectorPipeline.connect()
        metadata = {
            "source": "agent.memory_summary",
            "thread_id": str(state.get("thread_id") or state.get("metadata", {}).get("thread_id") or ""),
            "kind": "session_summary",
            "ts": _utcnow().isoformat(),
        }
        written = await pipe.ingest_text(summary_text, metadata)
        logger.info("memory_summary_node stored summary | chunks_written={}", written)
    except Exception as exc:  # noqa: BLE001
        logger.warning("memory_summary_node: vector ingest failed | err={!r}", exc)

    ctx = dict(state.get("context") or {})
    ctx["session_summary"] = summary_text[:4000]
    return {
        "context": ctx,
        "metadata": {
            **dict(state.get("metadata") or {}),
            "memory_summary_at": _utcnow().isoformat(),
        },
    }


__all__ = [
    "build_cross_thread_store",
    "build_memory_saver",
    "build_sqlite_saver",
    "cleanup_policy",
    "delete_history",
    "export_session_data",
    "get_checkpointer",
    "get_thread_config",
    "list_active_sessions",
    "load_checkpoint",
    "memory_summary_node",
]
