# 🤖 AI Models Installation Guide

**System Specs:** AMD Ryzen 5 5600H + RTX 3060 Mobile (6GB VRAM) + 14GB RAM

## ✅ Successfully Installed Models & Libraries

### 🎨 Image Generation & Processing

- ✅ **Stable Diffusion 1.5/XL** - Image generation (via `diffusers`)
- ✅ **PaddleOCR** - OCR text recognition (~200MB model, multilingual)
- ✅ **RealESRGAN** - Image upscaling 2x/4x (via `basicsr`)
- ✅ **Ultralytics YOLOv8** - Object detection, segmentation, pose
- ✅ **InsightFace** - Face recognition & analysis
- ✅ **rembg** - Background removal
- ✅ **ControlNet** - Conditional image generation
- ✅ **MediaPipe** - Pose, hands, face detection

### 🔤 Text Generation & NLP

- ✅ **Mistral-7B** (through Ollama, 4-bit quantized recommended)
- ✅ **CodeLlama-7B** (through Ollama)
- ✅ **spaCy 3.8** - NLP processing
- ✅ **XLM-RoBERTa** - Multilingual embeddings (via `transformers`)
- ✅ **Opus-MT** - Translation models (via `transformers`)
- ✅ **sentence-transformers** - Sentence embeddings
- ✅ **textblob** - Simple sentiment analysis

### 🎵 Audio Processing

- ✅ **librosa** - Audio analysis & feature extraction
- ✅ **soundfile** - Audio I/O
- ✅ **pydub** - Audio manipulation
- ⚠️ **XTTS v2** - NOT COMPATIBLE with Python 3.13 (requires <3.12)
- ⚠️ **AudioCraft/MusicGen** - NOT COMPATIBLE with Python 3.13

### 📊 Data & Finance

- ✅ **yfinance** - Stock data
- ✅ **pandas-ta** - Technical analysis
- ✅ **pyod** - Anomaly detection (20+ algorithms)
- ✅ **MLflow** - Experiment tracking
- ✅ **Weights & Biases** - Experiment tracking (cloud)
- ✅ **TensorBoard** - Visualization

### 🎮 Reinforcement Learning & Game AI

- ✅ **Gymnasium** - RL environments (OpenAI Gym successor)
- ✅ **Stable-Baselines3** - RL algorithms (PPO, A2C, SAC, TD3)
- ✅ **RecBole** - Recommendation systems

### 🌐 RAG & Vector Databases

- ✅ **LangChain** - LLM application framework
- ✅ **LangGraph** - Agent workflows
- ✅ **LlamaIndex** - RAG framework
- ✅ **ChromaDB** - Vector database
- ✅ **Qdrant** - Vector database
- ✅ **FAISS** - Similarity search

### 🎯 UI & Deployment

- ✅ **Gradio** - Quick ML UI demos
- ✅ **Streamlit** - Dashboard building
- ✅ **FastAPI** - API framework

---

## ⚠️ Python 3.13 Compatibility Issues

**Not Working:**

1. **TTS (Coqui XTTS)** - Requires Python <3.12
2. **AudioCraft (MusicGen)** - Requires spacy <3.6 which doesn't compile on 3.13
3. **MMDetection/MMPose** - Compilation issues

**Workarounds:**

- For TTS: Use cloud APIs (ElevenLabs, Google TTS) or downgrade to Python 3.11
- For MusicGen: Wait for Python 3.13 support or use Docker with Python 3.11
- For MMDetection: Use Ultralytics YOLOv8 (better alternative)

---

## 🚀 Quick Start Examples

### 1. Image Generation (Stable Diffusion)

```python
from diffusers import StableDiffusionPipeline
import torch

pipe = StableDiffusionPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5",
    torch_dtype=torch.float16
).to("cuda")

image = pipe("A beautiful sunset over mountains").images[0]
image.save("output.png")
```

### 2. OCR (PaddleOCR)

```python
from paddleocr import PaddleOCR

ocr = PaddleOCR(use_angle_cls=True, lang='en')
result = ocr.ocr('image.jpg', cls=True)

for line in result[0]:
    print(line[1][0])  # Recognized text
```

### 3. Object Detection (YOLOv8)

```python
from ultralytics import YOLO

model = YOLO('yolov8n.pt')
results = model('image.jpg')

for r in results:
    print(r.boxes)  # Detected boxes
    r.show()  # Display results
```

### 4. Face Recognition (InsightFace)

```python
import insightface
from insightface.app import FaceAnalysis

app = FaceAnalysis()
app.prepare(ctx_id=0, det_size=(640, 640))

img = cv2.imread('image.jpg')
faces = app.get(img)

for face in faces:
    print(f"Age: {face.age}, Gender: {face.gender}")
    print(f"Embedding: {face.embedding.shape}")
```

### 5. Background Removal (rembg)

```python
from rembg import remove
from PIL import Image

input_img = Image.open('input.png')
output_img = remove(input_img)
output_img.save('output.png')
```

### 6. LLM Chat (Ollama + Mistral-7B)

```python
import ollama

response = ollama.chat(model='mistral:7b-instruct-q4_0', messages=[
    {'role': 'user', 'content': 'Explain quantum computing in simple terms'}
])
print(response['message']['content'])
```

### 7. Audio Analysis (librosa)

```python
import librosa
import matplotlib.pyplot as plt

y, sr = librosa.load('audio.wav')
tempo, beats = librosa.beat.beat_track(y=y, sr=sr)

print(f"Tempo: {tempo} BPM")

# Spectogram
S = librosa.feature.melspectrogram(y=y, sr=sr)
plt.figure(figsize=(10, 4))
librosa.display.specshow(librosa.power_to_db(S, ref=np.max))
plt.show()
```

### 8. Sentiment Analysis (spaCy + textblob)

```python
from textblob import TextBlob

text = "I love this product! It's amazing!"
blob = TextBlob(text)

print(f"Sentiment: {blob.sentiment.polarity}")  # -1 to 1
print(f"Subjectivity: {blob.sentiment.subjectivity}")  # 0 to 1
```

### 9. Stock Analysis (yfinance + pandas-ta)

```python
import yfinance as yf
import pandas_ta as ta

# Download stock data
df = yf.download("AAPL", start="2024-01-01", end="2024-12-31")

# Calculate technical indicators
df.ta.sma(length=20, append=True)  # Simple Moving Average
df.ta.rsi(append=True)  # Relative Strength Index
df.ta.bbands(append=True)  # Bollinger Bands

print(df.tail())
```

### 10. Anomaly Detection (PyOD)

```python
from pyod.models.iforest import IForest
import numpy as np

# Generate sample data
X_train = np.random.randn(200, 2)
X_train = np.concatenate([X_train, np.random.randn(20, 2) + 5])  # Add outliers

# Train model
clf = IForest(contamination=0.1)
clf.fit(X_train)

# Predict
outlier_labels = clf.predict(X_train)  # 0 = inlier, 1 = outlier
outlier_scores = clf.decision_function(X_train)

print(f"Detected {sum(outlier_labels)} outliers")
```

---

## 📝 Model Recommendations for RTX 3060 Mobile (6GB VRAM)

### Image Generation

- ✅ **SD 1.5** - Perfect fit (~4GB VRAM)
- ✅ **SDXL** - Works with optimizations (--medvram)
- ❌ **FLUX.1** - Too large (needs 12-24GB VRAM)

### Text Generation

- ✅ **Mistral-7B-4bit** - ~3.5GB VRAM, great performance
- ✅ **Phi-3-mini (3.8B)** - ~2GB VRAM, fast
- ✅ **CodeLlama-7B-4bit** - ~3.5GB VRAM
- ❌ **Mistral-13B** - Too large even quantized
- ❌ **LLaVa-13B** - Use 7B version instead

### Vision Models

- ✅ **LLaVa-7B** - ~4GB VRAM, multimodal
- ✅ **BLIP-2** - ~3GB VRAM, image captioning
- ✅ **CLIPSeg** - ~2GB VRAM, segmentation

---

## 🔧 Optimization Tips

### 1. Use Quantization

```python
from transformers import AutoModelForCausalLM, BitsAndBytesConfig

bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_compute_dtype=torch.float16
)

model = AutoModelForCausalLM.from_pretrained(
    "mistralai/Mistral-7B-v0.1",
    quantization_config=bnb_config,
    device_map="auto"
)
```

### 2. Enable torch.compile()

```python
import torch

model = model.to("cuda")
model = torch.compile(model)  # ~20-30% speedup on RTX 3060
```

### 3. Use Flash Attention

```python
from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
    "model_name",
    attn_implementation="flash_attention_2",
    torch_dtype=torch.float16
)
```

### 4. Batch Processing

```python
# Process multiple items at once
results = model.generate(inputs, batch_size=4)
```

---

## 📥 Installing Models via Ollama

```bash
# Install Ollama (if not installed)
curl -fsSL https://ollama.ai/install.sh | sh

# Pull recommended models
ollama pull mistral:7b-instruct-q4_0    # Text generation (3.5GB)
ollama pull codellama:7b-instruct-q4_0  # Code generation (3.5GB)
ollama pull llava:7b-q4_0               # Vision + text (4GB)
ollama pull phi3:mini-q4_0              # Small fast model (2GB)

# Test model
ollama run mistral:7b-instruct-q4_0 "Hello!"
```

---

## 🐛 Troubleshooting

### Out of Memory (OOM)

```python
# Clear CUDA cache
import torch
torch.cuda.empty_cache()

# Enable gradient checkpointing
model.gradient_checkpointing_enable()

# Reduce batch size
batch_size = 1
```

### Slow Inference

```python
# Use FP16
model = model.half()

# Enable cuDNN autotuner
torch.backends.cudnn.benchmark = True

# Disable gradient computation
with torch.no_grad():
    output = model(input)
```

---

## 📚 Additional Resources

- [Hugging Face Model Hub](https://huggingface.co/models)
- [Ollama Model Library](https://ollama.ai/library)
- [Stable Diffusion Web UI](https://github.com/AUTOMATIC1111/stable-diffusion-webui)
- [LangChain Documentation](https://python.langchain.com/)
- [Ultralytics Documentation](https://docs.ultralytics.com/)

---

**Last Updated:** October 25, 2025 **Python Version:** 3.13.7 **CUDA Version:** 12.4 **Driver Version:** 580.95.05
