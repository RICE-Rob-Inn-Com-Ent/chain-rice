# Ra - 6GB VRAM Optimization Guide

## Model Configuration

**Ra** jest zoptymalizowany pod **6GB VRAM** używając tylko **Stable Diffusion 2.1**.

### Aktywny Stack:

- ✅ **Stable Diffusion 2.1** (FP16) - Główny model generacji obrazów
- ✅ **RealESRGAN** - 4x upscaling (lazy load)
- ✅ **RVM** - Background removal (lazy load)

### Usunięte (za duże dla 6GB):

- ❌ **FLUX.1** - Wymaga 16GB+ VRAM
- ❌ **Tripo SR** - 3D modeling (heavy)
- ❌ Inne duże modele

## Memory Optimizations

### 1. **FP16 Precision**

```python
torch_dtype=torch.float16
```

Zmniejsza zużycie pamięci o ~50% vs FP32

### 2. **Attention Slicing**

```python
sd_pipeline.enable_attention_slicing(slice_size="auto")
```

Procesuje attention w mniejszych kawałkach, oszczędza VRAM

### 3. **VAE Slicing**

```python
sd_pipeline.enable_vae_slicing()
```

Koduje/dekoduje obrazy w tile'ach zamiast całości

### 4. **CUDA Cache Clearing**

```python
torch.cuda.empty_cache()
```

Czyści cache przed każdą generacją

## VRAM Usage

### Stable Diffusion 2.1 (512x512):

- **Bez optymalizacji**: ~8GB VRAM
- **Z optymalizacjami (FP16 + slicing)**: ~4-5GB VRAM ✅

### Generacja różnych rozmiarów:

| Rozdzielczość | VRAM (optimized) |
| ------------- | ---------------- |
| 512x512       | ~4.5GB           |
| 768x768       | ~5.5GB           |
| 1024x1024     | ~6GB (limit)     |

## Konfiguracja Kontenera

```yaml
# docker-compose.yml
ra:
  image: ra:1
  container_name: ra
  environment:
    - CUDA_VISIBLE_DEVICES=0
    - GOD_NAME=Ra
    - GOD_ID=ra
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
```

## API Endpoints

### Generate Image

```bash
curl -X POST http://localhost:8002/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A beautiful sunset over Egyptian pyramids",
    "negative_prompt": "blurry, low quality",
    "steps": 30,
    "cfg_scale": 7.5,
    "width": 512,
    "height": 512
  }'
```

### Health Check

```bash
curl http://localhost:8002/health
```

Response:

```json
{
  "status": "active",
  "god": "Ra",
  "vram": "6GB optimized",
  "models": {
    "image_gen": "Stable Diffusion 2.1 FP16 (lazy)",
    "upscaler": "RealESRGAN (lazy)",
    "bg_removal": "RVM (lazy)"
  },
  "optimizations": ["attention_slicing", "vae_slicing", "fp16"]
}
```

## Rebuild Container

Po zmianach przebuduj kontener:

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer

# Stop Ra
docker-compose stop ra

# Rebuild z nową konfiguracją
docker-compose build ra

# Start z nowymi optymalizacjami
docker-compose up -d ra

# Sprawdź logi
docker logs ra -f
```

## Performance Tips

### 1. **Używaj niższych steps dla szybszego generowania:**

- 20 steps - szybko (~15s), dobra jakość
- 30 steps - balans (~25s), bardzo dobra jakość
- 50 steps - wolno (~40s), najlepsza jakość

### 2. **Maksymalne rozmiary dla 6GB:**

- 512x512 - bezpieczne, zawsze działa
- 768x768 - działa, ale blisko limitu
- 1024x1024 - może być niestabilne

### 3. **CFG Scale:**

- 5-7 - bardziej kreatywne
- 7.5 - balans (recommended)
- 10-15 - ściśle trzyma się promptu

## Troubleshooting

### "CUDA out of memory"

1. Restart kontenera: `docker restart ra`
2. Zmniejsz rozdzielczość: 512x512
3. Zmniejsz steps: 20-25
4. Sprawdź czy inne procesy nie używają GPU

### Wolna generacja

1. Sprawdź czy GPU jest dostępne: `nvidia-smi`
2. Zweryfikuj CUDA: `docker exec ra nvidia-smi`
3. Restart Ra: `docker-compose restart ra`

---

**Model Size:** ~5GB (Stable Diffusion 2.1)
**Peak VRAM:** ~5.5GB during generation
**Safe Margin:** 0.5GB buffer dla systemu
**Status:** ✅ Optimized for 6GB VRAM
