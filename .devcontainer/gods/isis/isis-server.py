"""
Isis - Goddess of Healing
Medical AI stack: Monai + Medical imaging
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Isis API", version="1.0.0")

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

# God state management
is_active = False

@app.get("/health")
async def health():
    return {"status": "active" if is_active else "sleeping", "god": "Isis", "models": {"medical_imaging": "Monai (lazy)", "visual_qa": "LLaVa (lazy)"}}

@app.post("/wake")
async def wake():
    """Mark god as active"""
    global is_active
    is_active = True
    return {"success": True, "god": "Isis", "status": "active"}

@app.post("/sleep")
async def sleep():
    """Mark god as sleeping"""
    global is_active
    is_active = False
    return {"success": True, "god": "Isis", "status": "sleeping"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
