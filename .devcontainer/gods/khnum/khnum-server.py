"""
Khnum - God of Wealth
Financial analysis: Mistral + PlotGPT + RecBole
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

app = FastAPI(title="Khnum API", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "mistral:7b-instruct-q4_K_M")

# God state management
is_active = False

@app.get("/health")
async def health():
    return {"status": "active" if is_active else "sleeping", "god": "Khnum", "models": {"llm": OLLAMA_MODEL, "visualization": "PlotGPT (lazy)", "recommendations": "RecBole (lazy)"}}

@app.post("/wake")
async def wake():
    """Mark god as active"""
    global is_active
    is_active = True
    return {"success": True, "god": "Khnum", "status": "active"}

@app.post("/sleep")
async def sleep():
    """Mark god as sleeping"""
    global is_active
    is_active = False
    return {"success": True, "god": "Khnum", "status": "sleeping"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
