"""Unit + integration: `function/agent` — router, graph, guard; LiteLLM, Temporal, NATS."""

from __future__ import annotations

import os

import pytest

from function.agent.graph import build_sage_react_graph
from function.agent.router import SageRouter, default_model_list
from function.helper.schema import SchemaBase

# TODO:
# [ ] test state initialization: AgentState has all required fields
# [ ] test graph compilation: graph compiles without error
# [ ] test planner node: returns valid Plan with at least one Step
# [ ] test validator node: accepts valid output, rejects invalid
# [ ] test retry logic: MaxRetriesExceeded raised after n failures
# [ ] test streaming: astream yields at least one chunk
# [ ] test tool registration: all tools have name, description, args_schema
# [ ] test memory read/write: stored message retrievable after write
# [ ] test router fallback: on primary model failure routes to fallback
# [ ] integration(litellm): real LiteLLM call returns non-empty response
# [ ] integration(nats): agent publishes to NATS, message received
# [ ] integration(temporal): workflow starts and returns result


def test_default_model_list_non_empty() -> None:
    ml = default_model_list()
    assert isinstance(ml, list)
    assert len(ml) >= 1
    assert "model_name" in ml[0]


def test_sage_router_instantiates() -> None:
    r = SageRouter(model_list=default_model_list(), fallbacks=[], num_retries=0)
    assert r.default_route


def test_build_sage_react_graph_compiles() -> None:
    g = build_sage_react_graph()
    assert g is not None


def test_guard_lazy_import() -> None:
    from function.agent.guard import build_default_guard

    g = build_default_guard()
    assert g is not None


def test_schema_base_for_agent_payloads() -> None:
    class P(SchemaBase):
        x: int

    assert P(x=1).x == 1


# --- Integration (opt-in: RUN_INTEGRATION=1 + env per service) ---


@pytest.mark.integration
@pytest.mark.litellm
@pytest.mark.asyncio
async def test_litellm_completion_smoke(integration_enabled: bool) -> None:
    if not integration_enabled or not os.getenv("LITELLM_API_KEY"):
        pytest.skip("RUN_INTEGRATION=1 and LITELLM_API_KEY required")
    import litellm

    r = await litellm.acompletion(
        model=os.getenv("SAGE_TEST_MODEL", "gpt-4o-mini"),
        messages=[{"role": "user", "content": "ping"}],
        max_tokens=5,
    )
    assert r.choices[0].message.content is not None


@pytest.mark.integration
@pytest.mark.temporal
@pytest.mark.asyncio
async def test_temporal_placeholder(integration_enabled: bool) -> None:
    if not integration_enabled:
        pytest.skip("set RUN_INTEGRATION=1")
    if not os.getenv("TEMPORAL_ADDRESS"):
        pytest.skip("TEMPORAL_ADDRESS not set — wire worker tests here")
    pytest.skip("Temporal e2e: podłącz klienta i workflow w deploymencie")


@pytest.mark.integration
@pytest.mark.nats
@pytest.mark.asyncio
async def test_nats_placeholder(integration_enabled: bool) -> None:
    if not integration_enabled:
        pytest.skip("set RUN_INTEGRATION=1")
    if not os.getenv("NATS_URL"):
        pytest.skip("NATS_URL not set")
    pytest.skip("JetStream: zainstaluj nats-py i dodaj pub/sub e2e")
