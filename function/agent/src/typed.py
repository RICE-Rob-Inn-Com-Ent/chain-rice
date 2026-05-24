"""Instructor — modele Pydantic na wyjściu, retry, opcjonalnie partial streaming."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

from enum import Enum
from typing import Any, Literal, TypeVar

import instructor
import litellm
from helper import SchemaBase
from pydantic import BaseModel, Field

TModel = TypeVar("TModel", bound=BaseModel)


class AgentRole(str, Enum):
    ARCHITECT = "architect"
    CODER = "coder"
    SCIENTIST = "scientist"
    CRITIC = "critic"


class ToolCall(SchemaBase):
    """One structured tool invocation requested by the LLM."""

    id: str = Field(min_length=1)
    name: str = Field(min_length=1)
    arguments: dict[str, Any] = Field(default_factory=dict)
    type: Literal["function"] = "function"


class ToolResult(SchemaBase):
    """Result payload returned after tool execution."""

    tool_call_id: str = Field(min_length=1)
    name: str = Field(min_length=1)
    content: str = ""
    is_error: bool = False
    metadata: dict[str, Any] = Field(default_factory=dict)


class RiceMessage(SchemaBase):
    """OpenAI/LiteLLM-like chat message with SAGE metadata."""

    role: Literal["system", "user", "assistant", "tool"]
    content: str | None = None
    name: str | None = None
    tool_call_id: str | None = None
    tool_calls: list[ToolCall] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(
        default_factory=dict,
        description="SAGE context metadata, e.g. {'module': 'vector'}",
    )


class RiceEvent(SchemaBase):
    """Structured streaming event for tokens, graph updates, status, and errors."""

    type: Literal[
        "token",
        "thought_token",
        "graph",
        "heartbeat",
        "error",
        "reset",
        "done",
    ]
    ts: float = Field(default=0.0)
    node: str | None = None
    content: str | None = None
    payload: dict[str, Any] = Field(default_factory=dict)


class AgentAction(SchemaBase):
    """Intermediate agent step that requests one or more tool calls."""

    role: AgentRole
    thought: str = ""
    tool_calls: list[ToolCall] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)


class AgentFinish(SchemaBase):
    """Terminal agent response for downstream orchestration layers."""

    role: AgentRole
    output: str
    finish_reason: Literal["stop", "tool_return", "error"] = "stop"
    messages: list[RiceMessage] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)


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


__all__ = [
    "AgentAction",
    "AgentFinish",
    "AgentRole",
    "RiceMessage",
    "RiceEvent",
    "ToolCall",
    "ToolResult",
    "complete_structured",
    "instructor_client",
]
