"""Vector package logging — scoped loggers for Qdrant and retrieval I/O."""

from __future__ import annotations

from helper import logger

store_logger = logger.bind(component="vector.store")

__all__ = ["logger", "store_logger"]
