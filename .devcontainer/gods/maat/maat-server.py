"""
Maat - Goddess of Justice
Legal analysis: Mistral + XLM-RoBERTa + Document parsing
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

app = FastAPI(title="Maat API", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "mistral:7b-instruct-q4_K_M")

# God state management
is_active = False

@app.get("/health")
async def health():
    return {"status": "active" if is_active else "sleeping", "god": "Maat", "models": {"llm": OLLAMA_MODEL, "text_analysis": "XLM-RoBERTa (lazy)", "doc_parser": "Donut (lazy)"}}

@app.post("/wake")
async def wake():
    """Mark god as active"""
    global is_active
    is_active = True
    return {"success": True, "god": "Maat", "status": "active"}

@app.post("/sleep")
async def sleep():
    """Mark god as sleeping"""
    global is_active
    is_active = False
    return {"success": True, "god": "Maat", "status": "sleeping"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
