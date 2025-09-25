#!/usr/bin/env python3
"""
Core AI Bot Application
======================

Main entry point for the AI bot system with CUDA support.
This application serves as the primary interface for AI model operations
including training, inference, and model management.

Features:
- CUDA-accelerated deep learning
- Hugging Face model integration
- Computer vision and audio processing
- RESTful API endpoints
- Real-time model serving
"""

import logging
import argparse
from typing import Dict, Any

# Core ML libraries
import torch
import transformers
from diffusers import StableDiffusionPipeline

# Web framework
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Global variables for model management
models: Dict[str, Any] = {}
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


class AIBotCore:
    """Main AI Bot Core class for model management and operations."""

    def __init__(self):
        self.device = device
        self.models = models
        logger.info(f"Initializing AI Bot Core on device: {self.device}")

        # Check CUDA availability
        if torch.cuda.is_available():
            logger.info(f"CUDA available with {torch.cuda.device_count()} GPU(s)")
            logger.info(f"GPU: {torch.cuda.get_device_name(0)}")
        else:
            logger.warning("CUDA not available, using CPU")

    def load_model(self, model_name: str, model_type: str = "transformer") -> bool:
        """Load a model into memory."""
        try:
            if model_type == "transformer":
                model = transformers.AutoModel.from_pretrained(model_name)
                model.to(self.device)
                self.models[model_name] = model
                logger.info(f"Loaded transformer model: {model_name}")
                return True

            elif model_type == "diffusion":
                dtype = torch.float16 if self.device.type == "cuda" else torch.float32
                pipeline = StableDiffusionPipeline.from_pretrained(
                    model_name, torch_dtype=dtype
                )
                pipeline.to(self.device)
                self.models[model_name] = pipeline
                logger.info(f"Loaded diffusion model: {model_name}")
                return True

            else:
                logger.error(f"Unknown model type: {model_type}")
                return False

        except Exception as e:
            logger.error(f"Failed to load model {model_name}: {e}")
            return False

    def generate_text(self, prompt: str, model_name: str = "gpt2") -> str:
        """Generate text using a language model."""
        if model_name not in self.models:
            logger.warning(f"Model {model_name} not loaded, loading now...")
            if not self.load_model(model_name):
                raise HTTPException(
                    status_code=500, detail=f"Failed to load model {model_name}"
                )

        try:
            model = self.models[model_name]
            tokenizer = transformers.AutoTokenizer.from_pretrained(model_name)

            inputs = tokenizer(prompt, return_tensors="pt").to(self.device)

            with torch.no_grad():
                outputs = model.generate(
                    inputs.input_ids,
                    max_length=100,
                    num_return_sequences=1,
                    temperature=0.7,
                    do_sample=True,
                    pad_token_id=tokenizer.eos_token_id,
                )

            generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
            return generated_text

        except Exception as e:
            logger.error(f"Text generation failed: {e}")
            raise HTTPException(status_code=500, detail="Text generation failed")

    def generate_image(
        self, prompt: str, model_name: str = "runwayml/stable-diffusion-v1-5"
    ) -> bytes:
        """Generate an image using a diffusion model."""
        if model_name not in self.models:
            logger.warning(f"Model {model_name} not loaded, loading now...")
            if not self.load_model(model_name, "diffusion"):
                raise HTTPException(
                    status_code=500, detail=f"Failed to load model {model_name}"
                )

        try:
            pipeline = self.models[model_name]

            image = pipeline(
                prompt,
                num_inference_steps=20,
                guidance_scale=7.5,
                width=512,
                height=512,
            ).images[0]

            # Convert to bytes
            import io

            img_byte_arr = io.BytesIO()
            image.save(img_byte_arr, format="PNG")
            img_byte_arr = img_byte_arr.getvalue()

            return img_byte_arr

        except Exception as e:
            logger.error(f"Image generation failed: {e}")
            raise HTTPException(status_code=500, detail="Image generation failed")


# Initialize the core
bot_core = AIBotCore()

# FastAPI application
app = FastAPI(
    title="AI Bot Core API",
    description="Core AI Bot API with CUDA support",
    version="1.0.0",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint with system information."""
    return {
        "message": "AI Bot Core API",
        "version": "1.0.0",
        "device": str(bot_core.device),
        "cuda_available": torch.cuda.is_available(),
        "loaded_models": list(bot_core.models.keys()),
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "device": str(bot_core.device),
        "cuda_available": torch.cuda.is_available(),
    }


@app.post("/generate/text")
async def generate_text_endpoint(request: Dict[str, str]):
    """Generate text using AI models."""
    prompt = request.get("prompt", "")
    model_name = request.get("model", "gpt2")

    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt is required")

    try:
        generated_text = bot_core.generate_text(prompt, model_name)
        return {"generated_text": generated_text}
    except Exception as e:
        logger.error(f"Text generation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/generate/image")
async def generate_image_endpoint(request: Dict[str, str]):
    """Generate image using diffusion models."""
    prompt = request.get("prompt", "")
    model_name = request.get("model", "runwayml/stable-diffusion-v1-5")

    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt is required")

    try:
        image_bytes = bot_core.generate_image(prompt, model_name)
        # Return as hex string for JSON
        return {"image_data": image_bytes.hex()}
    except Exception as e:
        logger.error(f"Image generation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/models/load")
async def load_model_endpoint(request: Dict[str, str]):
    """Load a model into memory."""
    model_name = request.get("model_name", "")
    model_type = request.get("model_type", "transformer")

    if not model_name:
        raise HTTPException(status_code=400, detail="Model name is required")

    try:
        success = bot_core.load_model(model_name, model_type)
        if success:
            return {"message": f"Model {model_name} loaded successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to load model")
    except Exception as e:
        logger.error(f"Model loading error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/models")
async def list_models():
    """List all loaded models."""
    return {
        "loaded_models": list(bot_core.models.keys()),
        "device": str(bot_core.device),
    }


def main():
    """Main entry point for the application."""
    parser = argparse.ArgumentParser(description="AI Bot Core Application")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8000, help="Port to bind to")
    parser.add_argument(
        "--workers", type=int, default=1, help="Number of worker processes"
    )
    parser.add_argument(
        "--reload", action="store_true", help="Enable auto-reload for development"
    )

    args = parser.parse_args()

    logger.info("Starting AI Bot Core API server...")
    logger.info(f"Device: {bot_core.device}")
    logger.info(f"CUDA available: {torch.cuda.is_available()}")

    # Start the server
    uvicorn.run(
        "app:app",
        host=args.host,
        port=args.port,
        workers=args.workers if not args.reload else 1,
        reload=args.reload,
        log_level="info",
    )


if __name__ == "__main__":
    main()
