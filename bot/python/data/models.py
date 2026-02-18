"""Pydantic models for data layer: table configs, query results, column types, validation.

Used by data/tables, data/query, and app/data facade. All field descriptions in English.
"""

from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, Field


# -----------------------------------------------------------------------------
# Table configs
# -----------------------------------------------------------------------------


class ColumnType(str, Enum):
    """Column type for mapping to Arrow/Polars (int64, float64, string, etc.)."""

    INT64 = "int64"
    FLOAT64 = "float64"
    STRING = "string"
    BOOLEAN = "boolean"
    TIMESTAMP = "timestamp"
    BINARY = "binary"


class TableConfig(BaseModel):
    """Table configuration: name, column types, primary key, Parquet options."""

    name: str = Field(description="Table name")
    columns: dict[str, ColumnType] = Field(default_factory=dict)
    primary_key: list[str] = Field(default_factory=list)
    parquet_compression: str = Field(default="snappy")


# -----------------------------------------------------------------------------
# Query result models
# -----------------------------------------------------------------------------


class QueryResult(BaseModel):
    """Query execution result: metadata and row count (success, column_names, error)."""

    row_count: int = Field(ge=0)
    column_names: list[str] = Field(default_factory=list)
    success: bool = True
    error: str | None = None


class ColumnSchema(BaseModel):
    """Schema for a single column (name, dtype, nullable)."""

    name: str
    dtype: str = Field(description="e.g. int64, float64, string")
    nullable: bool = True


# -----------------------------------------------------------------------------
# Validation models
# -----------------------------------------------------------------------------


class ValidationResult(BaseModel):
    """Validation result (e.g. for SQL query safety check)."""

    valid: bool = True
    message: str = ""


class IPCConfig(BaseModel):
    """Configuration for Arrow IPC stream (schema, max recursion depth)."""

    schema_predefined: bool = False
    max_recursion_depth: int = Field(default=64, ge=1, le=256)
