"""
OpenAI API Integration - Full Featured
Comprehensive GPT-4 wrapper with:
- Chat completions (streaming & non-streaming)
- Function calling & tools
- Embeddings & vision
- Image generation (DALL-E 3)
- Audio transcription (Whisper)
- Benchmarking & token counting
"""

import os
import time
import json
from collections.abc import AsyncGenerator
from openai import OpenAI, AsyncOpenAI

# Initialize clients
api_key = os.getenv("OPENAI_API_KEY", "")
client = OpenAI(api_key=api_key)
async_client = AsyncOpenAI(api_key=api_key)


# ============================================================
# 🚀 SUPERBORÓWKI - Main Chat Function
# ============================================================

async def chat_superborowka(
    message: str,
    system_prompt: str = "You are a helpful AI assistant.",
    model: str = "gpt-4-turbo-preview",
    max_tokens: int = 2000,
    temperature: float = 0.7,
    *,
    stream: bool = False,
    functions: list[dict] | None = None,
) -> dict[str, Any]:
    """
    🫐 Superborówki AI Assistant - Main chat function
    
    Args:
        message: User message
        system_prompt: System instructions
        model: GPT model to use
        max_tokens: Max response tokens
        temperature: Creativity (0-2)
        stream: Enable streaming
        functions: Optional function definitions for function calling
    
    Returns:
        Response with metrics and content
    """
    start_time = time.time()

    try:
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": message},
        ]

        # Prepare request params
        params = {
            "model": model,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "stream": stream,
        }

        # Add functions if provided
        if functions:
            params["tools"] = [{"type": "function", "function": f} for f in functions]
            params["tool_choice"] = "auto"

        if stream:
            # Streaming response
            return await stream_chat_openai(params, start_time)
        else:
            # Regular response
            response = await async_client.chat.completions.create(**params)

            latency = (time.time() - start_time) * 1000  # ms

            result = {
                "model": model,
                "response": response.choices[0].message.content,
                "usage": {
                    "input_tokens": response.usage.prompt_tokens,
                    "output_tokens": response.usage.completion_tokens,
                    "total_tokens": response.usage.total_tokens,
                },
                "latency_ms": round(latency, 2),
                "finish_reason": response.choices[0].finish_reason,
            }

            # Include function call if present
            if response.choices[0].message.tool_calls:
                result["tool_calls"] = [
                    {
                        "id": tc.id,
                        "function": tc.function.name,
                        "arguments": json.loads(tc.function.arguments),
                    }
                    for tc in response.choices[0].message.tool_calls
                ]

            return result

    except Exception as e:
        return {
            "model": model,
            "error": str(e),
            "latency_ms": round((time.time() - start_time) * 1000, 2),
        }


async def stream_chat_openai(params: dict) -> AsyncGenerator:
    """Stream chat response."""
    try:
        stream = await async_client.chat.completions.create(**params)

        async for chunk in stream:
            if chunk.choices[0].delta.content:
                yield {
                    "delta": chunk.choices[0].delta.content,
                    "finish_reason": chunk.choices[0].finish_reason,
                }
    except Exception as e:
        yield {"error": str(e)}


# ============================================================
# 🎨 DALL-E 3 - Image Generation
# ============================================================

async def generate_image(
    prompt: str,
    model: str = "dall-e-3",
    size: str = "1024x1024",
    quality: str = "standard",
    style: str = "vivid",
) -> Dict[str, Any]:
    """
    Generate image with DALL-E 3
    
    Args:
        prompt: Image description
        model: dall-e-3 or dall-e-2
        size: 1024x1024, 1792x1024, 1024x1792
        quality: standard or hd
        style: vivid or natural
    """
    start_time = time.time()

    try:
        response = await async_client.images.generate(
            model=model,
            prompt=prompt,
            size=size,
            quality=quality,
            style=style,
            n=1,
        )

        latency = (time.time() - start_time) * 1000

        return {
            "image_url": response.data[0].url,
            "revised_prompt": response.data[0].revised_prompt,
            "latency_ms": round(latency, 2),
        }
    except Exception as e:
        return {"error": str(e)}


# ============================================================
# 🎤 Whisper - Audio Transcription
# ============================================================

async def transcribe_audio(
    audio_file_path: str,
    model: str = "whisper-1",
    language: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Transcribe audio with Whisper
    
    Args:
        audio_file_path: Path to audio file
        model: whisper-1
        language: ISO language code (optional)
    """
    start_time = time.time()

    try:
        with open(audio_file_path, "rb") as audio_file:
            params = {"model": model, "file": audio_file}
            if language:
                params["language"] = language

            response = await async_client.audio.transcriptions.create(**params)

        latency = (time.time() - start_time) * 1000

        return {
            "text": response.text,
            "language": language or "auto",
            "latency_ms": round(latency, 2),
        }
    except Exception as e:
        return {"error": str(e)}


# ============================================================
# 🧮 Embeddings - Text Vectorization
# ============================================================

async def get_embeddings(
    texts: List[str],
    model: str = "text-embedding-3-large",
) -> Dict[str, Any]:
    """
    Generate embeddings for text
    
    Args:
        texts: List of texts to embed
        model: text-embedding-3-large or text-embedding-3-small
    
    Returns:
        List of embeddings (vectors)
    """
    start_time = time.time()

    try:
        response = await async_client.embeddings.create(
            model=model,
            input=texts,
        )

        latency = (time.time() - start_time) * 1000

        return {
            "embeddings": [item.embedding for item in response.data],
            "model": model,
            "usage": {
                "total_tokens": response.usage.total_tokens,
            },
            "latency_ms": round(latency, 2),
        }
    except Exception as e:
        return {"error": str(e)}


# ============================================================
# 👁️ GPT-4 Vision - Image Analysis
# ============================================================

async def analyze_image(
    image_url: str,
    prompt: str = "What's in this image?",
    model: str = "gpt-4-turbo",
    max_tokens: int = 500,
) -> Dict[str, Any]:
    """
    Analyze image with GPT-4 Vision
    
    Args:
        image_url: URL or base64 image
        prompt: Question about the image
        model: gpt-4-turbo or gpt-4o
        max_tokens: Max response tokens
    """
    start_time = time.time()

    try:
        response = await async_client.chat.completions.create(
            model=model,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": image_url}},
                    ],
                }
            ],
            max_tokens=max_tokens,
        )

        latency = (time.time() - start_time) * 1000

        return {
            "response": response.choices[0].message.content,
            "usage": {
                "total_tokens": response.usage.total_tokens,
            },
            "latency_ms": round(latency, 2),
        }
    except Exception as e:
        return {"error": str(e)}


# ============================================================
# 🛠️ Legacy - Backward Compatibility
# ============================================================

async def chat_openai(message: str, max_tokens: int = 1000, temperature: float = 0.7):
    """Legacy function - use chat_superborowka instead"""
    return await chat_superborowka(
        message=message,
        max_tokens=max_tokens,
        temperature=temperature,
    )


class OpenAIIntegration:
    """Legacy class for backward compatibility"""

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
                max_tokens=50,
            )
            return response.choices[0].message.content
        except Exception as e:
            return f"[OpenAI ERROR] {str(e)}"
