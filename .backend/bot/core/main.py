#!/usr/bin/env python3
"""
Core AI Bot Application
======================

Minimal FastAPI server for AI bot integrations.
"""

import logging
import os
from typing import Dict

import uvicorn  # noqa
from fastapi import FastAPI, HTTPException  # noqa
from fastapi.middleware.cors import CORSMiddleware  # noqa

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

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
        "status": "operational",
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


def main():
    """Main entry point for the application."""
    import argparse

    parser = argparse.ArgumentParser(description="AI Bot Core Application")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8000, help="Port to bind to")
    parser.add_argument("--reload", action="store_true", help="Enable auto-reload for development")

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
