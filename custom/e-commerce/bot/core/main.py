"""
Meowtopia Bot - FastAPI Application
Minimal bot service for meowtopia project
"""
from fastapi import FastAPI

app = FastAPI(title="Meowtopia Bot", version="1.0.0")

@app.get("/")
async def root():
    return {"message": "Meowtopia Bot is running", "status": "healthy"}

@app.get("/health")
async def health():
    return {"status": "healthy"}














