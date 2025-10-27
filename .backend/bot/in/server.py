"""
Bot Integrations API
Unified interface for OpenAI, Claude, Gemini with benchmarks
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import os

app = FastAPI(
    title="Bot Integrations API",
    version="1.0.0",
    description="AI Model Integrations: OpenAI, Claude, Gemini + Benchmarks"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    model: str  # "openai", "claude", "gemini"
    message: str
    max_tokens: Optional[int] = 1000
    temperature: Optional[float] = 0.7

class BenchmarkRequest(BaseModel):
    models: List[str] = ["openai", "claude", "gemini"]
    prompt: str = "Hello, how are you?"

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "integrations",
        "models": ["openai", "claude", "gemini"],
        "features": ["chat", "benchmark"],
    }

@app.post("/chat")
async def chat(request: ChatRequest):
    """Route chat requests to appropriate model"""
    if request.model == "openai":
        from .open_ai import chat_openai
        return await chat_openai(request.message, request.max_tokens, request.temperature)
    elif request.model == "claude":
        from .claude import chat_claude
        return await chat_claude(request.message, request.max_tokens, request.temperature)
    elif request.model == "gemini":
        from .gemini import chat_gemini
        return await chat_gemini(request.message, request.max_tokens, request.temperature)
    else:
        raise HTTPException(status_code=400, detail=f"Unknown model: {request.model}")

@app.post("/benchmark")
async def benchmark(request: BenchmarkRequest):
    """Benchmark multiple models with the same prompt"""
    from .benchmarks import run_benchmark
    return await run_benchmark(request.models, request.prompt)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8200)
