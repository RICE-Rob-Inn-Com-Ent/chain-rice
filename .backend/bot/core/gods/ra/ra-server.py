"""
Ra - God of Light
Graphics generation optimized for 6GB VRAM:
- Stable Diffusion 2.1 (FP16) - Image generation
- Memory optimizations: attention slicing, VAE slicing
- RealESRGAN - Upscaling (lazy load)
- RVM - Background removal (lazy load)
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import os

app = FastAPI(title="Ra API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Lazy loading
sd_pipeline = None
upscaler = None

# God state management
is_active = False


class ImageGenRequest(BaseModel):
    prompt: str
    negative_prompt: Optional[str] = ""
    steps: int = 30
    cfg_scale: float = 7.5
    width: int = 512
    height: int = 512


@app.get("/health")
async def health():
    return {
        "status": "active" if is_active else "sleeping",
        "god": "Ra",
        "vram": "6GB optimized",
        "models": {
            "image_gen": "Stable Diffusion 2.1 FP16 (lazy)",
            "upscaler": "RealESRGAN (lazy)",
            "bg_removal": "RVM (lazy)",
        },
        "optimizations": ["attention_slicing", "vae_slicing", "fp16"],
    }


@app.post("/wake")
async def wake():
    """Mark god as active"""
    global is_active
    is_active = True
    return {"success": True, "god": "Ra", "status": "active"}


@app.post("/sleep")
async def sleep():
    """Mark god as sleeping and clear VRAM"""
    global is_active, sd_pipeline, upscaler
    is_active = False
    # Clear models from memory
    sd_pipeline = None
    upscaler = None
    return {"success": True, "god": "Ra", "status": "sleeping"}


@app.post("/generate")
async def generate_image(request: ImageGenRequest):
    global sd_pipeline

    if sd_pipeline is None:
        from diffusers import StableDiffusionPipeline
        import torch

        sd_pipeline = StableDiffusionPipeline.from_pretrained(
            "stabilityai/stable-diffusion-2-1",
            torch_dtype=torch.float16,
        )

        # 6GB VRAM optimizations
        sd_pipeline.enable_attention_slicing(slice_size="auto")
        sd_pipeline.enable_vae_slicing()

        device = "cuda" if torch.cuda.is_available() else "cpu"
        sd_pipeline.to(device)

        if device == "cuda":
            # Clear cache before generating
            torch.cuda.empty_cache()

    # Generate
    image = sd_pipeline(
        request.prompt,
        negative_prompt=request.negative_prompt,
        num_inference_steps=request.steps,
        guidance_scale=request.cfg_scale,
        width=request.width,
        height=request.height,
    ).images[0]

    # Save to temp
    temp_path = f"/tmp/ra_output_{os.urandom(8).hex()}.png"
    image.save(temp_path)

    return {"image_path": temp_path, "prompt": request.prompt}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
