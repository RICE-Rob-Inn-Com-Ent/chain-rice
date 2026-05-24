"""Walidacja centralna: payloady Pydantic, slugi, modele AI, health-check startu, NATS (szkielet)."""

from __future__ import annotations

import asyncio
import re
from collections.abc import Mapping
from typing import Any, Self, TypeVar
from urllib.parse import urlparse

import httpx
from pydantic import BaseModel, Field, ValidationError as PydanticValidationError, field_validator, model_validator

from .error import ValidationError as RiceValidationError
from .log import get_logger
from .schema import SchemaBase
from .settings import get_settings

TModel = TypeVar("TModel", bound=BaseModel)

# --- prekompilowane wzorce (gorąca ścieżka) ---
_SLUG_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
# Identyfikatory modeli: HF `org/repo`, Ollama `llama3.2`, OpenAI `gpt-4o`, wersjonowanie `2024-06-01`.
_MODEL_NAME_RE = re.compile(
    r"\A[a-zA-Z0-9](?:[a-zA-Z0-9._:/+@~-]*[a-zA-Z0-9])?\Z",
)
_HOST_PORT_RE = re.compile(r"\A[\w.-]+:\d{1,5}\Z")


def validate_slug(v: str) -> str:
    """Identyfikator URL-safe (lowercase, myślniki) — `ValueError` pod `BeforeValidator` Pydantic."""
    s = v.strip().lower()
    if not _SLUG_RE.fullmatch(s):
        msg = "invalid slug format"
        raise ValueError(msg)
    return s


def validate_model_name(v: str) -> str:
    """Nazwa modelu AI (HF / Ollama / vendor); `ValueError` dla integracji z Pydantic."""
    s = str(v).strip()
    if len(s) < 2 or len(s) > 192:
        msg = "model name length must be between 2 and 192"
        raise ValueError(msg)
    if not _MODEL_NAME_RE.fullmatch(s):
        msg = "invalid model name format"
        raise ValueError(msg)
    return s


def validate_payload(model_class: type[TModel], data: Any) -> TModel:
    """`model_validate` / `model_validate_json` — `PydanticValidationError` → `RiceValidationError`."""
    log = get_logger()
    try:
        if isinstance(data, (bytes, bytearray)):
            return model_class.model_validate_json(data)
        if isinstance(data, str):
            stripped = data.strip()
            if stripped.startswith(("{", "[")):
                return model_class.model_validate_json(data)
        if isinstance(data, Mapping):
            return model_class.model_validate(data)
        return model_class.model_validate(data)
    except PydanticValidationError as exc:
        log.bind(model=model_class.__name__).warning(
            "payload validation failed | model={} | error_count={}",
            model_class.__name__,
            len(exc.errors()),
        )
        raise RiceValidationError(
            f"invalid payload for {model_class.__name__}",
            details={"model": model_class.__name__, "errors": exc.errors()},
        ) from exc


async def _tcp_probe(host: str, port: int, *, timeout_s: float) -> None:
    """`asyncio.open_connection` — nieblokujące TCP (Temporal / NATS)."""
    try:
        _reader, writer = await asyncio.wait_for(
            asyncio.open_connection(host, port),
            timeout=timeout_s,
        )
        writer.close()
        try:
            await writer.wait_closed()
        except (ConnectionError, OSError, RuntimeError):
            pass
    except TimeoutError as exc:
        msg = f"tcp timeout {host}:{port}"
        raise RiceValidationError(msg, details={"host": host, "port": port}) from exc
    except OSError as exc:
        msg = f"tcp unreachable {host}:{port}"
        raise RiceValidationError(msg, details={"host": host, "port": port}) from exc


async def _http_probe(client: httpx.AsyncClient, url: str) -> None:
    try:
        resp = await client.head(url, follow_redirects=True)
        if resp.status_code == 405 or resp.status_code == 501:
            resp = await client.get(url, follow_redirects=True)
        if resp.status_code >= 400:
            msg = f"http status {resp.status_code} for {url!r}"
            raise RiceValidationError(
                msg,
                details={"url": url, "status_code": resp.status_code},
            )
    except httpx.HTTPError as exc:
        msg = f"http error for {url!r}"
        raise RiceValidationError(msg, details={"url": url}) from exc


async def check_url_reachability(urls: list[str]) -> None:
    """Fail-fast: HTTP(S) przez `httpx`, `nats://` / `tcp://` / `host:port` przez TCP.

    Pomijane, gdy `settings.test_mode` lub `settings.skip_health_check`.
    """
    settings = get_settings()
    log = get_logger()
    if settings.test_mode or settings.skip_health_check:
        log.info(
            "reachability checks skipped | test_mode={} | skip_health_check={}",
            settings.test_mode,
            settings.skip_health_check,
        )
        return

    timeout = httpx.Timeout(
        connect=float(settings.http_connect_timeout_s),
        read=float(settings.http_read_timeout_s),
        write=float(settings.http_write_timeout_s),
        pool=float(settings.http_pool_timeout_s),
    )
    async with httpx.AsyncClient(timeout=timeout) as client:
        for raw in urls:
            url = raw.strip()
            if not url:
                continue
            lowered = url.lower()
            if lowered.startswith("http://") or lowered.startswith("https://"):
                log.debug("probing http | url={}", url)
                await _http_probe(client, url)
                continue

            if _HOST_PORT_RE.fullmatch(url):
                host, port_s = url.rsplit(":", 1)
                log.debug("probing host:port | host={} | port={}", host, port_s)
                await _tcp_probe(host, int(port_s), timeout_s=float(settings.http_connect_timeout_s))
                continue

            if "://" in url:
                parsed = urlparse(url)
                if parsed.scheme in {"nats", "tls"} and parsed.hostname:
                    port = parsed.port or 4222
                    log.debug("probing nats/tcp | host={} | port={}", parsed.hostname, port)
                    await _tcp_probe(
                        parsed.hostname,
                        port,
                        timeout_s=float(settings.http_connect_timeout_s),
                    )
                    continue
                if parsed.scheme == "tcp" and parsed.hostname and parsed.port:
                    log.debug("probing explicit tcp | host={} | port={}", parsed.hostname, parsed.port)
                    await _tcp_probe(
                        parsed.hostname,
                        int(parsed.port),
                        timeout_s=float(settings.http_connect_timeout_s),
                    )
                    continue

            msg = f"unsupported url scheme or format: {url!r}"
            log.error("reachability probe unsupported | url={}", url)
            raise RiceValidationError(msg, details={"url": url})


async def check_startup_infrastructure() -> None:
    """Kompozycja pod start SAGE: Qdrant, LiteLLM, OTel (HTTP), NATS, Temporal (TCP)."""
    s = get_settings()
    urls: list[str] = [str(s.qdrant.url), str(s.litellm.url)]
    if s.otel.exporter_otlp_endpoint is not None:
        urls.append(str(s.otel.exporter_otlp_endpoint))
    urls.append(str(s.nats.url))
    urls.append(s.temporal.target)
    await check_url_reachability(urls)


class CrossFieldExample(SchemaBase):
    """Cross-field: `start` ≤ `end` (walidacja `model_validator`)."""

    start: int = Field(ge=0)
    end: int = Field(ge=0)

    @model_validator(mode="after")
    def start_before_end(self) -> Self:
        if self.start > self.end:
            msg = "start must be <= end"
            raise ValueError(msg)
        return self


class EmailMixin(SchemaBase):
    """Mixin z normalizacją adresu e-mail."""

    email: str

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value: Any) -> str:
        if value is None or (isinstance(value, str) and not value.strip()):
            msg = "email is required"
            raise ValueError(msg)
        return str(value).strip().lower()


class NatsPayloadValidator:
    """Szkielet: dopasowanie `subject` → `BaseModel` i walidacja payloadu.

    Rozszerz rejestr przy starcie aplikacji (`register`). Dopasowanie: dokładny klucz,
    potem pierwszy prefiks zakończony `.*` / `>` (minimalny prototyp).
    """

    __slots__ = ("_exact", "_prefixes")

    def __init__(self) -> None:
        self._exact: dict[str, type[BaseModel]] = {}
        self._prefixes: list[tuple[str, type[BaseModel]]] = []

    def register(self, subject_pattern: str, model: type[BaseModel]) -> None:
        """Rejestruje schemat; wzorce z `*` na końcu trafiają do listy prefiksów."""
        key = subject_pattern.strip()
        if "*" in key or key.endswith(">"):
            base = key.rstrip(">*") + "."
            self._prefixes.append((base, model))
        else:
            self._exact[key] = model

    def schema_for_subject(self, subject: str) -> type[BaseModel] | None:
        if subject in self._exact:
            return self._exact[subject]
        for prefix, model in self._prefixes:
            if subject.startswith(prefix):
                return model
        return None

    def parse_subject_payload(self, subject: str, payload: Any) -> BaseModel:
        """Waliduje payload dla `subject`; brak schematu → `RiceValidationError`."""
        model = self.schema_for_subject(subject)
        if model is None:
            raise RiceValidationError(
                "no schema registered for NATS subject",
                details={"subject": subject},
            )
        return validate_payload(model, payload)


__all__ = [
    "CrossFieldExample",
    "EmailMixin",
    "NatsPayloadValidator",
    "check_startup_infrastructure",
    "check_url_reachability",
    "validate_model_name",
    "validate_payload",
    "validate_slug",
]
