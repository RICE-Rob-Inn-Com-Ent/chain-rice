#!/usr/bin/env python3
"""
🎉 Demo Script - Wszystkie Zainstalowane Modele AI
Pokazuje przykłady użycia dla każdej kategorii modeli
"""

import torch

print(f"🔧 Python 3.11.11 + PyTorch {torch.__version__}")
print(f"🎮 CUDA: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"   Device: {torch.cuda.get_device_name(0)}")
    print(f"   VRAM: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f}GB\n")

print("=" * 70)
print("PRZYKŁADY UŻYCIA MODELI".center(70))
print("=" * 70 + "\n")

# ============================================================================
# 1. IMAGE GENERATION - Stable Diffusion
# ============================================================================
print("🎨 1. IMAGE GENERATION (Stable Diffusion)")
print("-" * 70)
print(
    """
from diffusers import StableDiffusionPipeline
import torch

pipe = StableDiffusionPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5",
    torch_dtype=torch.float16,
    safety_checker=None
).to("cuda")

# Generate image
image = pipe(
    "A beautiful sunset over mountains, oil painting",
    num_inference_steps=30,
    guidance_scale=7.5
).images[0]

image.save("sunset.png")
print("✅ Image saved as sunset.png (~8 seconds on RTX 3060)")
"""
)

# ============================================================================
# 2. OCR - PaddleOCR
# ============================================================================
print("\n📄 2. OCR (PaddleOCR)")
print("-" * 70)
print(
    """
from paddleocr import PaddleOCR
import cv2

ocr = PaddleOCR(use_angle_cls=True, lang='en', use_gpu=True)
result = ocr.ocr('document.jpg', cls=True)

for line in result[0]:
    text = line[1][0]
    confidence = line[1][1]
    print(f"Text: {text} (conf: {confidence:.2f})")

# Supports: en, ch, fr, german, korean, japanese, polish, etc.
"""
)

# ============================================================================
# 3. OBJECT DETECTION - YOLOv8
# ============================================================================
print("\n👁️ 3. OBJECT DETECTION (Ultralytics YOLOv8)")
print("-" * 70)
print(
    """
from ultralytics import YOLO

# Load model (auto-downloads if needed)
model = YOLO('yolov8n.pt')  # nano = fastest, s/m/l/x = bigger

# Inference
results = model('street.jpg')

# Display results
for r in results:
    boxes = r.boxes
    for box in boxes:
        cls = int(box.cls[0])
        conf = float(box.conf[0])
        print(f"Detected: {model.names[cls]} ({conf:.2f})")

# Save with bounding boxes
results[0].save('result.jpg')
print("✅ ~15ms inference time!")
"""
)

# ============================================================================
# 4. FACE RECOGNITION - InsightFace
# ============================================================================
print("\n😊 4. FACE RECOGNITION (InsightFace)")
print("-" * 70)
print(
    """
from insightface.app import FaceAnalysis
import cv2

app = FaceAnalysis(providers=['CUDAExecutionProvider'])
app.prepare(ctx_id=0, det_size=(640, 640))

img = cv2.imread('photo.jpg')
faces = app.get(img)

for face in faces:
    print(f"Age: {face.age}, Gender: {'M' if face.gender==1 else 'F'}")
    print(f"Bbox: {face.bbox}")
    print(f"Embedding shape: {face.embedding.shape}")  # 512-d vector

# Face comparison
similarity = np.dot(face1.embedding, face2.embedding)
print(f"Similarity: {similarity:.2f}")
"""
)

# ============================================================================
# 5. VOICE SYNTHESIS - XTTS v2
# ============================================================================
print("\n🗣️ 5. VOICE SYNTHESIS & CLONING (XTTS v2)")
print("-" * 70)
print(
    """
from TTS.api import TTS

# Initialize XTTS v2
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to("cuda")

# Simple TTS (text to speech)
tts.tts_to_file(
    text="Witaj! To jest synteza polskiego głosu.",
    file_path="polish_voice.wav",
    language="pl"
)

# Voice Cloning (najlepsza feature!)
tts.tts_to_file(
    text="This is cloned voice speaking",
    speaker_wav="reference_voice.wav",  # 6-10 sec sample needed
    language="en",
    file_path="cloned_output.wav"
)

print("✅ Supports: Polish, English, Spanish, French, German, +15 languages")
print("⚡ ~4 seconds per 10s audio on RTX 3060")
"""
)

# ============================================================================
# 6. MUSIC GENERATION - MusicGen
# ============================================================================
print("\n🎵 6. MUSIC GENERATION (AudioCraft/MusicGen)")
print("-" * 70)
print(
    """
from audiocraft.models import MusicGen
from audiocraft.data.audio import audio_write

# Load model (small = 300MB, medium = 1.5GB)
model = MusicGen.get_pretrained('facebook/musicgen-small')
model.set_generation_params(duration=8)  # 8 seconds

# Generate music from text
descriptions = [
    "upbeat electronic dance music with heavy bass",
    "calm piano melody for meditation",
    "epic orchestral soundtrack"
]

wav = model.generate(descriptions)  # Returns tensor

# Save
for idx, one_wav in enumerate(wav):
    audio_write(
        f'music_{idx}',
        one_wav.cpu(),
        model.sample_rate,
        strategy="loudness"
    )

print("✅ ~30 seconds generation time for 8s audio")
"""
)

# ============================================================================
# 7. TEXT GENERATION - LLM via Ollama
# ============================================================================
print("\n💬 7. TEXT GENERATION (Ollama + LangChain)")
print("-" * 70)
print(
    """
import ollama
from langchain_community.llms import Ollama as LangChainOllama
from langchain.prompts import PromptTemplate

# Simple chat
response = ollama.chat(
    model='mistral:7b-instruct-q4_0',
    messages=[{
        'role': 'user',
        'content': 'Wyjaśnij uczenie maszynowe w prosty sposób'
    }]
)
print(response['message']['content'])

# With LangChain
llm = LangChainOllama(model="mistral:7b-instruct-q4_0")
prompt = PromptTemplate.from_template("Napisz {count} {topic}")
chain = prompt | llm
result = chain.invoke({"count": "3", "topic": "haiku o AI"})
print(result)
"""
)

# ============================================================================
# 8. CODE GENERATION - CodeLlama
# ============================================================================
print("\n💻 8. CODE GENERATION (CodeLlama)")
print("-" * 70)
print(
    """
import ollama

response = ollama.chat(
    model='codellama:7b-instruct-q4_0',
    messages=[{
        'role': 'user',
        'content': '''Write a Python function to:
        - Read CSV file
        - Calculate moving average
        - Plot results with matplotlib
        '''
    }]
)

print(response['message']['content'])
# Returns complete, working code!
"""
)

# ============================================================================
# 9. VISION + TEXT - LLaVa
# ============================================================================
print("\n👁️💬 9. MULTIMODAL (LLaVa - Vision + Text)")
print("-" * 70)
print(
    """
import ollama

response = ollama.chat(
    model='llava:7b-q4_0',
    messages=[{
        'role': 'user',
        'content': 'Describe what you see in this image in detail',
        'images': ['photo.jpg']
    }]
)

print(response['message']['content'])
# Can answer questions about images!
"""
)

# ============================================================================
# 10. RAG APPLICATION - ChromaDB + LangChain
# ============================================================================
print("\n📚 10. RAG APPLICATION (ChromaDB + LangChain)")
print("-" * 70)
print(
    """
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.llms import Ollama
from langchain.chains import RetrievalQA
from langchain.text_splitter import RecursiveCharacterTextSplitter

# Load documents
with open("knowledge_base.txt") as f:
    text = f.read()

# Split into chunks
splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
chunks = splitter.split_text(text)

# Create embeddings
embeddings = OllamaEmbeddings(model="mistral:7b-instruct-q4_0")
vectordb = Chroma.from_texts(chunks, embeddings)

# Create RAG chain
llm = Ollama(model="mistral:7b-instruct-q4_0")
qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=vectordb.as_retriever()
)

# Ask questions
answer = qa_chain.invoke("What is the main topic of the document?")
print(answer)
"""
)

# ============================================================================
# 11. ANOMALY DETECTION - PyOD
# ============================================================================
print("\n🔍 11. ANOMALY DETECTION (PyOD)")
print("-" * 70)
print(
    """
from pyod.models.iforest import IForest
from pyod.models.knn import KNN
from pyod.models.autoencoder import AutoEncoder
import numpy as np

# Generate data
X_train = np.random.randn(200, 10)
X_test = np.random.randn(50, 10)

# Train Isolation Forest
clf = IForest(contamination=0.1, random_state=42)
clf.fit(X_train)

# Predict
y_pred = clf.predict(X_test)  # 0 = normal, 1 = anomaly
scores = clf.decision_function(X_test)

print(f"Detected {sum(y_pred)} anomalies")
print(f"Top 5 anomaly scores: {sorted(scores, reverse=True)[:5]}")
"""
)

# ============================================================================
# 12. REINFORCEMENT LEARNING - Stable Baselines 3
# ============================================================================
print("\n🎮 12. REINFORCEMENT LEARNING (Stable-Baselines3)")
print("-" * 70)
print(
    """
from stable_baselines3 import PPO
from stable_baselines3.common.env_util import make_vec_env
import gymnasium as gym

# Create environment
env = make_vec_env("CartPole-v1", n_envs=4)

# Train agent
model = PPO("MlpPolicy", env, verbose=1)
model.learn(total_timesteps=10000)

# Save model
model.save("ppo_cartpole")

# Test agent
obs = env.reset()
for _ in range(1000):
    action, _states = model.predict(obs)
    obs, rewards, dones, info = env.step(action)

print("✅ Agent trained!")
"""
)

# ============================================================================
# 13. EXPERIMENT TRACKING - MLflow
# ============================================================================
print("\n📊 13. EXPERIMENT TRACKING (MLflow)")
print("-" * 70)
print(
    """
import mlflow
from sklearn.ensemble import RandomForestClassifier
from sklearn.datasets import make_classification
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

# Start MLflow run
with mlflow.start_run():
    # Log parameters
    mlflow.log_param("n_estimators", 100)
    mlflow.log_param("max_depth", 10)

    # Train model
    X, y = make_classification(n_samples=1000)
    X_train, X_test, y_train, y_test = train_test_split(X, y)

    model = RandomForestClassifier(n_estimators=100, max_depth=10)
    model.fit(X_train, y_train)

    # Log metrics
    acc = accuracy_score(y_test, model.predict(X_test))
    mlflow.log_metric("accuracy", acc)

    # Log model
    mlflow.sklearn.log_model(model, "model")

print(f"✅ Experiment logged! View with: mlflow ui")
"""
)

# ============================================================================
# 14. UI DEMO - Gradio
# ============================================================================
print("\n🌐 14. QUICK UI DEMO (Gradio)")
print("-" * 70)
print(
    """
import gradio as gr
from TTS.api import TTS

# Load XTTS
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to("cuda")

def text_to_speech(text, language):
    output_path = "output.wav"
    tts.tts_to_file(
        text=text,
        language=language,
        file_path=output_path
    )
    return output_path

# Create UI
iface = gr.Interface(
    fn=text_to_speech,
    inputs=[
        gr.Textbox(label="Enter text"),
        gr.Dropdown(["en", "pl", "es", "fr", "de"], label="Language")
    ],
    outputs=gr.Audio(label="Generated Speech"),
    title="🗣️ XTTS Voice Synthesis",
    description="Generate speech in multiple languages"
)

# Launch
iface.launch(server_name="0.0.0.0", server_port=7860)
print("✅ UI running at http://localhost:7860")
"""
)

# ============================================================================
# 15. BACKGROUND REMOVAL
# ============================================================================
print("\n✂️ 15. BACKGROUND REMOVAL (rembg)")
print("-" * 70)
print(
    """
from rembg import remove
from PIL import Image

input_img = Image.open('photo.jpg')
output_img = remove(input_img)
output_img.save('photo_no_bg.png')

print("✅ Background removed! (~2 seconds)")
"""
)

# ============================================================================
# 16. IMAGE UPSCALING - RealESRGAN
# ============================================================================
print("\n🔍 16. IMAGE UPSCALING (RealESRGAN)")
print("-" * 70)
print(
    """
# Wymaga basicsr i gfpgan
# Przykład użycia:
import cv2
from basicsr.archs.rrdbnet_arch import RRDBNet
from realesrgan import RealESRGANer

model = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64, num_block=23, num_grow_ch=32)
upsampler = RealESRGANer(
    scale=4,
    model_path='RealESRGAN_x4plus.pth',
    model=model,
    tile=0,
    tile_pad=10,
    pre_pad=0,
    half=True  # FP16 dla RTX 3060
)

img = cv2.imread('low_res.jpg')
output, _ = upsampler.enhance(img, outscale=4)
cv2.imwrite('upscaled_4x.jpg', output)
"""
)

# ============================================================================
print("\n" + "=" * 70)
print("WIĘCEJ PRZYKŁADÓW W MODELS_README.md".center(70))
print("=" * 70)

print(
    """
\n📚 DOSTĘPNE PLIKI DOKUMENTACJI:

1. MODELS_README.md - Kompletny przewodnik z przykładami
2. OLLAMA_SETUP.md - Setup Ollama + modele
3. INSTALLATION_SUMMARY.md - Co zainstalowane
4. FINAL_SUMMARY.md - Pełne podsumowanie
5. demo_all_models.py - Ten plik

\n🚀 NASTĘPNE KROKI:

1. Zainstaluj Ollama:
   curl -fsSL https://ollama.ai/install.sh | sh
   ollama pull mistral:7b-instruct-q4_0

2. Download spaCy models:
   python -m spacy download en_core_web_sm
   python -m spacy download pl_core_news_sm

3. Testuj modele i buduj swoje aplikacje!

\n💪 MASZ TERAZ:
- ✅ Stable Diffusion (image gen)
- ✅ XTTS (voice cloning)
- ✅ MusicGen (music)
- ✅ YOLOv8 (detection)
- ✅ Mistral/CodeLlama (text/code)
- ✅ LLaVa (vision+text)
- ✅ RAG tools (LangChain+ChromaDB)
- ✅ ML tools (scikit, PyOD, SB3)
- ✅ UI frameworks (Gradio, Streamlit)

🎉 WSZYSTKO GOTOWE DO UŻYCIA!
"""
)

if __name__ == "__main__":
    print("\n💡 TIP: Przeczytaj ten plik jako przewodnik, nie uruchamiaj go bezpośrednio")
    print("   Każda sekcja to osobny przykład do skopiowania\n")
