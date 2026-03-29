"""Okno kontekstu — liczenie tokenów, przycinanie historii wiadomości."""

from __future__ import annotations

from langchain_core.messages import BaseMessage
from loguru import logger

# TODO:
# [ ] implement context window manager:
# [ ]     count tokens via litellm.token_counter(model, messages)
# [ ]     model name from RICE_ACTIVE_MODEL env var
# [ ] implement sliding window: drop oldest messages when > RICE_CONTEXT_MAX_TOKENS
# [ ] implement context compression: summarize dropped messages via summary model
# [ ]     summary model from RICE_SUMMARY_MODEL env var
# [ ] implement retrieval augmentation: inject Qdrant results into context
# [ ]     top-k from RICE_RAG_TOP_K env var
# [ ]     collection from RICE_VECTOR_COLLECTION env var
# [ ] implement project context injection:
# [ ]     read custom/{project}/*.rice manifest → inject as system context
# [ ]     project name from RICE_ACTIVE_PROJECT env var
# [ ] implement hardware context injection:
# [ ]     read .rice-compute.json → inject GPU/VRAM availability into context
# [ ]     enables agent to make compute-aware decisions


def estimate_tokens_litellm(model: str, text: str) -> int:
    """Szacuje tokeny przez LiteLLM (jeśli dostępne dla modelu)."""
    try:
        from litellm import token_counter

        return int(token_counter(model=model, messages=[{"role": "user", "content": text}]))
    except Exception as exc:  # noqa: BLE001
        logger.debug("token_counter fallback: {}", exc)
        return max(1, len(text) // 4)


def truncate_messages(
    messages: list[BaseMessage],
    *,
    model: str,
    max_tokens: int,
) -> list[BaseMessage]:
    """Przycina od końca (najnowsze pierwsze), zachowując kolejność chronologiczną."""
    if not messages:
        return messages
    kept: list[BaseMessage] = []
    budget = 0
    for m in reversed(messages):
        cost = estimate_tokens_litellm(model, str(m.content))
        if budget + cost > max_tokens and kept:
            break
        kept.append(m)
        budget += cost
    return list(reversed(kept))
