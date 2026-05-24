"""Hermetyczna konfiguracja infrastruktury `.rice` — pydantic-settings, prefiks `RICE_`, singleton."""

from __future__ import annotations

import urllib.error
import urllib.request
from functools import lru_cache
from pathlib import Path
from typing import Annotated, Literal, Self, cast

from pydantic import (
    AnyHttpUrl,
    AnyUrl,
    BaseModel,
    ConfigDict,
    Field,
    SecretStr,
    UrlConstraints,
    model_validator,
)
from pydantic_settings import BaseSettings, SettingsConfigDict

from . import const

NatsUrl = Annotated[AnyUrl, UrlConstraints(allowed_schemes=["nats", "tls"])]


def _find_env_file() -> Path | None:
    """Szuka `.env` w łańcuchu katalogów w górę od `helper/`, potem w CWD (layout mono / `.rice`)."""
    cur = const.HELPER_MODULE_ROOT.resolve()
    for _ in range(12):
        candidate = cur / ".env"
        if candidate.is_file():
            return candidate
        if cur.parent == cur:
            break
        cur = cur.parent
    cwd_candidate = Path.cwd().resolve() / ".env"
    return cwd_candidate if cwd_candidate.is_file() else None


def _http_endpoint_reachable(url: str, *, timeout_s: float) -> bool:
    """Lekki sond HEAD z fallbackiem GET (bez zewnętrznych zależności)."""
    headers = {"User-Agent": "rice-helper-settings/1"}
    for method in ("HEAD", "GET"):
        try:
            req = urllib.request.Request(url, method=method, headers=headers)
            with urllib.request.urlopen(req, timeout=timeout_s) as resp:  # noqa: S310 — celowy health-check
                return resp.getcode() < 600
        except (urllib.error.URLError, TimeoutError, OSError):
            continue
    return False


class NatsSettings(BaseModel):
    """Połączenie NATS (`nats://` / `tls://` — nie HTTP)."""

    model_config = ConfigDict(extra="ignore")
    url: NatsUrl = Field(default=cast(AnyUrl, "nats://nats:4222"))


class QdrantSettings(BaseModel):
    """HTTP API Qdrant + opcjonalny klucz (SecretStr — bezpieczne logowanie)."""

    model_config = ConfigDict(extra="ignore")
    url: AnyHttpUrl = Field(default=cast(AnyHttpUrl, "http://qdrant:6333"))
    api_key: SecretStr | None = None


class TemporalSettings(BaseModel):
    """Adres front-endu / worker target (host:port) i namespace."""

    model_config = ConfigDict(extra="ignore")
    target: str = Field(default="temporal:7233", min_length=1, max_length=512)
    namespace: str = Field(default="rice", min_length=1, max_length=256)


class OtelSettings(BaseModel):
    """Eksport OTLP (HTTP) + nazwa usługi."""

    model_config = ConfigDict(extra="ignore")
    exporter_otlp_endpoint: AnyHttpUrl | None = None
    service_name: str = Field(default="rice-helper", min_length=1, max_length=256)


class LitellmSettings(BaseModel):
    """HTTP brama LiteLLM + klucz API (SecretStr)."""

    model_config = ConfigDict(extra="ignore")
    url: AnyHttpUrl = Field(default=cast(AnyHttpUrl, "http://litellm:4000"))
    api_key: SecretStr | None = None


class HelperSettings(BaseSettings):
    """Tylko infrastruktura: logi, OTel, NATS, Temporal, Qdrant, LiteLLM, timeouty."""

    model_config = SettingsConfigDict(
        env_prefix="RICE_",
        env_file=_find_env_file(),
        env_file_encoding=const.ENCODING,
        env_nested_delimiter="__",
        extra="ignore",
        case_sensitive=False,
    )

    app_env: Literal["local", "dev", "staging", "prod"] = "local"
    test_mode: bool = Field(default=False, description="Gdy true — pomija sondy sieciowe (CI / unit).")
    skip_health_check: bool = Field(
        default=False,
        description="Gdy true — pomija sondy HTTP mimo że test_mode jest false (dev bez stacku).",
    )

    log_level: str = Field(default="INFO", min_length=1, max_length=32)
    log_format: Literal["text", "json"] = Field(
        default="text",
        description="`json` → loguru `serialize=True` (Docker / prod); `text` → kolorowany stderr.",
    )
    log_json: bool = Field(
        default=False,
        description="Kompatybilność wsteczna: gdy true, traktuj jak `log_format=json`.",
    )
    log_role: str = Field(default="helper", min_length=1, max_length=128)
    log_mask_field_names: str = Field(
        default="api_key,password,token,secret,authorization",
        max_length=2048,
        description="Lista nazw (CSV) — maskowanie dopasowania `substring` w kluczach `extra`.",
    )
    log_debug_sample_rate: float = Field(
        default=1.0,
        ge=0.0,
        le=1.0,
        description="1.0 = wszystkie DEBUG; 0.1 ≈ 10% linii DEBUG (INFO+ zawsze w całości).",
    )
    log_text_format: str = Field(default=const.LOGURU_FORMAT_TEXT, max_length=8192)
    log_json_fields: str = Field(default=const.LOGURU_FORMAT_JSON_FIELDS, max_length=4096)

    nats_serializer: Literal["json", "msgpack"] = Field(
        default="json",
        description="Format serializacji ładunków NATS w helperze (`encode_nats_payload` / `decode_nats_payload`).",
    )

    @property
    def log_mask_tokens(self) -> tuple[str, ...]:
        """Tokeny maskowania (lowercase) — dopasowanie `substring` w kluczach `extra`."""
        return tuple(
            part.strip().lower()
            for part in self.log_mask_field_names.split(",")
            if part.strip()
        )

    nats: NatsSettings = Field(default_factory=lambda: NatsSettings())
    qdrant: QdrantSettings = Field(default_factory=lambda: QdrantSettings())
    temporal: TemporalSettings = Field(default_factory=lambda: TemporalSettings())
    otel: OtelSettings = Field(default_factory=lambda: OtelSettings())
    litellm: LitellmSettings = Field(default_factory=lambda: LitellmSettings())

    http_connect_timeout_s: float = Field(default=const.IO_CONNECT_TIMEOUT_S, gt=0, le=300.0)
    http_read_timeout_s: float = Field(default=const.IO_READ_TIMEOUT_S, gt=0, le=600.0)
    http_pool_timeout_s: float = Field(default=const.IO_POOL_TIMEOUT_S, gt=0, le=300.0)
    infra_retry_max_attempts: int = Field(default=const.RETRY_DEFAULT_MAX_ATTEMPTS, ge=1, le=64)
    retry_exponential_min_s: float = Field(default=const.RETRY_EXPONENTIAL_MIN_S, gt=0.0, le=120.0)
    retry_exponential_max_s: float = Field(default=const.RETRY_EXPONENTIAL_MAX_S, gt=0.0, le=600.0)
    retry_jitter_min_s: float = Field(default=const.RETRY_JITTER_MIN_S, gt=0.0, le=120.0)
    retry_jitter_max_s: float = Field(default=const.RETRY_JITTER_MAX_S, gt=0.0, le=600.0)
    retry_jitter_multiplier: float = Field(default=const.RETRY_JITTER_MULTIPLIER, gt=0.0, le=30.0)
    retry_jitter_max_attempts: int = Field(default=const.RETRY_JITTER_MAX_ATTEMPTS, ge=1, le=64)
    retry_idempotent_max_attempts: int = Field(default=const.RETRY_IDEMPOTENT_MAX_ATTEMPTS, ge=1, le=64)
    retry_idempotent_wait_s: float = Field(default=const.RETRY_IDEMPOTENT_WAIT_S, gt=0.0, le=300.0)
    retry_message_match_max_attempts: int = Field(
        default=const.RETRY_MESSAGE_MATCH_MAX_ATTEMPTS,
        ge=1,
        le=64,
    )
    retry_message_min_s: float = Field(default=const.RETRY_MESSAGE_MATCH_MIN_S, gt=0.0, le=120.0)
    retry_message_max_s: float = Field(default=const.RETRY_MESSAGE_MATCH_MAX_S, gt=0.0, le=600.0)

    use_reranker: bool = Field(
        default=False,
        description="When true, ``vector.VectorPipeline.search`` may run cross-encoder reranking after hybrid retrieval.",
    )

    @model_validator(mode="after")
    def validate_http_endpoints_reachable(self) -> Self:
        """Walidacja osiągalności endpointów HTTP — wyłączona w testach lub przy `skip_health_check`."""
        if self.test_mode or self.skip_health_check:
            return self
        timeout = float(self.http_connect_timeout_s)
        checks: list[tuple[str, AnyHttpUrl]] = [
            ("RICE_QDRANT__URL", self.qdrant.url),
            ("RICE_LITELLM__URL", self.litellm.url),
        ]
        if self.otel.exporter_otlp_endpoint is not None:
            checks.append(("RICE_OTEL__EXPORTER_OTLP_ENDPOINT", self.otel.exporter_otlp_endpoint))
        failures: list[str] = []
        for env_hint, endpoint in checks:
            url = str(endpoint)
            if not _http_endpoint_reachable(url, timeout_s=timeout):
                failures.append(f"{env_hint} ({url})")
        if failures:
            msg = "infrastructure HTTP health check failed for: " + ", ".join(failures)
            raise ValueError(msg)
        return self

    @property
    def qdrant_url(self) -> str:
        """Qdrant HTTP base URL (string form of ``qdrant.url``)."""
        return str(self.qdrant.url)

    @property
    def qdrant_api_key(self) -> str | None:
        """Qdrant API key when configured; otherwise ``None``."""
        secret = self.qdrant.api_key
        return secret.get_secret_value() if secret is not None else None


@lru_cache(maxsize=1)
def get_settings() -> HelperSettings:
    """Singleton ustawień — w testach: `get_settings.cache_clear()`."""
    return HelperSettings()
