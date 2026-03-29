"""LangGraph — checkpointing (MemorySaver, SqliteSaver), pamięć między wątkami, store."""

from __future__ import annotations

import os

from langgraph.checkpoint.memory import MemorySaver
from langgraph.store.memory import InMemoryStore
from loguru import logger

try:
    from langgraph.checkpoint.sqlite import SqliteSaver
except ImportError:  # opcjonalny pakiet `langgraph-checkpoint-sqlite`
    SqliteSaver = None  # type: ignore[misc, assignment]

# TODO:
# [ ] implement short-term memory: LangGraph checkpointer
# [ ]     dev: AsyncSqliteSaver (path from RICE_CHECKPOINTER_PATH env)
# [ ]     prod: AsyncPostgresSaver (DB_URL from env)
# [ ]     thread_id = session_id — soft-coded per conversation
# [ ] implement long-term memory: Qdrant-backed semantic store
# [ ]     collection = RICE_MEMORY_COLLECTION env var
# [ ]     embed before store via agent/src/embed (calls vector/embed.py)
# [ ]     retrieve top-k = RICE_MEMORY_TOP_K env var
# [ ] implement memory summary: summarize old messages when context > threshold
# [ ]     threshold from RICE_CONTEXT_THRESHOLD_TOKENS env var
# [ ]     summarizer model = RICE_SUMMARY_MODEL env var
# [ ] implement memory namespacing: per-project, per-role, per-user
# [ ]     namespace pattern: {project}/{role}/{user_id} — soft-coded
# [ ] implement memory TTL: expire long-term memories after RICE_MEMORY_TTL_DAYS
# [ ] implement cross-session memory: retrieve relevant memories across sessions
# [ ]     triggered when new session starts, top-k from RICE_CROSS_SESSION_K


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
