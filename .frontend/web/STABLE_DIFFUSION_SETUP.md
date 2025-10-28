# 🎨 Stable Diffusion WebUI Setup for Ra

## Quick Start

Ra używa **Automatic1111 Stable Diffusion WebUI** przez API. Aby używać prawdziwej generacji obrazów (zamiast
placeholderów), musisz uruchomić WebUI lokalnie.

## 📥 Instalacja Stable Diffusion WebUI

### Metoda 1: Automatic1111 (Recommended)

```bash
# Clone repository
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
cd stable-diffusion-webui

# Linux/Mac
./webui.sh --api --listen

# Windows
webui-user.bat --api --listen
```

### Metoda 2: Docker

```bash
docker run -d \
  --name sd-webui \
  --gpus all \
  -p 7860:7860 \
  -v ~/sd-models:/data/models \
  -v ~/sd-outputs:/output \
  sd-auto:latest \
  --api --listen
```

## ⚙️ Konfiguracja

### 1. Start WebUI with API enabled

```bash
cd stable-diffusion-webui
./webui.sh --api --listen --xformers --medvram
```

**Flags explanation:**

- `--api` - Enables REST API (required!)
- `--listen` - Makes API accessible from outside
- `--xformers` - Memory optimization (faster generation)
- `--medvram` - Optimize for 6-8GB VRAM
- `--lowvram` - Use if you have <6GB VRAM

### 2. Verify WebUI is running

Open browser: http://localhost:7860

You should see Stable Diffusion WebUI interface.

### 3. Test API

```bash
curl http://localhost:7860/sdapi/v1/sd-models
```

Should return list of available models in JSON.

## 🎯 Using Ra Demo

1. **Start Stable Diffusion WebUI** (port 7860)
2. **Open Ra Demo**: http://localhost:3001/demo/ra.html
3. **Check status**: Green dot = "WebUI Connected"
4. **Enter prompt** and click "✨ Generate"
5. **Wait** ~10-30 seconds (depending on GPU)
6. **Image appears!**

## 🚀 Features

### Text-to-Image

- Enter prompt: "A beautiful sunset over Egyptian pyramids"
- Negative prompt: "blurry, low quality"
- Adjust steps (10-100), CFG Scale (1-20)
- Select dimensions (512, 768, 1024)

### Upscaling (RealESRGAN)

- Click "⬆️ Upscale 4x" on generated image
- Uses RealESRGAN_x4plus model
- Increases resolution 4x (512 → 2048)

### Variations

- Click "🔄 Variations" to create similar images
- Uses img2img with same prompt
- Denoising strength: 0.5

## 📊 Performance

| GPU            | Resolution | Steps | Time |
| -------------- | ---------- | ----- | ---- |
| RTX 3060 (6GB) | 512x512    | 30    | ~15s |
| RTX 3060 (6GB) | 768x768    | 30    | ~30s |
| RTX 3060 (6GB) | 1024x1024  | 30    | ~60s |
| RTX 4090       | 512x512    | 30    | ~3s  |

## 🔧 Troubleshooting

### "WebUI Offline - Using placeholders"

**Problem**: Ra can't connect to Stable Diffusion WebUI

**Solutions**:

1. Check if WebUI is running: `curl http://localhost:7860/sdapi/v1/sd-models`
2. Start WebUI with `--api --listen` flags
3. Check firewall blocking port 7860
4. Restart Vite dev server: `yarn dev`

### CORS Errors

Vite proxy should handle CORS automatically. If you see CORS errors:

1. Check `vite.config.ts` has `/api/sd` proxy configured
2. Restart Vite: `Ctrl+C` then `yarn dev`
3. Clear browser cache

### Out of Memory (CUDA OOM)

**Solutions**:

1. Reduce image size (1024 → 768 or 512)
2. Reduce steps (30 → 20)
3. Use `--lowvram` or `--medvram` flags
4. Close other GPU applications

### Slow Generation

**Solutions**:

1. Install xformers: `pip install xformers`
2. Use `--xformers` flag when starting WebUI
3. Reduce steps to 20-25 (still good quality)
4. Use DPM++ 2M Karras sampler (faster)

## 📦 Recommended Models

### For 6GB VRAM:

- **Stable Diffusion 2.1 Base** (default) - 512-768 optimal
- **Realistic Vision V5.1** - Great for realistic images
- **Dreamshaper 8** - Artistic, good quality

### Download Models:

Place `.safetensors` files in:

```
stable-diffusion-webui/models/Stable-diffusion/
```

Or use WebUI UI: Settings → Stable Diffusion → Download Model

## 🎨 Example Prompts

### Egyptian Theme (for Ra):

```
masterpiece, highly detailed Egyptian pyramid at sunset,
golden hour lighting, palm trees, desert sand,
ancient architecture, volumetric lighting, 4k, photorealistic
```

### Fantasy Art:

```
fantasy landscape, floating islands, magical waterfalls,
glowing crystals, ethereal lighting, concept art,
detailed, trending on artstation
```

### Portrait:

```
portrait of a beautiful woman, Egyptian queen,
golden jewelry, detailed face, cinematic lighting,
realistic skin texture, professional photography
```

## 🔗 API Endpoints Used

Ra uses these WebUI endpoints:

- `GET /sdapi/v1/sd-models` - List models (health check)
- `POST /sdapi/v1/txt2img` - Generate images from text
- `POST /sdapi/v1/img2img` - Generate variations
- `POST /sdapi/v1/extra-single-image` - Upscale with RealESRGAN
- `GET /sdapi/v1/progress` - Get generation progress
- `POST /sdapi/v1/interrupt` - Cancel generation

## 📚 Resources

- [Automatic1111 WebUI GitHub](https://github.com/AUTOMATIC1111/stable-diffusion-webui)
- [API Documentation](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/API)
- [Model Database](https://civitai.com/)
- [Prompt Guide](https://stable-diffusion-art.com/prompt-guide/)

---

**Status**: ✅ Integration Complete | 🎨 Ra Demo Ready  
**Port**: 7860 (Stable Diffusion WebUI)  
**Frontend**: 3001 (Vite Dashboard)
