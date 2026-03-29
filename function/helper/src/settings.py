"""Pydantic Settings — konfiguracja z env, sekretów i pliku `.env`."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

# TODO:
# [ ] implement BaseSettings via pydantic-settings:
# [ ]     env_file = ".env", env_file_encoding = "utf-8"
# [ ]     env_prefix = "RICE_" — all settings prefixed
# [ ] define SageSettings model:
# [ ]     backend: Literal["ollama","vllm","litellm"] = "ollama"
# [ ]     vllm_url: AnyHttpUrl = "http://vllm:8000"
# [ ]     ollama_url: AnyHttpUrl = "http://ollama:11434"
# [ ]     litellm_url: AnyHttpUrl = "http://litellm:4000"
# [ ]     sage_port: int = 8001
# [ ]     sage_log_level: str = "INFO"
# [ ]     sage_max_retries: int = 3
# [ ]     sage_timeout_s: int = 30
# [ ]     qdrant_url: AnyHttpUrl = "http://qdrant:6333"
# [ ]     nats_url: str = "nats://nats:4222"
# [ ]     temporal_url: str = "temporal:7233"
# [ ]     temporal_namespace: str = "rice"
# [ ]     embedding_model: str — no default, required
# [ ]     embedding_dim: int — no default, required
# [ ]     chunk_size: int = 512
# [ ]     chunk_overlap: int = 64
# [ ]     gpu_max_temp_c: float = 83.0
# [ ]     gpu_resume_temp_c: float = 75.0
# [ ] implement settings singleton: lru_cache(maxsize=1) get_settings()
# [ ] implement settings validation: @model_validator checks url reachability
# [ ]     only in non-test mode: skip when RICE_TEST_MODE=true
# [ ] implement secrets loading: pydantic-settings SecretStr for keys
# [ ]     qdrant_api_key: SecretStr | None = None
# [ ]     litellm_master_key: SecretStr | None = None


def _find_env_file() -> Path | None:
    """Szuka `.env` w katalogu `function/` lub CWD."""
    here = Path(__file__).resolve().parent.parent
    for candidate in (here / ".env", Path.cwd() / ".env"):
        if candidate.is_file():
            return candidate
    return None


class HelperSettings(BaseSettings):
    """Wspólne ustawienia runtime (bez danych projektowych — tylko infrastruktura)."""

    model_config = SettingsConfigDict(
        env_file=_find_env_file(),
        env_file_encoding="utf-8",
        env_nested_delimiter="__",
        extra="ignore",
        case_sensitive=False,
    )

    app_env: Literal["local", "dev", "staging", "prod"] = Field(default="local")
    log_level: str = Field(default="INFO")

    litellm_api_key: SecretStr | None = Field(default=None, validation_alias="LITELLM_API_KEY")
    openai_api_key: SecretStr | None = Field(default=None, validation_alias="OPENAI_API_KEY")

    enable_agents: bool = Field(default=True, validation_alias="ENABLE_AGENTS")
    enable_quantum: bool = Field(default=False, validation_alias="ENABLE_QUANTUM")
    enable_data: bool = Field(default=True, validation_alias="ENABLE_DATA")
    enable_gpu: bool = Field(default=False, validation_alias="ENABLE_GPU")

    otel_exporter_otlp_endpoint: str | None = Field(
        default=None,
        validation_alias="OTEL_EXPORTER_OTLP_ENDPOINT",
    )
    otel_service_name: str = Field(default="rice-helper", validation_alias="OTEL_SERVICE_NAME")


@lru_cache
def get_settings() -> HelperSettings:
    """Singleton ustawień — czyść cache w testach: `get_settings.cache_clear()`."""
    return HelperSettings()
