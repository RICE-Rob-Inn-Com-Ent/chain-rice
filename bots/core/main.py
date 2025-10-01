#!/usr/bin/env python3
"""
Core AI Bot Application
======================

Minimal FastAPI server for AI bot integrations.
"""

import logging
import sys
import os
from typing import Dict
from fastapi import FastAPI, HTTPException  # noqa
from fastapi.middleware.cors import CORSMiddleware  # noqa
import uvicorn  # noqa

# Add parent directory to path for imports
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

# Import integrations
from integration.huggingface import HuggingFaceIntegration  # noqa: E402
from integration.openai import OpenAIIntegration  # noqa: E402

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Initialize integrations
hf_integration = HuggingFaceIntegration()
openai_integration = OpenAIIntegration()

# FastAPI application
app = FastAPI(
    title="AI Bot Core API",
    description="Minimal AI Bot API with integrations",
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
        "integrations": ["huggingface", "openai"],
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.post("/huggingface/query")
async def huggingface_query(request: Dict[str, str]):
    """Query Hugging Face models."""
    text = request.get("text", "")
    model = request.get("model", "gpt2")

    if not text:
        raise HTTPException(status_code=400, detail="Text is required")

    try:
        # Update model if specified
        if model != "gpt2":
            hf_integration.model = model

        response = hf_integration.query(text)
        return {"response": response}
    except Exception as e:
        logger.error(f"HuggingFace query error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/openai/query")
async def openai_query(request: Dict[str, str]):
    """Query OpenAI models."""
    prompt = request.get("prompt", "")

    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt is required")

    try:
        response = openai_integration.query(prompt)
        return {"response": response}
    except Exception as e:
        logger.error(f"OpenAI query error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def main():
    """Main entry point for the application."""
    import argparse

    parser = argparse.ArgumentParser(description="AI Bot Core Application")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8000, help="Port to bind to")
    parser.add_argument(
        "--reload", action="store_true", help="Enable auto-reload for development"
    )

    args = parser.parse_args()

    logger.info("Starting AI Bot Core API server...")
    logger.info("Available integrations: HuggingFace, OpenAI")

    # Start the server
    uvicorn.run(
        "main:app",
        host=args.host,
        port=args.port,
        reload=args.reload,
        log_level="info",
    )


if __name__ == "__main__":
    main()
