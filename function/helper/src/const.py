"""Niezmienne stałe infrastruktury modułu `helper` (ścieżki, logi, retry, walidacja, I/O).

Wartości są ładowane raz przy imporcie — bez alokacji w pętli gorących ścieżek.
"""

from __future__ import annotations

from pathlib import Path
from typing import Final

from pydantic import ConfigDict
from pydantic_settings import SettingsConfigDict

# ---------------------------------------------------------------------------
# [FILESYSTEM]
# ---------------------------------------------------------------------------

# Katalog pakietu źródłowego (`.../helper/src`).
HELPER_SRC_DIR: Final[Path] = Path(__file__).resolve().parent

# Katalog projektu wheel (`.../helper/`, obok `pyproject.toml`).
HELPER_MODULE_ROOT: Final[Path] = HELPER_SRC_DIR.parent

# Domyślny katalog plików logów (tworzony przez aplikację, nie przy imporcie).
HELPER_DEFAULT_LOG_DIR: Final[Path] = HELPER_MODULE_ROOT / "logs"

# Rezerwa: dane pomocnicze cache/state (np. pliki tymczasowe walidacji).
HELPER_DEFAULT_DATA_DIR: Final[Path] = HELPER_MODULE_ROOT / "var" / "helper"

# ---------------------------------------------------------------------------
# [LOGGING] — loguru: format, rotacja, retencja, kompresja
# ---------------------------------------------------------------------------

# Zgodne z `log.configure_logging` — czytelny stderr w dev.
LOGURU_FORMAT_TEXT: Final[str] = (
    "<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | "
    "<level>{level: <8}</level> | "
    "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
    "<level>{message}</level>"
)

# Strukturalny jednowierszowy (serialize=True); pola typowe dla agregacji.
LOGURU_FORMAT_JSON_FIELDS: Final[str] = (
    "{time:YYYY-MM-DDTHH:mm:ss.SSSZ} | {level} | {name}:{function}:{line} | {message}"
)

# Fragment `{time:...}` dla sinków tekstowych (składnia czasu loguru, nie strftime).
DATETIME_FORMAT: Final[str] = "YYYY-MM-DD HH:mm:ss.SSS"

LOGURU_ROTATION_SIZE: Final[str] = "20 MB"
LOGURU_RETENTION: Final[str] = "14 days"
LOGURU_COMPRESSION: Final[str] = "zip"
LOGURU_ENQUEUE: Final[bool] = True
LOGURU_BACKTRACE: Final[bool] = False
LOGURU_DIAGNOSE: Final[bool] = False

# Limity bufora sinków plikowych (rekordy w kolejce przed zapisem dyskowym).
LOGURU_SINK_QUEUE_SIZE: Final[int] = 256

# ---------------------------------------------------------------------------
# [RETRY_POLICY] — domyślne wartości pod `tenacity.wait_exponential` / `stop_after_attempt`
# ---------------------------------------------------------------------------

RETRY_DEFAULT_MAX_ATTEMPTS: Final[int] = 4
RETRY_DEFAULT_MULTIPLIER: Final[float] = 1.0
RETRY_EXPONENTIAL_MIN_S: Final[float] = 0.5
RETRY_EXPONENTIAL_MAX_S: Final[float] = 8.0

RETRY_IDEMPOTENT_MAX_ATTEMPTS: Final[int] = 3
RETRY_IDEMPOTENT_WAIT_S: Final[float] = 1.0

RETRY_JITTER_MAX_ATTEMPTS: Final[int] = 5
RETRY_JITTER_MULTIPLIER: Final[float] = 1.0
RETRY_JITTER_MIN_S: Final[float] = 1.0
RETRY_JITTER_MAX_S: Final[float] = 60.0

RETRY_MESSAGE_MATCH_MAX_ATTEMPTS: Final[int] = 5
RETRY_MESSAGE_MATCH_MIN_S: Final[float] = 1.0
RETRY_MESSAGE_MATCH_MAX_S: Final[float] = 20.0

# Łączny limit czasu strategii `stop_after_delay` (sekundy) — szablon pod wywołania.
RETRY_DEFAULT_BUDGET_S: Final[float] = 120.0

# Aliasy API dla `retry.py` / metryk (spójne nazewnictwo zewnętrzne).
MAX_RETRY_ATTEMPTS: Final[int] = RETRY_DEFAULT_MAX_ATTEMPTS
RETRY_BACKOFF_MIN: Final[float] = RETRY_EXPONENTIAL_MIN_S
RETRY_BACKOFF_MAX: Final[float] = RETRY_EXPONENTIAL_MAX_S

# ---------------------------------------------------------------------------
# [VALIDATION] — kodowanie, ISO 8601, domyślne `ConfigDict` dla modeli pomocniczych
# ---------------------------------------------------------------------------

DEFAULT_TEXT_ENCODING: Final[str] = "utf-8"

# Alias dla `pydantic-settings` / odczytu `.env` (jedna nazwa w całym helperze).
ENCODING: Final[str] = DEFAULT_TEXT_ENCODING

# Wzorzec strftime UTC z sufiksem `Z` (prezentacja / logi).
# Serializacja JSON zwykle przez `datetime.isoformat`.
DATETIME_ISO8601_UTC_STRFTIME: Final[str] = "%Y-%m-%dT%H:%M:%S.%fZ"

# Alias semantyczny dla pól daty bez czasu (kontrakty dokumentacyjne / walidatory custom).
DATE_ISO8601_STRFTIME: Final[str] = "%Y-%m-%d"

# Schematy bazowe: ścisłe API, brak nieznanych pól (modele domenowe helpera).
PYDANTIC_SCHEMA_CONFIG: Final[ConfigDict] = ConfigDict(
    str_strip_whitespace=True,
    validate_assignment=True,
    extra="forbid",
    use_enum_values=True,
    validate_default=True,
)

# Ustawienia runtime z env — ignoruj nadmiarowe klucze (kompatybilność `.env`).
PYDANTIC_SETTINGS_CONFIG_DEFAULTS: Final[SettingsConfigDict] = SettingsConfigDict(
    env_file_encoding=DEFAULT_TEXT_ENCODING,
    extra="ignore",
    case_sensitive=False,
)

# ---------------------------------------------------------------------------
# [NETWORK/IO] — timeouts i bufory dla funkcji pomocniczych (httpx/aiofiles itp.)
# ---------------------------------------------------------------------------

IO_CONNECT_TIMEOUT_S: Final[float] = 5.0
IO_READ_TIMEOUT_S: Final[float] = 30.0
IO_WRITE_TIMEOUT_S: Final[float] = 30.0
IO_POOL_TIMEOUT_S: Final[float] = 5.0

IO_SOCKET_TIMEOUT_S: Final[float] = 30.0

# Bufory strumieniowe (odczyt/zapis ogólnego przeznaczenia).
IO_STREAM_BUFFER_BYTES: Final[int] = 64 * 1024
IO_LINE_BUFFER_BYTES: Final[int] = 8 * 1024

# Limit pojedynczego bloku przy chunked read (np. `iter_chunked`).
IO_CHUNK_MAX_BYTES: Final[int] = 1 << 20

# ---------------------------------------------------------------------------
# [ERRORS] — prefiksy kodów błędów (SAGE / helper, hermetyczny kontrakt)
# ---------------------------------------------------------------------------

ERROR_CODE_PREFIX: Final[str] = "SAGE_"

__all__ = [
    "DATETIME_FORMAT",
    "DATETIME_ISO8601_UTC_STRFTIME",
    "DATE_ISO8601_STRFTIME",
    "DEFAULT_TEXT_ENCODING",
    "ENCODING",
    "ERROR_CODE_PREFIX",
    "HELPER_DEFAULT_DATA_DIR",
    "HELPER_DEFAULT_LOG_DIR",
    "HELPER_MODULE_ROOT",
    "HELPER_SRC_DIR",
    "IO_CHUNK_MAX_BYTES",
    "IO_CONNECT_TIMEOUT_S",
    "IO_LINE_BUFFER_BYTES",
    "IO_POOL_TIMEOUT_S",
    "IO_READ_TIMEOUT_S",
    "IO_SOCKET_TIMEOUT_S",
    "IO_STREAM_BUFFER_BYTES",
    "IO_WRITE_TIMEOUT_S",
    "LOGURU_BACKTRACE",
    "LOGURU_COMPRESSION",
    "LOGURU_DIAGNOSE",
    "LOGURU_ENQUEUE",
    "LOGURU_FORMAT_JSON_FIELDS",
    "LOGURU_FORMAT_TEXT",
    "LOGURU_RETENTION",
    "LOGURU_ROTATION_SIZE",
    "LOGURU_SINK_QUEUE_SIZE",
    "MAX_RETRY_ATTEMPTS",
    "PYDANTIC_SCHEMA_CONFIG",
    "PYDANTIC_SETTINGS_CONFIG_DEFAULTS",
    "RETRY_BACKOFF_MAX",
    "RETRY_BACKOFF_MIN",
    "RETRY_DEFAULT_BUDGET_S",
    "RETRY_DEFAULT_MAX_ATTEMPTS",
    "RETRY_DEFAULT_MULTIPLIER",
    "RETRY_EXPONENTIAL_MAX_S",
    "RETRY_EXPONENTIAL_MIN_S",
    "RETRY_IDEMPOTENT_MAX_ATTEMPTS",
    "RETRY_IDEMPOTENT_WAIT_S",
    "RETRY_JITTER_MAX_ATTEMPTS",
    "RETRY_JITTER_MAX_S",
    "RETRY_JITTER_MIN_S",
    "RETRY_JITTER_MULTIPLIER",
    "RETRY_MESSAGE_MATCH_MAX_ATTEMPTS",
    "RETRY_MESSAGE_MATCH_MAX_S",
    "RETRY_MESSAGE_MATCH_MIN_S",
]
