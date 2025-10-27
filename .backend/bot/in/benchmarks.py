"""
AI Model Benchmarking
Compare OpenAI, Claude, Gemini performance
"""

import asyncio
import time
from typing import List
from .open_ai import chat_openai
from .claude import chat_claude
from .gemini import chat_gemini

async def run_benchmark(models: List[str], prompt: str):
    """
    Run the same prompt on multiple models and compare results
    """
    results = []

    for model in models:
        if model == "openai":
            result = await chat_openai(prompt)
        elif model == "claude":
            result = await chat_claude(prompt)
        elif model == "gemini":
            result = await chat_gemini(prompt)
        else:
            continue

        results.append(result)

    # Calculate statistics
    latencies = [r.get("latency_ms", 0) for r in results if "error" not in r]
    avg_latency = sum(latencies) / len(latencies) if latencies else 0

    return {
        "prompt": prompt,
        "results": results,
        "summary": {
            "models_tested": len(results),
            "avg_latency_ms": round(avg_latency, 2),
            "fastest": min(results, key=lambda x: x.get("latency_ms", float('inf')))["model"] if results else None,
        }
    }
