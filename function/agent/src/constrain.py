"""Outlines — wymuszanie formatu na poziomie tokenów (JSON / regex / CFG); walidacja po stronie schematu."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import re
from typing import Any

from pydantic import BaseModel
from typing_extensions import Literal


class ConstraintKind:
    JSON_SCHEMA = "json_schema"
    REGEX = "regex"
    CFG = "cfg"


# TODO:
# [ ] implement instructor structured output extraction:
# [ ]     mode: TOOL_CALL|JSON|MD_JSON|ANTHROPIC_TOOLS — from RICE_INSTRUCTOR_MODE
# [ ]     max_retries from RICE_SAGE_MAX_RETRIES env var
# [ ]     patch LiteLLM client with instructor.patch()
# [ ] implement outlines constrained generation:
# [ ]     JSON schema mode: outlines.generate.json(model, schema)
# [ ]     regex mode: outlines.generate.regex(model, pattern)
# [ ]     choice mode: outlines.generate.choice(model, choices)
# [ ]     model loaded from RICE_OUTLINES_MODEL env var
# [ ] implement guardrails output validation:
# [ ]     load guard config from function/agent/src/guards/*.xml or python guards
# [ ]     RICE_GUARDRAILS_CONFIG env var points to config file
# [ ]     on_fail: REASK|NOOP|EXCEPTION|FIX — from RICE_GUARDRAILS_ON_FAIL
# [ ] implement typed output dispatch:
# [ ]     select constrain method based on RICE_CONSTRAIN_MODE env var
# [ ]     instructor: best for tool_call models
# [ ]     outlines: best for local models without tool support
# [ ]     guardrails: always runs as post-validation layer


def validate_json_to_model[T: BaseModel](model: type[T], raw: str) -> T:
    """Parsuje JSON do modelu Pydantic — twarda gwarancja struktury po generacji."""
    return model.model_validate_json(raw)


def match_regex(pattern: str, text: str) -> bool:
    """Regex jako prosty constraint na pełny tekst odpowiedzi."""
    return re.fullmatch(pattern, text, flags=re.DOTALL) is not None


def outlines_json_schema_hook(schema: dict[str, Any]) -> dict[str, Any]:
    """Zwraca uchwyt schematu dla integracji Outlines (generator podłączany do modelu lokalnego).

    Outlines wymaga backendu (Transformers/vLLM/llamacpp) — tu tylko przekazujemy metadane;
    faktyczne constrained decoding ustawiasz w pipeline z modelem Outlines.
    """
    return {"kind": ConstraintKind.JSON_SCHEMA, "schema": schema}


def outlines_regex_hook(pattern: str) -> dict[str, Any]:
    """Metadane pod regex constraint (Outlines `regex`)."""
    return {"kind": ConstraintKind.REGEX, "pattern": pattern}


def outlines_cfg_hook(grammar: str) -> dict[str, Any]:
    """Metadane pod CFG — np. gramatyka Lark/EBNF zależnie od backendu Outlines."""
    return {"kind": ConstraintKind.CFG, "grammar": grammar}


def constraint_mode() -> Literal["post", "outlines"]:
    """Tryb: `post` = walidacja po generacji; `outlines` = constrained decoding (osobna konfiguracja)."""
    return "post"
