"""Instructor — modele Pydantic na wyjściu, retry, opcjonalnie partial streaming."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from typing import Any, TypeVar

import instructor
import litellm
from pydantic import BaseModel

TModel = TypeVar("TModel", bound=BaseModel)

# TODO:
# [ ] define base Pydantic output models for all agent outputs:
# [ ]     Plan(steps: list[Step], reasoning: str, confidence: float)
# [ ]     Step(action: str, tool: str | None, args: dict, expected_output: str)
# [ ]     AgentOutput(result: Any, metadata: OutputMetadata, validation: ValidationResult)
# [ ]     OutputMetadata(model: str, tokens: int, latency_ms: float, role: str)
# [ ]     ValidationResult(passed: bool, errors: list[str], reasks: int)
# [ ] define role-specific output models:
# [ ]     MasonOutput(configs: dict[str, str], schemas: list[str])
# [ ]     SmithOutput(service: str, endpoint: str, health: bool)
# [ ]     ClerkOutput(proof: str, verified: bool, signature: str)
# [ ]     BardOutput(component: str, preview_url: str)
# [ ]     SageOutput(prediction: Any, confidence: float, grounded: bool)
# [ ]     ChiefOutput(compiled: bool, targets: list[str], errors: list[str])
# [ ] all models: inherit from BaseModel with model_config = ConfigDict(strict=True)
# [ ] add JSON schema export: each model.model_json_schema() → infra/schemas/


def instructor_client() -> Any:
    """Klient Instructor oparty o `litellm.acompletion` (async)."""
    return instructor.from_litellm(litellm.acompletion)


async def complete_structured(
    response_model: type[TModel],
    *,
    messages: list[dict[str, Any]],
    model: str,
    **kwargs: Any,
) -> TModel:
    """Jedno wywołanie z walidacją Pydantic na wyjściu."""
    client = instructor_client()
    return await client.chat.completions.create(
        model=model,
        messages=messages,
        response_model=response_model,
        **kwargs,
    )
