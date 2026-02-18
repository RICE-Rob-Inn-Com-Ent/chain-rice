"""LiteLLM client and prompt management.

Wrapper around LiteLLM for completions, streaming, retry, and structured output.
All model/config from app.config; generic prompt templates with placeholders.
"""

from __future__ import annotations

from typing import Any, AsyncIterator, TypeVar

from loguru import logger

from app.utils import LLMError

# Prompt templates: generic placeholders (user_input, context, instructions)
PROMPT_TEMPLATES = {
    "rag_query": "Context:\n{context}\n\nUser question: {user_input}\n\nAnswer based on the context above.",
    "extract": "Extract structured information from the following text.\n\nInstructions: {instructions}\n\nText:\n{user_input}",
    "chat": "{user_input}",
    "system_default": "You are a helpful assistant. Respond concisely and accurately.",
}

T = TypeVar("T")


def _get_config() -> Any:
    """Lazy import to avoid circular dependency and allow running without full config."""
    from app.config import get_settings
    return get_settings()


def _api_key() -> str:
    """Return LiteLLM API key from config. Empty if not set."""
    return _get_config().LITELLM_API_KEY or ""


def completion(
    prompt: str,
    *,
    model: str | None = None,
    temperature: float | None = None,
    max_tokens: int | None = None,
    api_key: str | None = None,
    **kwargs: Any,
) -> str:
    """Synchronous completion. Prefer async completion for FastAPI.

    Args:
        prompt: User or combined prompt text.
        model: Model override (default from config).
        temperature: Override config temperature.
        max_tokens: Override config max_tokens.
        api_key: Override config API key.
        **kwargs: Passed to litellm.completion.

    Returns:
        Assistant message content string.

    Raises:
        LLMError: On API or validation failure.
    """
    try:
        import litellm
    except ImportError as e:
        raise LLMError("LiteLLM not installed") from e

    cfg = _get_config()
    key = api_key or _api_key()
    if not key and "api_key" not in kwargs:
        kwargs["api_key"] = key  # allow empty for mock/local
    resp = litellm.completion(
        model=model or cfg.LITELLM_MODEL,
        messages=[{"role": "user", "content": prompt}],
        temperature=temperature if temperature is not None else cfg.LITELLM_TEMPERATURE,
        max_tokens=max_tokens if max_tokens is not None else cfg.LITELLM_MAX_TOKENS,
        **kwargs,
    )
    if not resp or not resp.choices:
        raise LLMError("Empty response from LLM")
    return (resp.choices[0].message.content or "").strip()


async def completion_async(
    prompt: str,
    *,
    model: str | None = None,
    temperature: float | None = None,
    max_tokens: int | None = None,
    **kwargs: Any,
) -> str:
    """Async completion for FastAPI endpoints.

    Returns:
        Assistant message content string.
    """
    try:
        import litellm
    except ImportError as e:
        raise LLMError("LiteLLM not installed") from e

    cfg = _get_config()
    resp = await litellm.acompletion(
        model=model or cfg.LITELLM_MODEL,
        messages=[{"role": "user", "content": prompt}],
        temperature=temperature if temperature is not None else cfg.LITELLM_TEMPERATURE,
        max_tokens=max_tokens if max_tokens is not None else cfg.LITELLM_MAX_TOKENS,
        api_key=_api_key() or None,
        **kwargs,
    )
    if not resp or not resp.choices:
        raise LLMError("Empty response from LLM")
    return (resp.choices[0].message.content or "").strip()


def completion_with_retry(
    prompt: str,
    *,
    max_attempts: int = 3,
    **kwargs: Any,
) -> str:
    """Completion with tenacity retry on transient failures."""
    from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_exponential

    @retry(
        retry=retry_if_exception_type((Exception,)),
        stop=stop_after_attempt(max_attempts),
        wait=wait_exponential(multiplier=1.0),
        reraise=True,
    )
    def _call() -> str:
        return completion(prompt, **kwargs)

    try:
        return _call()
    except Exception as e:
        logger.warning("LLM retries exhausted", error=str(e))
        raise LLMError(f"LLM call failed after {max_attempts} attempts: {e}") from e


async def stream_completion(
    prompt: str,
    *,
    model: str | None = None,
    **kwargs: Any,
) -> AsyncIterator[str]:
    """Stream completion chunks. Async generator."""
    try:
        import litellm
    except ImportError as e:
        raise LLMError("LiteLLM not installed") from e

    cfg = _get_config()
    stream = await litellm.acompletion(
        model=model or cfg.LITELLM_MODEL,
        messages=[{"role": "user", "content": prompt}],
        stream=True,
        api_key=_api_key() or None,
        **kwargs,
    )
    async for chunk in stream:
        if chunk and chunk.choices:
            delta = chunk.choices[0].delta
            if getattr(delta, "content", None):
                yield delta.content


def structured_completion(prompt: str, schema: type[T], **kwargs: Any) -> T:
    """Return completion parsed into Pydantic model. Uses JSON mode when possible."""
    try:
        import instructor
        import litellm
    except ImportError as e:
        raise LLMError("instructor or litellm not installed") from e

    cfg = _get_config()
    client = instructor.patch(litellm.completion, mode=instructor.Mode.JSON)
    resp = client(
        model=cfg.LITELLM_MODEL,
        messages=[{"role": "user", "content": prompt}],
        response_model=schema,
        api_key=_api_key() or None,
        **kwargs,
    )
    if isinstance(resp, schema):
        return resp
    return schema.model_validate(resp)


def token_count_estimate(text: str, model: str | None = None) -> int:
    """Rough token count (chars / 4). For accurate count use tiktoken if available."""
    try:
        import tiktoken
        enc = tiktoken.encoding_for_model(model or _get_config().LITELLM_MODEL)
        return len(enc.encode(text))
    except Exception:
        return max(0, len(text) // 4)


def cost_estimate(input_tokens: int, output_tokens: int, model: str | None = None) -> float:
    """Estimate cost in USD (placeholder rates). Override with real pricing in config."""
    _ = model or _get_config().LITELLM_MODEL
    # Placeholder: $0.15/1M in, $0.60/1M out (example)
    return (input_tokens * 0.15 + output_tokens * 0.60) / 1_000_000


async def chat(messages: list[dict[str, str]], model: str | None = None) -> str:
    """Multi-turn chat: list of {role, content}. Returns assistant content."""
    try:
        import litellm
    except ImportError as e:
        raise LLMError("LiteLLM not installed") from e

    cfg = _get_config()
    resp = await litellm.acompletion(
        model=model or cfg.LITELLM_MODEL,
        messages=messages,
        temperature=cfg.LITELLM_TEMPERATURE,
        max_tokens=cfg.LITELLM_MAX_TOKENS,
        api_key=_api_key() or None,
    )
    if not resp or not resp.choices:
        return ""
    return (resp.choices[0].message.content or "").strip()
