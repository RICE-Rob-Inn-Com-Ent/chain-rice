"""
Google Gemini Integration
API wrapper with benchmarking support
"""

import os
import time
import google.generativeai as genai

genai.configure(api_key=os.getenv("GOOGLE_API_KEY", ""))

async def chat_gemini(message: str, max_tokens: int = 1000, temperature: float = 0.7):
    """
    Send message to Gemini and return response with metrics
    """
    start_time = time.time()

    try:
        model = genai.GenerativeModel('gemini-1.5-pro')

        response = model.generate_content(
            message,
            generation_config=genai.types.GenerationConfig(
                max_output_tokens=max_tokens,
                temperature=temperature,
            )
        )

        latency = (time.time() - start_time) * 1000  # ms

        return {
            "model": "gemini-1.5-pro",
            "response": response.text,
            "usage": {
                "input_tokens": response.usage_metadata.prompt_token_count,
                "output_tokens": response.usage_metadata.candidates_token_count,
            },
            "latency_ms": round(latency, 2),
        }
    except Exception as e:
        return {
            "model": "gemini-1.5-pro",
            "error": str(e),
            "latency_ms": round((time.time() - start_time) * 1000, 2),
        }
