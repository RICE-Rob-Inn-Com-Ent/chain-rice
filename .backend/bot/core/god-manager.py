#!/usr/bin/env python3
"""
God Manager - Orchestrator for AI Gods
Manages GPU allocation - only ONE god on GPU at a time
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, List
import httpx
import asyncio
from datetime import datetime

app = FastAPI(title="God Manager", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# God registry
GODS = {
    "thoth": {"url": "http://rice-thot:8000", "name": "Thoth", "icon": "📚"},
    "ra": {"url": "http://rice-ra:8000", "name": "Ra", "icon": "☀️"},
    "isis": {"url": "http://rice-isis:8000", "name": "Isis", "icon": "✨"},
    "bastet": {"url": "http://rice-bastet:8000", "name": "Bastet", "icon": "🐱"},
    "maat": {"url": "http://rice-maat:8000", "name": "Maat", "icon": "⚖️"},
    "khnum": {"url": "http://rice-khnum:8000", "name": "Khnum", "icon": "🏺"},
}

# Current GPU allocation
current_gpu_god: Optional[str] = None


class GodStatus(BaseModel):
    god_id: str
    name: str
    icon: str
    status: str  # "offline", "cpu", "loading", "gpu"
    gpu_allocated: bool
    progress: Optional[int] = None  # 0-100 during loading
    estimated_time: Optional[int] = None  # seconds remaining


@app.get("/")
async def root():
    return {
        "service": "God Manager",
        "version": "1.0.0",
        "current_gpu_god": current_gpu_god,
        "gods_count": len(GODS),
    }


@app.get("/gods")
async def list_gods() -> List[GodStatus]:
    """List all gods with their current status"""
    statuses = []
    
    async with httpx.AsyncClient(timeout=5.0) as client:
        for god_id, god_info in GODS.items():
            try:
                response = await client.get(f"{god_info['url']}/health")
                data = response.json()
                
                # Determine actual status based on GPU allocation
                raw_status = data.get("status", "unknown")
                
                # Map status properly:
                # - If this god has GPU → "gpu"
                # - If model is loading → "loading"  
                # - If god is responsive but no GPU → "cpu"
                # - Otherwise → "offline"
                
                if god_id == current_gpu_god and raw_status in ["active", "online"]:
                    actual_status = "gpu"
                elif raw_status == "loading":
                    actual_status = "loading"
                elif raw_status in ["active", "sleeping", "online"]:
                    actual_status = "cpu"
                else:
                    actual_status = "offline"
                
                status = GodStatus(
                    god_id=god_id,
                    name=god_info["name"],
                    icon=god_info["icon"],
                    status=actual_status,
                    gpu_allocated=(god_id == current_gpu_god),
                    progress=data.get("loading", {}).get("percent") if isinstance(data.get("loading"), dict) else data.get("progress"),
                    estimated_time=data.get("estimated_time"),
                )
                statuses.append(status)
            except:
                statuses.append(
                    GodStatus(
                        god_id=god_id,
                        name=god_info["name"],
                        icon=god_info["icon"],
                        status="offline",
                        gpu_allocated=False,
                    )
                )
    
    return statuses


@app.post("/wake/{god_id}")
async def wake_god(god_id: str):
    """
    Wake a god and allocate GPU to it.
    AUTOMATICALLY sleeps other gods if GPU is allocated.
    """
    global current_gpu_god
    
    if god_id not in GODS:
        raise HTTPException(status_code=404, detail=f"God {god_id} not found")
    
    god_info = GODS[god_id]
    
    # CRITICAL: If another god has GPU, sleep it FIRST
    # This ensures only ONE model on GPU at a time
    if current_gpu_god and current_gpu_god != god_id:
        print(f"🌙 Auto-sleeping {current_gpu_god} to free GPU...")
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                sleep_response = await client.post(f"{GODS[current_gpu_god]['url']}/sleep")
                if sleep_response.status_code == 200:
                    print(f"✅ {current_gpu_god} unloaded from GPU")
                    current_gpu_god = None
                else:
                    print(f"⚠️ Failed to sleep {current_gpu_god}, forcing GPU allocation anyway")
                    current_gpu_god = None
        except Exception as e:
            print(f"⚠️ Error sleeping {current_gpu_god}: {e}")
            # Force clear GPU allocation even if sleep failed
            current_gpu_god = None
    
    # Wake the requested god with GPU
    print(f"⚡ Waking {god_id} and loading to GPU...")
    try:
        async with httpx.AsyncClient(timeout=180.0) as client:  # 3 min timeout for model loading
            response = await client.post(
                f"{god_info['url']}/wake",
                json={"use_gpu": True}
            )
            
            if response.status_code == 200:
                current_gpu_god = god_id
                return {
                    "success": True,
                    "god": god_id,
                    "gpu_allocated": True,
                    "previous_god_unloaded": True,
                    "message": f"{god_info['name']} is loading to GPU (may take 30-90s)",
                }
            else:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Failed to wake {god_id}"
                )
    except httpx.TimeoutException:
        # Model is probably still loading, mark as current anyway
        current_gpu_god = god_id
        return {
            "success": True,
            "god": god_id,
            "gpu_allocated": True,
            "loading": True,
            "message": f"{god_info['name']} is loading (check progress)"
        }


@app.post("/sleep/{god_id}")
async def sleep_god(god_id: str):
    """Put a god to sleep and free GPU"""
    global current_gpu_god

    if god_id not in GODS:
        raise HTTPException(status_code=404, detail=f"God {god_id} not found")

    god_info = GODS[god_id]

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(f"{god_info['url']}/sleep")

            if response.status_code == 200:
                if current_gpu_god == god_id:
                    current_gpu_god = None

                return {
                    "success": True,
                    "god": god_id,
                    "message": f"{god_info['name']} is now sleeping",
                }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to sleep {god_id}: {str(e)}"
        )


@app.get("/gpu")
async def gpu_status():
    """Get current GPU allocation status"""
    return {
        "allocated": current_gpu_god is not None,
        "current_god": current_gpu_god,
        "available": current_gpu_god is None,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8100)

