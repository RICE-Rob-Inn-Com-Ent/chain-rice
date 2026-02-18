"""Application configuration from environment variables.

Single source of truth for all configuration. Zero hardcoded business values.
Uses pydantic-settings BaseSettings with env_file=.env and @lru_cache singleton.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Optional

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application configuration loaded from environment variables.

    All values are read from env (or .env file). Categories: APP_*, LITELLM_*,
    ENABLE_*, QDRANT_*, DUCKDB_*, CUDA_*, LOG_*, CORS_*, security-related.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # -------------------------------------------------------------------------
    # APP_* - Application metadata
    # -------------------------------------------------------------------------
    APP_TITLE: str = "rice-bot"
    """Service title for OpenAPI and docs."""

    APP_VERSION: str = "1.0.0"
    """API version string."""

    APP_HOST: str = "0.0.0.0"
    """Bind host for uvicorn."""

    APP_PORT: int = 8000
    """Bind port for uvicorn."""

    APP_ENV: str = "development"
    """Environment: development, staging, production."""

    # -------------------------------------------------------------------------
    # LITELLM_* - LLM provider settings
    # -------------------------------------------------------------------------
    LITELLM_API_KEY: str = ""
    """API key for LLM provider (OpenAI/Anthropic/etc). Required for chat/agents."""

    LITELLM_MODEL: str = "gpt-4o-mini"
    """Model identifier (e.g. gpt-4o-mini, claude-3-haiku)."""

    LITELLM_TEMPERATURE: float = 0.7
    """Sampling temperature (0.0-2.0)."""

    LITELLM_MAX_TOKENS: int = 2000
    """Maximum tokens in response."""

    LITELLM_TIMEOUT: int = 30
    """Request timeout in seconds."""

    # -------------------------------------------------------------------------
    # ENABLE_* - Feature flags
    # -------------------------------------------------------------------------
    ENABLE_AGENTS: bool = False
    """Enable LangGraph/CrewAI agent endpoints (chat, extract)."""

    ENABLE_QUANTUM: bool = False
    """Enable quantum simulation endpoints."""

    ENABLE_DATA: bool = True
    """Enable data/query endpoints."""

    ENABLE_GPU: bool = False
    """Enable GPU/embedding endpoints (requires job extra)."""

    ENABLE_SECURITY_SCANS: bool = False
    """Enable security scan endpoints (Bandit, pip-audit)."""

    # -------------------------------------------------------------------------
    # QDRANT_* - Vector store (optional, model extra)
    # -------------------------------------------------------------------------
    QDRANT_URL: str = "http://localhost:6333"
    """Qdrant server URL."""

    QDRANT_API_KEY: str = ""
    """Optional API key for Qdrant."""

    QDRANT_COLLECTION_NAME: str = "documents"
    """Default collection name."""

    QDRANT_VECTOR_SIZE: int = 384
    """Embedding dimension for collection."""

    # -------------------------------------------------------------------------
    # DUCKDB_* - Analytical database
    # -------------------------------------------------------------------------
    DUCKDB_PATH: str = ":memory:"
    """DuckDB path. Use :memory: for in-memory or file path."""

    DUCKDB_MEMORY_LIMIT: str = "2GB"
    """Memory limit for DuckDB (e.g. 2GB)."""

    DUCKDB_THREADS: int = 4
    """Number of threads for DuckDB."""

    # -------------------------------------------------------------------------
    # CUDA_* / TORCH_* - GPU (optional, job extra)
    # -------------------------------------------------------------------------
    CUDA_VISIBLE_DEVICES: str = ""
    """Comma-separated GPU indices (e.g. 0,1). Empty = all."""

    CUDA_MEMORY_FRACTION: float = 0.8
    """Fraction of GPU memory to allow (0.0-1.0)."""

    TORCH_HOME: str = ""
    """Path for PyTorch model cache. Empty = default."""

    # -------------------------------------------------------------------------
    # LOG_* - Logging
    # -------------------------------------------------------------------------
    LOG_LEVEL: str = "INFO"
    """Log level: DEBUG, INFO, WARNING, ERROR, CRITICAL."""

    LOG_FORMAT: str = "json"
    """Output format: json or text."""

    LOG_FILE_PATH: Optional[str] = None
    """Optional file path for log output. None = stdout only."""

    # -------------------------------------------------------------------------
    # Security / audit
    # -------------------------------------------------------------------------
    BANDIT_SEVERITY_THRESHOLD: str = "MEDIUM"
    """Minimum severity to report: LOW, MEDIUM, HIGH."""

    AUDIT_FAIL_ON_CVE: bool = True
    """Whether to fail on critical CVE in audit."""

    GUARDRAILS_PII_SCRUB: bool = True
    """Whether to scrub PII in guardrails."""

    # -------------------------------------------------------------------------
    # CORS
    # -------------------------------------------------------------------------
    CORS_ALLOW_ORIGINS: str = "http://localhost:3000"
    """Comma-separated list of allowed origins. Empty = allow all."""

    CORS_ALLOW_CREDENTIALS: bool = True
    """Allow credentials in CORS."""

    # -------------------------------------------------------------------------
    # Agent / LangGraph
    # -------------------------------------------------------------------------
    AGENT_RECURSION_LIMIT: int = 10
    """Max steps in LangGraph to prevent runaway loops."""

    @field_validator("CORS_ALLOW_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: object) -> str:
        """Keep as string; app will split when building CORSMiddleware."""
        if isinstance(v, list):
            return ",".join(str(x) for x in v)
        return str(v) if v is not None else ""

    def cors_origin_list(self) -> list[str]:
        """Return CORS origins as list. Empty string means allow all (use ['*'] in middleware)."""
        raw = (self.CORS_ALLOW_ORIGINS or "").strip()
        if not raw:
            return ["*"]
        return [x.strip() for x in raw.split(",") if x.strip()]


@lru_cache
def get_settings() -> Settings:
    """Return cached settings instance (singleton)."""
    return Settings()


# Backwards compatibility: expose settings instance and common names as attributes
def _settings() -> Settings:
    return get_settings()


# Allow `from app.config import settings` for existing code
class _SettingsProxy:
    """Proxy so that settings.APP_TITLE etc. work and remain up-to-date with get_settings()."""

    def __getattr__(self, name: str):  # noqa: ANN401
        return getattr(get_settings(), name)


settings = _SettingsProxy()
