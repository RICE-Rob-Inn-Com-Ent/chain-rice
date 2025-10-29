# 🎵 Bes - Egyptian God of Music and Voice

**Audio AI Service with Tortoise TTS, XTTS, and MusicGen**

Bes is the Egyptian god of music, dance, and celebration. In our AI pantheon, he represents audio AI capabilities.

## Features

### 🎤 Text-to-Speech (Tortoise TTS)
- High-quality neural TTS
- Multiple voice presets
- Natural-sounding speech generation

### 🗣️ Voice Cloning (XTTS)
- Clone any voice from a short audio sample
- Multilingual support
- Real-time voice synthesis

### 🎸 Music Generation (MusicGen)
- Generate music from text prompts
- Multiple genres and styles
- Customizable duration and temperature

### 🔊 Audio Enhancement
- Noise reduction
- Audio normalization
- Format conversion

## Quick Start

### Docker
```bash
# Build image
docker build -t bes:latest .

# Run container
docker run -d \
  --name bes \
  --gpus all \
  -p 8007:8007 \
  -v $(pwd)/output:/tmp/bes_output \
  bes:latest

# Check health
curl http://localhost:8007/health
```

### Docker Compose
```bash
# From rice-mono root
docker-compose up bes
```

## API Endpoints

### Health Check
```bash
GET /health
```

Returns:
```json
{
  "status": "active",
  "device": "cuda",
  "models": {
    "tortoise_tts": "loaded",
    "xtts": "loaded",
    "musicgen": "loaded"
  },
  "memory": {
    "total": "8.00 GB",
    "allocated": "2.34 GB",
    "cached": "3.12 GB"
  }
}
```

### Text-to-Speech
```bash
POST /tts
Content-Type: application/json

{
  "text": "Hello, I am Bes, the god of music!",
  "voice": "default",
  "preset": "fast"
}
```

Presets: `fast`, `standard`, `high_quality`

### Voice Cloning
```bash
POST /voice-clone
Content-Type: multipart/form-data

text: "This is a test of voice cloning"
reference_audio: <audio_file.wav>
```

### Music Generation
```bash
POST /music-gen
Content-Type: application/json

{
  "prompt": "upbeat electronic dance music",
  "duration": 10,
  "temperature": 1.0
}
```

### Get Audio File
```bash
GET /audio/{filename}
```

## Model Details

### Tortoise TTS
- **Purpose**: High-quality text-to-speech
- **Model**: tortoise-tts 2.8.0
- **VRAM**: ~2GB
- **Speed**: Fast preset ~5s, High quality ~30s per sentence

### XTTS (Coqui TTS)
- **Purpose**: Voice cloning and multilingual TTS
- **Model**: xtts_v2
- **VRAM**: ~2GB
- **Speed**: ~2s per sentence
- **Languages**: 17 languages supported

### MusicGen
- **Purpose**: Music generation from text
- **Model**: facebook/musicgen-small
- **VRAM**: ~4GB
- **Speed**: ~10s per 10 seconds of music

## VRAM Management

Bes uses **lazy loading** to optimize VRAM usage:

- Models load only when needed
- Total VRAM: ~4-6GB when all models loaded
- Models can be unloaded when not in use

## Port

**8007** - Bes Audio AI Service

## Integration

### Frontend (Port 3001)
Bes appears in the Dashboard alongside other Egyptian AI gods:

```typescript
{
  id: "bes",
  name: "Bes",
  subtitle: "Bóg Muzyki i Głosu",
  icon: "🎵",
  gradient: "from-indigo-900 to-purple-900",
  description: "Audio AI • Synteza głosu, klonowanie i generacja muzyki",
  features: [
    "TTS (Tortoise TTS)",
    "Voice Cloning (XTTS)",
    "Music Generation (MusicGen)",
    "Audio Enhancement"
  ],
  tech: "Tortoise TTS • XTTS • MusicGen"
}
```

### Demo
Access demo at: `http://localhost:3001` → Click "Try Demo" on Bes card

## Development

### Local Setup
```bash
# Create virtual environment
python3.10 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run server
python main.py
```

### Testing
```bash
# Test TTS
curl -X POST http://localhost:8007/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello Bes!", "preset": "fast"}'

# Test health
curl http://localhost:8007/health | jq
```

## Logs

View logs:
```bash
# Docker
docker logs -f bes

# Docker Compose
docker-compose logs -f bes
```

## Troubleshooting

### CUDA Out of Memory
- Use smaller models
- Reduce batch size
- Unload unused models

### Slow Generation
- Use `fast` preset for TTS
- Reduce music duration
- Check GPU utilization

### Models Not Loading
- Check CUDA availability
- Verify VRAM is sufficient (min 6GB recommended)
- Check internet connection (first run downloads models)

## References

- [Tortoise TTS](https://github.com/neonbjb/tortoise-tts)
- [Coqui TTS (XTTS)](https://github.com/coqui-ai/TTS)
- [MusicGen](https://huggingface.co/facebook/musicgen-small)

---

**🎵 Bes - Let the music play! 🎵**

