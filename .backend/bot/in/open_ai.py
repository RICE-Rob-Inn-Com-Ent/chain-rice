"""
OpenAI API Integration
GPT-4 Turbo wrapper with benchmarking support
"""

import os
import time
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY", ""))


async def chat_openai(message: str, max_tokens: int = 1000, temperature: float = 0.7):
    """
    Send message to OpenAI and return response with metrics
    """
    start_time = time.time()

    try:
        response = client.chat.completions.create(
            model="gpt-4-turbo-preview",
            messages=[{"role": "user", "content": message}],
            max_tokens=max_tokens,
            temperature=temperature,
        )

        latency = (time.time() - start_time) * 1000  # ms

        return {
            "model": "gpt-4-turbo",
            "response": response.choices[0].message.content,
            "usage": {
                "input_tokens": response.usage.prompt_tokens,
                "output_tokens": response.usage.completion_tokens,
                "total_tokens": response.usage.total_tokens,
            },
            "latency_ms": round(latency, 2),
        }
    except Exception as e:
        return {
            "model": "gpt-4-turbo",
            "error": str(e),
            "latency_ms": round((time.time() - start_time) * 1000, 2),
        }


# Legacy class for backward compatibility
class OpenAIIntegration:
    def __init__(self):
        self.api_key = os.getenv("OPENAI_API_KEY")
        if self.api_key:
            global client
            client = OpenAI(api_key=self.api_key)

    def query(self, prompt: str) -> str:
        if not self.api_key:
            return f"[MOCK OpenAI response] Prompt: {prompt}"
        try:
            response = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=50
            )
            return response.choices[0].message.content
        except Exception as e:
            return f"[OpenAI ERROR] {str(e)}"
