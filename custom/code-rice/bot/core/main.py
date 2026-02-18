"""
Code Rice Bot - FastAPI Application
Minimal bot service for code-rice project
"""
from fastapi import FastAPI

app = FastAPI(title="Code Rice Bot", version="1.0.0")

@app.get("/")
async def root():
    return {"message": "Code Rice Bot is running", "status": "healthy"}

@app.get("/health")
async def health():
    return {"status": "healthy"}





