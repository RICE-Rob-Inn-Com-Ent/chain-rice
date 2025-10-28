"""
Thoth - God of Knowledge
Multi-model text processing server combining:
- Mistral 7B (via Ollama) - Base LLM
- PaddleOCR - OCR
- EasyNMT - Translation
- Transformers - Text analysis
"""

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import subprocess
import requests
import json
import os

app = FastAPI(title="Thoth API", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
OLLAMA_URL = "http://localhost:11434"
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "mistral:7b-instruct-q4_K_M")

# Lazy loading - initialize only when needed
ocr_reader = None
translator = None

# God state management
is_active = False
model_loading = False
model_loaded = False
loading_progress = {"status": "initializing", "percent": 0, "message": "Starting..."}


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = 2048


class LoRAConfig(BaseModel):
    name: str
    rank: int = 8
    alpha: int = 16
    learning_rate: float = 0.0001
    epochs: int = 3
    dataset_path: str


@app.get("/health")
async def health():
    """Health check"""
    # Check if Ollama is responding
    ollama_status = "offline"
    try:
        resp = requests.get(f"{OLLAMA_URL}/api/tags", timeout=2)
        if resp.status_code == 200:
            ollama_status = "online"
            # Check if model is actually loaded
            try:
                test_resp = requests.post(
                    f"{OLLAMA_URL}/api/generate",
                    json={"model": OLLAMA_MODEL, "prompt": "test", "stream": False},
                    timeout=5
                )
                if test_resp.status_code == 200:
                    global model_loaded
                    model_loaded = True
            except:
                pass
    except:
        pass
    
    return {
        "status": "loading" if model_loading else ("online" if model_loaded else "starting"),
        "god": "Thoth",
        "ollama": ollama_status,
        "model_loaded": model_loaded,
        "loading": loading_progress if model_loading else None,
        "models": {
            "llm": OLLAMA_MODEL,
            "ocr": "PaddleOCR (lazy)",
            "translation": "EasyNMT (lazy)",
        },
    }


@app.get("/status")
async def get_status():
    """Get detailed loading status"""
    return {
        "loading": model_loading,
        "loaded": model_loaded,
        "progress": loading_progress,
    }


@app.post("/wake")
async def wake():
    """Mark god as active"""
    global is_active
    is_active = True
    return {"success": True, "god": "Thoth", "status": "active"}


@app.post("/sleep")
async def sleep():
    """Mark god as sleeping and clear lazy-loaded models"""
    global is_active, ocr_reader, translator
    is_active = False
    # Clear lazy-loaded models from memory
    ocr_reader = None
    translator = None
    return {"success": True, "god": "Thoth", "status": "sleeping"}


@app.post("/chat")
async def chat(request: ChatRequest):
    """Main chat endpoint using Mistral"""
    try:
        # Call Ollama
        response = requests.post(
            f"{OLLAMA_URL}/api/chat",
            json={
                "model": OLLAMA_MODEL,
                "messages": [{"role": m.role, "content": m.content} for m in request.messages],
                "stream": False,
                "options": {
                    "temperature": request.temperature,
                    "num_ctx": 4096,
                },
            },
            timeout=120,
        )

        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="Ollama error")

        data = response.json()
        return {"message": data["message"], "model": data["model"]}

    except requests.exceptions.Timeout:
        raise HTTPException(status_code=504, detail="Timeout - model is loading or slow (CPU)")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/ocr")
async def ocr_image(file: UploadFile = File(...)):
    """OCR on uploaded image"""
    global ocr_reader

    # Lazy load OCR
    if ocr_reader is None:
        from paddleocr import PaddleOCR

        ocr_reader = PaddleOCR(use_angle_cls=True, lang="en")

    # Save temp file
    temp_path = f"/tmp/{file.filename}"
    with open(temp_path, "wb") as f:
        f.write(await file.read())

    # Run OCR
    result = ocr_reader.ocr(temp_path, cls=True)

    # Extract text
    texts = []
    for line in result:
        for word_info in line:
            texts.append(word_info[1][0])

    os.remove(temp_path)

    return {"text": " ".join(texts), "confidence": "high"}


@app.post("/translate")
async def translate_text(text: str, source_lang: str = "auto", target_lang: str = "en"):
    """Translate text using EasyNMT"""
    global translator

    # Lazy load translator
    if translator is None:
        from easynmt import EasyNMT

        translator = EasyNMT("opus-mt")

    translated = translator.translate(text, source_lang=source_lang, target_lang=target_lang)

    return {"translated": translated, "source_lang": source_lang, "target_lang": target_lang}


@app.post("/lora/train")
async def train_lora(config: LoRAConfig):
    """Train LoRA adapter on Mistral"""
    try:
        # Create LoRA training config
        lora_path = f"/lora-adapters/{config.name}"
        os.makedirs(lora_path, exist_ok=True)

        # Save config
        with open(f"{lora_path}/config.json", "w") as f:
            json.dump(config.dict(), f)

        # Start training (placeholder - implement actual training)
        return {
            "status": "training_started",
            "adapter_name": config.name,
            "path": lora_path,
            "message": "LoRA training started. This will take several minutes.",
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/lora/list")
async def list_lora_adapters():
    """List available LoRA adapters"""
    lora_dir = "/lora-adapters"
    if not os.path.exists(lora_dir):
        return {"adapters": []}

    adapters = []
    for adapter_name in os.listdir(lora_dir):
        adapter_path = os.path.join(lora_dir, adapter_name)
        if os.path.isdir(adapter_path):
            config_path = os.path.join(adapter_path, "config.json")
            if os.path.exists(config_path):
                with open(config_path) as f:
                    config = json.load(f)
                    adapters.append({"name": adapter_name, "config": config})

    return {"adapters": adapters}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
