"""
Bes - Egyptian God of Music and Voice
FastAPI Backend for Audio AI Services

Features:
- Text-to-Speech (Tortoise TTS)
- Voice Cloning (XTTS)
- Music Generation (MusicGen)
- Audio Enhancement

Port: 8007
"""

import os
import time
from pathlib import Path
from typing import Optional, List
import torch
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# Create FastAPI app
app = FastAPI(
    title="Bes Audio AI",
    description="Egyptian God of Music and Voice - Audio AI Services",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global state
models_loaded = False
device = "cuda" if torch.cuda.is_available() else "cpu"
tortoise_model = None
xtts_model = None
musicgen_model = None

# Output directory
OUTPUT_DIR = Path("/tmp/bes_output")
OUTPUT_DIR.mkdir(exist_ok=True)

# ============================================================================
# Models
# ============================================================================

class TTSRequest(BaseModel):
    text: str
    voice: str = "default"
    preset: str = "fast"  # fast, standard, high_quality

class VoiceCloneRequest(BaseModel):
    text: str
    reference_audio: str  # path to reference audio

class MusicGenRequest(BaseModel):
    prompt: str
    duration: int = 10  # seconds
    temperature: float = 1.0

class HealthResponse(BaseModel):
    status: str
    device: str
    models: dict
    memory: dict

# ============================================================================
# Lazy Loading Functions
# ============================================================================

def load_tortoise_tts():
    """Load Tortoise TTS model (lazy loading)"""
    global tortoise_model
    if tortoise_model is None:
        print("🎵 Loading Tortoise TTS...")
        try:
            from tortoise.api import TextToSpeech
            tortoise_model = TextToSpeech(device=device)
            print("✅ Tortoise TTS loaded!")
        except Exception as e:
            print(f"❌ Error loading Tortoise TTS: {e}")
            raise
    return tortoise_model

def load_xtts():
    """Load XTTS model for voice cloning (lazy loading)"""
    global xtts_model
    if xtts_model is None:
        print("🎤 Loading XTTS (Voice Cloning)...")
        try:
            from TTS.api import TTS
            xtts_model = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to(device)
            print("✅ XTTS loaded!")
        except Exception as e:
            print(f"❌ Error loading XTTS: {e}")
            raise
    return xtts_model

def load_musicgen():
    """Load MusicGen model (lazy loading)"""
    global musicgen_model
    if musicgen_model is None:
        print("🎸 Loading MusicGen...")
        try:
            from transformers import MusicgenForConditionalGeneration, AutoProcessor
            musicgen_model = {
                "model": MusicgenForConditionalGeneration.from_pretrained("facebook/musicgen-small"),
                "processor": AutoProcessor.from_pretrained("facebook/musicgen-small")
            }
            musicgen_model["model"].to(device)
            print("✅ MusicGen loaded!")
        except Exception as e:
            print(f"❌ Error loading MusicGen: {e}")
            raise
    return musicgen_model

# ============================================================================
# Health Endpoint
# ============================================================================

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    
    # Check GPU memory
    memory_info = {}
    if torch.cuda.is_available():
        memory_info = {
            "total": f"{torch.cuda.get_device_properties(0).total_memory / 1024**3:.2f} GB",
            "allocated": f"{torch.cuda.memory_allocated(0) / 1024**3:.2f} GB",
            "cached": f"{torch.cuda.memory_reserved(0) / 1024**3:.2f} GB"
        }
    
    return {
        "status": "active" if models_loaded else "sleeping",
        "device": device,
        "models": {
            "tortoise_tts": "loaded" if tortoise_model is not None else "not_loaded",
            "xtts": "loaded" if xtts_model is not None else "not_loaded",
            "musicgen": "loaded" if musicgen_model is not None else "not_loaded"
        },
        "memory": memory_info
    }

# ============================================================================
# TTS Endpoints
# ============================================================================

@app.post("/tts")
async def text_to_speech(request: TTSRequest):
    """Generate speech from text using Tortoise TTS"""
    try:
        model = load_tortoise_tts()
        
        # Generate speech
        print(f"🎵 Generating speech: '{request.text[:50]}...'")
        
        # Get reference audio clips
        voice_samples = None
        conditioning_latents = None
        
        # Generate audio
        gen = model.tts_with_preset(
            request.text,
            voice_samples=voice_samples,
            conditioning_latents=conditioning_latents,
            preset=request.preset
        )
        
        # Save to file
        output_path = OUTPUT_DIR / f"tts_{int(time.time())}.wav"
        import torchaudio
        torchaudio.save(str(output_path), gen.squeeze(0).cpu(), 24000)
        
        return {
            "status": "success",
            "file": str(output_path),
            "duration": len(gen[0]) / 24000
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"TTS failed: {str(e)}")

@app.post("/voice-clone")
async def voice_clone(text: str, reference_audio: UploadFile = File(...)):
    """Clone voice and generate speech using XTTS"""
    try:
        model = load_xtts()
        
        # Save reference audio
        ref_path = OUTPUT_DIR / f"ref_{int(time.time())}.wav"
        with open(ref_path, "wb") as f:
            f.write(await reference_audio.read())
        
        # Generate cloned speech
        output_path = OUTPUT_DIR / f"cloned_{int(time.time())}.wav"
        model.tts_to_file(
            text=text,
            speaker_wav=str(ref_path),
            file_path=str(output_path),
            language="en"
        )
        
        return {
            "status": "success",
            "file": str(output_path)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Voice cloning failed: {str(e)}")

@app.post("/music-gen")
async def generate_music(request: MusicGenRequest):
    """Generate music from text prompt using MusicGen"""
    try:
        models = load_musicgen()
        model = models["model"]
        processor = models["processor"]
        
        # Prepare inputs
        inputs = processor(
            text=[request.prompt],
            padding=True,
            return_tensors="pt"
        ).to(device)
        
        # Generate music
        print(f"🎸 Generating music: '{request.prompt}'")
        audio_values = model.generate(
            **inputs,
            max_new_tokens=256,
            do_sample=True,
            temperature=request.temperature
        )
        
        # Save to file
        output_path = OUTPUT_DIR / f"music_{int(time.time())}.wav"
        import scipy.io.wavfile
        sampling_rate = model.config.audio_encoder.sampling_rate
        scipy.io.wavfile.write(str(output_path), rate=sampling_rate, data=audio_values[0, 0].cpu().numpy())
        
        return {
            "status": "success",
            "file": str(output_path),
            "prompt": request.prompt
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Music generation failed: {str(e)}")

@app.get("/audio/{filename}")
async def get_audio(filename: str):
    """Retrieve generated audio file"""
    file_path = OUTPUT_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(file_path, media_type="audio/wav")

# ============================================================================
# Preload Models (optional)
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """Startup event - can preload models here"""
    print("=" * 80)
    print("🎵 BES - Egyptian God of Music and Voice")
    print("=" * 80)
    print(f"Device: {device}")
    print(f"CUDA Available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"GPU: {torch.cuda.get_device_name(0)}")
        print(f"VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.2f} GB")
    print("=" * 80)
    print("🚀 Server ready on port 8007")
    print("📚 Docs: http://localhost:8007/docs")
    print("=" * 80)

# ============================================================================
# Run Server
# ============================================================================

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8007,
        reload=False,
        log_level="info"
    )

