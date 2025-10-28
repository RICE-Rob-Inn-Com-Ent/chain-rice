# God-Specific LoRA Training Interfaces

This directory contains **dedicated LoRA training interfaces** for each Egyptian AI god. Each god has its own
specialized training UI with fields specific to their domain.

## 🎯 Overview

Instead of a generic training interface, each god has a **custom training page** with data upload fields tailored to
their specific AI models and use cases.

## 📚 Thoth - NLP Stack Training

**File**: `ThothTraining.tsx`

**Training Types**:

- **Text Generation**: Fine-tune Mistral 7B on custom conversations and Q&A pairs
- **OCR & Document Analysis**: Train PaddleOCR and Donut on scanned documents with ground truth labels
- **Translation**: Fine-tune Opus-MT on parallel corpus (source/target language pairs)

**Data Formats**:

- Text: `.txt`, `.json`, `.csv` (conversations, Q&A pairs)
- Documents: `.jpg`, `.png`, `.pdf` (scanned documents + OCR labels in JSON)
- Translation: CSV with `source` and `target` columns

## ☀️ Ra - Image & Video Generation Training

**File**: `RaTraining.tsx`

**Training Types**:

- **Image Generation**: Train Stable Diffusion 2.1 LoRA on custom styles/subjects
- **Image Upscaling**: Fine-tune RealESRGAN with low-res/high-res pairs
- **Style Transfer**: Train custom artistic style models

**Data Formats**:

- Generation: 20-100 images (min 512x512) + text captions + trigger word
- Upscaling: Paired low-res (256px) and high-res (2048px+) images
- Style: 10-50 style reference images + style description

## ✨ Isis - Medical & Audio AI Training

**File**: `IsisTraining.tsx`

**Training Types**:

- **Medical Imaging**: Train MONAI for organ/tumor segmentation
- **Voice Cloning**: Fine-tune XTTS on custom voice recordings
- **Music Generation**: Train MusicGen on specific music genres

**Data Formats**:

- Medical: DICOM/PNG scans + segmentation masks (anonymized, HIPAA compliant)
- Voice: WAV/MP3 audio (10-30 min) + transcriptions (`audio.wav|transcript` format)
- Music: 20-50 WAV/MP3 tracks of similar style + optional descriptions

**⚠️ Important**: Medical data must be anonymized (HIPAA/GDPR compliant) before upload.

## 🐱 Bastet - Computer Vision Training

**File**: `BastetTraining.tsx`

**Training Types**:

- **Face Recognition**: Train InsightFace on custom person datasets
- **Object Detection**: Fine-tune MMDetection with custom object classes
- **Pose Estimation**: Train MMPose with custom keypoint annotations

**Data Formats**:

- Faces: Folder structure (`person_1/`, `person_2/`, etc.) with 10-50 photos per person
- Objects: Images + COCO/YOLO format annotations (bounding boxes)
- Pose: Images + COCO keypoint format JSON (17-25 keypoints)

**Tools**: Use LabelImg, CVAT, or RoboFlow for creating annotations.

## ⚖️ Maat - Legal & Analytics Training

**File**: `MaatTraining.tsx`

**Training Types**:

- **Legal Analysis**: Fine-tune Mistral 7B on legal documents and questions
- **Sentiment Analysis**: Train XLM-RoBERTa on labeled sentiment data
- **Text Summarization**: Train abstractive summarization models

**Data Formats**:

- Legal: PDF/DOCX/TXT documents + Q&A pairs for legal questions
- Sentiment: CSV with `text` and `sentiment` columns (positive/negative/neutral)
- Summarization: CSV with `full_text` and `summary` columns

**⚠️ Important**: Anonymize client data (GDPR compliant) before upload.

## 🏺 Khnum - 3D & Game AI Training

**File**: `KhnumTraining.tsx`

**Training Types**:

- **3D Modeling**: Train Tripo SR on custom 3D model datasets
- **Code Generation**: Fine-tune StarCoder 7B on specific codebases
- **Game AI & Recommendations**: Train RecBole on user-item interaction data

**Data Formats**:

- 3D: OBJ/FBX/GLB models + multi-view reference images (front/side/top views)
- Code: ZIP archive or Git repo URL + optional code-comment pairs
- Game AI: CSV with `user_id`, `item_id`, `rating`, `timestamp` columns

## 🚀 How to Use

1. **From Dashboard**: Click the **"Train LoRA"** button on any god card
2. **Select Training Type**: Choose which specific model to train (e.g., Text Generation, OCR, Image Generation)
3. **Upload Data**: Use the drag-and-drop interfaces or file browsers to upload your training data
4. **Configure Training**: Set epochs, learning rate, batch size, LoRA rank
5. **Start Training**: Click "Start Training" and monitor progress (loss, accuracy, time remaining)
6. **Deploy**: Once complete, deploy the trained LoRA to a container and add it back to the dashboard

## 📊 Training Configuration

All interfaces include:

- **Epochs**: Number of training iterations
- **Learning Rate**: Step size for optimization (varies by model)
- **Batch Size**: Number of samples per training step
- **LoRA Rank**: Rank of low-rank adaptation matrices (typically 4-64)

## 🔄 Training Flow

```
Dashboard → Train LoRA → Select Type → Upload Data → Configure → Train → Deploy
```

## 📝 Data Preparation Tips

- **Quality over Quantity**: 50 high-quality examples > 500 low-quality ones
- **Consistency**: Keep naming conventions, formats, and quality consistent
- **Diversity**: Include varied examples (angles, lighting, contexts)
- **Privacy**: Always anonymize sensitive data (faces, medical info, personal data)
- **Validation**: Keep 10-20% of data for validation (not used in training)

## 🛠️ Backend Integration (Future)

Currently, these are **UI-only interfaces**. Backend API endpoints to implement:

- `POST /api/lora/train` - Start training job
- `GET /api/lora/status/:id` - Get training progress
- `POST /api/lora/deploy` - Deploy trained model to container
- `GET /api/lora/models` - List trained LoRA models

## 🎨 Customization

Each training interface can be extended with:

- Real-time preview of training results
- Advanced hyperparameter tuning
- Multi-GPU support
- Resume from checkpoint
- A/B testing between LoRA versions

---

**Built with**: React, TypeScript, Tailwind CSS, Iconify **Integrates with**: Ollama (localhost:11434) for model
management
