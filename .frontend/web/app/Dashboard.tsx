import React, { useState } from "react";
import { Icon } from "@iconify/react";
import { useOllama } from "../lib/hooks/useOllama";

interface AIGod {
  id: string;
  name: string;
  subtitle: string;
  icon: string;
  gradient: string;
  description: string;
  features: string[];
  tech: string;
  ollamaModels: string[]; // Ollama model names for this god
}

const aiGods: AIGod[] = [
  {
    id: "thoth",
    name: "Thoth",
    subtitle: "Bóg Mądrości i Tekstu",
    icon: "📚",
    gradient: "from-blue-900 to-indigo-900",
    description: "NLP Stack • Przetwarzanie tekstu i dokumentów",
    features: ["Text Generation (Mistral 7B)", "OCR (PaddleOCR)", "Translation (Opus-MT)", "Document Analysis (Donut)"],
    tech: "Mistral 7B Q4 • PaddleOCR • Opus-MT",
    ollamaModels: ["mistral:7b-instruct-q4_K_M"],
  },
  {
    id: "ra",
    name: "Ra",
    subtitle: "Bóg Światła i Kreacji",
    icon: "☀️",
    gradient: "from-amber-900 to-orange-900",
    description: "Image & Video Generation • Kreacja wizualna",
    features: ["Image Generation (SD 2.1)", "Image Editing", "Upscaling (RealESRGAN)", "Style Transfer"],
    tech: "SD 2.1 FP16 • RealESRGAN • RVM",
    ollamaModels: ["stable-diffusion"],
  },
  {
    id: "isis",
    name: "Isis",
    subtitle: "Bogini Uzdrawiania i Audio",
    icon: "✨",
    gradient: "from-purple-900 to-pink-900",
    description: "Medical & Audio AI • Diagnostyka i synteza głosu",
    features: ["Medical Imaging (MONAI)", "Speech Synthesis (XTTS)", "Voice Cloning", "Music Generation"],
    tech: "MONAI • XTTS • MusicGen",
    ollamaModels: ["llama2:7b"],
  },
  {
    id: "bastet",
    name: "Bastet",
    subtitle: "Bogini Wzroku",
    icon: "🐱",
    gradient: "from-yellow-900 to-amber-900",
    description: "Computer Vision • Analiza obrazu w czasie rzeczywistym",
    features: [
      "Face Recognition (InsightFace)",
      "Pose Estimation (MMPose)",
      "Object Detection (MMDetection)",
      "Visual QA (LLaVa 7B)",
    ],
    tech: "InsightFace • MMDetection • LLaVa 7B",
    ollamaModels: ["llava:7b"],
  },
  {
    id: "maat",
    name: "Maat",
    subtitle: "Bogini Sprawiedliwości",
    icon: "⚖️",
    gradient: "from-cyan-900 to-blue-900",
    description: "Legal & Analytics AI • Analiza prawna i danych",
    features: ["Legal Analysis", "Sentiment Analysis", "Text Summarization", "Data Visualization"],
    tech: "Mistral 7B Q4 • XLM-RoBERTa",
    ollamaModels: ["mistral:7b-instruct-q4_K_M"],
  },
  {
    id: "khnum",
    name: "Khnum",
    subtitle: "Bóg Tworzenia 3D",
    icon: "🏺",
    gradient: "from-emerald-900 to-teal-900",
    description: "3D & Game AI • Modelowanie i rekomendacje",
    features: [
      "3D Modeling (Tripo SR)",
      "System Recommendations (RecBole)",
      "Code Generation (StarCoder 7B)",
      "Game AI",
    ],
    tech: "Tripo SR • RecBole • StarCoder 7B",
    ollamaModels: ["codellama:7b"],
  },
];

export const Dashboard: React.FC = () => {
  const { models, runningModels, isHealthy, loading, error, downloadProgress } = useOllama(3000);
  const [loadingGod, setLoadingGod] = useState<string | null>(null);

  const getGodStatus = (god: AIGod): "active" | "idle" | "loading" | "downloading" | "error" => {
    if (loadingGod === god.id) return "loading";

    // Check if any of this god's models are downloading
    for (const modelName of god.ollamaModels) {
      if (downloadProgress.has(modelName)) {
        return "downloading";
      }
    }

    // Check if any of this god's models are running
    const isRunning = god.ollamaModels.some((modelName) => runningModels.includes(modelName));
    if (isRunning) return "active";

    // Check if models are installed
    const hasModels = god.ollamaModels.some((modelName) =>
      models.some((m) => m.name.startsWith(modelName.split(":")[0]))
    );

    if (!hasModels && isHealthy) return "error"; // Models not downloaded
    return "idle";
  };

  const handleWakeGod = async (god: AIGod) => {
    setLoadingGod(god.id);
    console.log(`Waking ${god.name}...`);

    // Simulate wake process - in real implementation, this would:
    // 1. Check if another god is active
    // 2. Unload that god's models
    // 3. Load this god's models via Ollama
    setTimeout(() => {
      setLoadingGod(null);
      console.log(`${god.name} is now active`);
    }, 3000);
  };

  const getProgressForGod = (god: AIGod): number | null => {
    for (const modelName of god.ollamaModels) {
      const progress = downloadProgress.get(modelName);
      if (progress && progress.total > 0) {
        return Math.round((progress.completed / progress.total) * 100);
      }
    }
    return null;
  };

  return (
    <div className="p-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-white mb-2">Egyptian AI Dashboard</h1>
        <p className="text-gray-300">Monitor and manage your AI god stacks</p>

        {/* Ollama Status */}
        <div className="mt-4 flex items-center gap-3">
          <div className={`w-3 h-3 rounded-full ${isHealthy ? "bg-green-500" : "bg-red-500"} animate-pulse`} />
          <span className="text-white font-medium">
            Ollama: {isHealthy ? "Connected" : "Disconnected"}
          </span>
          {loading && <Icon icon="svg-spinners:90-ring-with-bg" width={20} className="text-white" />}
        </div>

        {error && (
          <div className="mt-4 bg-red-900/30 border border-red-500/30 rounded-lg p-3">
            <p className="text-red-400 text-sm">{error}</p>
          </div>
        )}
      </div>

      {/* Gods Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {aiGods.map((god) => {
          const status = getGodStatus(god);
          const progress = getProgressForGod(god);

          return (
            <div
              key={god.id}
              className={`bg-gradient-to-br ${god.gradient} rounded-xl border border-white/20 p-6 relative overflow-hidden`}
            >
              {/* Status Badge */}
              <div className="absolute top-4 right-4">
                {status === "active" && (
                  <span className="px-3 py-1 bg-green-500/20 text-green-400 border border-green-500/30 rounded-full text-xs font-semibold flex items-center gap-1">
                    <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
                    ACTIVE
                  </span>
                )}
                {status === "idle" && (
                  <span className="px-3 py-1 bg-gray-500/20 text-gray-400 border border-gray-500/30 rounded-full text-xs font-semibold">
                    IDLE
                  </span>
                )}
                {status === "loading" && (
                  <span className="px-3 py-1 bg-yellow-500/20 text-yellow-400 border border-yellow-500/30 rounded-full text-xs font-semibold flex items-center gap-1">
                    <Icon icon="svg-spinners:90-ring-with-bg" width={16} />
                    LOADING
                  </span>
                )}
                {status === "downloading" && (
                  <span className="px-3 py-1 bg-blue-500/20 text-blue-400 border border-blue-500/30 rounded-full text-xs font-semibold flex items-center gap-1">
                    <Icon icon="svg-spinners:90-ring-with-bg" width={16} />
                    DOWNLOADING
                  </span>
                )}
                {status === "error" && (
                  <span className="px-3 py-1 bg-red-500/20 text-red-400 border border-red-500/30 rounded-full text-xs font-semibold">
                    NOT INSTALLED
                  </span>
                )}
              </div>

              {/* God Icon */}
              <div className="text-6xl mb-3">{god.icon}</div>

              {/* God Info */}
              <h2 className="text-2xl font-bold text-white mb-1">{god.name}</h2>
              <p className="text-gray-300 text-sm mb-3">{god.subtitle}</p>
              <p className="text-gray-400 text-sm mb-4">{god.description}</p>

              {/* Features */}
              <div className="space-y-1 mb-4">
                {god.features.map((feature, idx) => (
                  <div key={idx} className="flex items-start gap-2 text-xs text-gray-300">
                    <span className="text-green-400 mt-0.5">✓</span>
                    <span>{feature}</span>
                  </div>
                ))}
              </div>

              {/* Tech Stack */}
              <div className="bg-black/20 rounded-lg p-2 mb-4">
                <p className="text-xs text-gray-400">{god.tech}</p>
              </div>

              {/* Progress Bar */}
              {progress !== null && (
                <div className="mb-4">
                  <div className="flex justify-between text-xs text-gray-300 mb-1">
                    <span>Downloading...</span>
                    <span>{progress}%</span>
                  </div>
                  <div className="w-full h-2 bg-black/30 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-blue-500 to-purple-500 transition-all duration-300"
                      style={{ width: `${progress}%` }}
                    />
                  </div>
                </div>
              )}

              {/* Actions */}
              <div className="flex gap-2">
                {status === "idle" && (
                  <button
                    onClick={() => handleWakeGod(god)}
                    className="flex-1 px-4 py-2 bg-white/20 hover:bg-white/30 text-white rounded-lg font-semibold transition"
                  >
                    Wake Model
                  </button>
                )}
                {status === "active" && (
                  <button className="flex-1 px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg font-semibold transition">
                    Try Demo →
                  </button>
                )}
                {status === "loading" && (
                  <button disabled className="flex-1 px-4 py-2 bg-white/10 text-gray-400 rounded-lg font-semibold cursor-not-allowed">
                    Loading...
                  </button>
                )}
                {status === "downloading" && (
                  <button disabled className="flex-1 px-4 py-2 bg-white/10 text-gray-400 rounded-lg font-semibold cursor-not-allowed">
                    Downloading...
                  </button>
                )}
                {status === "error" && (
                  <button className="flex-1 px-4 py-2 bg-red-500/30 hover:bg-red-500/50 text-red-300 rounded-lg font-semibold transition">
                    Install Models
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Info Section */}
      <div className="mt-8 bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-3">ℹ️ About GPU Management</h3>
        <ul className="space-y-2 text-gray-300 text-sm">
          <li>• Only ONE god can be ACTIVE at a time due to 6-8GB VRAM limit</li>
          <li>• ACTIVE = Model loaded on GPU and ready for inference</li>
          <li>• IDLE = Model not loaded, available to wake</li>
          <li>• Waking a new god will automatically sleep the active one</li>
          <li>• Models are managed through Ollama (localhost:11434)</li>
        </ul>
      </div>
    </div>
  );
};

