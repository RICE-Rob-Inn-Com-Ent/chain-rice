"""Pydantic — walidatory modelu/pól i reguły cross-field."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import re
from typing import Any, Self

from pydantic import BaseModel, Field, field_validator, model_validator

# TODO:
# [ ] implement pydantic model validator factory:
# [ ]     validate_payload(model: Type[T], data: dict) → T | ValidationError
# [ ]     wraps ValidationError with RiceError schema from schema.py
# [ ] implement NATS payload validator:
# [ ]     validate incoming NATS message payload against registered schemas
# [ ]     schema registry: dict[subject_pattern, BaseModel] — loaded on startup
# [ ] implement env var validator:
# [ ]     validate all required env vars on startup
# [ ]     fail fast with clear error if required var missing
# [ ] implement URL reachability validator:
# [ ]     check Qdrant, NATS, Temporal URLs on startup
# [ ]     skip when RICE_TEST_MODE=true or RICE_SKIP_HEALTH_CHECK=true
# [ ] implement Pydantic custom validators:
# [ ]     positive_int, non_empty_str, valid_url, valid_model_name
# [ ]     reusable across all SAGE schemas

_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def validate_slug(v: str) -> str:
    """Identyfikator URL-safe (lowercase, myślniki)."""
    s = v.strip().lower()
    if not _SLUG.fullmatch(s):
        msg = "invalid slug format"
        raise ValueError(msg)
    return s


class CrossFieldExample(BaseModel):
    """Przykład cross-field: `start` musi być ≤ `end`."""

    start: int = Field(ge=0)
    end: int = Field(ge=0)

    @model_validator(mode="after")
    def start_before_end(self) -> Self:
        if self.start > self.end:
            msg = "start must be <= end"
            raise ValueError(msg)
        return self


class EmailMixin(BaseModel):
    """Mixin z normalizacją adresu e-mail."""

    email: str

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value: Any) -> str:
        if value is None or (isinstance(value, str) and not value.strip()):
            msg = "email is required"
            raise ValueError(msg)
        return str(value).strip().lower()
