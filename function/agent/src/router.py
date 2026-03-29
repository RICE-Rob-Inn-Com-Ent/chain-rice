"""LiteLLM — routing modeli (Ollama / vLLM / cloud), fallbacki, śledzenie kosztów."""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Any

import litellm
from litellm import Router
from loguru import logger

# TODO:
# [ ] implement LiteLLM router with model_list from function/model/litellm_config.yaml
# [ ]     config path read from RICE_LITELLM_CONFIG env var
# [ ] configure routing strategies: simple-shuffle|least-busy|latency-based|cost-based
# [ ]     strategy read from RICE_LITELLM_STRATEGY env var (default: least-busy)
# [ ] implement per-role model routing:
# [ ]     role=king   → RICE_KING_MODEL   (Qwen3-8B, reasoning)
# [ ]     role=mason  → RICE_MASON_MODEL  (Coder)
# [ ]     role=smith  → RICE_SMITH_MODEL  (Coder)
# [ ]     role=clerk  → RICE_CLERK_MODEL  (Coder, highest rank)
# [ ]     role=sage   → RICE_SAGE_MODEL   (Coder)
# [ ]     role=bard   → RICE_BARD_MODEL   (VL model)
# [ ]     role=chief  → RICE_CHIEF_MODEL  (fine-tuned on .rice)
# [ ] implement fallback chain: vllm → ollama → litellm_cloud
# [ ]     each endpoint from env var, never hardcoded
# [ ] implement caching: LiteLLM semantic cache via Qdrant
# [ ]     cache_collection = RICE_CACHE_COLLECTION env var
# [ ]     similarity threshold = RICE_CACHE_THRESHOLD env var
# [ ] implement rate limiting per model: RICE_RATE_LIMIT_RPM env var
# [ ] implement token budget: RICE_MAX_TOKENS env var per request
# [ ] implement cost tracking: log token usage to OTel counter metric
# [ ]     metric name: sage.litellm.tokens_used, labels: model, role


def default_model_list() -> list[dict[str, Any]]:
    """Lista modeli dla `Router`: pierwszy to domyślny worker; kolejne — fallback."""
    ollama_base = os.getenv("OLLAMA_API_BASE", "http://127.0.0.1:11434")
    vllm_base = os.getenv("VLLM_API_BASE", "http://127.0.0.1:8000/v1")
    cloud_model = os.getenv("SAGE_CLOUD_MODEL", "gpt-4o-mini")
    return [
        {
            "model_name": "primary",
            "litellm_params": {
                "model": os.getenv("SAGE_PRIMARY_MODEL", "ollama/llama3.2"),
                "api_base": ollama_base,
            },
        },
        {
            "model_name": "vllm",
            "litellm_params": {
                "model": os.getenv("SAGE_VLLM_MODEL", "openai/mistral-7b"),
                "api_base": vllm_base,
            },
        },
        {
            "model_name": "cloud",
            "litellm_params": {"model": cloud_model},
        },
    ]


def default_fallbacks() -> list[dict[str, list[str]]]:
    """Fallback chain: primary → vllm → cloud (nazwy jak w `default_model_list`)."""
    return [{"primary": ["vllm", "cloud"]}]


@dataclass
class CostLedger:
    """Prosty rejestr kosztów LiteLLM (USD) i liczby wywołań."""

    total_usd: float = 0.0
    calls: list[dict[str, Any]] = field(default_factory=list)

    def record(self, response: Any, *, model: str | None = None) -> float:
        cost = 0.0
        try:
            from litellm import completion_cost

            cost = float(completion_cost(completion_response=response) or 0.0)
        except Exception as exc:  # noqa: BLE001 — koszt jest best-effort
            logger.debug("completion_cost failed: {}", exc)
        self.total_usd += cost
        self.calls.append({"model": model, "cost_usd": cost})
        return cost


class SageRouter:
    """Router oparty o `litellm.Router` + opcjonalne śledzenie kosztów."""

    def __init__(
        self,
        *,
        model_list: list[dict[str, Any]] | None = None,
        fallbacks: list[dict[str, list[str]]] | None = None,
        num_retries: int = 0,
        track_cost: bool = True,
    ) -> None:
        self.model_list = model_list or default_model_list()
        self.fallbacks = fallbacks if fallbacks is not None else default_fallbacks()
        self._router = Router(
            model_list=self.model_list,
            fallbacks=self.fallbacks,
            num_retries=num_retries or None,
        )
        self.track_cost = track_cost
        self.ledger = CostLedger()

    @property
    def default_route(self) -> str:
        """Nazwa pierwszego modelu w `model_list` (routing LiteLLM)."""
        return str(self.model_list[0]["model_name"])

    async def acompletion(self, **kwargs: Any) -> Any:
        """Asynchroniczne wywołanie przez wewnętrzny `Router`."""
        model = kwargs.get("model") or self.default_route
        kwargs.setdefault("model", model)
        response = await self._router.acompletion(**kwargs)
        if self.track_cost:
            self.ledger.record(response, model=str(model))
        return response

    def completion(self, **kwargs: Any) -> Any:
        """Synchroniczne wywołanie — dla skryptów / testów."""
        model = kwargs.get("model") or self.default_route
        kwargs.setdefault("model", model)
        response = self._router.completion(**kwargs)
        if self.track_cost:
            self.ledger.record(response, model=str(model))
        return response
