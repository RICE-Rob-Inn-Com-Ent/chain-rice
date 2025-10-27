"""
Anthropic Claude Integration
API wrapper with benchmarking support
"""

import os
import time
from anthropic import Anthropic

client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY", ""))

async def chat_claude(message: str, max_tokens: int = 1000, temperature: float = 0.7):
    """
    Send message to Claude and return response with metrics
    """
    start_time = time.time()

    try:
        response = client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=max_tokens,
            temperature=temperature,
            messages=[{"role": "user", "content": message}]
        )

        latency = (time.time() - start_time) * 1000  # ms

        return {
            "model": "claude-3.5-sonnet",
            "response": response.content[0].text,
            "usage": {
                "input_tokens": response.usage.input_tokens,
                "output_tokens": response.usage.output_tokens,
            },
            "latency_ms": round(latency, 2),
        }
    except Exception as e:
        return {
            "model": "claude-3.5-sonnet",
            "error": str(e),
            "latency_ms": round((time.time() - start_time) * 1000, 2),
        }
