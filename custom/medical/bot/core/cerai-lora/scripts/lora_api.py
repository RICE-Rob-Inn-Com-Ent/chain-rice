#!/usr/bin/env python3
"""
LoRA API Server

FastAPI server for LoRA adapter inference.
"""

import os
import json
import logging
from pathlib import Path
from typing import Optional, Dict, Any, List

import torch
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import uvicorn

import sys

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).parent))

from load_lora import LoRALoader

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="CerAI LoRA API",
    description="API for LoRA adapter inference",
    version="1.0.0"
)

# Global loader
loader: Optional[LoRALoader] = None
loaded_adapters: Dict[str, Any] = {}


class InferenceRequest(BaseModel):
    """Request for inference."""
    adapter_name: str = Field(..., description="Name of the adapter to use")
    prompt: str = Field(..., description="Input prompt")
    max_length: int = Field(default=512, description="Maximum generation length")
    temperature: float = Field(default=0.7, description="Sampling temperature")
    top_p: float = Field(default=0.9, description="Top-p sampling")
    top_k: int = Field(default=40, description="Top-k sampling")


class InferenceResponse(BaseModel):
    """Response from inference."""
    text: str
    adapter_name: str
    model_name: str


@app.on_event("startup")
async def startup():
    """Initialize LoRA loader on startup."""
    global loader
    adapters_dir = os.getenv("ADAPTERS_DIR", "/app/adapters")
    loader = LoRALoader(adapters_dir=adapters_dir)
    logger.info(f"LoRA loader initialized with adapters_dir: {adapters_dir}")


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "name": "CerAI LoRA API",
        "version": "1.0.0",
        "status": "running"
    }


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.get("/adapters")
async def list_adapters():
    """List available adapters."""
    if not loader:
        raise HTTPException(status_code=503, detail="LoRA loader not initialized")
    
    adapters = loader.list_adapters()
    return {
        "adapters": adapters,
        "count": len(adapters)
    }


@app.post("/inference", response_model=InferenceResponse)
async def inference(request: InferenceRequest):
    """Run inference with LoRA adapter."""
    if not loader:
        raise HTTPException(status_code=503, detail="LoRA loader not initialized")
    
    # Check if adapter is loaded
    if request.adapter_name not in loaded_adapters:
        # Determine base model based on adapter name
        if "bielik" in request.adapter_name.lower():
            base_model = os.getenv("MODEL_NAME_BIELIK", "allegro/herbert-base-cased")
        elif "formatter" in request.adapter_name.lower():
            base_model = os.getenv("MODEL_NAME_FORMATTER", "Qwen/Qwen2.5-3B-Instruct")
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Unknown adapter type: {request.adapter_name}"
            )
        
        # Load adapter
        try:
            logger.info(f"Loading adapter: {request.adapter_name}")
            model, tokenizer = loader.load_adapter(
                base_model_name=base_model,
                adapter_name=request.adapter_name
            )
            loaded_adapters[request.adapter_name] = {
                "model": model,
                "tokenizer": tokenizer,
                "base_model": base_model
            }
        except Exception as e:
            logger.error(f"Error loading adapter: {e}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to load adapter: {str(e)}"
            )
    
    # Get loaded adapter
    adapter = loaded_adapters[request.adapter_name]
    model = adapter["model"]
    tokenizer = adapter["tokenizer"]
    
    # Tokenize input
    inputs = tokenizer(
        request.prompt,
        return_tensors="pt",
        truncation=True,
        max_length=request.max_length
    )
    
    # Move to device
    device = next(model.parameters()).device
    inputs = {k: v.to(device) for k, v in inputs.items()}
    
    # Generate
    try:
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_length=request.max_length,
                temperature=request.temperature,
                top_p=request.top_p,
                top_k=request.top_k,
                do_sample=True,
                pad_token_id=tokenizer.eos_token_id,
            )
        
        # Decode
        generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # Remove input prompt from output
        if generated_text.startswith(request.prompt):
            generated_text = generated_text[len(request.prompt):].strip()
        
        return InferenceResponse(
            text=generated_text,
            adapter_name=request.adapter_name,
            model_name=adapter["base_model"]
        )
    except Exception as e:
        logger.error(f"Error during inference: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Inference failed: {str(e)}"
        )


@app.delete("/adapters/{adapter_name}")
async def unload_adapter(adapter_name: str):
    """Unload adapter from memory."""
    if adapter_name in loaded_adapters:
        del loaded_adapters[adapter_name]
        return {"message": f"Adapter {adapter_name} unloaded"}
    else:
        raise HTTPException(
            status_code=404,
            detail=f"Adapter {adapter_name} not loaded"
        )


# Training Data Management
@app.get("/training-data")
async def list_training_files():
    """List all training data files."""
    data_dir = Path(os.getenv("DATA_DIR", "/app/data"))
    files = []
    
    if data_dir.exists():
        for file_path in data_dir.glob("*.json"):
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    files.append({
                        "filename": file_path.name,
                        "size": len(json.dumps(data)),
                        "items_count": len(data) if isinstance(data, list) else 1,
                        "adapter_type": _detect_adapter_type(file_path.name),
                        "modified": os.path.getmtime(file_path),
                    })
            except Exception as e:
                logger.warning(f"Error reading {file_path}: {e}")
    
    return {"files": files}


@app.get("/training-data/{filename}")
async def get_training_file(filename: str):
    """Get specific training data file."""
    data_dir = Path(os.getenv("DATA_DIR", "/app/data"))
    file_path = data_dir / filename
    
    if not file_path.exists() or not file_path.suffix == ".json":
        raise HTTPException(status_code=404, detail="File not found")
    
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return {
            "filename": filename,
            "data": data,
            "adapter_type": _detect_adapter_type(filename),
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error reading file: {str(e)}"
        )


@app.post("/training-data")
async def create_training_file(request: Dict[str, Any]):
    """Create new training data file."""
    filename = request.get("filename")
    data = request.get("data")
    adapter_type = request.get("adapter_type", "bielik")
    
    if not filename or not data:
        raise HTTPException(
            status_code=400,
            detail="Missing required fields: filename, data"
        )
    
    # Ensure .json extension
    if not filename.endswith(".json"):
        filename += ".json"
    
    data_dir = Path(os.getenv("DATA_DIR", "/app/data"))
    data_dir.mkdir(parents=True, exist_ok=True)
    file_path = data_dir / filename
    
    try:
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        return {
            "filename": filename,
            "message": "File created successfully",
            "size": os.path.getsize(file_path),
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error creating file: {str(e)}"
        )


@app.put("/training-data/{filename}")
async def update_training_file(filename: str, request: Dict[str, Any]):
    """Update training data file."""
    data = request.get("data")
    
    if not data:
        raise HTTPException(
            status_code=400,
            detail="Missing required field: data"
        )
    
    data_dir = Path(os.getenv("DATA_DIR", "/app/data"))
    file_path = data_dir / filename
    
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File not found")
    
    try:
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        return {
            "filename": filename,
            "message": "File updated successfully",
            "size": os.path.getsize(file_path),
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error updating file: {str(e)}"
        )


@app.delete("/training-data/{filename}")
async def delete_training_file(filename: str):
    """Delete training data file."""
    data_dir = Path(os.getenv("DATA_DIR", "/app/data"))
    file_path = data_dir / filename
    
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File not found")
    
    try:
        file_path.unlink()
        return {"message": "File deleted successfully"}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error deleting file: {str(e)}"
        )


@app.post("/training-data/search")
async def search_training_data(request: Dict[str, Any]):
    """Search training data by context."""
    query = request.get("query", "").lower()
    adapter_type = request.get("adapter_type")
    limit = int(request.get("limit", 10))
    
    if not query:
        return {"results": []}
    
    data_dir = Path(os.getenv("DATA_DIR", "/app/data"))
    results = []
    
    if data_dir.exists():
        for file_path in data_dir.glob("*.json"):
            # Filter by adapter type if specified
            if adapter_type and adapter_type not in file_path.name.lower():
                continue
            
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                
                # Search in file content
                items = data if isinstance(data, list) else [data]
                for idx, item in enumerate(items):
                    text = str(item.get("text", item.get("input", ""))).lower()
                    if query in text:
                        results.append({
                            "filename": file_path.name,
                            "index": idx,
                            "text": item.get("text", item.get("input", ""))[:200],
                            "match_score": text.count(query),
                        })
                        if len(results) >= limit:
                            break
                
                if len(results) >= limit:
                    break
            except Exception as e:
                logger.warning(f"Error searching {file_path}: {e}")
    
    # Sort by match score
    results.sort(key=lambda x: x["match_score"], reverse=True)
    return {"results": results[:limit]}


def _detect_adapter_type(filename: str) -> str:
    """Detect adapter type from filename."""
    filename_lower = filename.lower()
    if "bielik" in filename_lower or "invoice" in filename_lower:
        return "bielik"
    elif "formatter" in filename_lower or "json" in filename_lower:
        return "formatter"
    else:
        return "unknown"


if __name__ == "__main__":
    import torch
    port = int(os.getenv("PORT", "8007"))
    uvicorn.run(app, host="0.0.0.0", port=port)

